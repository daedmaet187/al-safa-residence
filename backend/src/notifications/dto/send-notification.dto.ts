import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsArray, IsUUID } from 'class-validator';

export class SendNotificationDto {
  @ApiProperty({ example: 'Water Interruption' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ example: 'Water will be off from 10am to 2pm' })
  @IsString()
  @IsNotEmpty()
  body: string;

  @ApiPropertyOptional({ description: 'Send to specific user IDs; omit for broadcast' })
  @IsArray()
  @IsUUID('4', { each: true })
  @IsOptional()
  userIds?: string[];

  @ApiPropertyOptional({ type: Object })
  @IsOptional()
  data?: Record<string, string>;
}
