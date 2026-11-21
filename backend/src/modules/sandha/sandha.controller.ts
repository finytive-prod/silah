import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SandhaService } from './sandha.service';
import { CreateSandhaPlanDto, EnrollMemberDto, RecordPaymentDto } from './dto/sandha.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { MasjidRoleGuard } from '../../common/guards/masjid-role.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { MasjidRoles } from '../../common/decorators/roles.decorator';
import { RoleType } from '@prisma/client';

@ApiTags('Sandha')
@Controller('masjids/:masjidId/sandha')
export class SandhaController {
  constructor(private readonly sandhaService: SandhaService) {}

  @Get('plans')
  @ApiOperation({ summary: 'List sandha plans for a masjid' })
  async getPlans(@Param('masjidId') masjidId: string) {
    return this.sandhaService.getPlans(masjidId);
  }

  @Post('plans')
  @UseGuards(JwtAuthGuard, MasjidRoleGuard)
  @MasjidRoles(RoleType.ADMIN, RoleType.FINANCE)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new sandha plan (Admin or Finance)' })
  async createPlan(
    @Param('masjidId') masjidId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: CreateSandhaPlanDto,
  ) {
    return this.sandhaService.createPlan(masjidId, userId, dto);
  }

  @Post('plans/:planId/members')
  @UseGuards(JwtAuthGuard, MasjidRoleGuard)
  @MasjidRoles(RoleType.ADMIN, RoleType.FINANCE)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Enroll a member into sandha plan with auto-linking by phone' })
  async enrollMember(
    @Param('masjidId') masjidId: string,
    @Param('planId') planId: string,
    @Body() dto: EnrollMemberDto,
  ) {
    return this.sandhaService.enrollMember(planId, dto);
  }

  @Post('payments')
  @UseGuards(JwtAuthGuard, MasjidRoleGuard)
  @MasjidRoles(RoleType.ADMIN, RoleType.FINANCE)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Record a sandha payment (Cash, UPI, etc.)' })
  async recordPayment(
    @Param('masjidId') masjidId: string,
    @CurrentUser('id') userId: string,
    @Body() dto: RecordPaymentDto,
  ) {
    return this.sandhaService.recordPayment(userId, dto);
  }

  @Get('my-status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current logged-in user Sandha enrollment and payment history' })
  async getMyStatus(@CurrentUser('id') userId: string) {
    return this.sandhaService.getUserSandhaStatus(userId);
  }
}
