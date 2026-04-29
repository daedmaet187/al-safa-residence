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
    const unit = await this.prisma.unit.findUnique({ where: { id: dto.unitId } });
    if (!unit) throw new NotFoundException(`Unit with ID ${dto.unitId} not found`);

    try {
      return await this.prisma.maintenanceRequest.create({
        data: {
          ...dto,
          userId,
          photoUrls: dto.photoUrls || [],
        },
        include: { unit: true },
      });
    } catch {
      throw new BadRequestException('Failed to create maintenance request');
    }
  }

  async findAll(userId: string, userRole: string, params?: { skip?: number; take?: number }) {
    const { skip = 0, take = 20 } = params || {};
    const where: any = {};

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
    const request = await this.prisma.maintenanceRequest.findUnique({
      where: { id },
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
