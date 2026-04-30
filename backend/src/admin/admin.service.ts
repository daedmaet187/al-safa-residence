import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { BillStatus, MaintenanceStatus, Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  // ── Dashboard ──────────────────────────────────────────────────────────────

  async getDashboardStats() {
    const now = new Date();
    const [
      totalResidents,
      totalUnits,
      occupiedUnits,
      pendingMaintenance,
      pendingBillsAgg,
      totalRevenueAgg,
    ] = await Promise.all([
      this.prisma.user.count({ where: { role: Role.RESIDENT, isActive: true, deletedAt: null } }),
      this.prisma.unit.count({ where: { isActive: true } }),
      this.prisma.unitAssignment.groupBy({ by: ['unitId'], where: { endDate: null } }).then((r) => r.length),
      this.prisma.maintenanceRequest.count({ where: { status: MaintenanceStatus.PENDING } }),
      this.prisma.bill.aggregate({
        _count: { id: true },
        where: { status: { in: [BillStatus.PENDING, BillStatus.OVERDUE] } },
      }),
      this.prisma.payment.aggregate({
        _sum: { amount: true },
        where: { status: 'COMPLETED' },
      }),
    ]);

    return {
      totalResidents,
      totalUnits,
      occupiedUnits,
      pendingMaintenance,
      pendingBills: pendingBillsAgg._count.id,
      totalRevenue: totalRevenueAgg._sum.amount ?? 0,
    };
  }

  // ── Residents ──────────────────────────────────────────────────────────────

  async getResidents(skip = 0, take = 50, search?: string) {
    const where: any = { role: Role.RESIDENT, deletedAt: null };
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
      ];
    }
    const [data, count] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true, name: true, email: true, phone: true,
          role: true, isActive: true, createdAt: true,
          unitAssignments: {
            where: { endDate: null },
            select: { unit: { select: { id: true, number: true, building: true } } },
          },
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      count,
      data: data.map((u) => ({ ...u, units: u.unitAssignments.map((a) => a.unit) })),
    };
  }

  // ── Units ──────────────────────────────────────────────────────────────────

  async getUnits(skip = 0, take = 50) {
    const [data, count] = await Promise.all([
      this.prisma.unit.findMany({
        skip,
        take,
        orderBy: [{ building: 'asc' }, { number: 'asc' }],
        include: {
          assignments: {
            where: { endDate: null },
            include: { user: { select: { id: true, name: true, email: true } } },
          },
        },
      }),
      this.prisma.unit.count(),
    ]);
    return { count, data };
  }

  // ── Announcements ──────────────────────────────────────────────────────────

  async getAnnouncements(skip = 0, take = 50) {
    const [data, count] = await Promise.all([
      this.prisma.announcement.findMany({
        where: { deletedAt: null },
        skip,
        take,
        orderBy: { publishedAt: 'desc' },
      }),
      this.prisma.announcement.count({ where: { deletedAt: null } }),
    ]);
    return { count, data };
  }

  async createAnnouncement(dto: { title: string; body: string; isImportant?: boolean; expiresAt?: string }) {
    return this.prisma.announcement.create({
      data: {
        title: dto.title,
        body: dto.body,
        isImportant: dto.isImportant ?? false,
        expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
      },
    });
  }

  // ── Maintenance ────────────────────────────────────────────────────────────

  async getMaintenance(skip = 0, take = 50, status?: string) {
    const where: any = {};
    if (status) where.status = status.toUpperCase();

    const [data, count] = await Promise.all([
      this.prisma.maintenanceRequest.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          unit: { select: { number: true, building: true } },
          user: { select: { id: true, name: true } },
        },
      }),
      this.prisma.maintenanceRequest.count({ where }),
    ]);
    return { count, data };
  }

  async updateMaintenanceStatus(id: string, status: string) {
    const record = await this.prisma.maintenanceRequest.findUnique({ where: { id } });
    if (!record) throw new NotFoundException(`Maintenance request ${id} not found`);

    return this.prisma.maintenanceRequest.update({
      where: { id },
      data: {
        status: status.toUpperCase() as MaintenanceStatus,
        resolvedAt: status.toUpperCase() === 'RESOLVED' ? new Date() : undefined,
      },
      include: {
        unit: { select: { number: true, building: true } },
        user: { select: { id: true, name: true } },
      },
    });
  }

  // ── Bills ──────────────────────────────────────────────────────────────────

  async getBills(skip = 0, take = 50, status?: string) {
    const now = new Date();
    let where: any = {};

    if (status === 'overdue') {
      where = {
        OR: [
          { status: BillStatus.OVERDUE },
          { status: BillStatus.PENDING, dueDate: { lt: now } },
        ],
      };
    } else if (status) {
      where.status = status.toUpperCase();
    }

    const [data, count] = await Promise.all([
      this.prisma.bill.findMany({
        where,
        skip,
        take,
        orderBy: { dueDate: 'asc' },
        include: {
          user: { select: { id: true, name: true, email: true } },
          unit: { select: { id: true, number: true, building: true } },
        },
      }),
      this.prisma.bill.count({ where }),
    ]);
    return { count, data };
  }

  async createBill(dto: { userId: string; unitId: string; type: string; amount: number; currency?: string; dueDate: string; description?: string }) {
    return this.prisma.bill.create({
      data: {
        userId: dto.userId,
        unitId: dto.unitId,
        type: dto.type.toUpperCase() as any,
        amount: dto.amount,
        currency: dto.currency ?? 'IQD',
        dueDate: new Date(dto.dueDate),
        description: dto.description,
      },
      include: {
        user: { select: { id: true, name: true, email: true } },
        unit: { select: { id: true, number: true, building: true } },
      },
    });
  }

  async markBillPaid(id: string) {
    const bill = await this.prisma.bill.findUnique({ where: { id } });
    if (!bill) throw new NotFoundException(`Bill ${id} not found`);

    return this.prisma.bill.update({
      where: { id },
      data: { status: BillStatus.PAID },
      include: {
        user: { select: { id: true, name: true } },
        unit: { select: { id: true, number: true, building: true } },
      },
    });
  }

  // ── Payments ───────────────────────────────────────────────────────────────

  async getPayments(skip = 0, take = 50) {
    const [data, count] = await Promise.all([
      this.prisma.payment.findMany({
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          bill: {
            include: {
              user: { select: { id: true, name: true } },
              unit: { select: { id: true, number: true } },
            },
          },
        },
      }),
      this.prisma.payment.count(),
    ]);
    return { count, data };
  }

  // ── Gate ───────────────────────────────────────────────────────────────────

  async getGatePasses(skip = 0, take = 50) {
    const [data, count] = await Promise.all([
      this.prisma.guestPass.findMany({
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: { user: { select: { id: true, name: true, email: true } } },
      }),
      this.prisma.guestPass.count(),
    ]);
    return { count, data };
  }

  async getGateLogs(skip = 0, take = 50) {
    const [data, count] = await Promise.all([
      this.prisma.gateLog.findMany({
        skip,
        take,
        orderBy: { scannedAt: 'desc' },
        include: {
          guestPass: {
            include: { user: { select: { id: true, name: true } } },
          },
        },
      }),
      this.prisma.gateLog.count(),
    ]);
    return { count, data };
  }

  // ── Staff ──────────────────────────────────────────────────────────────────

  async getStaff(skip = 0, take = 50) {
    const where = { role: { in: [Role.ADMIN, Role.SECURITY] }, deletedAt: null };
    const [data, count] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        select: { id: true, name: true, email: true, phone: true, role: true, isActive: true, createdAt: true },
      }),
      this.prisma.user.count({ where }),
    ]);
    return { count, data };
  }

  async createStaff(dto: { name: string; email: string; password: string; role: 'ADMIN' | 'SECURITY' }) {
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) throw new ConflictException('Email already in use');

    const passwordHash = await bcrypt.hash(dto.password, 10);
    return this.prisma.user.create({
      data: {
        name: dto.name,
        email: dto.email,
        passwordHash,
        role: dto.role as Role,
      },
      select: { id: true, name: true, email: true, phone: true, role: true, isActive: true, createdAt: true },
    });
  }

  async updateStaff(id: string, dto: { role?: string; isActive?: boolean }) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException(`User ${id} not found`);

    return this.prisma.user.update({
      where: { id },
      data: {
        ...(dto.role ? { role: dto.role.toUpperCase() as Role } : {}),
        ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
      },
      select: { id: true, name: true, email: true, phone: true, role: true, isActive: true, createdAt: true },
    });
  }

  // ── Reports ────────────────────────────────────────────────────────────────

  async getPaymentsReport() {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [total, paid, pending, overdue, revenueAgg, thisMonthAgg] = await Promise.all([
      this.prisma.bill.count(),
      this.prisma.bill.count({ where: { status: BillStatus.PAID } }),
      this.prisma.bill.count({ where: { status: BillStatus.PENDING } }),
      this.prisma.bill.count({
        where: {
          OR: [
            { status: BillStatus.OVERDUE },
            { status: BillStatus.PENDING, dueDate: { lt: now } },
          ],
        },
      }),
      this.prisma.payment.aggregate({ _sum: { amount: true }, where: { status: 'COMPLETED' } }),
      this.prisma.payment.aggregate({
        _sum: { amount: true },
        where: { status: 'COMPLETED', paidAt: { gte: startOfMonth } },
      }),
    ]);

    return {
      total,
      paid,
      pending,
      overdue,
      totalRevenue: revenueAgg._sum.amount ?? 0,
      thisMonth: thisMonthAgg._sum.amount ?? 0,
    };
  }

  async getMaintenanceReport() {
    const [total, pending, inProgress, resolved, cancelled, byCategoryRaw] = await Promise.all([
      this.prisma.maintenanceRequest.count(),
      this.prisma.maintenanceRequest.count({ where: { status: MaintenanceStatus.PENDING } }),
      this.prisma.maintenanceRequest.count({ where: { status: MaintenanceStatus.IN_PROGRESS } }),
      this.prisma.maintenanceRequest.count({ where: { status: MaintenanceStatus.RESOLVED } }),
      this.prisma.maintenanceRequest.count({ where: { status: MaintenanceStatus.CANCELLED } }),
      this.prisma.maintenanceRequest.groupBy({ by: ['category'], _count: { id: true } }),
    ]);

    return {
      total,
      pending,
      inProgress,
      resolved,
      cancelled,
      byCategory: byCategoryRaw.map((r) => ({ category: r.category, count: r._count.id })),
    };
  }

  async getOccupancyReport() {
    const [totalUnits, occupiedRaw] = await Promise.all([
      this.prisma.unit.count({ where: { isActive: true } }),
      this.prisma.unitAssignment.groupBy({ by: ['unitId'], where: { endDate: null } }),
    ]);

    const occupied = occupiedRaw.length;
    const vacant = totalUnits - occupied;

    return {
      totalUnits,
      occupied,
      vacant,
      occupancyRate: totalUnits > 0 ? Math.round((occupied / totalUnits) * 100) : 0,
    };
  }

  async getGateReport() {
    const [totalPasses, activePasses, usedPasses, totalScans, approvedScans] = await Promise.all([
      this.prisma.guestPass.count(),
      this.prisma.guestPass.count({ where: { status: 'ACTIVE' } }),
      this.prisma.guestPass.count({ where: { status: 'USED' } }),
      this.prisma.gateLog.count(),
      this.prisma.gateLog.count({ where: { result: 'approved' } }),
    ]);

    return { totalPasses, activePasses, usedPasses, totalScans, approvedScans };
  }
}
