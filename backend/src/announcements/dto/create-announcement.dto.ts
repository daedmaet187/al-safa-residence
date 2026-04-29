import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  IsBoolean,
  IsOptional,
  IsDateString,
} from 'class-validator';

export class CreateAnnouncementDto {
  @ApiProperty({ example: 'Scheduled maintenance this weekend' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ example: 'Water will be shut off from 10am to 2pm on Saturday.' })
  @IsString()
  @IsNotEmpty()
  body: string;

  @ApiPropertyOptional({ default: false })
  @IsBoolean()
  @IsOptional()
  isImportant?: boolean;

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  expiresAt?: string;
}
