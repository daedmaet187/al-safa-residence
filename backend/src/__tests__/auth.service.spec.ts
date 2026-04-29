import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { AuthService } from '../auth/auth.service';
import { PrismaService } from '../prisma/prisma.service';

const mockPrisma = {
  user: {
    findUnique: jest.fn(),
  },
  refreshToken: {
    findUnique: jest.fn(),
    create: jest.fn(),
    delete: jest.fn(),
    deleteMany: jest.fn(),
  },
};

const mockJwtService = {
  sign: jest.fn(),
  verify: jest.fn(),
};

const mockConfigService = {
  get: jest.fn((key: string) => {
    const config: Record<string, string> = {
      'jwt.accessSecret': 'test-access-secret',
      'jwt.refreshSecret': 'test-refresh-secret',
      'jwt.accessExpiry': '15m',
      'jwt.refreshExpiry': '7d',
    };
    return config[key];
  }),
};

describe('AuthService', () => {
  let service: AuthService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  describe('login', () => {
    const validUser = {
      id: 'user-1',
      email: 'resident@example.com',
      name: 'Test User',
      role: 'RESIDENT',
      passwordHash: '',
      isActive: true,
      deletedAt: null,
    };

    beforeEach(async () => {
      validUser.passwordHash = await bcrypt.hash('correct-password', 10);
    });

    it('returns access and refresh tokens on valid credentials', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(validUser);
      mockJwtService.sign
        .mockReturnValueOnce('access-token')
        .mockReturnValueOnce('refresh-token');
      mockPrisma.refreshToken.create.mockResolvedValue({});

      const result = await service.login({
        email: 'resident@example.com',
        password: 'correct-password',
      });

      expect(result.accessToken).toBe('access-token');
      expect(result.refreshToken).toBe('refresh-token');
      expect(result.user.email).toBe('resident@example.com');
    });

    it('throws UnauthorizedException on wrong password', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(validUser);

      await expect(
        service.login({ email: 'resident@example.com', password: 'wrong-password' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('throws UnauthorizedException on unknown email', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.login({ email: 'nobody@example.com', password: 'any-password' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('throws UnauthorizedException for inactive user', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ ...validUser, isActive: false });

      await expect(
        service.login({ email: 'resident@example.com', password: 'correct-password' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('throws UnauthorizedException for soft-deleted user', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({
        ...validUser,
        deletedAt: new Date(),
      });

      await expect(
        service.login({ email: 'resident@example.com', password: 'correct-password' }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('refresh', () => {
    const validPayload = { sub: 'user-1', email: 'resident@example.com', role: 'RESIDENT' };

    it('returns new access token with valid refresh token', async () => {
      mockJwtService.verify.mockReturnValue(validPayload);
      mockPrisma.refreshToken.findUnique.mockResolvedValue({
        token: 'valid-refresh',
        expiresAt: new Date(Date.now() + 86400000),
      });
      mockPrisma.refreshToken.delete.mockResolvedValue({});
      mockJwtService.sign
        .mockReturnValueOnce('new-access-token')
        .mockReturnValueOnce('new-refresh-token');
      mockPrisma.refreshToken.create.mockResolvedValue({});

      const result = await service.refresh('valid-refresh');

      expect(result.accessToken).toBe('new-access-token');
    });

    it('throws UnauthorizedException for invalid refresh token signature', async () => {
      mockJwtService.verify.mockImplementation(() => {
        throw new Error('invalid signature');
      });

      await expect(service.refresh('bad-token')).rejects.toThrow(UnauthorizedException);
    });

    it('throws UnauthorizedException when token not found in DB', async () => {
      mockJwtService.verify.mockReturnValue(validPayload);
      mockPrisma.refreshToken.findUnique.mockResolvedValue(null);

      await expect(service.refresh('unknown-token')).rejects.toThrow(UnauthorizedException);
    });

    it('throws UnauthorizedException for expired refresh token', async () => {
      mockJwtService.verify.mockReturnValue(validPayload);
      mockPrisma.refreshToken.findUnique.mockResolvedValue({
        token: 'expired-refresh',
        expiresAt: new Date(Date.now() - 1000),
      });

      await expect(service.refresh('expired-refresh')).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('logout', () => {
    it('deletes the refresh token on logout', async () => {
      mockPrisma.refreshToken.deleteMany.mockResolvedValue({ count: 1 });

      const result = await service.logout('some-refresh-token');

      expect(mockPrisma.refreshToken.deleteMany).toHaveBeenCalledWith({
        where: { token: 'some-refresh-token' },
      });
      expect(result.message).toMatch(/logged out/i);
    });
  });
});
