import { Controller, Get, Put, Post, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { PrayerTimesService } from './prayer-times.service';
import { UpdatePrayerTimeDto, UpdatePrayerTimeRangeDto } from './dto/prayer-time.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { MasjidRoleGuard } from '../../common/guards/masjid-role.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { MasjidRoles } from '../../common/decorators/roles.decorator';
import { RoleType } from '@prisma/client';

@ApiTags('Prayer Times')
@Controller('masjids/:masjidId/prayer-times')
export class PrayerTimesController {
  constructor(private readonly prayerTimesService: PrayerTimesService) {}

  @Get('today')
  @ApiOperation({ summary: 'Get prayer times for today or specific date' })
  @ApiQuery({ name: 'date', required: false, example: '2026-11-20' })
  async getTodayTimes(@Param('masjidId') masjidId: string, @Query('date') date?: string) {
    return this.prayerTimesService.getTodayTimes(masjidId, date);
  }

  @Get('schedule')
  @ApiOperation({ summary: 'Get full month prayer schedule' })
  @ApiQuery({ name: 'year', required: true, example: 2026 })
  @ApiQuery({ name: 'month', required: true, example: 11 })
  async getMonthSchedule(
    @Param('masjidId') masjidId: string,
    @Query('year') year: number,
    @Query('month') month: number,
  ) {
    return this.prayerTimesService.getMonthSchedule(masjidId, Number(year), Number(month));
  }

  @Put()
  @UseGuards(JwtAuthGuard, MasjidRoleGuard)
  @MasjidRoles(RoleType.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update or set prayer times for a date (Admin only)' })
  async updatePrayerTimes(
    @Param('masjidId') masjidId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: UpdatePrayerTimeDto,
  ) {
    return this.prayerTimesService.upsertPrayerTime(masjidId, userId, dto);
  }

  @Post('range')
  @UseGuards(JwtAuthGuard, MasjidRoleGuard)
  @MasjidRoles(RoleType.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Set prayer times across a date range (startDate to endDate) (Admin only)' })
  async updatePrayerTimeRange(
    @Param('masjidId') masjidId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: UpdatePrayerTimeRangeDto,
  ) {
    return this.prayerTimesService.upsertPrayerTimeRange(masjidId, userId, dto);
  }
}
