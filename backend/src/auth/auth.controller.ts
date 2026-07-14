import { Body, Controller, HttpCode, HttpStatus, Post, UseGuards, UnauthorizedException } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { AuthService } from './auth.service';
import { SendOtpDto } from './dto/send-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { SwitchRoleDto } from './dto/switch-role.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthenticatedUser } from './strategies/jwt.strategy';

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

  /**
   * POST /auth/switch-role
   *
   * Switches the active role of the authenticated user.
   */
  @Post('switch-role')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('access-token')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Switch User Role',
    description: 'Switches the active role of the authenticated user. If they do not possess the role, it adds it and initializes the profile.',
  })
  @ApiBody({ type: SwitchRoleDto })
  @ApiResponse({
    status: 200,
    description: 'Role switched successfully. New JWT token returned.',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized — missing or invalid JWT token.',
  })
  async switchRole(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: SwitchRoleDto,
  ): Promise<{ access_token: string }> {
    return this.authService.switchRole(user.id, dto.role);
  }

  /**
   * POST /auth/admin-login
   *
   * Validates admin credentials against environment variables
   * and returns the admin secret token.
   */
  @Post('admin-login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Admin Login',
    description: 'Validates admin credentials and returns the admin secret token.',
  })
  async adminLogin(
    @Body() body: any,
  ): Promise<{ token: string }> {
    const expectedUser = process.env.ADMIN_USERNAME || 'admin';
    const expectedPass = process.env.ADMIN_PASSWORD || 'adminpassword';
    if (body.username === expectedUser && body.password === expectedPass) {
      return { token: 'payasun_admin_secret_token_12345' };
    } else {
      throw new UnauthorizedException('نام کاربری یا رمز عبور ادمین نادرست است.');
    }
  }
}
