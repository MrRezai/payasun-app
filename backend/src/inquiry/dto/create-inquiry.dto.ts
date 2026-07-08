import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsBoolean, IsOptional, IsArray, ValidateNested, IsNumber, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class InquiryItemDto {
  @ApiProperty({ description: 'عنوان قلم کالا یا خدمات', example: 'جوشکاری چهارچوب درب' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ description: 'واحد اندازه‌گیری', example: 'عدد' })
  @IsString()
  @IsNotEmpty()
  unit: string;

  @ApiProperty({ description: 'تعداد یا مقدار مورد نیاز', example: 5 })
  @IsNumber()
  @Min(0.01)
  quantity: number;
}

export class CreateInquiryDto {
  @ApiProperty({ description: 'عنوان استعلام', example: 'پروژه جوشکاری ساختمان مسکونی ۴ طبقه' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ description: 'توضیحات تکمیلی پروژه', example: 'نیاز به جوشکاری درب و پنجره و اسکلت فلزی سبک' })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiProperty({ description: 'شهر محل پروژه', example: 'کرمان' })
  @IsString()
  @IsNotEmpty()
  city: string;

  @ApiPropertyOptional({ description: 'استان محل پروژه', example: 'کرمان' })
  @IsOptional()
  @IsString()
  province?: string;

  @ApiPropertyOptional({ description: 'آیا استعلام دارای فایل پلان/نقشه است؟', default: false, example: false })
  @IsOptional()
  @IsBoolean()
  has_blueprint?: boolean;

  @ApiPropertyOptional({ description: 'لیست اقلام استعلام (اگر پلان آپلود نشود)', type: [InquiryItemDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => InquiryItemDto)
  items?: InquiryItemDto[];
}
