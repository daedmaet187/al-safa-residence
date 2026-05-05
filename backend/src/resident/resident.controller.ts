import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ResidentService } from './resident.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { HouseholdAccessGuard } from '../auth/guards/household-access.guard';
import { RequireAccess } from '../auth/decorators/require-access.decorator';
import { User } from '../common/decorators/user.decorator';

@ApiTags('resident')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, HouseholdAccessGuard)
@Controller()
export class ResidentController {
  constructor(private readonly residentService: ResidentService) {}

  // ── Home dashboard ─────────────────────────────────────────────────────────

  @Get('dashboard/summary')
  @RequireAccess('FULL')
  @ApiOperation({ summary: 'Home screen summary for resident' })
  getDashboardSummary(@User() user: any) {
    return this.residentService.getDashboardSummary(user.id);
  }

  // ── Bills ──────────────────────────────────────────────────────────────────

  @Get('bills')
  @RequireAccess('PRIMARY_ONLY')
  @ApiOperation({ summary: 'List resident bills (optional ?status=paid)' })
  getBills(@User() user: any, @Query('status') status?: string) {
    return this.residentService.getBills(user.id, status);
  }

  @Get('bills/:id')
  @RequireAccess('PRIMARY_ONLY')
  @ApiOperation({ summary: 'Get bill detail' })
  getBill(@User() user: any, @Param('id') id: string) {
    return this.residentService.getBill(user.id, id);
  }

  @Post('bills/:id/pay')
  @RequireAccess('PRIMARY_ONLY')
  @ApiOperation({ summary: 'Pay a bill' })
  payBill(@User() user: any, @Param('id') id: string, @Body() dto: { method: string }) {
    return this.residentService.payBill(user.id, id, dto.method);
  }

  // ── Gate / Guest passes ────────────────────────────────────────────────────

  @Get('gate/my-qr')
  @RequireAccess('LIMITED')
  @ApiOperation({ summary: 'Get resident personal QR code' })
  getMyQr(@User() user: any) {
    return this.residentService.getMyQr(user.id);
  }

  @Get('gate/passes')
  @RequireAccess('FULL')
  @ApiOperation({ summary: 'List my guest passes' })
  getGuestPasses(@User() user: any) {
    return this.residentService.getGuestPasses(user.id);
  }

  @Post('gate/passes')
  @RequireAccess('FULL')
  @ApiOperation({ summary: 'Create a guest pass' })
  createGuestPass(
    @User() user: any,
    @Body() dto: { guestName: string; guestPhone: string; guestIdNumber?: string; validFrom: string; validUntil: string; purpose?: string },
  ) {
    return this.residentService.createGuestPass(user.id, dto);
  }

  @Delete('gate/passes/:id')
  @RequireAccess('FULL')
  @ApiOperation({ summary: 'Revoke a guest pass' })
  revokeGuestPass(@User() user: any, @Param('id') id: string) {
    return this.residentService.revokeGuestPass(user.id, id);
  }

  // ── Units ──────────────────────────────────────────────────────────────────

  @Get('units/my-unit')
  @RequireAccess('FULL')
  @ApiOperation({ summary: 'Get resident unit detail with stats' })
  getMyUnit(@User() user: any) {
    return this.residentService.getMyUnit(user.id);
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  @Get('profile')
  @RequireAccess('LIMITED')
  @ApiOperation({ summary: 'Get profile' })
  getProfile(@User() user: any) {
    return this.residentService.getProfile(user.id);
  }

  @Patch('profile')
  @RequireAccess('LIMITED')
  @ApiOperation({ summary: 'Update profile' })
  updateProfile(@User() user: any, @Body() dto: { name?: string; phone?: string }) {
    return this.residentService.updateProfile(user.id, dto);
  }

  @Post('profile/change-password')
  @ApiOperation({ summary: 'Change password' })
  changePassword(
    @User() user: any,
    @Body() dto: { currentPassword: string; newPassword: string },
  ) {
    return this.residentService.changePassword(user.id, dto.currentPassword, dto.newPassword);
  }
}
