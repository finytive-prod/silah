import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/prisma/prisma.service';
import { CreateSandhaPlanDto, EnrollMemberDto, RecordPaymentDto } from './dto/sandha.dto';

@Injectable()
export class SandhaService {
  constructor(private prisma: PrismaService) {}

  async getPlans(masjidId: string) {
    return this.prisma.sandhaPlan.findMany({
      where: { masjidId, isActive: true },
      include: {
        _count: { select: { members: true, payments: true } },
      },
    });
  }

  async createPlan(masjidId: string, userId: string, dto: CreateSandhaPlanDto) {
    return this.prisma.sandhaPlan.create({
      data: {
        ...dto,
        masjidId,
        createdBy: userId,
      },
    });
  }

  async enrollMember(planId: string, dto: EnrollMemberDto) {
    // Check if phone matches any registered user
    const existingUser = await this.prisma.user.findUnique({
      where: { phone: dto.phone },
    });

    return this.prisma.sandhaPlanMember.upsert({
      where: {
        idx_sandha_plan_members_unique: {
          planId,
          phone: dto.phone,
        },
      },
      update: {
        name: dto.name,
        ...(existingUser ? { userId: existingUser.id, autoLinked: true, linkedAt: new Date() } : {}),
      },
      create: {
        planId,
        phone: dto.phone,
        name: dto.name,
        userId: existingUser?.id || null,
        autoLinked: !!existingUser,
        linkedAt: existingUser ? new Date() : null,
      },
      include: {
        user: { select: { id: true, name: true, phone: true } },
      },
    });
  }

  async recordPayment(userId: string, dto: RecordPaymentDto) {
    const member = await this.prisma.sandhaPlanMember.findUnique({
      where: { id: dto.planMemberId },
    });

    if (!member) {
      throw new NotFoundException('Plan member not found');
    }

    return this.prisma.sandhaPayment.create({
      data: {
        planId: member.planId,
        planMemberId: member.id,
        userId: member.userId,
        amount: dto.amount,
        method: dto.method || 'CASH',
        receiptNumber: dto.receiptNumber,
        periodStart: new Date(dto.periodStart),
        periodEnd: new Date(dto.periodEnd),
        notes: dto.notes,
        recordedBy: userId,
        paidAt: new Date(),
      },
    });
  }

  async getUserSandhaStatus(userId: string) {
    const enrollments = await this.prisma.sandhaPlanMember.findMany({
      where: { userId },
      include: {
        plan: {
          include: {
            masjid: { select: { id: true, name: true, nameTa: true } },
          },
        },
        payments: {
          orderBy: { paidAt: 'desc' },
        },
      },
    });

    return enrollments;
  }
}
