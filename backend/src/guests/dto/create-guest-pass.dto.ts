import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsDateString,
} from 'class-validator';

export class CreateGuestPassDto {
  @ApiProperty({ example: 'Mohammed Ali' })
  @IsString()
  @IsNotEmpty()
  guestName: string;

  @ApiPropertyOptional({ example: '+9647501234567' })
  @IsString()
  @IsOptional()
  guestPhone?: string;

  @ApiPropertyOptional({ example: 'IQ-123456789', description: 'National ID number' })
  @IsString()
  @IsOptional()
  guestId?: string;

  @ApiPropertyOptional({ example: 'Family visit' })
  @IsString()
  @IsOptional()
  purpose?: string;

  @ApiPropertyOptional({ description: 'Pass expiry date/time' })
  @IsDateString()
  @IsOptional()
  validUntil?: string;
}
