import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, IsNumber, IsPositive } from 'class-validator';
import { PaymentMethod } from '@prisma/client';

export class PayBillDto {
  @ApiProperty({ enum: PaymentMethod })
  @IsEnum(PaymentMethod)
  method: PaymentMethod;

  @ApiProperty({ example: 150000 })
  @IsNumber()
  @IsPositive()
  amount: number;

  @ApiPropertyOptional({ example: 'TXN-123456' })
  @IsString()
  @IsOptional()
  reference?: string;
}
