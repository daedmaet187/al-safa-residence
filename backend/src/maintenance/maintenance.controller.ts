import {
  Controller,
  Get,
  Post,
  Patch,
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
import { MaintenanceService } from './maintenance.service';
import { CreateMaintenanceDto } from './dto/create-maintenance.dto';
import { UpdateMaintenanceStatusDto } from './dto/update-status.dto';
import { AddPhotosDto } from './dto/add-photos.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { HouseholdAccessGuard } from '../auth/guards/household-access.guard';
import { RequireAccess } from '../auth/decorators/require-access.decorator';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { User } from '../common/decorators/user.decorator';

@ApiTags('maintenance')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard, HouseholdAccessGuard)
@Controller('maintenance')
export class MaintenanceController {
  constructor(private readonly maintenanceService: MaintenanceService) {}

  @Post()
  @Roles(Role.RESIDENT, Role.ADMIN)
  @RequireAccess('FULL')
  @ApiOperation({ summary: 'Submit a maintenance request' })
  @ApiResponse({ status: HttpStatus.CREATED, description: 'Request created' })
  async create(@Body(ValidationPipe) dto: CreateMaintenanceDto, @User() user: any) {
    return this.maintenanceService.create(dto, user.id);
  }

  @Get()
  @RequireAccess('FULL')
  @ApiOperation({ summary: 'List maintenance requests (admin: all, resident: own)' })
  @ApiQuery({ name: 'skip', required: false, type: Number })
  @ApiQuery({ name: 'take', required: false, type: Number })
  @ApiResponse({ status: HttpStatus.OK, description: 'List of requests' })
  async findAll(
    @User() user: any,
    @Query('skip') skip?: string,
    @Query('take') take?: string,
  ) {
    return this.maintenanceService.findAll(user.id, user.role, {
      skip: skip ? parseInt(skip, 10) : 0,
      take: take ? parseInt(take, 10) : 20,
    });
  }

  @Get(':id')
  @RequireAccess('FULL')
  @ApiOperation({ summary: 'Get maintenance request detail' })
  @ApiParam({ name: 'id', type: 'string', format: 'uuid' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Request detail' })
  @ApiResponse({ status: HttpStatus.NOT_FOUND, description: 'Not found' })
  async findOne(@Param('id') id: string, @User() user: any) {
    return this.maintenanceService.findOne(id, user.id, user.role);
  }

  @Patch(':id/status')
  @Roles(Role.ADMIN)
  @ApiOperation({ summary: 'Update maintenance request status (admin only)' })
  @ApiParam({ name: 'id', type: 'string', format: 'uuid' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Status updated' })
  async updateStatus(
    @Param('id') id: string,
    @Body(ValidationPipe) dto: UpdateMaintenanceStatusDto,
  ) {
    return this.maintenanceService.updateStatus(id, dto);
  }

  @Post(':id/photos')
  @ApiOperation({ summary: 'Add photos to maintenance request' })
  @ApiParam({ name: 'id', type: 'string', format: 'uuid' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Photos added' })
  async addPhotos(
    @Param('id') id: string,
    @Body(ValidationPipe) dto: AddPhotosDto,
    @User() user: any,
  ) {
    return this.maintenanceService.addPhotos(id, dto.photoUrls, user.id, user.role);
  }
}
