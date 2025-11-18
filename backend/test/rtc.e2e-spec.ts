import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { UsersService } from '../src/modules/users/users.service';

describe('RTC (e2e)', () => {
  let app: INestApplication;
  let accessToken: string;
  let userId: number;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true }),
    );
    await app.init();

    // Create a test user and get auth token
    const usersService = app.get(UsersService);
    const user = await usersService.create({
      phone: '+1234567890',
      name: 'Test User',
    });
    userId = user.id;

    // Generate a test token (simplified - in real tests, use auth endpoint)
    const authResponse = await request(app.getHttpServer())
      .post('/auth/send-otp')
      .send({ phone: '+1234567890' })
      .expect(201);

    // For testing, we'll use a mock token
    accessToken = 'test-token';
  });

  afterAll(async () => {
    await app.close();
  });

  describe('/api/rtc/token (GET)', () => {
    it('should generate LiveKit token for authenticated user', () => {
      return request(app.getHttpServer())
        .get('/api/rtc/token')
        .query({ lessonId: 1 })
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200)
        .expect((res) => {
          expect(res.body).toHaveProperty('token');
          expect(res.body).toHaveProperty('roomName');
          expect(res.body).toHaveProperty('expiresAt');
          expect(res.body).toHaveProperty('sessionId');
          expect(res.body.token).toBeTruthy();
          expect(res.body.roomName).toMatch(/^lesson-\d+-\d+-\d+$/);
        });
    });

    it('should return 401 for unauthenticated request', () => {
      return request(app.getHttpServer())
        .get('/api/rtc/token')
        .query({ lessonId: 1 })
        .expect(401);
    });

    it('should validate lessonId parameter', () => {
      return request(app.getHttpServer())
        .get('/api/rtc/token')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(400);
    });
  });

  describe('/api/rtc/agent (POST)', () => {
    it('should create AI agent for room', () => {
      return request(app.getHttpServer())
        .post('/api/rtc/agent')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          roomName: 'test-room-123',
          lessonId: 1,
          topic: 'Greetings',
        })
        .expect(201)
        .expect((res) => {
          expect(res.body).toHaveProperty('success', true);
          expect(res.body).toHaveProperty('roomName', 'test-room-123');
        });
    });

    it('should return 401 for unauthenticated request', () => {
      return request(app.getHttpServer())
        .post('/api/rtc/agent')
        .send({
          roomName: 'test-room-123',
          lessonId: 1,
        })
        .expect(401);
    });

    it('should validate required fields', () => {
      return request(app.getHttpServer())
        .post('/api/rtc/agent')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          lessonId: 1,
        })
        .expect(400);
    });
  });

  describe('/api/rtc/end-session (POST)', () => {
    let sessionId: number;

    beforeEach(async () => {
      // Create a session first
      const tokenResponse = await request(app.getHttpServer())
        .get('/api/rtc/token')
        .query({ lessonId: 1 })
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      sessionId = tokenResponse.body.sessionId;
    });

    it('should end session and save analytics', () => {
      return request(app.getHttpServer())
        .post('/api/rtc/end-session')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          sessionId,
          conversationTurns: [
            {
              speaker: 'user',
              text: 'Hello, how are you?',
              timestamp: new Date().toISOString(),
            },
            {
              speaker: 'ai',
              text: 'I am doing well, thank you!',
              timestamp: new Date().toISOString(),
            },
          ],
        })
        .expect(201)
        .expect((res) => {
          expect(res.body).toHaveProperty('success', true);
          expect(res.body).toHaveProperty('analytics');
          expect(res.body.analytics).toHaveProperty('totalSpeakingTime');
          expect(res.body.analytics).toHaveProperty('wordsPerMinute');
          expect(res.body.analytics).toHaveProperty('fluencyScore');
        });
    });

    it('should return 404 for non-existent session', () => {
      return request(app.getHttpServer())
        .post('/api/rtc/end-session')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          sessionId: 99999,
          conversationTurns: [],
        })
        .expect(404);
    });

    it('should validate conversation turns format', () => {
      return request(app.getHttpServer())
        .post('/api/rtc/end-session')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          sessionId,
          conversationTurns: [
            {
              speaker: 'invalid',
              text: 'Test',
            },
          ],
        })
        .expect(400);
    });
  });

  describe('/api/rtc/sessions (GET)', () => {
    beforeEach(async () => {
      // Create a few sessions
      for (let i = 0; i < 3; i++) {
        await request(app.getHttpServer())
          .get('/api/rtc/token')
          .query({ lessonId: i + 1 })
          .set('Authorization', `Bearer ${accessToken}`)
          .expect(200);
      }
    });

    it('should retrieve user sessions', () => {
      return request(app.getHttpServer())
        .get('/api/rtc/sessions')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200)
        .expect((res) => {
          expect(Array.isArray(res.body)).toBe(true);
          expect(res.body.length).toBeGreaterThan(0);
          expect(res.body[0]).toHaveProperty('id');
          expect(res.body[0]).toHaveProperty('roomName');
          expect(res.body[0]).toHaveProperty('startTime');
        });
    });

    it('should limit number of sessions returned', () => {
      return request(app.getHttpServer())
        .get('/api/rtc/sessions')
        .query({ limit: 2 })
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200)
        .expect((res) => {
          expect(res.body.length).toBeLessThanOrEqual(2);
        });
    });

    it('should return 401 for unauthenticated request', () => {
      return request(app.getHttpServer()).get('/api/rtc/sessions').expect(401);
    });
  });

  describe('Concurrent calls', () => {
    it('should handle multiple simultaneous token requests', async () => {
      const requests = Array.from({ length: 5 }, (_, i) =>
        request(app.getHttpServer())
          .get('/api/rtc/token')
          .query({ lessonId: i + 1 })
          .set('Authorization', `Bearer ${accessToken}`)
          .expect(200),
      );

      const responses = await Promise.all(requests);

      // Verify all tokens are unique
      const tokens = responses.map((r) => r.body.token);
      const uniqueTokens = new Set(tokens);
      expect(uniqueTokens.size).toBe(tokens.length);

      // Verify all room names are unique
      const roomNames = responses.map((r) => r.body.roomName);
      const uniqueRoomNames = new Set(roomNames);
      expect(uniqueRoomNames.size).toBe(roomNames.length);
    });

    it('should handle multiple agents in different rooms', async () => {
      const rooms = ['room-1', 'room-2', 'room-3'];

      const requests = rooms.map((roomName) =>
        request(app.getHttpServer())
          .post('/api/rtc/agent')
          .set('Authorization', `Bearer ${accessToken}`)
          .send({
            roomName,
            lessonId: 1,
            topic: 'Test',
          })
          .expect(201),
      );

      const responses = await Promise.all(requests);

      responses.forEach((res, index) => {
        expect(res.body.success).toBe(true);
        expect(res.body.roomName).toBe(rooms[index]);
      });
    });
  });

  describe('Analytics calculation', () => {
    it('should calculate correct analytics for conversation', async () => {
      // Create session
      const tokenResponse = await request(app.getHttpServer())
        .get('/api/rtc/token')
        .query({ lessonId: 1 })
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);

      const sessionId = tokenResponse.body.sessionId;

      // End session with conversation turns
      const conversationTurns = [
        {
          speaker: 'user',
          text: 'Hello how are you today',
          timestamp: new Date('2024-01-01T10:00:00Z').toISOString(),
        },
        {
          speaker: 'ai',
          text: 'I am doing well thank you',
          timestamp: new Date('2024-01-01T10:00:05Z').toISOString(),
        },
        {
          speaker: 'user',
          text: 'That is great to hear',
          timestamp: new Date('2024-01-01T10:00:10Z').toISOString(),
        },
      ];

      return request(app.getHttpServer())
        .post('/api/rtc/end-session')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          sessionId,
          conversationTurns,
        })
        .expect(201)
        .expect((res) => {
          const analytics = res.body.analytics;
          expect(analytics.turnCount).toBe(3);
          expect(analytics.totalSpeakingTime).toBeGreaterThan(0);
          expect(analytics.wordsPerMinute).toBeGreaterThan(0);
          expect(analytics.fluencyScore).toBeGreaterThanOrEqual(0);
          expect(analytics.fluencyScore).toBeLessThanOrEqual(100);
        });
    });
  });
});
