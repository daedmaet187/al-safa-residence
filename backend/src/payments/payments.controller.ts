import {
  Controller,
  Get,
  Post,
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
import { PaymentsService } from './payments.service';
import { PayBillDto } from './dto/pay-bill.dto';
import { AutopayDto } from './dto/autopay.dto';
import { CreateBillDto } from './dto/create-bill.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { User } from '../common/decorators/user.decorator';

@ApiTags('payments')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('bills')
  @Roles(Role.ADMIN)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @ApiOperation({ summary: 'Create a bill (admin only)' })
  @ApiResponse({ status: HttpStatus.CREATED, description: 'Bill created' })
  async createBill(@Body(ValidationPipe) dto: CreateBillDto) {
    return this.paymentsService.createBill(dto);
  }

  @Get('bills')
  @ApiOperation({ summary: 'List bills (resident: own, admin: all)' })
  @ApiQuery({ name: 'skip', required: false, type: Number })
  @ApiQuery({ name: 'take', required: false, type: Number })
  @ApiResponse({ status: HttpStatus.OK, description: 'List of bills' })
  async findBills(
    @User() user: any,
    @Query('skip') skip?: string,
    @Query('take') take?: string,
  ) {
    return this.paymentsService.findBills(user.id, user.role, {
      skip: skip ? parseInt(skip, 10) : 0,
      take: take ? parseInt(take, 10) : 20,
    });
  }

  @Get('bills/:id')
  @ApiOperation({ summary: 'Get bill detail' })
  @ApiParam({ name: 'id', type: 'string', format: 'uuid' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Bill detail' })
  @ApiResponse({ status: HttpStatus.NOT_FOUND, description: 'Bill not found' })
  async findBill(@Param('id') id: string, @User() user: any) {
    return this.paymentsService.findBill(id, user.id, user.role);
  }

  @Post('bills/:id/pay')
  @ApiOperation({ summary: 'Pay a bill' })
  @ApiParam({ name: 'id', type: 'string', format: 'uuid' })
  @ApiResponse({ status: HttpStatus.CREATED, description: 'Payment recorded' })
  @ApiResponse({ status: HttpStatus.BAD_REQUEST, description: 'Bill already paid or cancelled' })
  async payBill(
    @Param('id') id: string,
    @Body(ValidationPipe) dto: PayBillDto,
    @User() user: any,
  ) {
    return this.paymentsService.payBill(id, dto, user.id, user.role);
  }

  @Get('history')
  @ApiOperation({ summary: 'Get payment history' })
  @ApiQuery({ name: 'skip', required: false, type: Number })
  @ApiQuery({ name: 'take', required: false, type: Number })
  @ApiResponse({ status: HttpStatus.OK, description: 'Payment history' })
  async findHistory(
    @User() user: any,
    @Query('skip') skip?: string,
    @Query('take') take?: string,
  ) {
    return this.paymentsService.findPaymentHistory(user.id, user.role, {
      skip: skip ? parseInt(skip, 10) : 0,
      take: take ? parseInt(take, 10) : 20,
    });
  }

  @Post('autopay')
  @ApiOperation({ summary: 'Configure autopay' })
  @ApiResponse({ status: HttpStatus.CREATED, description: 'Autopay configured' })
  async configureAutopay(@Body(ValidationPipe) dto: AutopayDto, @User() user: any) {
    return this.paymentsService.configureAutopay(dto, user.id);
  }
}
