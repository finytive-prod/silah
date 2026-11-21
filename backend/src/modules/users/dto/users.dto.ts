import { IsOptional, IsString, IsEnum, IsNotEmpty, IsInt, Min, Max, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Language } from '@prisma/client';

export class CreateUserDto {
  @ApiProperty({ example: '+919876543210' })
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

  @ApiPropertyOptional({ example: 'Chennai' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  @IsBoolean()
  isSuperAdmin?: boolean;
}

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 'Janab Abdul Rahman' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ enum: Language, example: 'ta' })
  @IsOptional()
  @IsEnum(Language)
  language?: Language;

  @ApiPropertyOptional({ example: 'https://cdn.masjidapp.com/avatars/user.jpg' })
  @IsOptional()
  @IsString()
  avatarUrl?: string;
}
