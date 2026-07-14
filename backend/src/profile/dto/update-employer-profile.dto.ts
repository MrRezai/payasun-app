import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, IsBoolean } from 'class-validator';

/**
 * DTO for partially updating an employer's profile.
 * All fields are optional — only provided fields will be updated.
 */
export class UpdateEmployerProfileDto {
  @ApiPropertyOptional({
    description: 'Employer first name',
    example: 'علی',
  })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  first_name?: string;

  @ApiPropertyOptional({
    description: 'Employer last name',
    example: 'رضایی',
  })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  last_name?: string;

  @ApiPropertyOptional({
    description: 'Employer province of operation',
    example: 'تهران',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  province?: string;

  @ApiPropertyOptional({
    description: 'Employer city of operation',
    example: 'تهران',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  city?: string;

  @ApiPropertyOptional({
    description: 'Employer company/brand name',
    example: 'صنایع فلزی غرب',
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  company_name?: string;

  @ApiPropertyOptional({
    description: 'Employer bio or address',
    example: 'تهران، میدان ونک، خیابان ملاصدرا',
  })
  @IsOptional()
  @IsString()
  bio?: string;

  @ApiPropertyOptional({
    description: 'Indicates if profile setup wizard is completed',
    example: true,
  })
  @IsOptional()
  @IsBoolean()
  is_setup_completed?: boolean;

  @ApiPropertyOptional({
    description: 'Employer card number (16 digits)',
    example: '6037991122334455',
  })
  @IsOptional()
  @IsString()
  @MaxLength(30)
  card_number?: string;

  @ApiPropertyOptional({
    description: 'Employer Sheba number (without IR)',
    example: '120120000000012345678901',
  })
  @IsOptional()
  @IsString()
  @MaxLength(40)
  shiba_number?: string;

  @ApiPropertyOptional({
    description: 'Employer bank name',
    example: 'بانک ملی',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  bank_name?: string;
}
