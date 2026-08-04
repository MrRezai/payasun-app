import { Injectable, Logger, InternalServerErrorException, BadRequestException } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';

/**
 * Response structure from MeliPayamak Console API (both shared pattern and simple send).
 */
export interface MeliPayamakConsoleResponse {
  recId?: number | string;
  status?: string;
}

/**
 * Service responsible for sending SMS messages through the modern MeliPayamak Console API.
 *
 * Endpoints:
 *  - Pattern SMS: POST https://console.melipayamak.com/api/send/shared/{API_KEY}
 *  - Simple SMS:  POST https://console.melipayamak.com/api/send/simple/{API_KEY}
 *
 * Supports an offline/debug mode controlled by the SMS_ENABLED environment
 * variable. When SMS_ENABLED=false, SMS messages are logged to the server console.
 */
@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  private readonly CONSOLE_SHARED_URL = 'https://console.melipayamak.com/api/send/shared';
  private readonly CONSOLE_SIMPLE_URL = 'https://console.melipayamak.com/api/send/simple';

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
   * Sends a pattern-based SMS (الگوی اشتراکی) via MeliPayamak Console API.
   *
   * POST https://console.melipayamak.com/api/send/shared/{API_KEY}
   * Body: { bodyId: number, to: string, args: string[] }
   *
   * @param to - Target phone number (will be normalized)
   * @param textArgs - Single string or array of arguments matching pattern placeholders ({0}, {1}, ...)
   * @param bodyIdOverride - Optional custom bodyId/pattern ID to override env MELIPAYAMAK_OTP_BODY_ID/MELIPAYAMAK_BODY_ID
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

    const argsArray = Array.isArray(textArgs)
      ? textArgs.map((arg) => String(arg))
      : [String(textArgs)];

    // ── Debug Mode: skip API call, log to console ──────────────────
    if (!this.isSmsEnabled) {
      this.logger.warn(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      this.logger.warn(`🔧 [DEBUG MODE] Shared Pattern SMS disabled (SMS_ENABLED=false)`);
      this.logger.warn(`📱 Phone: ${phoneNumber} | 💬 Pattern Args: ${JSON.stringify(argsArray)}`);
      this.logger.warn(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      return {
        success: true,
        message: `[DEBUG MODE] Pattern SMS simulated to ${phoneNumber}`,
      };
    }

    // ── Production Mode: validate credentials & call MeliPayamak Console API ─────
    const apiKey = this.configService.get<string>('MELIPAYAMAK_API_KEY');
    const defaultBodyId =
      this.configService.get<number>('MELIPAYAMAK_OTP_BODY_ID') ??
      this.configService.get<number>('MELIPAYAMAK_BODY_ID');
    const bodyId = bodyIdOverride ?? defaultBodyId;

    if (!apiKey || !bodyId) {
      this.logger.error(
        `MeliPayamak config missing! MELIPAYAMAK_API_KEY and MELIPAYAMAK_OTP_BODY_ID (or MELIPAYAMAK_BODY_ID) are required.`,
      );
      throw new InternalServerErrorException(
        'پیکربندی سامانه پیامک کامل نیست. لطفاً با پشتیبانی تماس بگیرید.',
      );
    }

    const url = `${this.CONSOLE_SHARED_URL}/${apiKey}`;
    const payload = {
      bodyId: Number(bodyId),
      to: phoneNumber,
      args: argsArray,
    };

    try {
      this.logger.log(
        `Dispatching Console Shared Pattern SMS to ${phoneNumber} (BodyID: ${bodyId}, Args: ${JSON.stringify(argsArray)})...`,
      );

      const response = await firstValueFrom(
        this.httpService.post<MeliPayamakConsoleResponse>(url, payload, {
          headers: { 'Content-Type': 'application/json' },
          timeout: 10000,
        }),
      );

      const data = response.data;
      this.logger.log(`MeliPayamak Shared Response: ${JSON.stringify(data)}`);

      // Check MeliPayamak Console response: recId present and non-zero/valid
      const hasRecId = data && data.recId !== undefined && data.recId !== null && Number(data.recId) > 0;

      if (!hasRecId) {
        this.logger.error(
          `MeliPayamak Shared Gateway Error: ${data?.status || 'No recId returned'}`,
        );
        throw new InternalServerErrorException(
          `ارسال پیامک پترن نا موفق بود: ${data?.status || 'خطای سامانه پیامک'}`,
        );
      }

      this.logger.log(
        `Pattern SMS successfully dispatched to ${phoneNumber} | RecID: ${data.recId}`,
      );

      return {
        success: true,
        recId: String(data.recId),
        message: data.status || 'پیامک با موفقیت ارسال شد.',
      };
    } catch (error: any) {
      if (error instanceof InternalServerErrorException || error instanceof BadRequestException) {
        throw error;
      }

      this.logger.error(
        `Failed to communicate with MeliPayamak Console API: ${error?.message || error}`,
        error?.stack,
      );
      throw new InternalServerErrorException(
        'خطا در برقراری ارتباط با سامانه پیامک. لطفاً مجدداً تلاش کنید.',
      );
    }
  }

  /**
   * Sends a simple/plain notification SMS via MeliPayamak Console API.
   *
   * POST https://console.melipayamak.com/api/send/simple/{API_KEY}
   * Body: { from: string, to: string, text: string }
   *
   * @param to - Target phone number (will be normalized)
   * @param text - Plain text message content
   * @param fromNumberOverride - Optional sender line override (defaults to MELIPAYAMAK_FROM_NUMBER)
   */
  async sendSimpleSms(
    to: string,
    text: string,
    fromNumberOverride?: string,
  ): Promise<{ success: boolean; recId?: string; message: string }> {
    const phoneNumber = this.normalizePhoneNumber(to);

    if (!/^09\d{9}$/.test(phoneNumber)) {
      this.logger.error(`Invalid mobile number format: "${to}" (normalized: "${phoneNumber}")`);
      throw new BadRequestException('شماره تلفن همراه وارد شده معتبر نیست.');
    }

    if (!text || text.trim().length === 0) {
      throw new BadRequestException('متن پیامک نمی‌تواند خالی باشد.');
    }

    // ── Debug Mode: skip API call, log to console ──────────────────
    if (!this.isSmsEnabled) {
      this.logger.warn(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      this.logger.warn(`🔧 [DEBUG MODE] Simple Notification SMS disabled (SMS_ENABLED=false)`);
      this.logger.warn(`📱 Phone: ${phoneNumber} | ✉️ Message: ${text}`);
      this.logger.warn(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      return {
        success: true,
        message: `[DEBUG MODE] Simple SMS simulated to ${phoneNumber}`,
      };
    }

    // ── Production Mode ──────────────────────────────────────────────
    const apiKey = this.configService.get<string>('MELIPAYAMAK_API_KEY');
    const defaultFrom = this.configService.get<string>('MELIPAYAMAK_FROM_NUMBER');
    const fromNumber = fromNumberOverride || defaultFrom;

    if (!apiKey || !fromNumber) {
      this.logger.error(
        `MeliPayamak config missing! Set MELIPAYAMAK_API_KEY and MELIPAYAMAK_FROM_NUMBER in environment.`,
      );
      throw new InternalServerErrorException(
        'پیکربندی خط ارسال پیامک اطلاع‌رسانی کامل نیست.',
      );
    }

    const url = `${this.CONSOLE_SIMPLE_URL}/${apiKey}`;
    const payload = {
      from: fromNumber,
      to: phoneNumber,
      text: text,
    };

    try {
      this.logger.log(
        `Dispatching Console Simple SMS to ${phoneNumber} from line ${fromNumber}...`,
      );

      const response = await firstValueFrom(
        this.httpService.post<MeliPayamakConsoleResponse>(url, payload, {
          headers: { 'Content-Type': 'application/json' },
          timeout: 10000,
        }),
      );

      const data = response.data;
      this.logger.log(`MeliPayamak Simple SMS Response: ${JSON.stringify(data)}`);

      const hasRecId = data && data.recId !== undefined && data.recId !== null && Number(data.recId) > 0;

      if (!hasRecId) {
        this.logger.error(
          `MeliPayamak Simple SMS Error: ${data?.status || 'No recId returned'}`,
        );
        throw new InternalServerErrorException(
          `ارسال پیامک اطلاع‌رسانی نا موفق بود: ${data?.status || 'خطای سامانه پیامک'}`,
        );
      }

      this.logger.log(
        `Simple SMS successfully dispatched to ${phoneNumber} | RecID: ${data.recId}`,
      );

      return {
        success: true,
        recId: String(data.recId),
        message: data.status || 'پیامک با موفقیت ارسال شد.',
      };
    } catch (error: any) {
      if (error instanceof InternalServerErrorException || error instanceof BadRequestException) {
        throw error;
      }

      this.logger.error(
        `Failed to send Simple SMS via MeliPayamak Console API: ${error?.message || error}`,
        error?.stack,
      );
      throw new InternalServerErrorException(
        'خطا در ارسال پیامک اطلاع‌رسانی. لطفاً مجدداً تلاش کنید.',
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
      [code],
      otpBodyId ? Number(otpBodyId) : undefined,
    );
  }
}


