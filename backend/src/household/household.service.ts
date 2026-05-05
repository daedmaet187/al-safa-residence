import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMemberDto } from './dto/create-member.dto';
import { UpdateMemberDto } from './dto/update-member.dto';

@Injectable()
export class HouseholdService {
  constructor(private readonly prisma: PrismaService) {}

  async getMembers(primaryUserId: string) {
    const members = await this.prisma.householdMember.findMany({
      where: { primaryUserId, isActive: true },
      orderBy: { createdAt: 'asc' },
    });
    return { members };
  }

  async addMember(primaryUserId: string, dto: CreateMemberDto) {
    const existing = await this.prisma.householdMember.findUnique({
      where: { phone: dto.phone },
    });
    if (existing) {
      throw new ConflictException('A household member with this phone number already exists');
    }

    // Also check if it's a registered resident phone
    const existingUser = await this.prisma.user.findFirst({ where: { phone: dto.phone } });
    if (existingUser) {
      throw new ConflictException('This phone number belongs to a registered resident account');
    }

    const member = await this.prisma.householdMember.create({
      data: {
        primaryUserId,
        phone: dto.phone,
        name: dto.name,
        relationship: dto.relationship,
        accessLevel: dto.accessLevel ?? 'LIMITED',
      },
    });
    return member;
  }

  async updateMember(primaryUserId: string, memberId: string, dto: UpdateMemberDto) {
    const member = await this.findOwnedMember(primaryUserId, memberId);

    const updated = await this.prisma.householdMember.update({
      where: { id: member.id },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.relationship !== undefined && { relationship: dto.relationship }),
        ...(dto.accessLevel !== undefined && { accessLevel: dto.accessLevel }),
      },
    });
    return updated;
  }

  async removeMember(primaryUserId: string, memberId: string) {
    const member = await this.findOwnedMember(primaryUserId, memberId);

    await this.prisma.householdMember.update({
      where: { id: member.id },
      data: { isActive: false },
    });

    return { message: 'Household member removed' };
  }

  private async findOwnedMember(primaryUserId: string, memberId: string) {
    const member = await this.prisma.householdMember.findUnique({
      where: { id: memberId },
    });

    if (!member || !member.isActive) {
      throw new NotFoundException('Household member not found');
    }

    if (member.primaryUserId !== primaryUserId) {
      throw new ForbiddenException('You do not own this household member');
    }

    return member;
  }
}
