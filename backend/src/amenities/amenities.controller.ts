import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { AmenitiesService } from './amenities.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { User } from '../common/decorators/user.decorator';

@ApiTags('amenities')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('amenities')
export class AmenitiesController {
  constructor(private readonly amenitiesService: AmenitiesService) {}

  @Get()
  @ApiOperation({ summary: 'List active amenities' })
  @ApiQuery({ name: 'page', required: false })
  @ApiQuery({ name: 'limit', required: false })
  listAmenities(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.amenitiesService.listAmenities(page ? +page : 1, limit ? +limit : 20);
  }

  @Get('my-bookings')
  @ApiOperation({ summary: "Get resident's own bookings (paginated)" })
  @ApiQuery({ name: 'page', required: false })
  @ApiQuery({ name: 'limit', required: false })
  getMyBookings(
    @User() user: any,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.amenitiesService.getMyBookings(user.id, page ? +page : 1, limit ? +limit : 20);
  }

  @Delete('bookings/:id')
  @ApiOperation({ summary: 'Cancel own booking' })
  cancelBooking(@Param('id') id: string, @User() user: any) {
    return this.amenitiesService.cancelBooking(user.id, id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Amenity detail with recent bookings count' })
  getAmenity(@Param('id') id: string) {
    return this.amenitiesService.getAmenity(id);
  }

  @Get(':id/availability')
  @ApiOperation({ summary: 'Get booked slots for a date' })
  @ApiQuery({ name: 'date', required: true, description: 'YYYY-MM-DD' })
  getAvailability(@Param('id') id: string, @Query('date') date: string) {
    return this.amenitiesService.getAvailability(id, date);
  }

  @Post(':id/bookings')
  @ApiOperation({ summary: 'Create a booking for an amenity' })
  createBooking(
    @Param('id') amenityId: string,
    @Body() dto: CreateBookingDto,
    @User() user: any,
  ) {
    return this.amenitiesService.createBooking(user.id, amenityId, dto);
  }
}
