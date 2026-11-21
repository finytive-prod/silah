import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { DashboardService } from './dashboard.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { MasjidRoleGuard } from '../../common/guards/masjid-role.guard';
import { Roles, MasjidRoles } from '../../common/decorators/roles.decorator';
import { RoleType } from '@prisma/client';

@ApiTags('Dashboard')
@Controller('dashboard')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get('super-admin')
  @UseGuards(RolesGuard)
  @Roles('SUPER_ADMIN')
  @ApiOperation({ summary: 'Super Admin system-wide metrics and analytics' })
  async getSuperAdminOverview() {
    return this.dashboardService.getSuperAdminOverview();
  }

  @Get('masjid/:masjidId')
  @UseGuards(MasjidRoleGuard)
  @MasjidRoles(RoleType.ADMIN, RoleType.FINANCE, RoleType.ANNOUNCEMENT)
  @ApiOperation({ summary: 'Masjid Admin & Volunteer operational dashboard' })
  async getMasjidAdminOverview(@Param('masjidId') masjidId: string) {
    return this.dashboardService.getMasjidAdminOverview(masjidId);
  }
}
