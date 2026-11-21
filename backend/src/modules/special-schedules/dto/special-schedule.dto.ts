import { IsNotEmpty, IsString, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ScheduleType } from '@prisma/client';

export class CreateSpecialScheduleDto {
  @ApiProperty({ enum: ScheduleType, example: 'RAMZAN_TIMETABLE' })
  @IsNotEmpty()
  @IsEnum(ScheduleType)
  type: ScheduleType;

  @ApiProperty({ example: 'ரமலான் தராஹீஹ் தொழுகை / Ramadan Taraweeh' })
  @IsNotEmpty()
  @IsString()
  title: string;

  @ApiPropertyOptional({ example: 'ரமலான் தராஹீஹ் தொழுகை' })
  @IsOptional()
  @IsString()
  titleTa?: string;

  @ApiProperty({ example: '2026-03-01', description: 'Start date YYYY-MM-DD' })
  @IsNotEmpty()
  @IsString()
  startDate: string;

  @ApiPropertyOptional({ example: '2026-03-30', description: 'End date YYYY-MM-DD' })
  @IsOptional()
  @IsString()
  endDate?: string;

  @ApiProperty({ example: '20:45', description: 'Start time HH:mm' })
  @IsNotEmpty()
  @IsString()
  startTime: string;

  @ApiPropertyOptional({ example: '22:15', description: 'End time HH:mm' })
  @IsOptional()
  @IsString()
  endTime?: string;

  @ApiPropertyOptional({ example: '20 Rakah Taraweeh with Khatamul Quran' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ example: '20 ரக்அத் தராஹீஹ்' })
  @IsOptional()
  @IsString()
  notesTa?: string;
}
