import { Injectable, BadRequestException, ForbiddenException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { PresignedUrlDto } from './dto/presigned-url.dto';

@Injectable()
export class UploadsService {
  private s3: S3Client;
  private bucket: string;

  constructor(private readonly config: ConfigService) {
    this.s3 = new S3Client({
      region: config.get<string>('aws.region'),
    });
    this.bucket = config.get<string>('aws.s3Bucket');
  }

  async getPresignedUrl(dto: PresignedUrlDto, user: { id: string; role: string }) {
    const allowedContentTypes = [
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/heic',
      'application/pdf',
    ];

    if (!allowedContentTypes.includes(dto.contentType)) {
      throw new BadRequestException(`Content type ${dto.contentType} is not allowed`);
    }

    if (dto.key.includes('..') || dto.key.startsWith('/')) {
      throw new BadRequestException('Invalid key');
    }

    if (user.role !== 'ADMIN' && !dto.key.startsWith(`uploads/${user.id}/`)) {
      throw new ForbiddenException(`Key must start with uploads/${user.id}/`);
    }

    try {
      const command = new PutObjectCommand({
        Bucket: this.bucket,
        Key: dto.key,
        ContentType: dto.contentType,
        ContentLength: dto.contentLength,
      });

      const url = await getSignedUrl(this.s3, command, { expiresIn: 300 });

      return {
        url,
        key: dto.key,
        expiresIn: 300,
      };
    } catch {
      throw new BadRequestException('Failed to generate presigned URL');
    }
  }
}
