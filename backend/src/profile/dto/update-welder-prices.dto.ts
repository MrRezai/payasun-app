import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsNotEmpty,
  IsNumber,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';

/**
 * Represents a single pricing item in the welder's auto-pricing list.
 */
export class BasePriceItemDto {
  @ApiProperty({
    description: 'Title/description of the service',
    example: 'جوشکاری آرگون هر بند',
  })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({
    description: 'Unit of measurement for the service',
    example: 'هر بند',
  })
  @IsString()
  @IsNotEmpty()
  unit: string;

  @ApiProperty({
    description: 'Price per unit in Rials',
    example: 350000,
  })
  @IsNumber()
  @Min(0)
  price_per_unit: number;
}

/**
 * DTO for initializing or replacing the welder's entire base price list.
 * This is a PUT operation — the entire list is replaced.
 */
export class UpdateWelderPricesDto {
  @ApiProperty({
    description: 'Complete list of pricing items',
    type: [BasePriceItemDto],
    example: [
      { title: 'جوشکاری آرگون هر بند', unit: 'هر بند', price_per_unit: 350000 },
      { title: 'جوشکاری CO2 هر متر', unit: 'هر متر', price_per_unit: 200000 },
      { title: 'جوشکاری برق هر ساعت', unit: 'هر ساعت', price_per_unit: 500000 },
    ],
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => BasePriceItemDto)
  base_price_list: BasePriceItemDto[];
}
