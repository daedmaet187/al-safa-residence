import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { BillStatus, PaymentStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PayBillDto } from './dto/pay-bill.dto';
import { CreateBillDto } from './dto/create-bill.dto';

@Injectable()
export class PaymentsService {
  constructor(private readonly prisma: PrismaService) {}

  async createBill(dto: CreateBillDto) {
    return this.prisma.bill.create({
      data: {
        userId: dto.userId,
        unitId: dto.unitId,
        type: dto.type,
        amount: dto.amount,
        currency: dto.currency ?? 'IQD',
        dueDate: new Date(dto.dueDate),
        description: dto.description,
      },
      include: {
        unit: { select: { id: true, number: true, building: true } },
        user: { select: { id: true, name: true, email: true } },
      },
    });
  }

  async removeBill(id: string) {
    const bill = await this.prisma.bill.findFirst({ where: { id, deletedAt: null } });
    if (!bill) throw new NotFoundException(`Bill with ID ${id} not found`);
    return this.prisma.bill.update({ where: { id }, data: { deletedAt: new Date() } });
  }

  async removePayment(id: string) {
    const payment = await this.prisma.payment.findFirst({ where: { id, deletedAt: null } });
    if (!payment) throw new NotFoundException(`Payment with ID ${id} not found`);
    return this.prisma.payment.update({ where: { id }, data: { deletedAt: new Date() } });
  }

  async findBills(userId: string, userRole: string, params?: { skip?: number; take?: number }) {
    const { skip = 0, take = 20 } = params || {};
    const where: any = { deletedAt: null };

    if (userRole === 'RESIDENT') {
      where.userId = userId;
    }

    const [data, count] = await Promise.all([
      this.prisma.bill.findMany({
        where,
        skip,
        take,
        orderBy: { dueDate: 'asc' },
        include: {
          unit: { select: { id: true, number: true, building: true } },
          user: { select: { id: true, name: true } },
          payments: { orderBy: { createdAt: 'desc' }, take: 1 },
        },
      }),
      this.prisma.bill.count({ where }),
    ]);

    return { count, data };
  }

  async findBill(id: string, userId: string, userRole: string) {
    const bill = await this.prisma.bill.findUnique({
      where: { id },
      include: {
        unit: true,
        user: { select: { id: true, name: true, email: true } },
        payments: { orderBy: { createdAt: 'desc' } },
      },
    });
    if (!bill) throw new NotFoundException(`Bill with ID ${id} not found`);

    if (userRole === 'RESIDENT' && bill.userId !== userId) {
      throw new NotFoundException(`Bill with ID ${id} not found`);
    }

    return bill;
  }

  payBill = async (billId: string, dto: PayBillDto, userId: string, userRole: string) => {
    const bill = await this.findBill(billId, userId, userRole);

    if (bill.status === BillStatus.PAID) {
      throw new BadRequestException('Bill is already paid');
    }
    if (bill.status === BillStatus.CANCELLED) {
      throw new BadRequestException('Bill is cancelled');
    }

    return this.prisma.$transaction(async (tx) => {
      const payment = await tx.payment.create({
        data: {
          billId,
          userId,
          amount: dto.amount,
          currency: bill.currency,
          method: dto.method,
          status: PaymentStatus.COMPLETED,
          reference: dto.reference,
          paidAt: new Date(),
        },
      });

      await tx.bill.update({
        where: { id: billId },
        data: { status: BillStatus.PAID },
      });

      return payment;
    });
  };

  async findPaymentHistory(userId: string, userRole: string, params?: { skip?: number; take?: number }) {
    const { skip = 0, take = 20 } = params || {};
    const where: any = { deletedAt: null };

    if (userRole === 'RESIDENT') {
      where.userId = userId;
    }

    const [data, count] = await Promise.all([
      this.prisma.payment.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          bill: { select: { id: true, type: true, dueDate: true } },
          user: { select: { id: true, name: true } },
        },
      }),
      this.prisma.payment.count({ where }),
    ]);

    return { count, data };
  }

  async configureAutopay(dto: any, userId: string) {
    return { message: 'Autopay configuration saved', userId, ...dto };
  }
}
