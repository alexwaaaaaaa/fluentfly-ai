import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { INestApplication } from '@nestjs/common';

export const setupSwagger = (app: INestApplication): void => {
  const config = new DocumentBuilder()
    .setTitle('FluentFly API')
    .setDescription(
      `AI-powered English learning platform API documentation
      
## Overview
FluentFly is a comprehensive language learning platform that combines AI-powered conversations, 
gamification, and structured lessons to help users learn English effectively.

## Authentication
Most endpoints require authentication using Firebase JWT tokens. Include the token in the Authorization header:
\`Authorization: Bearer <firebase-jwt-token>\`

## Rate Limiting
- Standard endpoints: 100 requests per minute
- AI endpoints: 20 requests per minute
- Speech endpoints: 30 requests per minute

## Error Responses
All errors follow a consistent format:
\`\`\`json
{
  "statusCode": 400,
  "message": "Error description",
  "error": "Bad Request"
}
\`\`\`

## Pagination
List endpoints support pagination with query parameters:
- \`page\`: Page number (default: 1)
- \`limit\`: Items per page (default: 20, max: 100)

## Caching
Responses include cache headers. Clients should respect cache-control directives for optimal performance.`,
    )
    .setVersion('1.0')
    .setContact(
      'FluentFly Support',
      'https://fluentfly.app',
      'support@fluentfly.app',
    )
    .setLicense('MIT', 'https://opensource.org/licenses/MIT')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Enter Firebase JWT token',
      },
      'firebase-jwt',
    )
    .addTag('auth', 'Authentication and user registration')
    .addTag('users', 'User profile and preferences management')
    .addTag('lessons', 'Lesson content and exercises')
    .addTag('progress', 'User progress tracking and analytics')
    .addTag('gamification', 'XP, streaks, badges, and leaderboards')
    .addTag('chat', 'AI-powered conversation practice')
    .addTag('speech', 'Text-to-speech and speech recognition')
    .addTag('rtc', 'Real-time communication for live sessions')
    .addTag('storage', 'File upload and asset management')
    .addTag('health', 'System health and monitoring')
    .addServer('http://localhost:3000', 'Local development')
    .addServer('https://api.fluentfly.app', 'Production')
    .build();

  const document = SwaggerModule.createDocument(app, config, {
    operationIdFactory: (controllerKey: string, methodKey: string) => methodKey,
  });

  SwaggerModule.setup('api/docs', app, document, {
    customSiteTitle: 'FluentFly API Documentation',
    customfavIcon: 'https://fluentfly.app/favicon.ico',
    customCss: `
      .swagger-ui .topbar { display: none }
      .swagger-ui .info { margin: 50px 0 }
      .swagger-ui .info .title { font-size: 36px }
    `,
    swaggerOptions: {
      persistAuthorization: true,
      displayRequestDuration: true,
      filter: true,
      showExtensions: true,
      showCommonExtensions: true,
    },
  });
};
