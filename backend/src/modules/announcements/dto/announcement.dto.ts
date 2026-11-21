import { IsNotEmpty, IsString, IsOptional, IsBoolean, IsEnum } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AnnouncementCategory } from '@prisma/client';

export class CreateAnnouncementDto {
  @ApiProperty({ enum: AnnouncementCategory, example: 'GENERAL' })
  @IsNotEmpty()
  @IsEnum(AnnouncementCategory)
  category: AnnouncementCategory;

  @ApiProperty({ example: 'ஜும்ஆ தொழுகை நேரம் மாற்றம் / Jummah Time Update' })
  @IsNotEmpty()
  @IsString()
  title: string;

  @ApiPropertyOptional({ example: 'ஜும்ஆ தொழுகை நேரம் மாற்றம்' })
  @IsOptional()
  @IsString()
  titleTa?: string;

  @ApiProperty({ example: 'Jummah khutbah will start at 12:45 PM starting this Friday.' })
  @IsNotEmpty()
  @IsString()
  body: string;

  @ApiPropertyOptional({ example: 'இந்த வாரம் முதல் ஜும்ஆ குத்பா மதியம் 12:45 மணிக்கு தொடங்கும்.' })
  @IsOptional()
  @IsString()
  bodyTa?: string;

  @ApiPropertyOptional({ example: true, default: false })
  @IsOptional()
  @IsBoolean()
  isPinned?: boolean;

  @ApiPropertyOptional({ example: true, default: true })
  @IsOptional()
  @IsBoolean()
  notifyPush?: boolean;
}
