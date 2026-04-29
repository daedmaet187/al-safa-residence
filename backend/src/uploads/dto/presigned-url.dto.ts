import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsInt, Min, Max } from 'class-validator';

export class PresignedUrlDto {
  @ApiProperty({ example: 'uploads/user-id/photo.jpg' })
  @IsString()
  @IsNotEmpty()
  key: string;

  @ApiProperty({ example: 'image/jpeg' })
  @IsString()
  @IsNotEmpty()
  contentType: string;

  @ApiProperty({ description: 'File size in bytes (max 20MB)', example: 1048576 })
  @IsInt()
  @Min(1)
  @Max(20971520)
  contentLength: number;
}
