import { IsNotEmpty, IsString, Matches, IsOptional, IsInt, Min, Max } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SendOtpDto {
  @ApiProperty({ example: '1234567890', description: '10-digit mobile number or E.164 number' })
  @IsNotEmpty()
  @IsString()
  @Matches(/^(\+?[1-9]\d{6,14}|\d{10})$/, {
    message: 'Phone must be a valid 10-digit number or international format (e.g. 1234567890 or +911234567890)',
  })
  phone: string;
}

export class VerifyOtpDto {
  @ApiProperty({ example: '1234567890', description: '10-digit mobile number or E.164 number' })
  @IsNotEmpty()
  @IsString()
  @Matches(/^(\+?[1-9]\d{6,14}|\d{10})$/)
  phone: string;

  @ApiProperty({ example: '123456', description: '6-digit OTP' })
  @IsNotEmpty()
  @IsString()
  @Matches(/^\d{6}$/, { message: 'OTP must be 6 digits' })
  otp: string;
}

export class CheckUserDto {
  @ApiProperty({ example: '9876543210' })
  @IsNotEmpty()
  @IsString()
  phone: string;
}

export class RegisterUserDto {
  @ApiProperty({ example: '9876543210' })
  @IsNotEmpty()
  @IsString()
  phone: string;

  @ApiProperty({ example: 'Ahmed' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 32 })
  @IsOptional()
  @IsInt()
  @Min(5)
  @Max(120)
  age?: number;

  @ApiPropertyOptional({ example: 'No 12, Main Road, Chennai' })
  @IsOptional()
  @IsString()
  address?: string;
}

export class DeviceTokenDto {
  @ApiProperty({ example: 'fcm_token_string' })
  @IsNotEmpty()
  @IsString()
  fcmToken: string;

  @ApiPropertyOptional({ example: 'ANDROID' })
  @IsOptional()
  @IsString()
  platform?: string;
}

export class RefreshTokenDto {
  @ApiProperty({ description: 'Valid JWT refresh token' })
  @IsNotEmpty()
  @IsString()
  refreshToken: string;
}
