import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsDateString,
  Matches,
  MaxLength,
} from 'class-validator';

export class CreateGuestPassDto {
  @ApiProperty({ example: 'Mohammed Ali' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  guestName: string;

  @ApiPropertyOptional({ example: '+9647501234567' })
  @IsString()
  @IsOptional()
  @Matches(/^\+?\d{10,15}$/, { message: 'guestPhone must be 10–15 digits' })
  guestPhone?: string;

  @ApiPropertyOptional({ example: 'IQ-123456789', description: 'National ID number' })
  @IsString()
  @IsOptional()
  @MaxLength(50)
  guestId?: string;

  @ApiPropertyOptional({ example: 'Family visit' })
  @IsString()
  @IsOptional()
  @MaxLength(200)
  purpose?: string;

  @ApiPropertyOptional({ description: 'Pass expiry date/time' })
  @IsDateString()
  @IsOptional()
  validUntil?: string;
}
