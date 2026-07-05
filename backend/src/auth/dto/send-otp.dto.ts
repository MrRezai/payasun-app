import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, Matches } from 'class-validator';

/**
 * DTO for requesting an OTP code to be sent via SMS.
 */
export class SendOtpDto {
  @ApiProperty({
    description: 'Iranian mobile phone number starting with 09',
    example: '09121234567',
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^09\d{9}$/, {
    message: 'phone_number must be a valid Iranian mobile number (e.g., 09121234567)',
  })
  phone_number: string;
}
