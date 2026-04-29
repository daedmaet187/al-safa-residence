import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty } from 'class-validator';

export class PresignedUrlDto {
  @ApiProperty({ example: 'maintenance/photos/abc123.jpg' })
  @IsString()
  @IsNotEmpty()
  key: string;

  @ApiProperty({ example: 'image/jpeg' })
  @IsString()
  @IsNotEmpty()
  contentType: string;
}
