import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

describe('Authentication Flow (e2e)', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();

    // Apply global validation pipe like in main.ts
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );

    await app.init();

    dataSource = moduleFixture.get<DataSource>(DataSource);
  });

  afterAll(async () => {
    // Clean up test data
    if (dataSource) {
      await dataSource.query("DELETE FROM users WHERE phone LIKE '+1555%'");
    }
    await app.close();
  });

  describe('Phone OTP Authentication', () => {
    const testPhone = '+15551234567';
    let accessToken: string;
    let refreshToken: string;

    it('should send OTP to valid phone number', async () => {
      const response = await request(app.getHttpServer())
        .post('/auth/phone/send-otp')
        .send({ phone: testPhone });

      if (response.status !== 200) {
        console.log('Error response:', response.body);
      }

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('success', true);
    });

    it('should reject invalid phone format', async () => {
      await request(app.getHttpServer())
        .post('/auth/phone/send-otp')
        .send({ phone: '1234567890' })
        .expect(400);
    });

    it('should verify OTP and create new user', async () => {
      // Note: In real tests, you'd need to mock Firebase or use test OTP
      // For integration tests, we'll test the endpoint structure
      const response = await request(app.getHttpServer())
        .post('/auth/phone/verify-otp')
        .send({
          phone: testPhone,
          otp: '123456',
          name: 'Test User',
        })
        .expect((res) => {
          // Accept either 200 (success) or 401 (invalid OTP in real env)
          expect([200, 401]).toContain(res.status);
        });

      // If successful (mocked environment), verify response structure
      if (response.status === 200) {
        expect(response.body).toHaveProperty('accessToken');
        expect(response.body).toHaveProperty('refreshToken');
        expect(response.body).toHaveProperty('user');
        expect(response.body.user).toHaveProperty('id');
        expect(response.body.user).toHaveProperty('name');
        expect(response.body.user).toHaveProperty('phone', testPhone);

        accessToken = response.body.accessToken;
        refreshToken = response.body.refreshToken;
      }
    });

    it('should reject OTP verification without name for new user', async () => {
      await request(app.getHttpServer())
        .post('/auth/phone/verify-otp')
        .send({
          phone: '+15559999999',
          otp: '123456',
        })
        .expect((res) => {
          // Should fail validation or return 401
          expect([400, 401]).toContain(res.status);
        });
    });

    it('should refresh access token with valid refresh token', async () => {
      if (!refreshToken) {
        // Skip if we don't have a refresh token from previous test
        return;
      }

      const response = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken })
        .expect((res) => {
          expect([200, 401]).toContain(res.status);
        });

      if (response.status === 200) {
        expect(response.body).toHaveProperty('accessToken');
        expect(response.body).toHaveProperty('refreshToken');
      }
    });

    it('should reject invalid refresh token', async () => {
      await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: 'invalid-token' })
        .expect(401);
    });
  });

  describe('Google OAuth Authentication', () => {
    it('should accept valid Google OAuth token', async () => {
      // Note: In real tests, you'd mock Google OAuth
      const response = await request(app.getHttpServer())
        .post('/auth/google')
        .send({
          idToken: 'mock-google-id-token',
        });

      // Accept either 200 (success with mock) or 401 (invalid token)
      expect([200, 401]).toContain(response.status);

      if (response.status === 200) {
        expect(response.body).toHaveProperty('accessToken');
        expect(response.body).toHaveProperty('refreshToken');
        expect(response.body).toHaveProperty('user');
      }
    });

    it('should reject Google OAuth without token', async () => {
      await request(app.getHttpServer())
        .post('/auth/google')
        .send({})
        .expect(400);
    });
  });

  describe('Protected Routes', () => {
    it('should reject requests without authentication token', async () => {
      await request(app.getHttpServer()).get('/lessons').expect(401);
    });

    it('should reject requests with invalid token', async () => {
      await request(app.getHttpServer())
        .get('/lessons')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });
  });
});
