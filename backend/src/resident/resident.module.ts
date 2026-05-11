import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ResidentController } from './resident.controller';
import { ResidentService } from './resident.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule, ConfigModule],
  controllers: [ResidentController],
  providers: [ResidentService],
  exports: [ResidentService],
})
export class ResidentModule {}
