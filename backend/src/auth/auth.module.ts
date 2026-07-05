import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';

import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './strategies/jwt.strategy';
import { SmsModule } from '../sms/sms.module';
import { User } from '../entities/user.entity';
import { EmployerProfile } from '../entities/employer-profile.entity';
import { WelderProfile } from '../entities/welder-profile.entity';

/**
 * Authentication module handling OTP flow, JWT issuance, and user registration.
 *
 * Dependencies:
 * - SmsModule: for dispatching OTP codes via MeliPayamak
 * - CacheModule: registered globally in AppModule for OTP storage
 * - JwtModule: async-configured to read JWT_SECRET and JWT_EXPIRATION from env
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([User, EmployerProfile, WelderProfile]),
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: {
          expiresIn: configService.get<string>('JWT_EXPIRATION', '7d'),
        },
      }),
    }),
    SmsModule,
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
  exports: [AuthService, JwtStrategy, PassportModule],
})
export class AuthModule {}
