import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { MASJID_ROLES_KEY } from '../decorators/roles.decorator';
import { PrismaService } from '../prisma/prisma.service';
import { RoleType } from '@prisma/client';

@Injectable()
export class MasjidRoleGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredRoles = this.reflector.getAllAndOverride<RoleType[]>(MASJID_ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;
    if (!user) {
      throw new ForbiddenException('User context missing');
    }

    // Super Admin bypasses all masjid-scoped restrictions
    if (user.isSuperAdmin) {
      return true;
    }

    const masjidId = request.params.masjidId || request.params.id || request.body.masjidId || request.query.masjidId;
    if (!masjidId) {
      throw new ForbiddenException('Masjid ID context missing for role verification');
    }

    const adminRecord = await this.prisma.masjidAdmin.findFirst({
      where: {
        userId: user.id,
        masjidId: masjidId,
      },
      include: {
        role: true,
      },
    });

    if (!adminRecord) {
      throw new ForbiddenException('You do not have administrative access to this masjid');
    }

    // ADMIN role for a masjid inherits all permissions (Finance, Announcement)
    if (adminRecord.role.name === RoleType.ADMIN) {
      return true;
    }

    const hasSpecificRole = requiredRoles.includes(adminRecord.role.name);
    if (!hasSpecificRole) {
      throw new ForbiddenException(`Requires role: ${requiredRoles.join(' or ')}`);
    }

    return true;
  }
}
