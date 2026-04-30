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
import { ApiTags, ApiBearerAuth, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // ── Dashboard ──────────────────────────────────────────────────────────────

  @Get('dashboard/stats')
  @ApiOperation({ summary: 'Dashboard stats' })
  getDashboardStats() {
    return this.adminService.getDashboardStats();
  }

  // ── Residents ──────────────────────────────────────────────────────────────

  @Get('residents')
  @ApiOperation({ summary: 'List residents' })
  @ApiQuery({ name: 'skip', required: false })
  @ApiQuery({ name: 'take', required: false })
  @ApiQuery({ name: 'search', required: false })
  getResidents(
    @Query('skip') skip?: string,
    @Query('take') take?: string,
    @Query('search') search?: string,
  ) {
    return this.adminService.getResidents(
      skip ? +skip : 0,
      take ? +take : 50,
      search,
    );
  }

  // ── Units ──────────────────────────────────────────────────────────────────

  @Get('units')
  @ApiOperation({ summary: 'List units' })
  getUnits(@Query('skip') skip?: string, @Query('take') take?: string) {
    return this.adminService.getUnits(skip ? +skip : 0, take ? +take : 50);
  }

  // ── Announcements ──────────────────────────────────────────────────────────

  @Get('announcements')
  @ApiOperation({ summary: 'List announcements' })
  getAnnouncements(@Query('skip') skip?: string, @Query('take') take?: string) {
    return this.adminService.getAnnouncements(skip ? +skip : 0, take ? +take : 50);
  }

  @Post('announcements')
  @ApiOperation({ summary: 'Create announcement' })
  createAnnouncement(
    @Body() dto: { title: string; body: string; isImportant?: boolean; expiresAt?: string },
  ) {
    return this.adminService.createAnnouncement(dto);
  }

  // ── Maintenance ────────────────────────────────────────────────────────────

  @Get('maintenance')
  @ApiOperation({ summary: 'List maintenance requests' })
  @ApiQuery({ name: 'status', required: false })
  getMaintenance(
    @Query('skip') skip?: string,
    @Query('take') take?: string,
    @Query('status') status?: string,
  ) {
    return this.adminService.getMaintenance(skip ? +skip : 0, take ? +take : 50, status);
  }

  @Patch('maintenance/:id/status')
  @ApiOperation({ summary: 'Update maintenance request status' })
  updateMaintenanceStatus(@Param('id') id: string, @Body() dto: { status: string }) {
    return this.adminService.updateMaintenanceStatus(id, dto.status);
  }

  // ── Bills ──────────────────────────────────────────────────────────────────

  @Get('bills')
  @ApiOperation({ summary: 'List bills (supports ?status=overdue)' })
  @ApiQuery({ name: 'status', required: false })
  getBills(
    @Query('skip') skip?: string,
    @Query('take') take?: string,
    @Query('status') status?: string,
  ) {
    return this.adminService.getBills(skip ? +skip : 0, take ? +take : 50, status);
  }

  @Post('bills')
  @ApiOperation({ summary: 'Create a bill' })
  createBill(
    @Body() dto: { userId: string; unitId: string; type: string; amount: number; currency?: string; dueDate: string; description?: string },
  ) {
    return this.adminService.createBill(dto);
  }

  @Patch('bills/:id/mark-paid')
  @ApiOperation({ summary: 'Mark bill as paid' })
  markBillPaid(@Param('id') id: string) {
    return this.adminService.markBillPaid(id);
  }

  // ── Payments ───────────────────────────────────────────────────────────────

  @Get('payments')
  @ApiOperation({ summary: 'List payments' })
  getPayments(@Query('skip') skip?: string, @Query('take') take?: string) {
    return this.adminService.getPayments(skip ? +skip : 0, take ? +take : 50);
  }

  // ── Gate ───────────────────────────────────────────────────────────────────

  @Get('gate/passes')
  @ApiOperation({ summary: 'List guest passes' })
  getGatePasses(@Query('skip') skip?: string, @Query('take') take?: string) {
    return this.adminService.getGatePasses(skip ? +skip : 0, take ? +take : 50);
  }

  @Get('gate/logs')
  @ApiOperation({ summary: 'List gate logs' })
  getGateLogs(@Query('skip') skip?: string, @Query('take') take?: string) {
    return this.adminService.getGateLogs(skip ? +skip : 0, take ? +take : 50);
  }

  // ── Staff ──────────────────────────────────────────────────────────────────

  @Get('staff')
  @ApiOperation({ summary: 'List staff (ADMIN + SECURITY)' })
  getStaff(@Query('skip') skip?: string, @Query('take') take?: string) {
    return this.adminService.getStaff(skip ? +skip : 0, take ? +take : 50);
  }

  @Post('staff')
  @ApiOperation({ summary: 'Create staff member' })
  createStaff(
    @Body() dto: { name: string; email: string; password: string; role: 'ADMIN' | 'SECURITY' },
  ) {
    return this.adminService.createStaff(dto);
  }

  @Patch('staff/:id')
  @ApiOperation({ summary: 'Update staff member' })
  updateStaff(@Param('id') id: string, @Body() dto: { role?: string; isActive?: boolean }) {
    return this.adminService.updateStaff(id, dto);
  }

  // ── Reports ────────────────────────────────────────────────────────────────

  @Get('reports/payments')
  @ApiOperation({ summary: 'Payment stats' })
  getPaymentsReport() {
    return this.adminService.getPaymentsReport();
  }

  @Get('reports/maintenance')
  @ApiOperation({ summary: 'Maintenance stats' })
  getMaintenanceReport() {
    return this.adminService.getMaintenanceReport();
  }

  @Get('reports/occupancy')
  @ApiOperation({ summary: 'Occupancy stats' })
  getOccupancyReport() {
    return this.adminService.getOccupancyReport();
  }

  @Get('reports/gate')
  @ApiOperation({ summary: 'Gate access stats' })
  getGateReport() {
    return this.adminService.getGateReport();
  }
}
