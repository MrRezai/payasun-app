import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { ProfileModule } from '../profile/profile.module';
import { InquiryModule } from '../inquiry/inquiry.module';
import { AppSetting } from '../entities/app-setting.entity';

@Module({
  imports: [ProfileModule, InquiryModule, TypeOrmModule.forFeature([AppSetting])],
  controllers: [AdminController],
})
export class AdminModule {}
