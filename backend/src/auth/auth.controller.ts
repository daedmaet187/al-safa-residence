import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  HttpStatus,
  ValidationPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { SendOtpDto, VerifyOtpDto } from './dto/verify-otp.dto';
import { AuthResponseDto } from './dto/auth-response.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { User } from '../common/decorators/user.decorator';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('send-otp')
  @ApiOperation({ summary: 'Send OTP to phone number (mobile login step 1)' })
  @ApiResponse({ status: HttpStatus.OK, description: 'OTP sent' })
  @ApiResponse({ status: HttpStatus.NOT_FOUND, description: 'Phone not registered for given role' })
  async sendOtp(@Body(ValidationPipe) dto: SendOtpDto) {
    return this.authService.sendOtp(dto.phone, dto.role ?? 'RESIDENT');
  }

  @Post('verify-otp')
  @ApiOperation({ summary: 'Verify OTP by phone (mobile login step 2) — default OTP: 123456' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Tokens + user + units' })
  @ApiResponse({ status: HttpStatus.UNAUTHORIZED, description: 'Invalid OTP or phone not found' })
  @ApiResponse({ status: HttpStatus.NOT_FOUND, description: 'Phone not registered for given role' })
  async verifyOtp(@Body(ValidationPipe) dto: VerifyOtpDto) {
    return this.authService.verifyOtp(dto.phone, dto.otp, dto.role ?? 'RESIDENT');
  }

  @Post('login')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({ summary: 'Login with email and password' })
  @ApiResponse({ status: HttpStatus.OK, type: AuthResponseDto })
  @ApiResponse({ status: HttpStatus.UNAUTHORIZED, description: 'Invalid credentials' })
  async login(@Body(ValidationPipe) dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('refresh')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({ summary: 'Refresh access token' })
  @ApiResponse({ status: HttpStatus.OK, description: 'New access and refresh tokens' })
  @ApiResponse({ status: HttpStatus.UNAUTHORIZED, description: 'Invalid refresh token' })
  async refresh(@Body(ValidationPipe) dto: RefreshDto) {
    return this.authService.refresh(dto.refreshToken);
  }

  @Post('logout')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Logout and invalidate refresh token' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Logged out' })
  async logout(@Body(ValidationPipe) dto: RefreshDto) {
    return this.authService.logout(dto.refreshToken);
  }

  @Get('me')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Get current user profile with units' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Current user + units' })
  async me(@User() user: any) {
    return this.authService.getMe(user.id, user.actorType);
  }
}
