import {
  BadRequestException,
  Inject,
  Injectable,
  Logger,
  UnauthorizedException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { Cache } from 'cache-manager';

import { User } from '../entities/user.entity';
import { EmployerProfile } from '../entities/employer-profile.entity';
import { WelderProfile } from '../entities/welder-profile.entity';
import { Role } from '../common/enums/role.enum';
import { SmsService } from '../sms/sms.service';

/** Cache key prefix for OTP codes */
const OTP_PREFIX = 'otp:';

/** OTP time-to-live in milliseconds (2 minutes) */
const OTP_TTL_MS = 2 * 60 * 1000;

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,

    @InjectRepository(EmployerProfile)
    private readonly employerProfileRepository: Repository<EmployerProfile>,

    @InjectRepository(WelderProfile)
    private readonly welderProfileRepository: Repository<WelderProfile>,

    @Inject(CACHE_MANAGER)
    private readonly cacheManager: Cache,

    private readonly jwtService: JwtService,
    private readonly smsService: SmsService,
  ) {}

  /**
   * Generates a random 5-digit OTP code, stores it in the in-memory cache
   * with a 2-minute TTL, and dispatches it to the user via MeliPayamak SMS.
   *
   * When SMS_ENABLED=false (debug mode), the OTP code is included in the
   * API response for frontend testing convenience.
   *
   * @param phoneNumber - The target Iranian mobile number
   * @returns Confirmation message, and optionally the OTP code in debug mode
   */
  async sendOtp(
    phoneNumber: string,
  ): Promise<{ message: string; otpCode?: string }> {
    const user = await this.userRepository.findOne({ where: { phone_number: phoneNumber } });
    if (user && user.is_blocked) {
      throw new BadRequestException('حساب شما مسدود شده است. لطفا با پشتیبانی تماس بگیرید.');
    }

    const code = Math.floor(10000 + Math.random() * 90000).toString();

    // Store in cache with 2-minute expiration
    await this.cacheManager.set(`${OTP_PREFIX}${phoneNumber}`, code, OTP_TTL_MS);

    this.logger.log(`OTP generated for ${phoneNumber}: ${code}`);

    // Send SMS via MeliPayamak (or log in debug mode)
    await this.smsService.sendOtp(phoneNumber, code);

    // In debug mode, return the OTP code directly in the response
    if (!this.smsService.isSmsEnabled) {
      return {
        message: 'OTP generated in debug mode.',
        otpCode: code,
      };
    }

    return { message: 'OTP code sent successfully.' };
  }

  /**
   * Validates the OTP code against the cached value, then either
   * creates a new user or authenticates an existing one.
   *
   * For new users:
   *   - Creates a User row with the specified role
   *   - Creates the corresponding profile row (EmployerProfile or WelderProfile)
   *
   * For existing users:
   *   - Verifies the role matches the original registration
   *   - Updates is_authenticated to true
   *
   * @param phoneNumber - The user's phone number
   * @param code        - The 5-digit OTP code to verify
   * @param role        - The role to register/authenticate as
   * @returns JWT access token
   */
  async verifyOtp(
    phoneNumber: string,
    code: string,
    role: Role,
  ): Promise<{ access_token: string }> {
    // Retrieve cached OTP
    const cachedCode = await this.cacheManager.get<string>(
      `${OTP_PREFIX}${phoneNumber}`,
    );

    if (!cachedCode) {
      throw new UnauthorizedException(
        'OTP code has expired. Please request a new one.',
      );
    }

    if (cachedCode !== code) {
      throw new UnauthorizedException('Invalid OTP code.');
    }

    // OTP is valid — remove it from cache to prevent reuse
    await this.cacheManager.del(`${OTP_PREFIX}${phoneNumber}`);

    // Find or create the user
    let user = await this.userRepository.findOne({
      where: { phone_number: phoneNumber },
    });

    if (user) {
      if (user.is_blocked) {
        throw new BadRequestException('حساب شما مسدود شده است. لطفا با پشتیبانی تماس بگیرید.');
      }
      // Ensure roles is initialized
      if (!user.roles) {
        user.roles = [user.role];
      }
      if (!user.initial_role) {
        user.initial_role = user.role;
      }

      // Check if user has the selected login role
      const hasRole = user.roles.includes(role);
      if (!hasRole) {
        throw new BadRequestException(
          `این شماره موبایل با نقش دیگری ثبت شده است. برای تغییر نقش ابتدا با نقش قبلی وارد شده و از داخل برنامه اقدام کنید.`,
        );
      }

      // Update active role to the logged-in role
      user.role = role;
      user.is_authenticated = true;
      user = await this.userRepository.save(user);

      this.logger.log(`Existing user authenticated: ${user.id} (active role: ${user.role})`);
    } else {
      // New user — create user + profile
      user = this.userRepository.create({
        phone_number: phoneNumber,
        role,
        initial_role: role,
        roles: [role],
        is_authenticated: true,
      });
      user = await this.userRepository.save(user);

      // Create the role-specific profile
      await this.createProfileForRole(user.id, role);

      this.logger.log(`New user created: ${user.id} (${role})`);
    }

    // Sign JWT
    const payload = {
      sub: user.id,
      role: user.role,
      phone_number: user.phone_number,
    };
    const access_token = this.jwtService.sign(payload);

    return { access_token };
  }

  /**
   * Switches the user's active role.
   * If the target role is not present in their roles, it adds it and creates the blank profile.
   */
  async switchRole(
    userId: string,
    targetRole: Role,
  ): Promise<{ access_token: string }> {
    let user = await this.userRepository.findOne({
      where: { id: userId },
    });
    if (!user) {
      throw new NotFoundException('User not found.');
    }

    if (user.is_blocked) {
      throw new BadRequestException('حساب شما مسدود شده است. لطفا با پشتیبانی تماس بگیرید.');
    }

    if (!user.roles) {
      user.roles = [user.role];
    }
    if (!user.initial_role) {
      user.initial_role = user.role;
    }

    // Add target role if not present
    if (!user.roles.includes(targetRole)) {
      user.roles.push(targetRole);
      // Create empty profile
      await this.createProfileForRole(user.id, targetRole);

      // Synchronize names upon initial creation
      if (targetRole === Role.EMPLOYER) {
        const welderProfile = await this.welderProfileRepository.findOne({
          where: { user_id: userId },
        });
        const employerProfile = await this.employerProfileRepository.findOne({
          where: { user_id: userId },
        });
        if (welderProfile && employerProfile) {
          employerProfile.first_name = welderProfile.first_name;
          employerProfile.last_name = welderProfile.last_name;
          await this.employerProfileRepository.save(employerProfile);
        }
      } else if (targetRole === Role.WELDER) {
        const employerProfile = await this.employerProfileRepository.findOne({
          where: { user_id: userId },
        });
        const welderProfile = await this.welderProfileRepository.findOne({
          where: { user_id: userId },
        });
        if (employerProfile && welderProfile) {
          welderProfile.first_name = employerProfile.first_name;
          welderProfile.last_name = employerProfile.last_name;
          await this.welderProfileRepository.save(welderProfile);
        }
      }
    }

    // Set user's active role to targetRole
    user.role = targetRole;
    user = await this.userRepository.save(user);

    // Sign new JWT
    const payload = {
      sub: user.id,
      role: user.role,
      phone_number: user.phone_number,
    };
    const access_token = this.jwtService.sign(payload);

    return { access_token };
  }

  /**
   * Creates the appropriate profile entity based on the user's role.
   */
  private async createProfileForRole(
    userId: string,
    role: Role,
  ): Promise<void> {
    if (role === Role.EMPLOYER) {
      const profile = this.employerProfileRepository.create({
        user_id: userId,
      });
      await this.employerProfileRepository.save(profile);
    } else if (role === Role.WELDER) {
      const profile = this.welderProfileRepository.create({
        user_id: userId,
        active_cities: [],
        base_price_list: [],
      });
      await this.welderProfileRepository.save(profile);
    }
  }
}
