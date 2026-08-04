import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, IsNumber } from 'class-validator';

export class TestSmsDto {
  @ApiProperty({
    description: 'Target mobile phone number (e.g. 09121234567)',
    example: '09121234567',
  })
  @IsNotEmpty({ message: 'شماره تلفن همراه نمی‌تواند خالی باشد.' })
  @IsString()
  phone_number: string;

  @ApiProperty({
    description: 'Pattern arguments (e.g. "12345" or "val1;val2")',
    example: '12345',
  })
  @IsNotEmpty({ message: 'متن/کد پترن نمی‌تواند خالی باشد.' })
  @IsString()
  text: string;

  @ApiProperty({
    description: 'Optional custom Body ID (Pattern ID) to test',
    example: 12345,
    required: false,
  })
  @IsOptional()
  @IsNumber({}, { message: 'Body ID باید عدد باشد.' })
  body_id?: number;
}
