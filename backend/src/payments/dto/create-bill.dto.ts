import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsUUID, IsNumber, IsEnum, IsOptional, IsDateString, IsNotEmpty, IsPositive } from 'class-validator';
import { BillType } from '@prisma/client';

export class CreateBillDto {
  @ApiProperty({ example: 'uuid-of-user' })
  @IsUUID()
  @IsNotEmpty()
  userId: string;

  @ApiProperty({ example: 'uuid-of-unit' })
  @IsUUID()
  @IsNotEmpty()
  unitId: string;

  @ApiProperty({ enum: BillType, example: 'MONTHLY_FEE' })
  @IsEnum(BillType)
  @IsNotEmpty()
  type: BillType;

  @ApiProperty({ example: 450000, description: 'Amount in smallest unit' })
  @IsNumber()
  @IsPositive()
  amount: number;

  @ApiPropertyOptional({ example: 'IQD' })
  @IsString()
  @IsOptional()
  currency?: string;

  @ApiProperty({ example: '2026-05-15T00:00:00.000Z' })
  @IsDateString()
  @IsNotEmpty()
  dueDate: string;

  @ApiPropertyOptional({ example: 'Monthly service fee — May 2026' })
  @IsString()
  @IsOptional()
  description?: string;
}
