import { IsString, IsNotEmpty, Length, IsOptional, IsIn } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SendOtpDto {
  @ApiProperty({ example: '+9647501234567', description: 'Phone number of the resident/staff' })
  @IsString()
  @IsNotEmpty()
  phone: string;

  @ApiPropertyOptional({ example: 'RESIDENT', enum: ['RESIDENT', 'SECURITY'], description: 'Role to authenticate as' })
  @IsOptional()
  @IsIn(['RESIDENT', 'SECURITY'])
  role?: 'RESIDENT' | 'SECURITY';
}

export class VerifyOtpDto {
  @ApiProperty({ example: '+9647501234567' })
  @IsString()
  @IsNotEmpty()
  phone: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @Length(6, 6)
  otp: string;

  @ApiPropertyOptional({ example: 'RESIDENT', enum: ['RESIDENT', 'SECURITY'] })
  @IsOptional()
  @IsIn(['RESIDENT', 'SECURITY'])
  role?: 'RESIDENT' | 'SECURITY';
}
