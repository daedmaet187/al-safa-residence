import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsString, IsNotEmpty } from 'class-validator';

export class AddPhotosDto {
  @ApiProperty({ type: [String], description: 'S3 photo URLs to add' })
  @IsArray()
  @IsString({ each: true })
  @IsNotEmpty({ each: true })
  photoUrls: string[];
}
