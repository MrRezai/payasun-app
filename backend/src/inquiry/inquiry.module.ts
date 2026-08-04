import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Inquiry } from '../entities/inquiry.entity';
import { Offer } from '../entities/offer.entity';
import { AppSetting } from '../entities/app-setting.entity';
import { User } from '../entities/user.entity';
import { WelderProfile } from '../entities/welder-profile.entity';
import { InquiryDispatch } from '../entities/inquiry-dispatch.entity';
import { EmployerReview } from '../entities/employer-review.entity';
import { InquiryService } from './inquiry.service';
import { InquiryController } from './inquiry.controller';
import { WelderScoringService } from '../scoring/welder-scoring.service';
import { WelderLevelingService } from '../leveling/welder-leveling.service';
import { InquiryDispatchService } from '../dispatch/inquiry-dispatch.service';
import { SmsModule } from '../sms/sms.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Inquiry,
      Offer,
      AppSetting,
      User,
      WelderProfile,
      InquiryDispatch,
      EmployerReview,
    ]),
    SmsModule,
  ],
  controllers: [InquiryController],
  providers: [
    InquiryService,
    WelderScoringService,
    WelderLevelingService,
    InquiryDispatchService,
  ],
  exports: [
    InquiryService,
    WelderScoringService,
    WelderLevelingService,
    InquiryDispatchService,
  ],
})
export class InquiryModule {}

