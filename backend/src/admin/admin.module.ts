import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { ProfileModule } from '../profile/profile.module';
import { InquiryModule } from '../inquiry/inquiry.module';

@Module({
  imports: [ProfileModule, InquiryModule],
  controllers: [AdminController],
})
export class AdminModule {}
