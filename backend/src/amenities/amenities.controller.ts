import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpStatus,
  ValidationPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiResponse,
  ApiParam,
} from '@nestjs/swagger';
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
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: HttpStatus.OK, description: 'List of amenities' })
  listAmenities(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.amenitiesService.listAmenities(page ? +page : 1, limit ? +limit : 20);
  }

  @Get('my-bookings')
  @ApiOperation({ summary: "Get resident's own bookings (paginated)" })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: HttpStatus.OK, description: 'List of bookings' })
  getMyBookings(
    @User() user: any,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.amenitiesService.getMyBookings(user.id, page ? +page : 1, limit ? +limit : 20);
  }

  @Delete('bookings/:id')
  @ApiOperation({ summary: 'Cancel own booking' })
  @ApiParam({ name: 'id', type: 'string', format: 'uuid' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Booking cancelled' })
  @ApiResponse({ status: HttpStatus.NOT_FOUND, description: 'Booking not found' })
  cancelBooking(@Param('id') id: string, @User() user: any) {
    return this.amenitiesService.cancelBooking(user.id, id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Amenity detail with recent bookings count' })
  @ApiParam({ name: 'id', type: 'string', format: 'uuid' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Amenity detail' })
  @ApiResponse({ status: HttpStatus.NOT_FOUND, description: 'Amenity not found' })
  getAmenity(@Param('id') id: string) {
    return this.amenitiesService.getAmenity(id);
  }

  @Get(':id/availability')
  @ApiOperation({ summary: 'Get booked slots for a date' })
  @ApiParam({ name: 'id', type: 'string', format: 'uuid' })
  @ApiQuery({ name: 'date', required: true, description: 'YYYY-MM-DD' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Available time slots' })
  getAvailability(@Param('id') id: string, @Query('date') date: string) {
    return this.amenitiesService.getAvailability(id, date);
  }

  @Post(':id/bookings')
  @ApiOperation({ summary: 'Create a booking for an amenity' })
  @ApiParam({ name: 'id', type: 'string', format: 'uuid' })
  @ApiResponse({ status: HttpStatus.CREATED, description: 'Booking created' })
  @ApiResponse({ status: HttpStatus.BAD_REQUEST, description: 'Slot already booked' })
  @ApiResponse({ status: HttpStatus.NOT_FOUND, description: 'Amenity not found' })
  createBooking(
    @Param('id') amenityId: string,
    @Body(ValidationPipe) dto: CreateBookingDto,
    @User() user: any,
  ) {
    return this.amenitiesService.createBooking(user.id, amenityId, dto);
  }
}
