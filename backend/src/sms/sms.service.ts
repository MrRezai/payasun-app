import { Injectable, Logger, InternalServerErrorException } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';

/**
 * Service responsible for sending SMS messages through the MeliPayamak
 * REST API using the shared pattern (الگوی اشتراکی) endpoint.
 *
 * Supports an offline/debug mode controlled by the SMS_ENABLED environment
 * variable. When SMS_ENABLED=false, OTP codes are logged to the server
 * console instead of hitting the MeliPayamak API — essential for frontend
 * development without burning SMS wallet credit.
 *
 * API Docs: https://www.melipayamak.com
 * Endpoint: POST /api/SendSMS/BaseServiceNumber
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
   *
   * When false, sendOtp() will only log to console and skip the API call.
   */
  get isSmsEnabled(): boolean {
    const value = this.configService.get<string>('SMS_ENABLED', 'false');
    return value.toLowerCase() === 'true';
  }

  /**
   * Sends an OTP code to the specified phone number.
   *
   * - If SMS_ENABLED=true: dispatches via MeliPayamak shared pattern API.
   * - If SMS_ENABLED=false: logs the OTP to the NestJS server console only.
   *
   * @param phoneNumber - Iranian mobile number (e.g., "09121234567")
   * @param code        - The 5-digit OTP code to send
   * @throws InternalServerErrorException if SMS is enabled and the API call fails
   */
  async sendOtp(phoneNumber: string, code: string): Promise<void> {
    // ── Debug Mode: skip MeliPayamak, log to console ──────────────
    if (!this.isSmsEnabled) {
      this.logger.warn(
        `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`,
      );
      this.logger.warn(
        `🔧 [DEBUG MODE] SMS is disabled (SMS_ENABLED=false)`,
      );
      this.logger.warn(
        `📱 Phone: ${phoneNumber} | 🔑 OTP Code: ${code}`,
      );
      this.logger.warn(
        `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`,
      );
      return;
    }

    // ── Production Mode: send via MeliPayamak REST API ────────────
    const username = this.configService.get<string>('MELIPAYAMAK_USERNAME');
    const password = this.configService.get<string>('MELIPAYAMAK_PASSWORD');
    const bodyId = this.configService.get<number>('MELIPAYAMAK_BODY_ID');

    const payload = {
      username,
      password,
      to: phoneNumber,
      bodyId: Number(bodyId),
      text: code,
    };

    try {
      const response = await firstValueFrom(
        this.httpService.post(this.BASE_URL, payload, {
          headers: { 'Content-Type': 'application/json' },
          timeout: 10000,
        }),
      );

      this.logger.log(
        `SMS sent to ${phoneNumber} | Response: ${JSON.stringify(response.data)}`,
      );
    } catch (error: any) {
      this.logger.error(
        `Failed to send SMS to ${phoneNumber}: ${error.message}`,
        error.stack,
      );
      throw new InternalServerErrorException(
        'Failed to send SMS. Please try again later.',
      );
    }
  }
}
