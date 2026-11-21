import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../../common/prisma/prisma.service';

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);

  constructor(private prisma: PrismaService) {}

  normalizePhone(phone: string): string {
    const cleaned = phone.trim().replace(/[\s-]/g, '');
    if (cleaned.length === 10 && !cleaned.startsWith('+')) {
      return `+91${cleaned}`;
    }
    return cleaned;
  }

  async generateAndSendOtp(rawPhone: string): Promise<{ success: boolean; message: string; debugOtp?: string }> {
    const phone = this.normalizePhone(rawPhone);

    // Super Admin master phone or custom OTP
    let otp = Math.floor(100000 + Math.random() * 900000).toString();
    if (phone.includes('1234567890')) {
      otp = '123456';
    }

    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 mins validity

    await this.prisma.otpVerification.updateMany({
      where: { phone, isUsed: false },
      data: { isUsed: true },
    });

    await this.prisma.otpVerification.create({
      data: {
        phone,
        otp,
        expiresAt,
      },
    });

    this.logger.log(`\n========================================\n[OTP DISPATCH] Mobile: ${phone} -> OTP: ${otp}\n========================================`);

    return {
      success: true,
      message: 'OTP sent successfully',
      debugOtp: otp,
    };
  }

  async verifyOtp(rawPhone: string, otp: string): Promise<boolean> {
    const phone = this.normalizePhone(rawPhone);

    // Super admin 1234567890 master OTP bypass
    if (phone.includes('1234567890') && otp === '123456') {
      return true;
    }

    // In dev mode, allow master OTP 123456 for any test phone
    if (process.env.NODE_ENV !== 'production' && otp === '123456') {
      return true;
    }

    const record = await this.prisma.otpVerification.findFirst({
      where: {
        phone,
        otp,
        isUsed: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!record) {
      throw new BadRequestException('Invalid or expired OTP. Please use OTP 123456 or request a new one.');
    }

    await this.prisma.otpVerification.update({
      where: { id: record.id },
      data: { isUsed: true },
    });

    return true;
  }
}
