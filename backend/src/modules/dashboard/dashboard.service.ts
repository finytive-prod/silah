import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';

@Injectable()
export class DashboardService {
  constructor(private prisma: PrismaService) {}

  async getSuperAdminOverview() {
    const [
      totalMasjids,
      totalUsers,
      totalMemberships,
      totalSandhaPlans,
      paymentsSummary,
      recentMasjids,
      pendingRequestsCount,
      pendingRequests,
    ] = await Promise.all([
      this.prisma.masjid.count({ where: { isActive: true } }),
      this.prisma.user.count({ where: { isActive: true } }),
      this.prisma.membership.count(),
      this.prisma.sandhaPlan.count({ where: { isActive: true } }),
      this.prisma.sandhaPayment.aggregate({
        _sum: { amount: true },
        _count: { id: true },
      }),
      this.prisma.masjid.findMany({
        take: 5,
        where: { isActive: true },
        orderBy: { createdAt: 'desc' },
        include: {
          _count: { select: { memberships: true, admins: true } },
        },
      }),
      this.prisma.masjid.count({ where: { approvalStatus: 'PENDING' } }),
      this.prisma.masjid.findMany({
        where: { approvalStatus: 'PENDING' },
        include: {
          creator: { select: { id: true, name: true, phone: true } },
        },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    return {
      metrics: {
        totalMasjids,
        totalUsers,
        totalFollowers: totalMemberships,
        totalSandhaPlans,
        totalSandhaCollected: paymentsSummary._sum.amount || 0,
        totalTransactions: paymentsSummary._count.id,
        pendingRequestsCount,
      },
      recentMasjids,
      pendingRequests,
    };
  }

  async getMasjidAdminOverview(masjidId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
      masjid,
      memberCount,
      todayPrayerTimes,
      activeAnnouncements,
      sandhaPlans,
      recentPayments,
    ] = await Promise.all([
      this.prisma.masjid.findUnique({ where: { id: masjidId } }),
      this.prisma.membership.count({ where: { masjidId } }),
      this.prisma.prayerTime.findUnique({
        where: {
          idx_prayer_times_unique: {
            masjidId,
            date: today,
          },
        },
      }),
      this.prisma.announcement.count({
        where: {
          masjidId,
          publishedAt: { lte: new Date() },
          OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }],
        },
      }),
      this.prisma.sandhaPlan.findMany({
        where: { masjidId, isActive: true },
        include: {
          _count: { select: { members: true, payments: true } },
        },
      }),
      this.prisma.sandhaPayment.findMany({
        where: { plan: { masjidId } },
        take: 5,
        orderBy: { paidAt: 'desc' },
        include: {
          planMember: { select: { name: true, phone: true } },
        },
      }),
    ]);

    return {
      masjid,
      metrics: {
        memberCount,
        hasConfiguredTodayTimes: !!todayPrayerTimes,
        activeAnnouncementsCount: activeAnnouncements,
        activePlansCount: sandhaPlans.length,
      },
      todayPrayerTimes,
      sandhaPlans,
      recentPayments,
    };
  }
}
