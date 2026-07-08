import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CacheModule } from '@nestjs/cache-manager';

import { AuthModule } from './auth/auth.module';
import { ProfileModule } from './profile/profile.module';
import { SmsModule } from './sms/sms.module';
import { InquiryModule } from './inquiry/inquiry.module';
import { GeoModule } from './geo/geo.module';

import { User } from './entities/user.entity';
import { EmployerProfile } from './entities/employer-profile.entity';
import { WelderProfile } from './entities/welder-profile.entity';
import { Inquiry } from './entities/inquiry.entity';
import { Skill } from './entities/skill.entity';

/**
 * Root application module that bootstraps:
 * - ConfigModule (global, reads .env)
 * - TypeORM (async PostgreSQL connection)
 * - CacheModule (global in-memory cache for OTP storage)
 * - Feature modules: AuthModule, ProfileModule, SmsModule, GeoModule
 */
@Module({
  imports: [
    // ── Global Config ────────────────────────────────────────────
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // ── Database ─────────────────────────────────────────────────
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DB_HOST', 'localhost'),
        port: configService.get<number>('DB_PORT', 5432),
        username: configService.get<string>('DB_USERNAME', 'postgres'),
        password: configService.get<string>('DB_PASSWORD', 'postgres'),
        database: configService.get<string>('DB_NAME', 'joftojoor_db'),
        entities: [User, EmployerProfile, WelderProfile, Inquiry, Skill],
        synchronize: true, // Auto-create tables in dev — disable in production!
        logging: ['error', 'warn'],
      }),
    }),

    // ── In-Memory Cache (for OTP storage) ────────────────────────
    CacheModule.register({
      isGlobal: true,
      ttl: 120 * 1000, // Default 2-minute TTL in milliseconds
      max: 10000,      // Maximum number of cached items
    }),

    // ── Feature Modules ──────────────────────────────────────────
    SmsModule,
    AuthModule,
    ProfileModule,
    InquiryModule,
    GeoModule,
  ],
})
export class AppModule {}
