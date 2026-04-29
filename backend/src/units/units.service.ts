import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUnitDto } from './dto/create-unit.dto';
import { UpdateUnitDto } from './dto/update-unit.dto';
import { AssignUnitDto } from './dto/assign-unit.dto';

@Injectable()
export class UnitsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateUnitDto) {
    const existing = await this.prisma.unit.findUnique({ where: { number: dto.number } });
    if (existing) throw new ConflictException(`Unit ${dto.number} already exists`);

    try {
      return await this.prisma.unit.create({ data: dto });
    } catch {
      throw new BadRequestException('Failed to create unit');
    }
  }

  async findAll(userId?: string, userRole?: string) {
    const where: any = { isActive: true };

    if (userRole === 'RESIDENT' && userId) {
      where.assignments = { some: { userId, endDate: null } };
    }

    const [data, count] = await Promise.all([
      this.prisma.unit.findMany({
        where,
        orderBy: [{ building: 'asc' }, { floor: 'asc' }, { number: 'asc' }],
        include: {
          assignments: {
            where: { endDate: null },
            include: { user: { select: { id: true, name: true, email: true } } },
          },
        },
      }),
      this.prisma.unit.count({ where }),
    ]);

    return { count, data };
  }

  async findOne(id: string) {
    const unit = await this.prisma.unit.findFirst({
      where: { id, isActive: true },
      include: {
        assignments: {
          where: { endDate: null },
          include: { user: { select: { id: true, name: true, email: true, phone: true } } },
        },
        maintenance: {
          orderBy: { createdAt: 'desc' },
          take: 5,
        },
        bills: {
          where: { status: { in: ['PENDING', 'OVERDUE'] } },
          orderBy: { dueDate: 'asc' },
        },
      },
    });
    if (!unit) throw new NotFoundException(`Unit with ID ${id} not found`);
    return unit;
  }

  async update(id: string, dto: UpdateUnitDto) {
    const unit = await this.prisma.unit.findUnique({ where: { id } });
    if (!unit) throw new NotFoundException(`Unit with ID ${id} not found`);
    try {
      return await this.prisma.unit.update({ where: { id }, data: dto });
    } catch {
      throw new BadRequestException('Failed to update unit');
    }
  }

  async assign(unitId: string, dto: AssignUnitDto) {
    const unit = await this.prisma.unit.findUnique({ where: { id: unitId } });
    if (!unit) throw new NotFoundException(`Unit with ID ${unitId} not found`);

    const user = await this.prisma.user.findFirst({ where: { id: dto.userId, deletedAt: null } });
    if (!user) throw new NotFoundException(`User with ID ${dto.userId} not found`);

    const existing = await this.prisma.unitAssignment.findUnique({
      where: { userId_unitId: { userId: dto.userId, unitId } },
    });

    if (existing) {
      return this.prisma.unitAssignment.update({
        where: { userId_unitId: { userId: dto.userId, unitId } },
        data: { isPrimary: dto.isPrimary, endDate: dto.endDate ? new Date(dto.endDate) : null },
      });
    }

    if (dto.isPrimary) {
      await this.prisma.unitAssignment.updateMany({
        where: { userId: dto.userId, isPrimary: true, endDate: null },
        data: { isPrimary: false },
      });
    }

    return this.prisma.unitAssignment.create({
      data: {
        userId: dto.userId,
        unitId,
        isPrimary: dto.isPrimary ?? false,
        endDate: dto.endDate ? new Date(dto.endDate) : null,
      },
    });
  }
}
