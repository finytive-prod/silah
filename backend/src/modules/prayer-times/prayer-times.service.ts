import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { UpdatePrayerTimeDto, UpdatePrayerTimeRangeDto } from './dto/prayer-time.dto';

@Injectable()
export class PrayerTimesService {
  constructor(private prisma: PrismaService) {}

  async getTodayTimes(masjidId: string, dateStr?: string) {
    const targetDate = dateStr ? new Date(dateStr) : new Date();
    targetDate.setHours(0, 0, 0, 0);

    let times = await this.prisma.prayerTime.findUnique({
      where: {
        idx_prayer_times_unique: {
          masjidId,
          date: targetDate,
        },
      },
    });

    // If specific date not found, fallback to latest configured day for this masjid
    if (!times) {
      times = await this.prisma.prayerTime.findFirst({
        where: { masjidId },
        orderBy: { date: 'desc' },
      });
    }

    if (!times) {
      // Default standard fallback times
      return {
        masjidId,
        date: targetDate.toISOString().split('T')[0],
        fajrAdhan: '05:00',
        fajrJamaah: '05:30',
        dhuhrAdhan: '12:30',
        dhuhrJamaah: '01:15',
        asrAdhan: '16:15',
        asrJamaah: '16:45',
        maghribAdhan: '18:15',
        maghribJamaah: '18:20',
        ishaAdhan: '19:45',
        ishaJamaah: '20:15',
        isDefaultFallback: true,
      };
    }

    return times;
  }

  async getMonthSchedule(masjidId: string, year: number, month: number) {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0);

    return this.prisma.prayerTime.findMany({
      where: {
        masjidId,
        date: {
          gte: startDate,
          lte: endDate,
        },
      },
      orderBy: { date: 'asc' },
    });
  }

  async upsertPrayerTimeRange(masjidId: string, userId: string, dto: UpdatePrayerTimeRangeDto) {
    const start = new Date(dto.startDate);
    const end = new Date(dto.endDate);
    const results: any[] = [];

    const cur = new Date(start);
    while (cur <= end) {
      const targetDate = new Date(cur);
      targetDate.setHours(0, 0, 0, 0);

      const record = await this.prisma.prayerTime.upsert({
        where: {
          idx_prayer_times_unique: {
            masjidId,
            date: targetDate,
          },
        },
        update: {
          fajrAdhan: dto.fajrAdhan,
          fajrJamaah: dto.fajrJamaah,
          dhuhrAdhan: dto.dhuhrAdhan,
          dhuhrJamaah: dto.dhuhrJamaah,
          asrAdhan: dto.asrAdhan,
          asrJamaah: dto.asrJamaah,
          maghribAdhan: dto.maghribAdhan,
          maghribJamaah: dto.maghribJamaah,
          ishaAdhan: dto.ishaAdhan,
          ishaJamaah: dto.ishaJamaah,
          jummahKhutbah: dto.jummahKhutbah,
          jummahJamaah: dto.jummahJamaah,
          date: targetDate,
          updatedBy: userId,
        },
        create: {
          masjidId,
          date: targetDate,
          fajrAdhan: dto.fajrAdhan,
          fajrJamaah: dto.fajrJamaah,
          dhuhrAdhan: dto.dhuhrAdhan,
          dhuhrJamaah: dto.dhuhrJamaah,
          asrAdhan: dto.asrAdhan,
          asrJamaah: dto.asrJamaah,
          maghribAdhan: dto.maghribAdhan,
          maghribJamaah: dto.maghribJamaah,
          ishaAdhan: dto.ishaAdhan,
          ishaJamaah: dto.ishaJamaah,
          jummahKhutbah: dto.jummahKhutbah,
          jummahJamaah: dto.jummahJamaah,
          updatedBy: userId,
        },
      });
      results.push(record);
      cur.setDate(cur.getDate() + 1);
    }

    return {
      success: true,
      count: results.length,
      startDate: dto.startDate,
      endDate: dto.endDate,
    };
  }

  async upsertPrayerTime(masjidId: string, userId: string, dto: UpdatePrayerTimeDto) {
    const date = new Date(dto.date);
    date.setHours(0, 0, 0, 0);

    return this.prisma.prayerTime.upsert({
      where: {
        idx_prayer_times_unique: {
          masjidId,
          date,
        },
      },
      update: {
        ...dto,
        date,
        updatedBy: userId,
      },
      create: {
        ...dto,
        masjidId,
        date,
        updatedBy: userId,
      },
    });
  }
}
