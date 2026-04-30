import {
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';

const DEFAULT_OTP = '123456';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  // ── Admin dashboard login (email + password) ───────────────────────────────
  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (!user || user.deletedAt || !user.isActive) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const passwordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!passwordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const tokens = await this.generateTokens(user.id, user.email ?? user.phone, user.role);

    return {
      ...tokens,
      requiresOtp: false,
      user: { id: user.id, email: user.email, name: user.name, role: user.role },
    };
  }

  // ── Mobile: send OTP to phone ──────────────────────────────────────────────
  async sendOtp(phone: string) {
    const user = await this.prisma.user.findUnique({ where: { phone } });
    if (!user || user.deletedAt || !user.isActive) {
      throw new UnauthorizedException('No account found with this phone number');
    }
    // TODO: integrate SMS provider here — for now OTP is always 123456
    return { message: 'OTP sent', phone };
  }

  // ── Mobile: verify OTP by phone ────────────────────────────────────────────
  async verifyOtp(phone: string, otp: string) {
    const user = await this.prisma.user.findUnique({
      where: { phone },
      include: {
        unitAssignments: {
          include: { unit: true },
          where: { endDate: null },
        },
      },
    });

    if (!user || user.deletedAt || !user.isActive) {
      throw new UnauthorizedException('No account found with this phone number');
    }

    if (otp !== DEFAULT_OTP) {
      throw new UnauthorizedException('Invalid OTP');
    }

    const tokens = await this.generateTokens(user.id, user.email ?? user.phone, user.role);

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
      user: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        name: user.name,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role,
      },
      units,
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

  async logout(refreshToken: string) {
    await this.prisma.refreshToken.deleteMany({ where: { token: refreshToken } });
    return { message: 'Logged out successfully' };
  }

  private async generateTokens(userId: string, emailOrPhone: string, role: string) {
    const payload = { sub: userId, email: emailOrPhone, role };

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
