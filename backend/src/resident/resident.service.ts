import { Injectable, NotFoundException, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import { S3Client, GetObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { PrismaService } from '../prisma/prisma.service';

const GUEST_PASS_MAX_ACTIVE = 5;
const GUEST_PASS_MAX_PER_MONTH = 10;

@Injectable()
export class ResidentService {
  private readonly s3: S3Client;
  private readonly bucket: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    this.s3 = new S3Client({ region: config.get<string>('aws.region') });
    this.bucket = config.get<string>('aws.s3Bucket') ?? '';
  }

  // ── Home summary ───────────────────────────────────────────────────────────

  async getDashboardSummary(userId: string) {
    const now = new Date();

    await this.prisma.guestPass.updateMany({
      where: { userId, status: 'ACTIVE', validUntil: { lt: now } },
      data: { status: 'EXPIRED' },
    });

    const [recentAnnouncements, activeGuestPasses, overdueBillsCount, openMaintenance] =
      await Promise.all([
        this.prisma.announcement.findMany({
          where: {
            deletedAt: null,
            OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
          },
          orderBy: [{ isImportant: 'desc' }, { publishedAt: 'desc' }],
          take: 5,
        }),
        this.prisma.guestPass.count({
          where: { userId, status: 'ACTIVE' },
        }),
        this.prisma.bill.count({
          where: {
            userId,
            OR: [
              { status: 'OVERDUE' },
              { status: 'PENDING', dueDate: { lt: now } },
            ],
          },
        }),
        this.prisma.maintenanceRequest.count({
          where: { userId, status: { in: ['PENDING', 'IN_PROGRESS'] } },
        }),
      ]);

    return {
      recentAnnouncements,
      activeGuestPasses,
      overdueBills: overdueBillsCount,
      openMaintenanceRequests: openMaintenance,
    };
  }

  // ── Bills ──────────────────────────────────────────────────────────────────

  async getBills(userId: string, status?: string) {
    const now = new Date();
    let where: any = { userId };

    if (status === 'paid') {
      where.status = 'PAID';
    } else if (status === 'overdue') {
      where = {
        userId,
        OR: [{ status: 'OVERDUE' }, { status: 'PENDING', dueDate: { lt: now } }],
      };
    } else if (status) {
      where.status = status.toUpperCase();
    }

    const bills = await this.prisma.bill.findMany({
      where,
      orderBy: { dueDate: 'asc' },
      include: {
        unit: { select: { number: true, building: true } },
        payments: { orderBy: { createdAt: 'desc' }, take: 1 },
      },
    });

    // Shape to match mobile Bill model: needs title, lineItems
    return bills.map((b) => ({
      id: b.id,
      title: this.billTitle(b.type, b.description),
      type: b.type.toLowerCase(),
      amount: b.amount,
      currency: b.currency,
      status: b.status.toLowerCase(),
      dueDate: b.dueDate,
      paidAt: b.payments[0]?.paidAt ?? null,
      unit: b.unit,
      lineItems: [],
    }));
  }

  async getBill(userId: string, id: string) {
    const bill = await this.prisma.bill.findUnique({
      where: { id },
      include: {
        unit: { select: { number: true, building: true } },
        payments: { orderBy: { createdAt: 'desc' } },
      },
    });
    if (!bill || bill.userId !== userId) throw new NotFoundException('Bill not found');

    return {
      id: bill.id,
      title: this.billTitle(bill.type, bill.description),
      type: bill.type.toLowerCase(),
      amount: bill.amount,
      currency: bill.currency,
      status: bill.status.toLowerCase(),
      dueDate: bill.dueDate,
      paidAt: bill.payments[0]?.paidAt ?? null,
      unit: bill.unit,
      lineItems: [{ label: this.billTitle(bill.type, bill.description), amount: bill.amount }],
    };
  }

  async payBill(userId: string, billId: string, method: string) {
    const bill = await this.prisma.bill.findUnique({ where: { id: billId } });
    if (!bill || bill.userId !== userId) throw new NotFoundException('Bill not found');
    if (bill.status === 'PAID') throw new BadRequestException('Bill already paid');

    const methodMap: Record<string, string> = {
      cash: 'CASH',
      bank_transfer: 'BANK_TRANSFER',
      card: 'CARD',
      online: 'ONLINE',
    };

    await this.prisma.$transaction([
      this.prisma.payment.create({
        data: {
          billId,
          userId,
          amount: bill.amount,
          currency: bill.currency,
          method: (methodMap[method?.toLowerCase()] ?? 'CASH') as any,
          status: 'COMPLETED',
          paidAt: new Date(),
        },
      }),
      this.prisma.bill.update({ where: { id: billId }, data: { status: 'PAID' } }),
    ]);

    return { success: true, billId };
  }

  private billTitle(type: string, description?: string | null): string {
    if (description) return description;
    const map: Record<string, string> = {
      MONTHLY_FEE: 'Monthly Service Fee',
      UTILITIES: 'Utilities',
      MAINTENANCE_FEE: 'Maintenance Fee',
      PARKING: 'Parking Fee',
      OTHER: 'Bill',
    };
    return map[type] ?? type;
  }

  // ── Gate ───────────────────────────────────────────────────────────────────

  async getMyQr(userId: string) {
    // Return a stable QR based on userId — this is the resident's gate pass
    return { qrCode: `resident:${userId}` };
  }

  async getGuestPasses(userId: string) {
    const now = new Date();
    await this.prisma.guestPass.updateMany({
      where: { userId, status: 'ACTIVE', validUntil: { lt: now } },
      data: { status: 'EXPIRED' },
    });

    const passes = await this.prisma.guestPass.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { name: true, unitAssignments: { where: { endDate: null, isPrimary: true }, include: { unit: { select: { number: true } } }, take: 1 } } },
      },
    });

    return passes.map((p) => ({
      id: p.id,
      guestName: p.guestName,
      guestPhone: p.guestPhone ?? '',
      guestIdNumber: p.guestId ?? null,
      validFrom: p.validFrom,
      validUntil: p.validUntil ?? new Date(p.validFrom.getTime() + 24 * 60 * 60 * 1000),
      status: p.status.toLowerCase(),
      qrCode: p.qrCode,
      residentName: p.user.name,
      unitNumber: p.user.unitAssignments[0]?.unit.number ?? '',
    }));
  }

  async createGuestPass(
    userId: string,
    dto: { guestName: string; guestPhone: string; guestIdNumber?: string; validFrom: string; validUntil: string; purpose?: string },
  ) {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const [activeCount, monthCount] = await Promise.all([
      this.prisma.guestPass.count({ where: { userId, status: 'ACTIVE' } }),
      this.prisma.guestPass.count({ where: { userId, createdAt: { gte: monthStart } } }),
    ]);

    if (activeCount >= GUEST_PASS_MAX_ACTIVE) {
      throw new BadRequestException(
        `You have reached the limit of ${GUEST_PASS_MAX_ACTIVE} active guest passes. Revoke an existing pass before creating a new one.`,
      );
    }
    if (monthCount >= GUEST_PASS_MAX_PER_MONTH) {
      throw new BadRequestException(
        `You have reached the monthly limit of ${GUEST_PASS_MAX_PER_MONTH} guest passes.`,
      );
    }

    const pass = await this.prisma.guestPass.create({
      data: {
        userId,
        guestName: dto.guestName,
        guestPhone: dto.guestPhone,
        guestId: dto.guestIdNumber,
        purpose: dto.purpose,
        qrCode: uuidv4(),
        validFrom: new Date(dto.validFrom),
        validUntil: new Date(dto.validUntil),
      },
      include: {
        user: { select: { name: true, unitAssignments: { where: { endDate: null, isPrimary: true }, include: { unit: { select: { number: true } } }, take: 1 } } },
      },
    });

    return {
      id: pass.id,
      guestName: pass.guestName,
      guestPhone: pass.guestPhone ?? '',
      guestIdNumber: pass.guestId ?? null,
      validFrom: pass.validFrom,
      validUntil: pass.validUntil!,
      status: pass.status.toLowerCase(),
      qrCode: pass.qrCode,
      residentName: pass.user.name,
      unitNumber: pass.user.unitAssignments[0]?.unit.number ?? '',
    };
  }

  async revokeGuestPass(userId: string, passId: string) {
    const pass = await this.prisma.guestPass.findUnique({ where: { id: passId } });
    if (!pass || pass.userId !== userId) throw new NotFoundException('Guest pass not found');
    return this.prisma.guestPass.update({ where: { id: passId }, data: { status: 'REVOKED' } });
  }

  // ── Units ──────────────────────────────────────────────────────────────────

  async getMyUnit(userId: string) {
    const assignment = await this.prisma.unitAssignment.findFirst({
      where: { userId, endDate: null, isPrimary: true },
      include: { unit: true },
    });

    if (!assignment) throw new NotFoundException('No unit assigned');

    const unit = assignment.unit;
    const now = new Date();
    const startDate = assignment.startDate;
    const monthsInResidence = Math.floor(
      (now.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24 * 30),
    );

    const [totalPaidAgg, openMaintenance] = await Promise.all([
      this.prisma.bill.aggregate({
        _sum: { amount: true },
        where: { userId, unitId: unit.id, status: 'PAID' },
      }),
      this.prisma.maintenanceRequest.count({
        where: { userId, unitId: unit.id, status: { in: ['PENDING', 'IN_PROGRESS'] } },
      }),
    ]);

    return {
      unit: {
        id: unit.id,
        number: unit.number,
        floor: unit.floor,
        building: unit.building,
        type: unit.type,
        area: unit.area,
        bedrooms: unit.bedrooms,
        bathrooms: unit.bathrooms,
        parkingSpot: unit.parkingSpot,
      },
      stats: {
        monthsInResidence,
        totalPaid: totalPaidAgg._sum.amount ?? 0,
        openMaintenanceRequests: openMaintenance,
      },
      documents: [],
    };
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, firstName: true, lastName: true, name: true, email: true, phone: true, role: true, createdAt: true },
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async updateProfile(userId: string, dto: { firstName?: string; lastName?: string; name?: string; phone?: string; email?: string }) {
    const data: any = {};
    if (dto.firstName !== undefined) data.firstName = dto.firstName;
    if (dto.lastName !== undefined) data.lastName = dto.lastName;
    if (dto.firstName || dto.lastName) {
      const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { firstName: true, lastName: true } });
      data.name = `${dto.firstName ?? user!.firstName} ${dto.lastName ?? user!.lastName}`.trim();
    }
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.phone !== undefined) data.phone = dto.phone;
    if (dto.email !== undefined) data.email = dto.email;
    return this.prisma.user.update({
      where: { id: userId },
      data,
      select: { id: true, firstName: true, lastName: true, name: true, email: true, phone: true, role: true, createdAt: true },
    });
  }

  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    const valid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!valid) throw new UnauthorizedException('Current password is incorrect');

    const hash = await bcrypt.hash(newPassword, 10);
    await this.prisma.user.update({ where: { id: userId }, data: { passwordHash: hash } });
    return { message: 'Password changed successfully' };
  }

  // ── Documents ─────────────────────────────────────────────────────────────

  async listDocuments(userId: string) {
    const docs = await this.prisma.document.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    const withUrls = await Promise.all(
      docs.map(async (doc) => {
        let url: string | null = null;
        if (this.bucket) {
          try {
            const cmd = new GetObjectCommand({ Bucket: this.bucket, Key: doc.s3Key });
            url = await getSignedUrl(this.s3, cmd, { expiresIn: 3600 });
          } catch {
            // non-critical — return null url
          }
        }
        return { ...doc, url };
      }),
    );

    return withUrls;
  }

  async saveDocument(
    userId: string,
    dto: { name: string; type: string; s3Key: string; contentType: string },
  ) {
    if (!dto.s3Key.startsWith(`uploads/${userId}/`)) {
      throw new BadRequestException('Invalid document key');
    }
    return this.prisma.document.create({
      data: {
        userId,
        name: dto.name,
        type: dto.type ?? 'other',
        s3Key: dto.s3Key,
        contentType: dto.contentType,
      },
    });
  }

  async deleteDocument(userId: string, docId: string) {
    const doc = await this.prisma.document.findUnique({ where: { id: docId } });
    if (!doc || doc.userId !== userId) throw new NotFoundException('Document not found');

    if (this.bucket) {
      try {
        await this.s3.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: doc.s3Key }));
      } catch {
        // S3 delete is best-effort; still remove DB record
      }
    }

    await this.prisma.document.delete({ where: { id: docId } });
    return { message: 'Document deleted' };
  }

  // ── Support ────────────────────────────────────────────────────────────────

  getSupportInfo() {
    return {
      contact: {
        phone: '+964 770 000 0000',
        email: 'support@al-safa-residence.iq',
        workingHours: 'Sun–Thu, 8:00 AM – 6:00 PM',
      },
      faq: [
        {
          question: 'How do I pay my monthly bill?',
          answer: 'Go to Payments in the main menu, select the bill, and choose a payment method.',
        },
        {
          question: 'How do I submit a maintenance request?',
          answer: 'Tap Maintenance in the menu, then tap the + button to describe the issue.',
        },
        {
          question: 'How do I create a guest pass?',
          answer: 'Go to Gate Access and tap + New Pass. Enter your guest\'s details and validity period.',
        },
        {
          question: 'How do I add a household member?',
          answer: 'Open Profile → Household Members and tap Add Member. Set their access level.',
        },
        {
          question: 'Who do I contact for urgent issues?',
          answer: 'Call the building management directly at +964 770 000 0000 or use Chat Support.',
        },
      ],
    };
  }
}
