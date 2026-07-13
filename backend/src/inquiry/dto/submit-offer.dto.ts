import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsBoolean, IsNumber, ValidateNested, IsString } from 'class-validator';
import { Type } from 'class-transformer';

export class OfferItemPriceDto {
  @ApiProperty({ description: 'عنوان ردیف فنی' })
  @IsString()
  title: string;

  @ApiProperty({ description: 'قیمت پیشنهادی به تومان' })
  @IsNumber()
  price: number;
}

export class SubmitOfferDto {
  @ApiProperty({ description: 'قیمت پیشنهادی اقلام', type: [OfferItemPriceDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OfferItemPriceDto)
  items_prices: OfferItemPriceDto[];

  @ApiProperty({ description: 'قیمت کل' })
  @IsNumber()
  total_price: number;

  @ApiProperty({ description: 'تامین زیر پایی' })
  @IsBoolean()
  scaffold_checked: boolean;

  @ApiProperty({ description: 'تامین برق' })
  @IsBoolean()
  power_checked: boolean;

  @ApiProperty({ description: 'تامین سیم جوش' })
  @IsBoolean()
  rod_checked: boolean;

  @ApiProperty({ description: 'تحویل آهن آلات' })
  @IsBoolean()
  delivery_checked: boolean;
}
