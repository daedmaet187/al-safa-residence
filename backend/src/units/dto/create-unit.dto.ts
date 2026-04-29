import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  IsInt,
  IsNumber,
  IsOptional,
  IsPositive,
  Min,
} from 'class-validator';

export class CreateUnitDto {
  @ApiProperty({ example: 'A-101' })
  @IsString()
  @IsNotEmpty()
  number: string;

  @ApiProperty({ example: 1 })
  @IsInt()
  @Min(0)
  floor: number;

  @ApiPropertyOptional({ example: 'Tower A' })
  @IsString()
  @IsOptional()
  building?: string;

  @ApiProperty({ example: '2br', description: 'studio, 1br, 2br, 3br, penthouse' })
  @IsString()
  @IsNotEmpty()
  type: string;

  @ApiProperty({ example: 95.5, description: 'Area in sqm' })
  @IsNumber()
  @IsPositive()
  area: number;

  @ApiProperty({ example: 2 })
  @IsInt()
  @Min(0)
  bedrooms: number;

  @ApiProperty({ example: 2 })
  @IsInt()
  @Min(1)
  bathrooms: number;

  @ApiPropertyOptional({ example: 'P-42' })
  @IsString()
  @IsOptional()
  parkingSpot?: string;
}
