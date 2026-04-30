import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsUUID, IsNumber, IsEnum, IsOptional, IsDateString } from 'class-validator';
import { BillType } from '@prisma/client';

export class CreateBillDto {
  @ApiProperty({ example: 'uuid-of-user' })
  @IsUUID()
  userId: string;

  @ApiProperty({ example: 'uuid-of-unit' })
  @IsUUID()
  unitId: string;

  @ApiProperty({ enum: BillType, example: 'MONTHLY_FEE' })
  @IsEnum(BillType)
  type: BillType;

  @ApiProperty({ example: 450000 })
  @IsNumber()
  amount: number;

  @ApiPropertyOptional({ example: 'IQD' })
  @IsString()
  @IsOptional()
  currency?: string;

  @ApiProperty({ example: '2026-05-15T00:00:00.000Z' })
  @IsDateString()
  dueDate: string;

  @ApiPropertyOptional({ example: 'Monthly service fee — May 2026' })
  @IsString()
  @IsOptional()
  description?: string;
}
