import { NestFactory } from '@nestjs/core';
import { ExpressAdapter } from '@nestjs/platform-express';
import { AppModule } from '../src/app.module';
import { ValidationPipe } from '@nestjs/common';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';
import express, { Request, Response } from 'express';

const server = express();
let isReady = false;
let initPromise: Promise<void> | null = null;

// Fallback root health check route for Vercel
server.get('/', (_req: Request, res: Response) => {
  res.json({
    status: 'online',
    message: 'Masjid Management & Namaz Time API is running',
    version: '1.0.0',
    endpoints: {
      auth: '/v1/auth',
      masjids: '/v1/masjids',
      prayerTimes: '/v1/masjids/:masjidId/prayer-times',
      announcements: '/v1/masjids/:masjidId/announcements',
      sandha: '/v1/masjids/:masjidId/sandha',
      dashboard: '/v1/dashboard',
    },
    timestamp: new Date().toISOString(),
  });
});

async function bootstrap() {
  const app = await NestFactory.create(AppModule, new ExpressAdapter(server), {
    logger: ['error', 'warn', 'log'],
  });

  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  app.setGlobalPrefix('v1', {
    exclude: ['/'],
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalInterceptors(new TransformInterceptor());

  await app.init();
  isReady = true;
}

export default async function handler(req: Request, res: Response) {
  try {
    if (!isReady) {
      if (!initPromise) {
        initPromise = bootstrap();
      }
      await initPromise;
    }
    server(req, res);
  } catch (error: any) {
    console.error('Vercel serverless initialization error:', error);
    return res.status(500).json({
      statusCode: 500,
      message: 'Serverless Function Initialization Error',
      error: error?.message || String(error),
      hint: 'Please ensure DATABASE_URL, JWT secrets, and other required environment variables are set in your Vercel Project Settings.',
    });
  }
}
