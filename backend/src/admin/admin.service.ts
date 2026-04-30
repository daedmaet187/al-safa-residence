import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { BillStatus, MaintenanceStatus, Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

// Helper: wrap paginated responses in the shape the dashboard expects
function paginate<T>(data: T[], count: number, skip: number, take: number) {
  return {
    data,
    total: count,
    count,  // keep for backward compat
    page: Math.floor(skip / take) + 1,
    limit: take,
    totalPages: Math.ceil(count / take),
  };
}

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

    const mapped = data.map((u) => ({
      ...u,
      status: u.isActive ? 'active' : 'inactive',
      units: u.unitAssignments.map((a) => a.unit),
    }));
    return paginate(mapped, count, skip, take);
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
            include: { user: { select: { id: true, name: true, email: true, phone: true } } },
          },
        },
      }),
      this.prisma.unit.count(),
    ]);
    // Map assignments → residents (dashboard expects unit.residents[])
    const mapped = data.map((u) => ({
      ...u,
      status: u.assignments.length > 0 ? 'occupied' : 'vacant',
      residents: u.assignments.map((a) => ({
        id: a.user.id,
        name: a.user.name,
        email: a.user.email,
        role: 'resident',
      })),
    }));
    return paginate(mapped, count, skip, take);
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
    return paginate(data, count, skip, take);
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

  async updateAnnouncement(id: string, dto: { title?: string; body?: string; isImportant?: boolean; expiresAt?: string }) {
    const record = await this.prisma.announcement.findUnique({ where: { id } });
    if (!record || record.deletedAt) throw new NotFoundException(`Announcement ${id} not found`);
    return this.prisma.announcement.update({
      where: { id },
      data: {
        ...(dto.title ? { title: dto.title } : {}),
        ...(dto.body ? { body: dto.body } : {}),
        ...(dto.isImportant !== undefined ? { isImportant: dto.isImportant } : {}),
        ...(dto.expiresAt !== undefined ? { expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null } : {}),
      },
    });
  }

  async deleteAnnouncement(id: string) {
    const record = await this.prisma.announcement.findUnique({ where: { id } });
    if (!record) throw new NotFoundException(`Announcement ${id} not found`);
    return this.prisma.announcement.update({ where: { id }, data: { deletedAt: new Date() } });
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
          unit: { select: { id: true, number: true, building: true } },
          user: { select: { id: true, name: true, email: true } },
        },
      }),
      this.prisma.maintenanceRequest.count({ where }),
    ]);
    // Rename user→resident; add submittedAt alias for dashboard
    const mapped = data.map((r) => ({
      ...r,
      resident: { id: r.user.id, name: r.user.name, email: (r.user as any).email, role: 'resident' },
      submittedAt: r.createdAt,
      status: r.status.toLowerCase().replace('_', '-') as any,
      priority: r.priority.toLowerCase() as any,
      category: r.category.toLowerCase().replace('_', '-') as any,
    }));
    return paginate(mapped, count, skip, take);
  }

  async updateMaintenanceStatus(id: string, status: string, adminNotes?: string) {
    const record = await this.prisma.maintenanceRequest.findUnique({ where: { id } });
    if (!record) throw new NotFoundException(`Maintenance request ${id} not found`);

    const upperStatus = status ? status.toUpperCase() as MaintenanceStatus : record.status;
    return this.prisma.maintenanceRequest.update({
      where: { id },
      data: {
        status: upperStatus,
        resolvedAt: upperStatus === 'RESOLVED' ? new Date() : undefined,
        ...(adminNotes ? { notes: adminNotes } : {}),
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
    // Rename user→resident; lowercase status/type for dashboard
    const mapped = data.map((b) => ({
      ...b,
      resident: { id: b.user.id, name: b.user.name, email: b.user.email, role: 'resident' },
      status: b.status.toLowerCase() as any,
      type: b.type.toLowerCase().replace('_', '-') as any,
    }));
    return paginate(mapped, count, skip, take);
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
    // Shape bill to include resident alias
    const mapped = data.map((p) => ({
      ...p,
      bill: {
        ...p.bill,
        resident: { id: p.bill.user.id, name: p.bill.user.name, role: 'resident' },
        type: p.bill.type.toLowerCase().replace('_', '-'),
      },
    }));
    return paginate(mapped, count, skip, take);
  }

  // ── Gate ───────────────────────────────────────────────────────────────────

  async getGatePasses(skip = 0, take = 50) {
    const [data, count] = await Promise.all([
      this.prisma.guestPass.findMany({
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: {
              id: true, name: true, email: true,
              unitAssignments: {
                where: { endDate: null, isPrimary: true },
                include: { unit: { select: { id: true, number: true, building: true } } },
                take: 1,
              },
            },
          },
        },
      }),
      this.prisma.guestPass.count(),
    ]);
    // Add resident + unit fields dashboard expects
    const mapped = data.map((p) => ({
      ...p,
      status: p.status.toLowerCase() as any,
      resident: { id: p.user.id, name: p.user.name, email: p.user.email, role: 'resident' },
      unit: (p.user as any).unitAssignments?.[0]?.unit ?? null,
    }));
    return paginate(mapped, count, skip, take);
  }

  async getGateLogs(skip = 0, take = 50) {
    const [data, count] = await Promise.all([
      this.prisma.gateLog.findMany({
        skip,
        take,
        orderBy: { scannedAt: 'desc' },
        include: {
          guestPass: {
            include: {
              user: {
                select: {
                  id: true, name: true,
                  unitAssignments: {
                    where: { endDate: null, isPrimary: true },
                    include: { unit: { select: { number: true } } },
                    take: 1,
                  },
                },
              },
            },
          },
        },
      }),
      this.prisma.gateLog.count(),
    ]);
    const mapped = data.map((l) => ({
      ...l,
      guestName: l.guestPass.guestName,
      unit: (l.guestPass.user as any).unitAssignments?.[0]?.unit ?? null,
    }));
    return paginate(mapped, count, skip, take);
  }

  async revokeGuestPass(id: string) {
    const pass = await this.prisma.guestPass.findUnique({ where: { id } });
    if (!pass) throw new NotFoundException(`Guest pass ${id} not found`);
    return this.prisma.guestPass.update({ where: { id }, data: { status: 'REVOKED' } });
  }

  async createResident(dto: {
    firstName: string;
    lastName: string;
    phone: string;
    email?: string;
    unitId?: string;
    nationalId?: string;
    moveInDate?: string;
  }) {
    const existing = await this.prisma.user.findFirst({ where: { phone: dto.phone } });
    if (existing) throw new ConflictException('Phone number already in use');
    if (dto.email) {
      const emailExists = await this.prisma.user.findUnique({ where: { email: dto.email } });
      if (emailExists) throw new ConflictException('Email already in use');
    }
    const fullName = `${dto.firstName} ${dto.lastName}`.trim();
    const user = await this.prisma.user.create({
      data: {
        firstName: dto.firstName,
        lastName: dto.lastName,
        name: fullName,
        phone: dto.phone,
        email: dto.email ?? null,
        role: Role.RESIDENT,
      },
      select: { id: true, firstName: true, lastName: true, name: true, email: true, phone: true, role: true, isActive: true, createdAt: true },
    });
    if (dto.unitId) {
      await this.prisma.unitAssignment.create({
        data: {
          userId: user.id,
          unitId: dto.unitId,
          isPrimary: true,
          startDate: dto.moveInDate ? new Date(dto.moveInDate) : new Date(),
        },
      });
    }
    return user;
  }

  async updateResident(id: string, dto: { name?: string; phone?: string; isActive?: boolean; status?: string }) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException(`User ${id} not found`);
    const isActive = dto.isActive !== undefined ? dto.isActive : dto.status !== undefined ? dto.status === 'active' : undefined;
    return this.prisma.user.update({
      where: { id },
      data: {
        ...(dto.name ? { name: dto.name } : {}),
        ...(dto.phone !== undefined ? { phone: dto.phone } : {}),
        ...(isActive !== undefined ? { isActive } : {}),
      },
      select: { id: true, name: true, email: true, phone: true, role: true, isActive: true, createdAt: true },
    });
  }

  async createUnit(dto: { number: string; floor: number; building?: string; type: string; area: number; bedrooms: number; bathrooms: number; parkingSpot?: string }) {
    return this.prisma.unit.create({ data: dto });
  }

  async updateUnit(id: string, dto: any) {
    const unit = await this.prisma.unit.findUnique({ where: { id } });
    if (!unit) throw new NotFoundException(`Unit ${id} not found`);
    return this.prisma.unit.update({ where: { id }, data: dto });
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
    const mapped = data.map((u) => ({ ...u, status: u.isActive ? 'active' : 'inactive' }));
    return paginate(mapped, count, skip, take);
  }

  async createStaff(dto: { firstName: string; lastName: string; phone: string; email?: string; password?: string; role: 'ADMIN' | 'SECURITY' }) {
    const existing = await this.prisma.user.findFirst({ where: { phone: dto.phone } });
    if (existing) throw new ConflictException('Phone number already in use');
    if (dto.email) {
      const emailExists = await this.prisma.user.findUnique({ where: { email: dto.email } });
      if (emailExists) throw new ConflictException('Email already in use');
    }
    // ADMIN role requires email+password for dashboard login; SECURITY uses phone OTP only
    const passwordHash = (dto.role === 'ADMIN' && dto.password)
      ? await bcrypt.hash(dto.password, 10)
      : null;
    const fullName = `${dto.firstName} ${dto.lastName}`.trim();
    return this.prisma.user.create({
      data: {
        firstName: dto.firstName,
        lastName: dto.lastName,
        name: fullName,
        phone: dto.phone,
        email: dto.email ?? null,
        passwordHash,
        role: dto.role as Role,
      },
      select: { id: true, firstName: true, lastName: true, name: true, email: true, phone: true, role: true, isActive: true, createdAt: true },
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

    const [paidBillsAgg, overdueTotal, byTypeRaw, thisMonthAgg] = await Promise.all([
      this.prisma.bill.aggregate({ _sum: { amount: true }, where: { status: BillStatus.PAID } }),
      this.prisma.bill.aggregate({
        _sum: { amount: true },
        where: { OR: [{ status: BillStatus.OVERDUE }, { status: BillStatus.PENDING, dueDate: { lt: now } }] },
      }),
      this.prisma.bill.groupBy({
        by: ['type'],
        _sum: { amount: true },
        _count: { id: true },
        where: { status: BillStatus.PAID },
      }),
      this.prisma.bill.aggregate({
        _sum: { amount: true },
        where: { status: BillStatus.PAID, updatedAt: { gte: startOfMonth } },
      }),
    ]);

    return {
      collectedThisMonth: thisMonthAgg._sum.amount ?? 0,
      overdueTotal: overdueTotal._sum.amount ?? 0,
      byType: byTypeRaw.map((r) => ({ type: r.type, amount: r._sum.amount ?? 0, count: r._count.id })),
      // also include legacy fields for other consumers
      totalRevenue: paidBillsAgg._sum.amount ?? 0,
    };
  }

  async getMaintenanceReport() {
    const [byCategoryRaw, byStatusRaw, resolvedRequests] = await Promise.all([
      this.prisma.maintenanceRequest.groupBy({ by: ['category'], _count: { id: true } }),
      this.prisma.maintenanceRequest.groupBy({ by: ['status'], _count: { id: true } }),
      this.prisma.maintenanceRequest.findMany({
        where: { status: MaintenanceStatus.RESOLVED, resolvedAt: { not: null } },
        select: { createdAt: true, resolvedAt: true },
      }),
    ]);

    const avgResolutionDays = resolvedRequests.length
      ? resolvedRequests.reduce((sum, r) => {
          const diff = (r.resolvedAt!.getTime() - r.createdAt.getTime()) / (1000 * 60 * 60 * 24);
          return sum + diff;
        }, 0) / resolvedRequests.length
      : 0;

    return {
      byCategory: byCategoryRaw.map((r) => ({ category: r.category, count: r._count.id })),
      byStatus: byStatusRaw.map((r) => ({ status: r.status, count: r._count.id })),
      avgResolutionDays: Math.round(avgResolutionDays * 10) / 10,
      // legacy flat fields
      total: byStatusRaw.reduce((s, r) => s + r._count.id, 0),
      pending: byStatusRaw.find((r) => r.status === 'PENDING')?._count.id ?? 0,
      inProgress: byStatusRaw.find((r) => r.status === 'IN_PROGRESS')?._count.id ?? 0,
      resolved: byStatusRaw.find((r) => r.status === 'RESOLVED')?._count.id ?? 0,
      cancelled: byStatusRaw.find((r) => r.status === 'CANCELLED')?._count.id ?? 0,
    };
  }

  async getOccupancyReport() {
    const [totalUnits, occupiedRaw, byTypeRaw] = await Promise.all([
      this.prisma.unit.count({ where: { isActive: true } }),
      this.prisma.unitAssignment.groupBy({ by: ['unitId'], where: { endDate: null } }),
      this.prisma.unit.groupBy({ by: ['type'], _count: { id: true } }),
    ]);

    const occupiedUnitIds = new Set(occupiedRaw.map((r) => r.unitId));
    const occupied = occupiedRaw.length;
    const vacant = totalUnits - occupied;

    // byType occupancy
    const allUnits = await this.prisma.unit.findMany({ where: { isActive: true }, select: { id: true, type: true } });
    const byTypeMap: Record<string, { occupied: number; total: number }> = {};
    for (const u of allUnits) {
      if (!byTypeMap[u.type]) byTypeMap[u.type] = { occupied: 0, total: 0 };
      byTypeMap[u.type].total++;
      if (occupiedUnitIds.has(u.id)) byTypeMap[u.type].occupied++;
    }

    return {
      total: totalUnits,
      occupied,
      vacant,
      occupancyRate: totalUnits > 0 ? Math.round((occupied / totalUnits) * 100) : 0,
      byType: Object.entries(byTypeMap).map(([type, v]) => ({ type, ...v })),
      // legacy fields
      totalUnits,
    };
  }

  async getGateReport() {
    const now = new Date();
    const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

    const [totalPasses, activePasses, usedPasses, passesThisWeek, totalScans, approvedScans, recentLogs] =
      await Promise.all([
        this.prisma.guestPass.count(),
        this.prisma.guestPass.count({ where: { status: 'ACTIVE' } }),
        this.prisma.guestPass.count({ where: { status: 'USED' } }),
        this.prisma.guestPass.count({ where: { createdAt: { gte: weekAgo } } }),
        this.prisma.gateLog.count(),
        this.prisma.gateLog.count({ where: { result: 'approved' } }),
        this.prisma.gateLog.findMany({
          where: { scannedAt: { gte: weekAgo } },
          select: { scannedAt: true, result: true },
          orderBy: { scannedAt: 'asc' },
        }),
      ]);

    // Build scans per day for last 7 days
    const dayMap: Record<string, { approved: number; denied: number }> = {};
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);
      dayMap[d.toISOString().slice(0, 10)] = { approved: 0, denied: 0 };
    }
    for (const log of recentLogs) {
      const day = log.scannedAt.toISOString().slice(0, 10);
      if (dayMap[day]) {
        if (log.result === 'approved') dayMap[day].approved++;
        else dayMap[day].denied++;
      }
    }
    const scansPerDay = Object.entries(dayMap).map(([date, v]) => ({ date, ...v }));

    return {
      passesCreatedThisWeek: passesThisWeek,
      scansPerDay,
      // legacy fields
      totalPasses,
      activePasses,
      usedPasses,
      totalScans,
      approvedScans,
    };
  }
}
