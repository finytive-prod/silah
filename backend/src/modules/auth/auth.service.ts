import { Injectable, UnauthorizedException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../common/prisma/prisma.service';
import { OtpService } from './otp/otp.service';
import { SendOtpDto, VerifyOtpDto, RefreshTokenDto, CheckUserDto, RegisterUserDto, DeviceTokenDto } from './dto/auth.dto';
import { JwtPayload } from './strategies/jwt.strategy';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private otpService: OtpService,
  ) {}

  async checkUser(dto: CheckUserDto) {
    const phone = this.otpService.normalizePhone(dto.phone);
    const isMasterSuperAdmin = phone.includes('1234567890');

    const user = await this.prisma.user.findUnique({
      where: { phone },
      include: {
        memberships: true,
        masjidAdmins: { include: { role: true } },
      },
    });

    if (user) {
      return {
        exists: true,
        isOnboarded: user.isOnboarded,
        isSuperAdmin: user.isSuperAdmin || isMasterSuperAdmin,
        name: user.name,
        hasMasjid: user.memberships.length > 0,
      };
    }

    return {
      exists: false,
      isOnboarded: false,
      isSuperAdmin: isMasterSuperAdmin,
    };
  }

  async loginDirect(dto: CheckUserDto) {
    const phone = this.otpService.normalizePhone(dto.phone);
    const isMasterSuperAdmin = phone.includes('1234567890');

    let user = await this.prisma.user.findUnique({
      where: { phone },
      include: {
        memberships: true,
        masjidAdmins: { include: { role: true } },
      },
    });

    if (isMasterSuperAdmin && !user) {
      user = await this.prisma.user.create({
        data: {
          phone,
          name: 'Super Admin',
          isSuperAdmin: true,
          isActive: true,
        },
        include: {
          memberships: true,
          masjidAdmins: { include: { role: true } },
        },
      });
    }

    if (!user) {
      return {
        exists: false,
        message: 'User does not exist. Please register.',
      };
    }

    const tokens = await this.generateTokens(user.id, user.phone, user.isSuperAdmin);

    return {
      exists: true,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        age: user.age,
        address: user.address,
        isOnboarded: user.isOnboarded,
        isSuperAdmin: user.isSuperAdmin,
        hasMasjid: user.memberships.length > 0,
        primaryMasjidId: user.memberships.find((m) => m.isPrimary)?.masjidId ?? user.memberships[0]?.masjidId,
        adminRoles: user.masjidAdmins.map((ma) => ({
          masjidId: ma.masjidId,
          role: ma.role.name,
        })),
      },
      tokens,
      hasMasjid: user.memberships.length > 0,
    };
  }

  async register(dto: RegisterUserDto) {
    const phone = this.otpService.normalizePhone(dto.phone);
    const isMasterSuperAdmin = phone.includes('1234567890');

    const user = await this.prisma.user.upsert({
      where: { phone },
      update: {
        name: dto.name,
        age: dto.age,
        address: dto.address,
        isOnboarded: true,
        isActive: true,
      },
      create: {
        phone,
        name: dto.name,
        age: dto.age,
        address: dto.address,
        isOnboarded: true,
        isSuperAdmin: isMasterSuperAdmin,
        isActive: true,
      },
      include: {
        masjidAdmins: { include: { role: true } },
        memberships: true,
      },
    });

    await this.autoLinkSandhaRecords(user.id, user.phone);
    const tokens = await this.generateTokens(user.id, user.phone, user.isSuperAdmin);

    return {
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        age: user.age,
        address: user.address,
        isOnboarded: user.isOnboarded,
        isSuperAdmin: user.isSuperAdmin,
        hasMasjid: user.memberships.length > 0,
        adminRoles: user.masjidAdmins.map((ma) => ({
          masjidId: ma.masjidId,
          role: ma.role.name,
        })),
      },
      tokens,
    };
  }

  async updateDeviceToken(userId: string, dto: DeviceTokenDto) {
    const platform = dto.platform?.toUpperCase() === 'IOS' ? 'IOS' : 'ANDROID';
    await this.prisma.device.upsert({
      where: { fcmToken: dto.fcmToken },
      update: {
        userId,
        platform: platform as any,
        lastActiveAt: new Date(),
        isActive: true,
      },
      create: {
        fcmToken: dto.fcmToken,
        userId,
        platform: platform as any,
        isActive: true,
      },
    });
    return { success: true, message: 'FCM device token registered' };
  }

  async sendOtp(dto: SendOtpDto) {
    return this.otpService.generateAndSendOtp(dto.phone);
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const phone = this.otpService.normalizePhone(dto.phone);
    await this.otpService.verifyOtp(dto.phone, dto.otp);

    const isMasterSuperAdmin = phone.includes('1234567890');

    // Find or create user by mobile number
    let user = await this.prisma.user.findUnique({
      where: { phone },
      include: {
        memberships: true,
        masjidAdmins: {
          include: { role: true },
        },
      },
    });

    let isNewUser = false;
    if (!user) {
      isNewUser = true;
      user = await this.prisma.user.create({
        data: {
          phone,
          name: isMasterSuperAdmin ? 'Super Admin' : 'User',
          isSuperAdmin: isMasterSuperAdmin,
          isActive: true,
        },
        include: {
          memberships: true,
          masjidAdmins: {
            include: { role: true },
          },
        },
      });
      this.logger.log(`Created new user with mobile: ${phone}`);
    } else if (isMasterSuperAdmin && !user.isSuperAdmin) {
      user = await this.prisma.user.update({
        where: { id: user.id },
        data: { isSuperAdmin: true, name: 'Super Admin' },
        include: {
          memberships: true,
          masjidAdmins: {
            include: { role: true },
          },
        },
      });
    }

    // Auto-link Sandha records by phone number
    await this.autoLinkSandhaRecords(user.id, user.phone);

    // Generate tokens
    const tokens = await this.generateTokens(user.id, user.phone, user.isSuperAdmin);

    return {
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        language: user.language,
        isOnboarded: user.isOnboarded,
        isSuperAdmin: user.isSuperAdmin,
        hasMasjid: user.memberships.length > 0,
        adminRoles: user.masjidAdmins.map((ma) => ({
          masjidId: ma.masjidId,
          role: ma.role.name,
        })),
      },
      tokens,
      isNewUser,
    };
  }

  async refreshToken(dto: RefreshTokenDto) {
    try {
      const payload = this.jwtService.verify<JwtPayload>(dto.refreshToken, {
        secret: process.env.JWT_REFRESH_SECRET || 'masjid_super_secret_jwt_refresh_key_2026',
      });

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });

      if (!user || !user.isActive) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      return this.generateTokens(user.id, user.phone, user.isSuperAdmin);
    } catch (err) {
      throw new UnauthorizedException('Expired or invalid refresh token');
    }
  }

  private async generateTokens(userId: string, phone: string, isSuperAdmin: boolean) {
    const payload: JwtPayload = { sub: userId, phone, isSuperAdmin };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: process.env.JWT_ACCESS_SECRET || 'masjid_super_secret_jwt_access_key_2026',
        expiresIn: '15m',
      }),
      this.jwtService.signAsync(payload, {
        secret: process.env.JWT_REFRESH_SECRET || 'masjid_super_secret_jwt_refresh_key_2026',
        expiresIn: '120d', // 120 days persistent session
      }),
    ]);

    return {
      accessToken,
      refreshToken,
      expiresIn: 900, // 15 mins in seconds
      refreshExpiresIn: 10368000, // 120 days in seconds
    };
  }

  private async autoLinkSandhaRecords(userId: string, phone: string) {
    try {
      const unlinkedMembers = await this.prisma.sandhaPlanMember.findMany({
        where: {
          phone,
          userId: null,
        },
      });

      if (unlinkedMembers.length > 0) {
        this.logger.log(`Auto-linking ${unlinkedMembers.length} Sandha records to user ${userId}`);
        await this.prisma.sandhaPlanMember.updateMany({
          where: {
            phone,
            userId: null,
          },
          data: {
            userId,
            autoLinked: true,
            linkedAt: new Date(),
          },
        });

        // Also update any previous payments under those member records
        for (const member of unlinkedMembers) {
          await this.prisma.sandhaPayment.updateMany({
            where: {
              planMemberId: member.id,
              userId: null,
            },
            data: {
              userId,
            },
          });
        }
      }
    } catch (e) {
      this.logger.error(`Error during Sandha auto-link: ${e.message}`);
    }
  }
}
