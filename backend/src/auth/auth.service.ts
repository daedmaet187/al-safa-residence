import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (!user || user.deletedAt || !user.isActive) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const passwordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!passwordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const tokens = await this.generateTokens(user.id, user.email, user.role);

    return {
      ...tokens,
      user: { id: user.id, email: user.email, name: user.name, role: user.role },
    };
  }

  async refresh(refreshToken: string) {
    let payload: { sub: string; email: string; role: string };
    try {
      payload = this.jwtService.verify(refreshToken, {
        secret: this.configService.get<string>('jwt.refreshSecret'),
      });
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const stored = await this.prisma.refreshToken.findUnique({
      where: { token: refreshToken },
    });

    if (!stored || stored.expiresAt < new Date()) {
      throw new UnauthorizedException('Refresh token not found or expired');
    }

    await this.prisma.refreshToken.delete({ where: { token: refreshToken } });

    const tokens = await this.generateTokens(payload.sub, payload.email, payload.role);
    return tokens;
  }

  async sendOtp(email: string) {
    // Stub: OTP sending not implemented yet
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || user.deletedAt || !user.isActive) {
      throw new UnauthorizedException('User not found');
    }
    return { message: 'OTP sent' };
  }

  async verifyOtp(email: string, otp: string) {
    // Default OTP for development/testing
    const DEFAULT_OTP = '123456';

    const user = await this.prisma.user.findUnique({
      where: { email },
      include: {
        unitAssignments: {
          include: { unit: true },
          where: { endDate: null },
        },
      },
    });

    if (!user || user.deletedAt || !user.isActive) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (otp !== DEFAULT_OTP) {
      throw new UnauthorizedException('Invalid OTP');
    }

    const tokens = await this.generateTokens(user.id, user.email, user.role);

    const units = user.unitAssignments.map((a) => ({
      id: a.unit.id,
      number: a.unit.number,
      floor: a.unit.floor,
      building: a.unit.building,
      type: a.unit.type,
      area: a.unit.area,
      bedrooms: a.unit.bedrooms,
      bathrooms: a.unit.bathrooms,
      parkingSpot: a.unit.parkingSpot,
      isPrimary: a.isPrimary,
    }));

    return {
      ...tokens,
      role: user.role,
      user: { id: user.id, email: user.email, name: user.name, role: user.role },
      units,
    };
  }

  async logout(refreshToken: string) {
    await this.prisma.refreshToken.deleteMany({ where: { token: refreshToken } });
    return { message: 'Logged out successfully' };
  }

  private async generateTokens(userId: string, email: string, role: string) {
    const payload = { sub: userId, email, role };

    const accessToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('jwt.accessSecret'),
      expiresIn: this.configService.get<string>('jwt.accessExpiry'),
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('jwt.refreshSecret'),
      expiresIn: this.configService.get<string>('jwt.refreshExpiry'),
    });

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    await this.prisma.refreshToken.create({
      data: { userId, token: refreshToken, expiresAt },
    });

    return { accessToken, refreshToken };
  }
}
