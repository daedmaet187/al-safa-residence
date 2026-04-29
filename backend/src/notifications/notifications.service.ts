import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterTokenDto } from './dto/register-token.dto';
import { SendNotificationDto } from './dto/send-notification.dto';

@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  async registerToken(dto: RegisterTokenDto, userId: string) {
    try {
      return await this.prisma.deviceToken.upsert({
        where: { token: dto.token },
        update: { userId, platform: dto.platform },
        create: { userId, token: dto.token, platform: dto.platform },
      });
    } catch {
      throw new BadRequestException('Failed to register device token');
    }
  }

  async send(dto: SendNotificationDto) {
    let tokens: string[];

    if (dto.userIds && dto.userIds.length > 0) {
      const deviceTokens = await this.prisma.deviceToken.findMany({
        where: { userId: { in: dto.userIds } },
        select: { token: true },
      });
      tokens = deviceTokens.map((t) => t.token);
    } else {
      const deviceTokens = await this.prisma.deviceToken.findMany({
        select: { token: true },
      });
      tokens = deviceTokens.map((t) => t.token);
    }

    if (tokens.length === 0) {
      return { message: 'No device tokens found', sent: 0 };
    }

    // FCM sending is handled externally via firebase-admin in production
    // This returns a stub response for now
    return {
      message: `Notification queued for ${tokens.length} device(s)`,
      sent: tokens.length,
      title: dto.title,
    };
  }
}
