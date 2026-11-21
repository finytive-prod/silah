import { Module } from '@nestjs/common';
import { SpecialSchedulesController } from './special-schedules.controller';
import { SpecialSchedulesService } from './special-schedules.service';
import { PrismaModule } from '../../common/prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [SpecialSchedulesController],
  providers: [SpecialSchedulesService],
  exports: [SpecialSchedulesService],
})
export class SpecialSchedulesModule {}
