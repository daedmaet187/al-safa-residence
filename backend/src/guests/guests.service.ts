import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';
import * as QRCode from 'qrcode';
import { GuestPassStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateGuestPassDto } from './dto/create-guest-pass.dto';
import { ScanQrDto } from './dto/scan-qr.dto';

@Injectable()
export class GuestsService {
  constructor(private readonly prisma: PrismaService) {}

  private signQr(uuid: string): string {
    const secret = process.env.JWT_ACCESS_SECRET ?? '';
    const sig = crypto.createHmac('sha256', secret).update(uuid).digest('hex');
    return `${uuid}.${sig}`;
  }

  private verifyQr(qrCode: string): string | null {
    const dotIndex = qrCode.lastIndexOf('.');
    if (dotIndex === -1) return null;
    const uuid = qrCode.slice(0, dotIndex);
    const sig = qrCode.slice(dotIndex + 1);
    const secret = process.env.JWT_ACCESS_SECRET ?? '';
    const expected = crypto.createHmac('sha256', secret).update(uuid).digest('hex');
    if (!crypto.timingSafeEqual(Buffer.from(sig, 'hex'), Buffer.from(expected, 'hex'))) return null;
    return uuid;
  }

  async create(dto: CreateGuestPassDto, userId: string) {
    const uuid = uuidv4();
    const qrCode = this.signQr(uuid);

    const qrDataUrl = await QRCode.toDataURL(qrCode);

    try {
      const pass = await this.prisma.guestPass.create({
        data: {
          userId,
          guestName: dto.guestName,
          guestPhone: dto.guestPhone,
          guestId: dto.guestId,
          purpose: dto.purpose,
          qrCode,
          validUntil: dto.validUntil ? new Date(dto.validUntil) : null,
        },
      });
      return { ...pass, qrDataUrl };
    } catch {
      throw new BadRequestException('Failed to create guest pass');
    }
  }

  async findAll(userId: string, params?: { skip?: number; take?: number }) {
    const { skip = 0, take = 20 } = params || {};

    const [data, count] = await Promise.all([
      this.prisma.guestPass.findMany({
        where: { userId },
        skip,
        take,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.guestPass.count({ where: { userId } }),
    ]);

    return { count, data };
  }

  async findOne(id: string, userId: string) {
    const pass = await this.prisma.guestPass.findFirst({
      where: { id, userId },
      include: { gateLog: { orderBy: { scannedAt: 'desc' } } },
    });
    if (!pass) throw new NotFoundException(`Guest pass with ID ${id} not found`);
    return pass;
  }

  async revoke(id: string, userId: string) {
    const pass = await this.prisma.guestPass.findFirst({ where: { id, userId } });
    if (!pass) throw new NotFoundException(`Guest pass with ID ${id} not found`);

    if (pass.status !== GuestPassStatus.ACTIVE) {
      throw new BadRequestException('Guest pass is not active');
    }

    return this.prisma.guestPass.update({
      where: { id },
      data: { status: GuestPassStatus.REVOKED },
    });
  }

  scanQr = async (dto: ScanQrDto, scannedById: string) => {
    const uuid = this.verifyQr(dto.qrCode);
    if (!uuid) {
      return { result: 'DENIED', reason: 'Invalid QR code' };
    }

    const pass = await this.prisma.guestPass.findUnique({
      where: { qrCode: dto.qrCode },
      include: {
        user: {
          select: {
            id: true, name: true, phone: true,
            unitAssignments: {
              where: { endDate: null },
              include: { unit: { select: { id: true, number: true, building: true, floor: true } } },
            },
          },
        },
      },
    });

    if (!pass) {
      return { result: 'DENIED', reason: 'Invalid QR code' };
    }

    const now = new Date();
    let result = 'APPROVED';
    let reason = '';

    if (pass.status === GuestPassStatus.REVOKED) {
      result = 'DENIED';
      reason = 'Pass has been revoked';
    } else if (pass.status === GuestPassStatus.USED) {
      result = 'DENIED';
      reason = 'Pass has already been used';
    } else if (pass.status === GuestPassStatus.EXPIRED) {
      result = 'DENIED';
      reason = 'Pass has expired';
    } else if (pass.validUntil && pass.validUntil < now) {
      result = 'EXPIRED';
      reason = 'Pass validity period has ended';
      await this.prisma.guestPass.update({
        where: { id: pass.id },
        data: { status: GuestPassStatus.EXPIRED },
      });
    }

    await this.prisma.gateLog.create({
      data: {
        guestPassId: pass.id,
        scannedById,
        result,
        notes: dto.notes,
      },
    });

    if (result === 'APPROVED') {
      await this.prisma.guestPass.update({
        where: { id: pass.id },
        data: { usedAt: now, status: GuestPassStatus.USED },
      });
    }

    return {
      result,
      reason: reason || undefined,
      guestName: pass.guestName,
      guestPhone: pass.guestPhone,
      purpose: pass.purpose,
      resident: pass.user,
    };
  };

  async findGateLog(params?: { skip?: number; take?: number }) {
    const { skip = 0, take = 50 } = params || {};

    const [data, count] = await Promise.all([
      this.prisma.gateLog.findMany({
        skip,
        take,
        orderBy: { scannedAt: 'desc' },
        include: {
          guestPass: {
            select: {
              guestName: true, guestPhone: true, purpose: true,
              user: { select: { id: true, name: true } },
            },
          },
        },
      }),
      this.prisma.gateLog.count(),
    ]);

    return { count, data };
  }
}
