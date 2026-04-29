import {
  Controller,
  Post,
  Body,
  UseGuards,
  HttpStatus,
  ValidationPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
} from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { NotificationsService } from './notifications.service';
import { RegisterTokenDto } from './dto/register-token.dto';
import { SendNotificationDto } from './dto/send-notification.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { User } from '../common/decorators/user.decorator';

@ApiTags('notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post('register-token')
  @ApiOperation({ summary: 'Register FCM device token' })
  @ApiResponse({ status: HttpStatus.CREATED, description: 'Token registered' })
  async registerToken(@Body(ValidationPipe) dto: RegisterTokenDto, @User() user: any) {
    return this.notificationsService.registerToken(dto, user.id);
  }

  @Post('send')
  @Roles(Role.ADMIN)
  @ApiOperation({ summary: 'Send push notification (admin only)' })
  @ApiResponse({ status: HttpStatus.CREATED, description: 'Notification sent' })
  async send(@Body(ValidationPipe) dto: SendNotificationDto) {
    return this.notificationsService.send(dto);
  }
}
