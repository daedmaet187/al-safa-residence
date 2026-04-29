import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UploadsService } from '../uploads/uploads.service';

// Mock the AWS SDK
jest.mock('@aws-sdk/client-s3', () => ({
  S3Client: jest.fn().mockImplementation(() => ({})),
  PutObjectCommand: jest.fn().mockImplementation((input) => input),
}));

jest.mock('@aws-sdk/s3-request-presigner', () => ({
  getSignedUrl: jest.fn().mockResolvedValue('https://s3.example.com/presigned'),
}));

const mockConfigService = {
  get: jest.fn((key: string) => {
    const config: Record<string, string> = {
      'aws.region': 'eu-central-1',
      'aws.s3Bucket': 'al-safa-uploads',
    };
    return config[key];
  }),
};

const adminUser = { id: 'admin-1', role: 'ADMIN' };
const residentUser = { id: 'resident-1', role: 'RESIDENT' };

describe('UploadsService.getPresignedUrl', () => {
  let service: UploadsService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UploadsService,
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    service = module.get<UploadsService>(UploadsService);
  });

  it('RESIDENT can get presigned URL with correct uploads/{userId}/ prefix', async () => {
    const dto = {
      key: `uploads/${residentUser.id}/photo.jpg`,
      contentType: 'image/jpeg',
      contentLength: 1024,
    };

    const result = await service.getPresignedUrl(dto, residentUser);

    expect(result.url).toBe('https://s3.example.com/presigned');
    expect(result.key).toBe(dto.key);
    expect(result.expiresIn).toBe(300);
  });

  it('ADMIN can use any key prefix', async () => {
    const dto = {
      key: 'admin-docs/report.pdf',
      contentType: 'application/pdf',
      contentLength: 2048,
    };

    const result = await service.getPresignedUrl(dto, adminUser);

    expect(result.url).toBe('https://s3.example.com/presigned');
  });

  it('RESIDENT using wrong key prefix throws ForbiddenException', async () => {
    const dto = {
      key: `uploads/other-user-id/photo.jpg`,
      contentType: 'image/jpeg',
      contentLength: 1024,
    };

    await expect(service.getPresignedUrl(dto, residentUser)).rejects.toThrow(
      ForbiddenException,
    );
  });

  it('RESIDENT cannot use admin prefix', async () => {
    const dto = {
      key: 'admin-docs/evil.pdf',
      contentType: 'application/pdf',
      contentLength: 512,
    };

    await expect(service.getPresignedUrl(dto, residentUser)).rejects.toThrow(
      ForbiddenException,
    );
  });

  it('throws BadRequestException for disallowed content type', async () => {
    const dto = {
      key: `uploads/${residentUser.id}/script.exe`,
      contentType: 'application/x-msdownload',
      contentLength: 512,
    };

    await expect(service.getPresignedUrl(dto, residentUser)).rejects.toThrow(
      BadRequestException,
    );
  });

  it('throws BadRequestException for path traversal in key', async () => {
    const dto = {
      key: `uploads/${residentUser.id}/../admin/secret.pdf`,
      contentType: 'application/pdf',
      contentLength: 512,
    };

    await expect(service.getPresignedUrl(dto, residentUser)).rejects.toThrow(
      BadRequestException,
    );
  });
});
