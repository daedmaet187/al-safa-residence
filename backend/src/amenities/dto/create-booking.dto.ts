import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, MaxLength, Matches } from 'class-validator';

const TIME_REGEX = /^\d{2}:\d{2}$/;

export class CreateBookingDto {
  @ApiProperty({ example: '2026-06-01', description: 'Booking date (YYYY-MM-DD)' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'date must be in YYYY-MM-DD format' })
  date: string;

  @ApiProperty({ example: '09:00', description: 'Start time (HH:MM)' })
  @IsString()
  @IsNotEmpty()
  @Matches(TIME_REGEX, { message: 'startTime must be in HH:MM format' })
  startTime: string;

  @ApiProperty({ example: '11:00', description: 'End time (HH:MM)' })
  @IsString()
  @IsNotEmpty()
  @Matches(TIME_REGEX, { message: 'endTime must be in HH:MM format' })
  endTime: string;

  @ApiPropertyOptional({ example: 'Birthday party for 10 guests' })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  notes?: string;
}
