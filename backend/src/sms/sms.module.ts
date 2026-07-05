import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { SmsService } from './sms.service';

/**
 * Module that encapsulates the MeliPayamak SMS gateway integration.
 * Exports SmsService for use by other modules (primarily AuthModule).
 */
@Module({
  imports: [
    HttpModule.register({
      timeout: 10000,
      maxRedirects: 3,
    }),
  ],
  providers: [SmsService],
  exports: [SmsService],
})
export class SmsModule {}
