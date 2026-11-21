import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { CreateSpecialScheduleDto } from './dto/special-schedule.dto';

@Injectable()
export class SpecialSchedulesService {
  constructor(private prisma: PrismaService) {}

  async findByMasjid(masjidId: string) {
    return this.prisma.specialSchedule.findMany({
      where: { masjidId },
      orderBy: { startDate: 'asc' },
      include: {
        creator: { select: { id: true, name: true } },
      },
    });
  }

  async create(masjidId: string, userId: string, dto: CreateSpecialScheduleDto) {
    return this.prisma.specialSchedule.create({
      data: {
        masjidId,
        type: dto.type,
        title: dto.title,
        titleTa: dto.titleTa,
        startDate: new Date(dto.startDate),
        endDate: dto.endDate ? new Date(dto.endDate) : null,
        startTime: dto.startTime,
        endTime: dto.endTime,
        notes: dto.notes,
        notesTa: dto.notesTa,
        createdBy: userId,
      },
    });
  }

  async delete(masjidId: string, id: string) {
    const existing = await this.prisma.specialSchedule.findFirst({
      where: { id, masjidId },
    });
    if (!existing) {
      throw new NotFoundException('Special schedule not found');
    }
    return this.prisma.specialSchedule.delete({
      where: { id },
    });
  }
}
