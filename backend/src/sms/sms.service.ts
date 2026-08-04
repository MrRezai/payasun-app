import { Injectable, Logger, InternalServerErrorException, BadRequestException } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';

/**
 * Interface representing the response format from MeliPayamak BaseServiceNumber API.
 */
export interface MeliPayamakPatternResponse {
  Value: string;        // Delivery reference ID (15+ digits) or status code (e.g., "0", "11")
  RetStatus: number;    // 1 = Success, 0 = Error
  StrRetStatus: string; // Description from MeliPayamak
}

/**
 * Service responsible for sending SMS messages through the MeliPayamak
 * REST API using the shared pattern (الگوی اشتراکی / BaseServiceNumber) endpoint.
 *
 * Supports an offline/debug mode controlled by the SMS_ENABLED environment
 * variable. When SMS_ENABLED=false, OTP codes are logged to the server
 * console instead of hitting the MeliPayamak API — essential for frontend
 * development without burning SMS wallet credit.
 *
 * API Docs: https://www.melipayamak.com
 * Endpoint: POST https://rest.payamak-panel.com/api/SendSMS/BaseServiceNumber
 */
@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  private readonly BASE_URL =
    'https://rest.payamak-panel.com/api/SendSMS/BaseServiceNumber';

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Whether the MeliPayamak SMS gateway is enabled.
   * Reads the SMS_ENABLED environment variable (defaults to 'false').
   */
  get isSmsEnabled(): boolean {
    const value = this.configService.get<string>('SMS_ENABLED', 'false');
    return value.toLowerCase() === 'true';
  }

  /**
   * Normalizes Iranian mobile phone numbers into 11-digit format starting with 09.
   * Handles Persian/Arabic digits, +98/98 country prefixes, and whitespace/dashes.
   *
   * Examples:
   *  - "+989123456789" -> "09123456789"
   *  - "989123456789"  -> "09123456789"
   *  - "۹۱۲۳۴۵۶۷۸۹"     -> "09123456789"
   *  - "0912-345-6789"  -> "09123456789"
   */
  normalizePhoneNumber(phoneNumber: string): string {
    if (!phoneNumber) return '';

    // Convert Persian & Arabic digits to ASCII English digits
    let cleaned = phoneNumber
      .replace(/[۰-۹]/g, (d) => String(d.charCodeAt(0) - 1776))
      .replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - 1632))
      .replace(/[\s\-\(\)\+]/g, '');

    // Replace country prefixes (+98 or 98) with standard leading 0
    if (cleaned.startsWith('98') && cleaned.length === 12) {
      cleaned = '0' + cleaned.slice(2);
    } else if (cleaned.startsWith('9') && cleaned.length === 10) {
      cleaned = '0' + cleaned;
    }

    return cleaned;
  }

  /**
   * Sends a pattern-based SMS (الگوی اشتراکی) via MeliPayamak REST API.
   *
   * @param to - Target phone number (will be normalized)
   * @param textArgs - Single string or array of arguments matching pattern placeholders ({0}, {1}, ...)
   * @param bodyIdOverride - Optional custom bodyId/pattern ID to override env MELIPAYAMAK_BODY_ID
   */
  async sendPatternSms(
    to: string,
    textArgs: string | string[],
    bodyIdOverride?: number,
  ): Promise<{ success: boolean; recId?: string; message: string }> {
    const phoneNumber = this.normalizePhoneNumber(to);

    if (!/^09\d{9}$/.test(phoneNumber)) {
      this.logger.error(`Invalid mobile number format: "${to}" (normalized: "${phoneNumber}")`);
      throw new BadRequestException('شماره تلفن همراه وارد شده معتبر نیست.');
    }

    const textPayload = Array.isArray(textArgs) ? textArgs.join(';') : textArgs;

    // ── Debug Mode: skip API call, log to console ──────────────────
    if (!this.isSmsEnabled) {
      this.logger.warn(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      this.logger.warn(`🔧 [DEBUG MODE] SMS disabled (SMS_ENABLED=false)`);
      this.logger.warn(`📱 Phone: ${phoneNumber} | 💬 Text/Pattern Args: ${textPayload}`);
      this.logger.warn(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      return {
        success: true,
        message: `[DEBUG MODE] SMS simulated to ${phoneNumber}`,
      };
    }

    // ── Production Mode: validate credentials & call MeliPayamak ─────
    const username = this.configService.get<string>('MELIPAYAMAK_USERNAME');
    const password = this.configService.get<string>('MELIPAYAMAK_PASSWORD');
    const defaultBodyId =
      this.configService.get<number>('MELIPAYAMAK_OTP_BODY_ID') ??
      this.configService.get<number>('MELIPAYAMAK_BODY_ID');
    const bodyId = bodyIdOverride ?? defaultBodyId;

    if (!username || !password || !bodyId) {
      this.logger.error(
        `MeliPayamak credentials missing! Set MELIPAYAMAK_USERNAME, MELIPAYAMAK_PASSWORD, and MELIPAYAMAK_OTP_BODY_ID (or MELIPAYAMAK_BODY_ID).`,
      );
      throw new InternalServerErrorException(
        'پیکربندی سامانه پیامک کامل نیست. لطفاً با پشتیبانی تماس بگیرید.',
      );
    }

    const payload = {
      username,
      password,
      to: phoneNumber,
      bodyId: Number(bodyId),
      text: textPayload,
    };

    try {
      this.logger.log(
        `Dispatching pattern SMS to ${phoneNumber} using BodyID ${bodyId}...`,
      );

      const response = await firstValueFrom(
        this.httpService.post<MeliPayamakPatternResponse>(
          this.BASE_URL,
          payload,
          {
            headers: { 'Content-Type': 'application/json' },
            timeout: 10000,
          },
        ),
      );

      const data = response.data;
      this.logger.log(
        `MeliPayamak Raw Response: ${JSON.stringify(data)}`,
      );

      // Check MeliPayamak status response
      // RetStatus === 1 or Value length > 10 indicates success delivery recId
      const isSuccess =
        data &&
        (data.RetStatus === 1 || (data.Value && data.Value.length >= 10));

      if (!isSuccess) {
        const errorDesc = this.mapMeliPayamakError(data?.Value, data?.StrRetStatus);
        this.logger.error(
          `MeliPayamak Gateway Error: ${errorDesc} (Value: ${data?.Value}, RetStatus: ${data?.RetStatus})`,
        );
        throw new InternalServerErrorException(
          `ارسال پیامک نا موفق بود: ${data?.StrRetStatus || 'خطای سامانه پیامک'}`,
        );
      }

      this.logger.log(
        `SMS successfully dispatched to ${phoneNumber} | RecID: ${data.Value}`,
      );

      return {
        success: true,
        recId: data.Value,
        message: data.StrRetStatus || 'پیامک با موفقیت ارسال شد.',
      };
    } catch (error: any) {
      if (error instanceof InternalServerErrorException || error instanceof BadRequestException) {
        throw error;
      }

      this.logger.error(
        `Failed to communicate with MeliPayamak API: ${error?.message || error}`,
        error?.stack,
      );
      throw new InternalServerErrorException(
        'خطا در برقراری ارتباط با سامانه پیامک. لطفاً مجدداً تلاش کنید.',
      );
    }
  }

  /**
   * Sends an OTP code to the specified phone number using the dedicated OTP pattern ID (MELIPAYAMAK_OTP_BODY_ID).
   *
   * @param phoneNumber - Target Iranian mobile number
   * @param code - 5-digit OTP code to insert into pattern placeholder
   */
  async sendOtp(phoneNumber: string, code: string): Promise<void> {
    const otpBodyId =
      this.configService.get<number>('MELIPAYAMAK_OTP_BODY_ID') ??
      this.configService.get<number>('MELIPAYAMAK_BODY_ID');

    await this.sendPatternSms(
      phoneNumber,
      code,
      otpBodyId ? Number(otpBodyId) : undefined,
    );
  }

  /**
   * Maps MeliPayamak numeric error codes to human-readable Iranian Persian descriptions.
   */
  private mapMeliPayamakError(value?: string, defaultMsg?: string): string {
    switch (value) {
      case '0':
        return 'نام کاربری یا رمز عبور پنل ملی پیامک اشتباه است.';
      case '1':
        return 'اعتبار ریالی/پیامکی پنل کافی نیست.';
      case '2':
        return 'محدودیت ارسال روزانه سامانه فعال شده است.';
      case '6':
        return 'سامانه ملی پیامک در حال به‌روزرسانی می‌باشد.';
      case '7':
        return 'شماره گیرنده نامعتبر است.';
      case '11':
        return 'شناسه متن/پترن (Body ID) یافت نشد یا هنوز تایید نشده است.';
      case '35':
        return 'شماره گیرنده در لیست سیاه دریافت پیامک تبلیغاتی قرار دارد.';
      default:
        return defaultMsg || `خطای کد ${value} از سامانه ملی پیامک`;
    }
  }
}

