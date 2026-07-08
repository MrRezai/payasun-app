import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { ProfileController } from './profile.controller';
import { ProfileService } from './profile.service';
import { User } from '../entities/user.entity';
import { EmployerProfile } from '../entities/employer-profile.entity';
import { WelderProfile } from '../entities/welder-profile.entity';
import { Skill } from '../entities/skill.entity';

/**
 * Profile module handling CRUD operations for Employer and Welder profiles.
 * All endpoints require JWT authentication.
 */
@Module({
  imports: [TypeOrmModule.forFeature([User, EmployerProfile, WelderProfile, Skill])],
  controllers: [ProfileController],
  providers: [ProfileService],
  exports: [ProfileService],
})
export class ProfileModule {}
