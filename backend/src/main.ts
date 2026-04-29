import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('api');

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  app.enableCors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') ?? ['https://safa-admin.stuff187.com', 'https://safa.stuff187.com'],
    credentials: true,
  });

  const config = new DocumentBuilder()
    .setTitle('Al-Safa Residence API')
    .setDescription('Property management platform API for Al-Safa Residence')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`Al-Safa Residence API running on port ${port}`);
}

bootstrap();
