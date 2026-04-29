import { Test, TestingModule } from '@nestjs/testing';
import { GuestsService } from '../guests/guests.service';
import { PrismaService } from '../prisma/prisma.service';

const mockPrisma = {
  guestPass: {
    findUnique: jest.fn(),
    findFirst: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
  },
  gateLog: {
    create: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
  },
};

const SCANNER_ID = 'guard-1';

const basePass = {
  id: 'pass-1',
  userId: 'resident-1',
  qrCode: 'valid-qr-uuid',
  guestName: 'John Doe',
  guestPhone: '+9647001234567',
  purpose: 'Visit',
  validUntil: new Date(Date.now() + 86400000),
  user: {
    id: 'resident-1',
    name: 'Resident',
    phone: '+9647009999999',
    unitAssignments: [],
  },
};

describe('GuestsService.scanQr', () => {
  let service: GuestsService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GuestsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<GuestsService>(GuestsService);

    mockPrisma.gateLog.create.mockResolvedValue({});
    mockPrisma.guestPass.update.mockResolvedValue({});
  });

  it('ACTIVE pass returns APPROVED and sets status to USED', async () => {
    mockPrisma.guestPass.findUnique.mockResolvedValue({
      ...basePass,
      status: 'ACTIVE',
    });

    const result = await service.scanQr({ qrCode: 'valid-qr-uuid' }, SCANNER_ID);

    expect(result.result).toBe('APPROVED');
    expect(mockPrisma.guestPass.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ status: 'USED' }),
      }),
    );
  });

  it('USED pass returns DENIED', async () => {
    mockPrisma.guestPass.findUnique.mockResolvedValue({
      ...basePass,
      status: 'USED',
    });

    const result = await service.scanQr({ qrCode: 'valid-qr-uuid' }, SCANNER_ID);

    expect(result.result).toBe('DENIED');
    expect(result.reason).toMatch(/already been used/i);
  });

  it('REVOKED pass returns DENIED', async () => {
    mockPrisma.guestPass.findUnique.mockResolvedValue({
      ...basePass,
      status: 'REVOKED',
    });

    const result = await service.scanQr({ qrCode: 'valid-qr-uuid' }, SCANNER_ID);

    expect(result.result).toBe('DENIED');
    expect(result.reason).toMatch(/revoked/i);
  });

  it('ACTIVE pass with expired validUntil returns EXPIRED/DENIED', async () => {
    mockPrisma.guestPass.findUnique.mockResolvedValue({
      ...basePass,
      status: 'ACTIVE',
      validUntil: new Date(Date.now() - 1000),
    });

    const result = await service.scanQr({ qrCode: 'valid-qr-uuid' }, SCANNER_ID);

    expect(['DENIED', 'EXPIRED']).toContain(result.result);
    expect(mockPrisma.guestPass.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ status: 'EXPIRED' }),
      }),
    );
  });

  it('non-existent QR code returns DENIED', async () => {
    mockPrisma.guestPass.findUnique.mockResolvedValue(null);

    const result = await service.scanQr({ qrCode: 'ghost-qr' }, SCANNER_ID);

    expect(result.result).toBe('DENIED');
    expect(result.reason).toMatch(/invalid qr code/i);
    expect(mockPrisma.gateLog.create).not.toHaveBeenCalled();
  });
});
