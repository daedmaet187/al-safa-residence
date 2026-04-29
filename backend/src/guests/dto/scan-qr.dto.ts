import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class ScanQrDto {
  @ApiProperty({ description: 'QR code value (UUID)' })
  @IsString()
  @IsNotEmpty()
  qrCode: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  notes?: string;
}
