import { Controller, Post, Body, HttpCode, HttpStatus, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { SendOtpDto, VerifyOtpDto, RefreshTokenDto, CheckUserDto, RegisterUserDto, DeviceTokenDto } from './dto/auth.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('check-user')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Check if mobile number exists in database' })
  async checkUser(@Body() dto: CheckUserDto) {
    return this.authService.checkUser(dto);
  }

  @Post('login-direct')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Direct mobile login without OTP' })
  async loginDirect(@Body() dto: CheckUserDto) {
    return this.authService.loginDirect(dto);
  }

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Register new user profile (Name, Age, optional Address)' })
  async register(@Body() dto: RegisterUserDto) {
    return this.authService.register(dto);
  }

  @Post('device-token')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Register or update FCM device token for push notifications' })
  async updateDeviceToken(@CurrentUser('id') userId: string, @Body() dto: DeviceTokenDto) {
    return this.authService.updateDeviceToken(userId, dto);
  }

  @Post('otp/send')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request OTP to mobile number' })
  async sendOtp(@Body() dto: SendOtpDto) {
    return this.authService.sendOtp(dto);
  }

  @Post('otp/verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify OTP and authenticate (login or register)' })
  @ApiResponse({ status: 200, description: 'Authenticated successfully. Returns JWT tokens.' })
  async verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyOtp(dto);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Refresh expired access token using refresh token' })
  @ApiResponse({ status: 200, description: 'New access and refresh tokens returned' })
  async refreshToken(@Body() dto: RefreshTokenDto) {
    return this.authService.refreshToken(dto);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current authenticated user profile' })
  @ApiResponse({ status: 200, description: 'User profile with memberships and roles' })
  async getProfile(@CurrentUser() user: any) {
    return {
      id: user.id,
      phone: user.phone,
      name: user.name,
      age: user.age,
      address: user.address,
      isOnboarded: user.isOnboarded ?? true,
      language: user.language,
      avatarUrl: user.avatarUrl,
      isSuperAdmin: user.isSuperAdmin,
      adminRoles: user.masjidAdmins?.map((ma: any) => ({
        masjidId: ma.masjidId,
        masjidName: ma.masjid.name,
        masjidNameTa: ma.masjid.nameTa,
        role: ma.role.name,
      })) || [],
      memberships: user.memberships?.map((m: any) => ({
        masjidId: m.masjidId,
        masjidName: m.masjid.name,
        masjidNameTa: m.masjid.nameTa,
        isPrimary: m.isPrimary,
      })) || [],
    };
  }
}
