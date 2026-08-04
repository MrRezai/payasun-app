import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class TestSimpleSmsDto {
  @ApiProperty({
    description: 'Target mobile phone number (e.g. 09121234567)',
    example: '09121234567',
  })
  @IsNotEmpty({ message: 'شماره تلفن همراه نمی‌تواند خالی باشد.' })
  @IsString()
  phone_number: string;

  @ApiProperty({
    description: 'Plain notification text message',
    example: 'پیامک آزمایشی اطلاع‌رسانی پایاپرداز',
  })
  @IsNotEmpty({ message: 'متن پیامک نمی‌تواند خالی باشد.' })
  @IsString()
  text: string;

  @ApiProperty({
    description: 'Optional sender line number override (e.g. 50001234)',
    example: '5000123456',
    required: false,
  })
  @IsOptional()
  @IsString()
  from_number?: string;
}
