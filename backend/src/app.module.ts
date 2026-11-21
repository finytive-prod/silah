import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './common/prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { MasjidsModule } from './modules/masjids/masjids.module';
import { PrayerTimesModule } from './modules/prayer-times/prayer-times.module';
import { AnnouncementsModule } from './modules/announcements/announcements.module';
import { SandhaModule } from './modules/sandha/sandha.module';
import { DashboardModule } from './modules/dashboard/dashboard.module';
import { SpecialSchedulesModule } from './modules/special-schedules/special-schedules.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    MasjidsModule,
    PrayerTimesModule,
    AnnouncementsModule,
    SandhaModule,
    DashboardModule,
    SpecialSchedulesModule,
  ],
})
export class AppModule {}
