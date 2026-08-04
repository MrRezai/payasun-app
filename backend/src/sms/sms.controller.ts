import { Body, Controller, Get, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { SmsService } from './sms.service';
import { TestSmsDto } from './dto/test-sms.dto';

@ApiTags('SMS Gateway')
@Controller('sms')
export class SmsController {
  constructor(private readonly smsService: SmsService) {}

  @Get('status')
  @ApiOperation({
    summary: 'Check SMS Gateway Status',
    description: 'Returns whether MeliPayamak SMS integration is enabled in production mode or offline debug mode.',
  })
  @ApiResponse({ status: 200, description: 'SMS gateway status details' })
  getStatus() {
    return {
      sms_enabled: this.smsService.isSmsEnabled,
      mode: this.smsService.isSmsEnabled ? 'PRODUCTION (MeliPayamak)' : 'DEBUG (Console Log)',
    };
  }

  @Post('test')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Test MeliPayamak Pattern SMS Dispatch',
    description: 'Directly sends a test pattern SMS via MeliPayamak REST BaseServiceNumber API to verify panel credentials and pattern ID.',
  })
  @ApiResponse({ status: 200, description: 'SMS test result' })
  async testSms(@Body() dto: TestSmsDto) {
    const result = await this.smsService.sendPatternSms(
      dto.phone_number,
      dto.text,
      dto.body_id,
    );
    return result;
  }
}
