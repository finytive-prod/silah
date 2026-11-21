import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { CreateAnnouncementDto } from './dto/announcement.dto';

@Injectable()
export class AnnouncementsService {
  private readonly logger = new Logger(AnnouncementsService.name);

  constructor(private prisma: PrismaService) {}

  async findByMasjid(masjidId: string) {
    return this.prisma.announcement.findMany({
      where: {
        masjidId,
        publishedAt: { lte: new Date() },
        OR: [
          { expiresAt: null },
          { expiresAt: { gt: new Date() } },
        ],
      },
      orderBy: [
        { isPinned: 'desc' },
        { publishedAt: 'desc' },
      ],
      include: {
        creator: { select: { id: true, name: true } },
      },
    });
  }

  async create(masjidId: string, userId: string, dto: CreateAnnouncementDto) {
    const announcement = await this.prisma.announcement.create({
      data: {
        ...dto,
        masjidId,
        createdBy: userId,
        publishedAt: new Date(),
      },
    });

    if (dto.notifyPush) {
      // Simulate/trigger FCM push broadcast to all followers
      this.logger.log(`[FCM Broadcast] Triggered announcement push for masjid ${masjidId}: "${dto.title}"`);
    }

    return announcement;
  }

  async delete(masjidId: string, id: string) {
    return this.prisma.announcement.deleteMany({
      where: { id, masjidId },
    });
  }
}
