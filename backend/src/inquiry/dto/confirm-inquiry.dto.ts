import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsOptional, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { InquiryItemDto } from './create-inquiry.dto';

export class ConfirmInquiryDto {
  @ApiPropertyOptional({ description: 'لیست نهایی و اصلاح شده اقلام توسط کارفرما', type: [InquiryItemDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => InquiryItemDto)
  items?: InquiryItemDto[];
}
