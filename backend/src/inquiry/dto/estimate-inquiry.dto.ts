import { ApiProperty } from '@nestjs/swagger';
import { IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { InquiryItemDto } from './create-inquiry.dto';

export class EstimateInquiryDto {
  @ApiProperty({ description: 'لیست اقلام برآورد شده توسط کارشناس', type: [InquiryItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => InquiryItemDto)
  items: InquiryItemDto[];
}
