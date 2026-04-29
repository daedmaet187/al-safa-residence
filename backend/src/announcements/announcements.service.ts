import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAnnouncementDto } from './dto/create-announcement.dto';
import { UpdateAnnouncementDto } from './dto/update-announcement.dto';

@Injectable()
export class AnnouncementsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateAnnouncementDto) {
    try {
      return await this.prisma.announcement.create({
        data: {
          ...dto,
          expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
        },
      });
    } catch {
      throw new BadRequestException('Failed to create announcement');
    }
  }

  async findAll(params?: { skip?: number; take?: number }) {
    const { skip = 0, take = 20 } = params || {};
    const now = new Date();

    const where = {
      deletedAt: null,
      OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
    };

    const [data, count] = await Promise.all([
      this.prisma.announcement.findMany({
        where,
        skip,
        take,
        orderBy: [{ isImportant: 'desc' }, { publishedAt: 'desc' }],
      }),
      this.prisma.announcement.count({ where }),
    ]);

    return { count, data };
  }

  async findOne(id: string) {
    const announcement = await this.prisma.announcement.findFirst({
      where: { id, deletedAt: null },
    });
    if (!announcement) throw new NotFoundException(`Announcement with ID ${id} not found`);
    return announcement;
  }

  async update(id: string, dto: UpdateAnnouncementDto) {
    await this.findOne(id);
    const data: any = { ...dto };
    if (dto.expiresAt) data.expiresAt = new Date(dto.expiresAt);
    try {
      return await this.prisma.announcement.update({ where: { id }, data });
    } catch {
      throw new BadRequestException('Failed to update announcement');
    }
  }

  async remove(id: string) {
    await this.findOne(id);
    await this.prisma.announcement.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
    return { message: `Announcement with ID ${id} has been deleted` };
  }
}
