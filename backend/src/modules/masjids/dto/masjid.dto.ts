import { IsNotEmpty, IsString, IsOptional, IsNumber, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateMasjidDto {
  @ApiProperty({ example: 'Jamia Masjid' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 'ஜாமியா பள்ளிவாசல்' })
  @IsOptional()
  @IsString()
  nameTa?: string;

  @ApiProperty({ example: '12 Anna Salai, Thousand Lights' })
  @IsNotEmpty()
  @IsString()
  address: string;

  @ApiProperty({ example: 'Chennai' })
  @IsNotEmpty()
  @IsString()
  city: string;

  @ApiPropertyOptional({ example: 'Tamil Nadu' })
  @IsOptional()
  @IsString()
  state?: string;

  @ApiPropertyOptional({ example: 13.0604 })
  @IsOptional()
  @IsNumber()
  latitude?: number;

  @ApiPropertyOptional({ example: 80.2496 })
  @IsOptional()
  @IsNumber()
  longitude?: number;

  @ApiPropertyOptional({ example: '+914428291234' })
  @IsOptional()
  @IsString()
  phone?: string;
}

export class UpdateMasjidDto {
  @ApiPropertyOptional({ example: 'Jamia Masjid' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: 'ஜாமியா பள்ளிவாசல்' })
  @IsOptional()
  @IsString()
  nameTa?: string;

  @ApiPropertyOptional({ example: '12 Anna Salai, Thousand Lights' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: 'Chennai' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional({ example: 'Tamil Nadu' })
  @IsOptional()
  @IsString()
  state?: string;

  @ApiPropertyOptional({ example: 13.0604 })
  @IsOptional()
  @IsNumber()
  latitude?: number;

  @ApiPropertyOptional({ example: 80.2496 })
  @IsOptional()
  @IsNumber()
  longitude?: number;

  @ApiPropertyOptional({ example: '+914428291234' })
  @IsOptional()
  @IsString()
  phone?: string;
}

export class AddMemberDto {
  @ApiProperty({ example: '+919876543210' })
  @IsNotEmpty()
  @IsString()
  phone: string;

  @ApiPropertyOptional({ example: 'Abdul Rahman' })
  @IsOptional()
  @IsString()
  name?: string;
}

export class AssignRoleDto {
  @ApiProperty({ example: '+919876543215', description: 'Phone number of user to assign role' })
  @IsNotEmpty()
  @IsString()
  phone: string;

  @ApiProperty({ example: 'Janab Farooq' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ example: 'FINANCE', enum: ['ADMIN', 'FINANCE', 'ANNOUNCEMENT'] })
  @IsNotEmpty()
  @IsString()
  role: string;
}
