import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsIn } from 'class-validator';

export class RegisterTokenDto {
  @ApiProperty({ example: 'fcm_token_here' })
  @IsString()
  @IsNotEmpty()
  token: string;

  @ApiProperty({ enum: ['ios', 'android'], example: 'android' })
  @IsString()
  @IsIn(['ios', 'android'])
  platform: string;
}
