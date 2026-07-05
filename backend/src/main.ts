import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

/**
 * Bootstraps the Payasun NestJS application with:
 * - Global validation pipe (whitelist + transform)
 * - Swagger UI documentation at /api/docs
 * - CORS enabled
 */
async function bootstrap(): Promise<void> {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // ── Global Pipes ───────────────────────────────────────────────
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,           // Strip unknown properties from DTOs
      forbidNonWhitelisted: true, // Throw error if unknown properties are sent
      transform: true,            // Auto-transform payloads to DTO instances
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // ── CORS ───────────────────────────────────────────────────────
  app.enableCors({
    origin: '*', // Restrict in production
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // ── Swagger UI Setup ───────────────────────────────────────────
  const swaggerConfig = new DocumentBuilder()
    .setTitle('Payasun API')
    .setDescription(
      '## Payasun — Dynamic Platform\n\n' +
      'RESTful API for connecting **Employers** with professional **Welders**.\n\n' +
      '### Phase 1 Features\n' +
      '- **OTP Authentication** via MeliPayamak SMS gateway\n' +
      '- **JWT Bearer** token-based authorization\n' +
      '- **Profile Management** for Employers and Welders\n' +
      '- **Auto-Pricing Configuration** for Welder service lists\n\n' +
      '### Authentication Flow\n' +
      '1. `POST /auth/send-otp` — Request an OTP code\n' +
      '2. `POST /auth/verify-otp` — Verify OTP and receive JWT\n' +
      '3. Use the JWT token in the `Authorization: Bearer <token>` header\n',
    )
    .setVersion('1.0.0')
    .setContact(
      'Payasun Team',
      'https://payasun.ir',
      'support@payasun.ir',
    )
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'Authorization',
        description: 'Enter your JWT token obtained from /auth/verify-otp',
        in: 'header',
      },
      'access-token', // Security scheme name referenced by @ApiBearerAuth()
    )
    .addTag('Authentication', 'OTP-based registration and login endpoints')
    .addTag('Profile', 'User profile management endpoints (JWT required)')
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document, {
    customSiteTitle: 'Payasun API Documentation',
    customCss: `
      .swagger-ui .topbar { background-color: #1a1a2e; }
      .swagger-ui .topbar .link { content: none; }
      .swagger-ui .info .title { color: #e94560; }
    `,
    swaggerOptions: {
      persistAuthorization: true,
      docExpansion: 'list',
      filter: true,
      showRequestDuration: true,
    },
  });

  // ── Start Server ───────────────────────────────────────────────
  const port = process.env.APP_PORT || 3000;
  await app.listen(port);

  logger.log(`🚀 Application running on: http://localhost:${port}`);
  logger.log(`📖 Swagger UI available at: http://localhost:${port}/api/docs`);
}

bootstrap();
