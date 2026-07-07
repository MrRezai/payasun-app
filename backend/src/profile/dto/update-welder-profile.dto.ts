import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsOptional, IsString, MaxLength, IsBoolean } from 'class-validator';

/**
 * DTO for partially updating a welder's profile.
 * All fields are optional — only provided fields will be updated.
 */
export class UpdateWelderProfileDto {
  @ApiPropertyOptional({
    description: 'Welder first name',
    example: 'محمد',
  })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  first_name?: string;

  @ApiPropertyOptional({
    description: 'Welder last name',
    example: 'احمدی',
  })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  last_name?: string;

  @ApiPropertyOptional({
    description: 'Welder home city / base of operations',
    example: 'کرمان',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  home_city?: string;

  @ApiPropertyOptional({
    description: 'Array of city names where the welder is willing to work',
    example: ['کرمان', 'بم', 'رفسنجان', 'جیرفت'],
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  active_cities?: string[];

  @ApiPropertyOptional({
    description: 'Welder biography — experience, facilities, specializations',
    example: 'جوشکار آرگون با ۱۰ سال سابقه کار. دارای کارگاه مجهز و امکانات حمل و نقل.',
  })
  @IsOptional()
  @IsString()
  bio?: string;

  @ApiPropertyOptional({
    description: 'Flag indicating if the onboarding setup is completed',
    example: true,
  })
  @IsOptional()
  @IsBoolean()
  is_setup_completed?: boolean;
}
