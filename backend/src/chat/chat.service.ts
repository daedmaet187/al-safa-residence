import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { ConversationStatus, SenderType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateConversationDto } from './dto/create-conversation.dto';
import { CreateMessageDto } from './dto/create-message.dto';

function paginate<T>(data: T[], count: number, skip: number, take: number) {
  return {
    data,
    total: count,
    page: Math.floor(skip / take) + 1,
    limit: take,
    totalPages: Math.ceil(count / take),
  };
}

function mapConversation(c: any) {
  return {
    ...c,
    status: c.status.toLowerCase(),
    messages: (c.messages ?? []).map(mapMessage),
  };
}

function mapMessage(m: any) {
  return {
    ...m,
    senderType: m.senderType.toLowerCase(),
  };
}

@Injectable()
export class ChatService {
  constructor(private readonly prisma: PrismaService) {}

  async createConversation(residentId: string, dto: CreateConversationDto) {
    // Resolve the resident's active unit
    const assignment = await this.prisma.unitAssignment.findFirst({
      where: { userId: residentId, endDate: null },
      orderBy: { isPrimary: 'desc' },
    });

    const conversation = await this.prisma.conversation.create({
      data: {
        residentId,
        unitId: assignment?.unitId ?? null,
        subject: dto.subject,
      },
      include: {
        resident: { select: { id: true, name: true, phone: true } },
        unit: { select: { id: true, number: true } },
        messages: true,
      },
    });

    return mapConversation(conversation);
  }

  async getConversations(residentId: string, skip = 0, take = 20) {
    const where = { residentId };
    const [data, count] = await Promise.all([
      this.prisma.conversation.findMany({
        where,
        skip,
        take,
        orderBy: { updatedAt: 'desc' },
        include: {
          unit: { select: { id: true, number: true } },
          messages: {
            orderBy: { createdAt: 'desc' },
            take: 1,
          },
          _count: { select: { messages: { where: { isRead: false, senderType: SenderType.ADMIN } } } },
        },
      }),
      this.prisma.conversation.count({ where }),
    ]);

    const mapped = data.map((c) => ({
      ...mapConversation(c),
      unreadCount: c._count.messages,
    }));

    return paginate(mapped, count, skip, take);
  }

  async getConversation(residentId: string, conversationId: string) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: {
        resident: { select: { id: true, name: true, phone: true } },
        unit: { select: { id: true, number: true } },
        messages: { orderBy: { createdAt: 'asc' } },
        _count: { select: { messages: { where: { isRead: false, senderType: SenderType.ADMIN } } } },
      },
    });

    if (!conversation) throw new NotFoundException('Conversation not found');
    if (conversation.residentId !== residentId) throw new ForbiddenException();

    return {
      ...mapConversation(conversation),
      unreadCount: conversation._count.messages,
    };
  }

  async sendMessage(residentId: string, conversationId: string, dto: CreateMessageDto) {
    const conversation = await this.prisma.conversation.findUnique({ where: { id: conversationId } });
    if (!conversation) throw new NotFoundException('Conversation not found');
    if (conversation.residentId !== residentId) throw new ForbiddenException();
    if (conversation.status === ConversationStatus.CLOSED) {
      throw new ForbiddenException('Conversation is closed');
    }

    const [message] = await this.prisma.$transaction([
      this.prisma.message.create({
        data: {
          conversationId,
          senderId: residentId,
          senderType: SenderType.RESIDENT,
          content: dto.content,
        },
      }),
      this.prisma.conversation.update({
        where: { id: conversationId },
        data: { updatedAt: new Date() },
      }),
    ]);

    return mapMessage(message);
  }

  async markRead(residentId: string, conversationId: string) {
    const conversation = await this.prisma.conversation.findUnique({ where: { id: conversationId } });
    if (!conversation) throw new NotFoundException('Conversation not found');
    if (conversation.residentId !== residentId) throw new ForbiddenException();

    await this.prisma.message.updateMany({
      where: { conversationId, senderType: SenderType.ADMIN, isRead: false },
      data: { isRead: true },
    });

    return { ok: true };
  }

  // ── Admin methods ────────────────────────────────────────────────────────────

  async adminGetConversations(skip = 0, take = 20, status?: string) {
    const where: any = {};
    if (status && status !== 'all') {
      where.status = status.toUpperCase() as ConversationStatus;
    }

    const [data, count] = await Promise.all([
      this.prisma.conversation.findMany({
        where,
        skip,
        take,
        orderBy: { updatedAt: 'desc' },
        include: {
          resident: { select: { id: true, name: true, phone: true } },
          unit: { select: { id: true, number: true } },
          messages: {
            orderBy: { createdAt: 'desc' },
            take: 1,
          },
          _count: { select: { messages: { where: { isRead: false, senderType: SenderType.RESIDENT } } } },
        },
      }),
      this.prisma.conversation.count({ where }),
    ]);

    const mapped = data.map((c) => ({
      ...mapConversation(c),
      unreadCount: c._count.messages,
    }));

    return paginate(mapped, count, skip, take);
  }

  async adminGetConversation(conversationId: string) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: {
        resident: { select: { id: true, name: true, phone: true } },
        unit: { select: { id: true, number: true } },
        messages: { orderBy: { createdAt: 'asc' } },
        _count: { select: { messages: { where: { isRead: false, senderType: SenderType.RESIDENT } } } },
      },
    });

    if (!conversation) throw new NotFoundException('Conversation not found');

    return {
      ...mapConversation(conversation),
      unreadCount: conversation._count.messages,
    };
  }

  async adminSendMessage(adminId: string, conversationId: string, dto: CreateMessageDto) {
    const conversation = await this.prisma.conversation.findUnique({ where: { id: conversationId } });
    if (!conversation) throw new NotFoundException('Conversation not found');

    const [message] = await this.prisma.$transaction([
      this.prisma.message.create({
        data: {
          conversationId,
          senderId: adminId,
          senderType: SenderType.ADMIN,
          content: dto.content,
        },
      }),
      this.prisma.conversation.update({
        where: { id: conversationId },
        data: { updatedAt: new Date() },
      }),
    ]);

    return mapMessage(message);
  }

  async adminUpdateStatus(conversationId: string, status: string) {
    const conversation = await this.prisma.conversation.findUnique({ where: { id: conversationId } });
    if (!conversation) throw new NotFoundException('Conversation not found');

    const updated = await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { status: status.toUpperCase() as ConversationStatus },
      include: {
        resident: { select: { id: true, name: true, phone: true } },
        unit: { select: { id: true, number: true } },
      },
    });

    return mapConversation(updated);
  }

  async closeConversation(residentId: string, conversationId: string) {
    const conv = await this.prisma.conversation.findUnique({ where: { id: conversationId } });
    if (!conv) throw new NotFoundException('Conversation not found');
    if (conv.residentId !== residentId) throw new ForbiddenException();
    if (conv.status === ConversationStatus.CLOSED) return mapConversation(conv);

    const updated = await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { status: ConversationStatus.CLOSED, updatedAt: new Date() },
    });
    return mapConversation(updated);
  }

  async adminMarkRead(conversationId: string) {
    const conversation = await this.prisma.conversation.findUnique({ where: { id: conversationId } });
    if (!conversation) throw new NotFoundException('Conversation not found');

    await this.prisma.message.updateMany({
      where: { conversationId, senderType: SenderType.RESIDENT, isRead: false },
      data: { isRead: true },
    });

    return { ok: true };
  }
}
