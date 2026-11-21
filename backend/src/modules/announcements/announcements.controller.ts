import { Controller, Get, Post, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AnnouncementsService } from './announcements.service';
import { CreateAnnouncementDto } from './dto/announcement.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { MasjidRoleGuard } from '../../common/guards/masjid-role.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { MasjidRoles } from '../../common/decorators/roles.decorator';
import { RoleType } from '@prisma/client';

@ApiTags('Announcements')
@Controller('masjids/:masjidId/announcements')
export class AnnouncementsController {
  constructor(private readonly announcementsService: AnnouncementsService) {}

  @Get()
  @ApiOperation({ summary: 'List published announcements for a masjid' })
  async getAnnouncements(@Param('masjidId') masjidId: string) {
    return this.announcementsService.findByMasjid(masjidId);
  }

  @Post()
  @UseGuards(JwtAuthGuard, MasjidRoleGuard)
  @MasjidRoles(RoleType.ADMIN, RoleType.ANNOUNCEMENT)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create and broadcast an announcement (Admin or Announcement volunteer)' })
  async createAnnouncement(
    @Param('masjidId') masjidId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: CreateAnnouncementDto,
  ) {
    return this.announcementsService.create(masjidId, userId, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, MasjidRoleGuard)
  @MasjidRoles(RoleType.ADMIN, RoleType.ANNOUNCEMENT)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete an announcement' })
  async deleteAnnouncement(@Param('masjidId') masjidId: string, @Param('id') id: string) {
    return this.announcementsService.delete(masjidId, id);
  }
}
