import { Body, Controller, Get, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { SmsService } from './sms.service';
import { TestSmsDto } from './dto/test-sms.dto';
import { TestSimpleSmsDto } from './dto/test-simple-sms.dto';

@ApiTags('SMS Gateway')
@Controller('sms')
export class SmsController {
  constructor(private readonly smsService: SmsService) {}

  @Get('status')
  @ApiOperation({
    summary: 'Check SMS Gateway Status',
    description: 'Returns whether MeliPayamak Console SMS integration is enabled in production mode or offline debug mode.',
  })
  @ApiResponse({ status: 200, description: 'SMS gateway status details' })
  getStatus() {
    return {
      sms_enabled: this.smsService.isSmsEnabled,
      mode: this.smsService.isSmsEnabled ? 'PRODUCTION (MeliPayamak Console API)' : 'DEBUG (Console Log)',
    };
  }

  @Post('test')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Test MeliPayamak Console Pattern SMS Dispatch',
    description: 'Directly sends a test pattern SMS via MeliPayamak Console Shared API to verify API key and Body ID.',
  })
  @ApiResponse({ status: 200, description: 'SMS pattern test result' })
  async testSms(@Body() dto: TestSmsDto) {
    const result = await this.smsService.sendPatternSms(
      dto.phone_number,
      dto.text,
      dto.body_id,
    );
    return result;
  }

  @Post('test-simple')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Test MeliPayamak Console Simple Notification SMS Dispatch',
    description: 'Directly sends a plain notification SMS via MeliPayamak Console Simple API.',
  })
  @ApiResponse({ status: 200, description: 'Simple SMS test result' })
  async testSimpleSms(@Body() dto: TestSimpleSmsDto) {
    const result = await this.smsService.sendSimpleSms(
      dto.phone_number,
      dto.text,
      dto.from_number,
    );
    return result;
  }
}

