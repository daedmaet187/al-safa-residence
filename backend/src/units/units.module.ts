import { Module } from '@nestjs/common';
import { UnitsController } from './units.controller';
import { UnitsService } from './units.service';
import { ResidentModule } from '../resident/resident.module';

@Module({
  imports: [ResidentModule],
  controllers: [UnitsController],
  providers: [UnitsService],
  exports: [UnitsService],
})
export class UnitsModule {}
