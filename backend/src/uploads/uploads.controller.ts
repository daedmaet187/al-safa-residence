import {
  Controller,
  Post,
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
import { UploadsService } from './uploads.service';
import { PresignedUrlDto } from './dto/presigned-url.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { User } from '../common/decorators/user.decorator';

@ApiTags('uploads')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('uploads')
export class UploadsController {
  constructor(private readonly uploadsService: UploadsService) {}

  @Post('presigned')
  @ApiOperation({ summary: 'Get presigned S3 PUT URL for file upload' })
  @ApiResponse({
    status: HttpStatus.CREATED,
    description: 'Presigned URL generated',
    schema: {
      properties: {
        url: { type: 'string' },
        key: { type: 'string' },
        expiresIn: { type: 'number' },
      },
    },
  })
  @ApiResponse({ status: HttpStatus.BAD_REQUEST, description: 'Invalid content type or key' })
  @ApiResponse({ status: HttpStatus.FORBIDDEN, description: 'Key prefix not allowed for this user' })
  async getPresignedUrl(@Body(ValidationPipe) dto: PresignedUrlDto, @User() user: any) {
    return this.uploadsService.getPresignedUrl(dto, user);
  }
}
