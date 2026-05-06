import { IsString, IsNotEmpty, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateMessageDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @MaxLength(5000)
  content: string;
}
