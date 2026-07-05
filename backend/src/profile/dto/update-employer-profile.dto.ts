import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

/**
 * DTO for partially updating an employer's profile.
 * All fields are optional — only provided fields will be updated.
 */
export class UpdateEmployerProfileDto {
  @ApiPropertyOptional({
    description: 'Employer full name',
    example: 'علی رضایی',
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  full_name?: string;

  @ApiPropertyOptional({
    description: 'Employer city of operation',
    example: 'کرمان',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  city?: string;
}
