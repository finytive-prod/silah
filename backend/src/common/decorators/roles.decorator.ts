import { SetMetadata } from '@nestjs/common';
import { RoleType } from '@prisma/client';

export const ROLES_KEY = 'roles';
export const Roles = (...roles: (RoleType | 'SUPER_ADMIN')[]) => SetMetadata(ROLES_KEY, roles);

export const MASJID_ROLES_KEY = 'masjid_roles';
export const MasjidRoles = (...roles: RoleType[]) => SetMetadata(MASJID_ROLES_KEY, roles);
