import { Module } from '@nestjs/common';
import { SandhaController } from './sandha.controller';
import { SandhaService } from './sandha.service';

@Module({
  controllers: [SandhaController],
  providers: [SandhaService],
  exports: [SandhaService],
})
export class SandhaModule {}
