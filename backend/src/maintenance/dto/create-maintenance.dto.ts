import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  IsEnum,
  IsOptional,
  IsArray,
  IsUUID,
} from 'class-validator';
import { MaintenanceCategory, Priority } from '@prisma/client';

export class CreateMaintenanceDto {
  @ApiProperty({ description: 'Unit ID for this request' })
  @IsUUID()
  @IsNotEmpty()
  unitId: string;

  @ApiProperty({ example: 'Leaking faucet in kitchen' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ example: 'The kitchen faucet has been dripping constantly for 2 days' })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiProperty({ enum: MaintenanceCategory })
  @IsEnum(MaintenanceCategory)
  category: MaintenanceCategory;

  @ApiPropertyOptional({ enum: Priority, default: Priority.NORMAL })
  @IsEnum(Priority)
  @IsOptional()
  priority?: Priority;

  @ApiPropertyOptional({ type: [String] })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  photoUrls?: string[];
}
