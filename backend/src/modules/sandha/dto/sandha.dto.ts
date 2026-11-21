import { IsNotEmpty, IsString, IsOptional, IsNumber, IsEnum, Matches } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SandhaFrequency, PaymentMethod } from '@prisma/client';

export class CreateSandhaPlanDto {
  @ApiProperty({ example: 'மாதாந்திர சந்தா / Monthly Maintenance' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ example: 200.00 })
  @IsNotEmpty()
  @IsNumber()
  amount: number;

  @ApiProperty({ enum: SandhaFrequency, example: 'MONTHLY' })
  @IsNotEmpty()
  @IsEnum(SandhaFrequency)
  frequency: SandhaFrequency;

  @ApiPropertyOptional({ example: 'General maintenance fund' })
  @IsOptional()
  @IsString()
  description?: string;
}

export class EnrollMemberDto {
  @ApiProperty({ example: '+919876543213', description: 'Member phone number (auto-link key)' })
  @IsNotEmpty()
  @IsString()
  @Matches(/^\+[1-9]\d{6,14}$/)
  phone: string;

  @ApiProperty({ example: 'Abdul Rahman' })
  @IsNotEmpty()
  @IsString()
  name: string;
}

export class RecordPaymentDto {
  @ApiProperty({ example: 'uuid-of-plan-member' })
  @IsNotEmpty()
  @IsString()
  planMemberId: string;

  @ApiProperty({ example: 200.00 })
  @IsNotEmpty()
  @IsNumber()
  amount: number;

  @ApiPropertyOptional({ enum: PaymentMethod, default: 'CASH' })
  @IsOptional()
  @IsEnum(PaymentMethod)
  method?: PaymentMethod;

  @ApiPropertyOptional({ example: 'REC-2026-001' })
  @IsOptional()
  @IsString()
  receiptNumber?: string;

  @ApiProperty({ example: '2026-11-01' })
  @IsNotEmpty()
  @IsString()
  periodStart: string;

  @ApiProperty({ example: '2026-11-30' })
  @IsNotEmpty()
  @IsString()
  periodEnd: string;

  @ApiPropertyOptional({ example: 'Paid in cash at Jummah' })
  @IsOptional()
  @IsString()
  notes?: string;
}
