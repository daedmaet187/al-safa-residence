import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBookingDto } from './dto/create-booking.dto';

function paginate<T>(data: T[], count: number, skip: number, take: number) {
  return {
    data,
    total: count,
    page: Math.floor(skip / take) + 1,
    limit: take,
    totalPages: Math.ceil(count / take),
  };
}

@Injectable()
export class AmenitiesService {
  constructor(private readonly prisma: PrismaService) {}

  async listAmenities(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [data, count] = await Promise.all([
      this.prisma.amenity.findMany({
        where: { isActive: true },
        skip,
        take: limit,
        orderBy: { name: 'asc' },
      }),
      this.prisma.amenity.count({ where: { isActive: true } }),
    ]);
    return paginate(data, count, skip, limit);
  }

  async getAmenity(id: string) {
    const amenity = await this.prisma.amenity.findUnique({
      where: { id },
      include: {
        _count: {
          select: {
            bookings: { where: { status: { not: 'CANCELLED' as any } } },
          },
        },
      },
    });
    if (!amenity) throw new NotFoundException(`Amenity ${id} not found`);
    return amenity;
  }

  async getAvailability(amenityId: string, date: string) {
    const amenity = await this.prisma.amenity.findUnique({ where: { id: amenityId } });
    if (!amenity) throw new NotFoundException(`Amenity ${amenityId} not found`);

    const bookedSlots = await this.prisma.amenityBooking.findMany({
      where: {
        amenityId,
        date,
        status: { not: 'CANCELLED' as any },
      },
      select: { id: true, startTime: true, endTime: true, status: true },
    });
    return { date, bookedSlots };
  }

  async createBooking(residentId: string, amenityId: string, dto: CreateBookingDto) {
    const amenity = await this.prisma.amenity.findUnique({ where: { id: amenityId } });
    if (!amenity || !amenity.isActive) throw new NotFoundException(`Amenity ${amenityId} not found`);

    const overlappingCount = await this.prisma.amenityBooking.count({
      where: {
        amenityId,
        date: dto.date,
        status: { not: 'CANCELLED' as any },
        startTime: { lt: dto.endTime },
        endTime: { gt: dto.startTime },
      },
    });
    if (overlappingCount >= amenity.capacity) {
      throw new BadRequestException('Amenity is at full capacity for this time slot');
    }

    const assignment = await this.prisma.unitAssignment.findFirst({
      where: { userId: residentId, endDate: null, isPrimary: true },
    });

    return this.prisma.amenityBooking.create({
      data: {
        amenityId,
        residentId,
        unitId: assignment?.unitId ?? null,
        date: dto.date,
        startTime: dto.startTime,
        endTime: dto.endTime,
        notes: dto.notes,
      },
      include: {
        amenity: { select: { id: true, name: true, location: true } },
      },
    });
  }

  async cancelBooking(residentId: string, bookingId: string) {
    const booking = await this.prisma.amenityBooking.findUnique({ where: { id: bookingId } });
    if (!booking || booking.residentId !== residentId) {
      throw new NotFoundException(`Booking ${bookingId} not found`);
    }
    if (booking.status === 'CANCELLED') {
      throw new BadRequestException('Booking is already cancelled');
    }
    return this.prisma.amenityBooking.update({
      where: { id: bookingId },
      data: { status: 'CANCELLED' },
    });
  }

  async getMyBookings(residentId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [data, count] = await Promise.all([
      this.prisma.amenityBooking.findMany({
        where: { residentId },
        skip,
        take: limit,
        orderBy: [{ date: 'desc' }, { startTime: 'desc' }],
        include: {
          amenity: { select: { id: true, name: true, location: true, imageUrl: true } },
        },
      }),
      this.prisma.amenityBooking.count({ where: { residentId } }),
    ]);
    return paginate(data, count, skip, limit);
  }
}
