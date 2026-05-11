import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsNotEmpty, Matches } from 'class-validator';

export class UpdateProfileDto {
  @ApiPropertyOptional()
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional({ example: '+9647501234567' })
  @IsString()
  @IsOptional()
  @Matches(/^\+?\d{10,15}$/, { message: 'phone must be 10–15 digits' })
  phone?: string;
}
