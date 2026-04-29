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
  ApiResponse,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { GuestsService } from './guests.service';
import { CreateGuestPassDto } from './dto/create-guest-pass.dto';
import { ScanQrDto } from './dto/scan-qr.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { User } from '../common/decorators/user.decorator';

@ApiTags('guests')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('guests')
export class GuestsController {
  constructor(private readonly guestsService: GuestsService) {}

  @Post()
  @Roles(Role.RESIDENT, Role.ADMIN)
  @ApiOperation({ summary: 'Create a guest pass and generate QR code' })
  @ApiResponse({ status: HttpStatus.CREATED, description: 'Guest pass created with QR code' })
  async create(@Body(ValidationPipe) dto: CreateGuestPassDto, @User() user: any) {
    return this.guestsService.create(dto, user.id);
  }

  @Get()
  @Roles(Role.RESIDENT, Role.ADMIN)
  @ApiOperation({ summary: 'List my guest passes' })
  @ApiQuery({ name: 'skip', required: false, type: Number })
  @ApiQuery({ name: 'take', required: false, type: Number })
  @ApiResponse({ status: HttpStatus.OK, description: 'List of guest passes' })
  async findAll(
    @User() user: any,
    @Query('skip') skip?: string,
    @Query('take') take?: string,
  ) {
    return this.guestsService.findAll(user.id, {
      skip: skip ? parseInt(skip, 10) : 0,
      take: take ? parseInt(take, 10) : 20,
    });
  }

  @Get('log')
  @Roles(Role.SECURITY, Role.ADMIN)
  @ApiOperation({ summary: 'Get gate access log (security + admin)' })
  @ApiQuery({ name: 'skip', required: false, type: Number })
  @ApiQuery({ name: 'take', required: false, type: Number })
  @ApiResponse({ status: HttpStatus.OK, description: 'Gate access log' })
  async findGateLog(@Query('skip') skip?: string, @Query('take') take?: string) {
    return this.guestsService.findGateLog({
      skip: skip ? parseInt(skip, 10) : 0,
      take: take ? parseInt(take, 10) : 50,
    });
  }

  @Post('scan')
  @Roles(Role.SECURITY, Role.ADMIN)
  @ApiOperation({ summary: 'Scan QR code at gate (security only)' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Scan result with resident and unit info' })
  async scan(@Body(ValidationPipe) dto: ScanQrDto, @User() user: any) {
    return this.guestsService.scanQr(dto, user.id);
  }

  @Get(':id')
  @Roles(Role.RESIDENT, Role.ADMIN)
  @ApiOperation({ summary: 'Get guest pass detail' })
  @ApiParam({ name: 'id', type: 'string', format: 'uuid' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Guest pass detail' })
  @ApiResponse({ status: HttpStatus.NOT_FOUND, description: 'Not found' })
  async findOne(@Param('id') id: string, @User() user: any) {
    return this.guestsService.findOne(id, user.id);
  }

  @Delete(':id')
  @Roles(Role.RESIDENT, Role.ADMIN)
  @ApiOperation({ summary: 'Revoke guest pass' })
  @ApiParam({ name: 'id', type: 'string', format: 'uuid' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Pass revoked' })
  async revoke(@Param('id') id: string, @User() user: any) {
    return this.guestsService.revoke(id, user.id);
  }
}
