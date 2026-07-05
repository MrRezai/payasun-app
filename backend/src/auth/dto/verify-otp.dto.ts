import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsString, Length, Matches } from 'class-validator';
import { Role } from '../../common/enums/role.enum';

/**
 * DTO for verifying an OTP code and registering/authenticating the user.
 */
export class VerifyOtpDto {
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

  @ApiProperty({
    description: 'The 5-digit OTP code received via SMS',
    example: '12345',
  })
  @IsString()
  @IsNotEmpty()
  @Length(5, 5, { message: 'code must be exactly 5 digits' })
  @Matches(/^\d{5}$/, { message: 'code must contain only digits' })
  code: string;

  @ApiProperty({
    description: 'The role the user wants to register/authenticate as',
    enum: Role,
    example: Role.WELDER,
  })
  @IsEnum(Role, { message: 'role must be either EMPLOYER or WELDER' })
  @IsNotEmpty()
  role: Role;
}
