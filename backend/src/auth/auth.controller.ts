import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import {
  ApiBody,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { AuthService } from './auth.service';
import { SendOtpDto } from './dto/send-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';

@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * POST /auth/send-otp
   *
   * Generates a 5-digit OTP, caches it for 2 minutes, and sends it
   * to the provided phone number via MeliPayamak SMS gateway.
   *
   * When SMS_ENABLED=false (debug mode), the OTP code is returned
   * directly in the response body for frontend testing convenience.
   */
  @Post('send-otp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Send OTP Code',
    description:
      'Generates a 5-digit OTP code, stores it in an in-memory cache with ' +
      'a 2-minute expiration, and sends it to the specified phone number ' +
      'via the MeliPayamak shared pattern SMS gateway.\n\n' +
      '**Debug Mode** (`SMS_ENABLED=false`): The OTP code is returned ' +
      'directly in the response as `otpCode` instead of sending an SMS. ' +
      'This is intended for frontend development without consuming SMS credit.',
  })
  @ApiBody({ type: SendOtpDto })
  @ApiResponse({
    status: 200,
    description: 'OTP dispatched (via SMS or debug console).',
    schema: {
      type: 'object',
      properties: {
        message: {
          type: 'string',
          example: 'OTP code sent successfully.',
        },
        otpCode: {
          type: 'string',
          example: '12345',
          description: 'Only present when SMS_ENABLED=false (debug mode)',
          nullable: true,
        },
      },
    },
  })
  @ApiResponse({
    status: 400,
    description: 'Validation error — invalid phone number format.',
  })
  @ApiResponse({
    status: 500,
    description: 'SMS gateway failure (only when SMS_ENABLED=true).',
  })
  async sendOtp(
    @Body() dto: SendOtpDto,
  ): Promise<{ message: string; otpCode?: string }> {
    return this.authService.sendOtp(dto.phone_number);
  }

  /**
   * POST /auth/verify-otp
   *
   * Verifies the OTP code and role. On success, either creates a new user
   * (with the corresponding profile) or authenticates an existing one,
   * then returns a signed JWT Bearer token.
   */
  @Post('verify-otp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Verify OTP & Authenticate',
    description:
      'Validates the 5-digit OTP code against the cached value. If valid, ' +
      'creates a new user and profile (on first login) or authenticates an ' +
      'existing user, then returns a JWT Bearer access token. The role ' +
      'parameter determines whether an EmployerProfile or WelderProfile is created.',
  })
  @ApiBody({ type: VerifyOtpDto })
  @ApiResponse({
    status: 200,
    description: 'Authentication successful. JWT token returned.',
    schema: {
      type: 'object',
      properties: {
        access_token: {
          type: 'string',
          example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        },
      },
    },
  })
  @ApiResponse({
    status: 400,
    description: 'Validation error or role mismatch.',
  })
  @ApiResponse({
    status: 401,
    description: 'Invalid or expired OTP code.',
  })
  async verifyOtp(
    @Body() dto: VerifyOtpDto,
  ): Promise<{ access_token: string }> {
    return this.authService.verifyOtp(dto.phone_number, dto.code, dto.role);
  }
}
