import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { MaintenanceStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMaintenanceDto } from './dto/create-maintenance.dto';
import { UpdateMaintenanceStatusDto } from './dto/update-status.dto';

@Injectable()
export class MaintenanceService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateMaintenanceDto, userId: string) {
    // Auto-resolve unitId from user's primary unit if not provided
    let unitId = dto.unitId;
    if (!unitId) {
      const assignment = await this.prisma.unitAssignment.findFirst({
        where: { userId, endDate: null, isPrimary: true },
      });
      if (!assignment) throw new NotFoundException('No unit assigned to your account');
      unitId = assignment.unitId;
    }
    const unit = await this.prisma.unit.findUnique({ where: { id: unitId } });
    if (!unit) throw new NotFoundException(`Unit with ID ${unitId} not found`);

    try {
      return await this.prisma.maintenanceRequest.create({
        data: {
          ...dto,
          unitId,
          userId,
          photoUrls: dto.photoUrls || [],
        },
        include: { unit: true },
      });
    } catch {
      throw new BadRequestException('Failed to create maintenance request');
    }
  }

  async remove(id: string, userId: string, userRole: string) {
    const request = await this.prisma.maintenanceRequest.findUnique({ where: { id } });
    if (!request || request.deletedAt) throw new NotFoundException(`Maintenance request with ID ${id} not found`);
    if (userRole === 'RESIDENT' && request.userId !== userId) throw new ForbiddenException('Access denied');
    return this.prisma.maintenanceRequest.update({ where: { id }, data: { deletedAt: new Date() } });
  }

  async findAll(userId: string, userRole: string, params?: { skip?: number; take?: number }) {
    const { skip = 0, take = 20 } = params || {};
    const where: any = { deletedAt: null };

    if (userRole === 'RESIDENT') {
      where.userId = userId;
    }

    const [data, count] = await Promise.all([
      this.prisma.maintenanceRequest.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, name: true } },
          unit: { select: { id: true, number: true, building: true } },
        },
      }),
      this.prisma.maintenanceRequest.count({ where }),
    ]);

    return { count, data };
  }

  async findOne(id: string, userId: string, userRole: string) {
    const request = await this.prisma.maintenanceRequest.findFirst({
      where: { id, deletedAt: null },
      include: {
        user: { select: { id: true, name: true, phone: true } },
        unit: true,
      },
    });
    if (!request) throw new NotFoundException(`Maintenance request with ID ${id} not found`);

    if (userRole === 'RESIDENT' && request.userId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    return request;
  }

  updateStatus = async (id: string, dto: UpdateMaintenanceStatusDto) => {
    const request = await this.prisma.maintenanceRequest.findUnique({ where: { id } });
    if (!request) throw new NotFoundException(`Maintenance request with ID ${id} not found`);

    const data: any = { status: dto.status, notes: dto.notes };
    if (dto.status === MaintenanceStatus.RESOLVED) {
      data.resolvedAt = new Date();
    }

    return this.prisma.maintenanceRequest.update({
      where: { id },
      data,
      include: { user: { select: { id: true, name: true } }, unit: true },
    });
  };

  async addPhotos(id: string, photoUrls: string[], userId: string, userRole: string) {
    const request = await this.prisma.maintenanceRequest.findUnique({ where: { id } });
    if (!request) throw new NotFoundException(`Maintenance request with ID ${id} not found`);

    if (userRole === 'RESIDENT' && request.userId !== userId) {
      throw new ForbiddenException('Access denied');
    }

    return this.prisma.maintenanceRequest.update({
      where: { id },
      data: { photoUrls: { push: photoUrls } },
    });
  }
}
