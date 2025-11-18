import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

describe('Lessons Retrieval with Exercises (e2e)', () => {
  let app: INestApplication;
  let dataSource: DataSource;
  let authToken: string;
  let testUserId: number;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();

    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );

    await app.init();

    dataSource = moduleFixture.get<DataSource>(DataSource);

    // Create a test user for authenticated requests with unique phone
    const uniquePhone = `+1555${Math.floor(Math.random() * 10000000)}`;
    const userResult = await dataSource.query(
      `INSERT INTO users (name, phone, xp, streak, level) 
       VALUES ($1, $2, $3, $4, $5) 
       RETURNING id`,
      ['Test Lesson User', uniquePhone, 0, 0, 'A1'],
    );
    testUserId = userResult[0].id;

    // Generate a test token (simplified - in real app use auth service)
    const { JwtService } = require('@nestjs/jwt');
    const jwtService = app.get(JwtService);
    authToken = jwtService.sign({ sub: testUserId, phone: uniquePhone });
  });

  afterAll(async () => {
    // Clean up test data
    if (dataSource && testUserId) {
      await dataSource.query('DELETE FROM users WHERE id = $1', [testUserId]);
    }
    await app.close();
  });

  describe('GET /lessons', () => {
    it('should return all lessons with authentication', async () => {
      const response = await request(app.getHttpServer())
        .get('/lessons')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThan(0);

      // Verify lesson structure
      const lesson = response.body[0];
      expect(lesson).toHaveProperty('id');
      expect(lesson).toHaveProperty('title');
      expect(lesson).toHaveProperty('skill');
      expect(lesson).toHaveProperty('level');
      expect(lesson).toHaveProperty('description');
    });

    it('should filter lessons by level', async () => {
      const response = await request(app.getHttpServer())
        .get('/lessons?level=A1')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);

      // All returned lessons should be A1 level
      response.body.forEach((lesson: any) => {
        expect(lesson.level).toBe('A1');
      });
    });

    it('should filter lessons by search term', async () => {
      const response = await request(app.getHttpServer())
        .get('/lessons?search=greeting')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);

      // Results should contain the search term in title or skill
      if (response.body.length > 0) {
        const hasSearchTerm = response.body.some(
          (lesson: any) =>
            lesson.title.toLowerCase().includes('greeting') ||
            lesson.skill.toLowerCase().includes('greeting'),
        );
        expect(hasSearchTerm).toBe(true);
      }
    });

    it('should reject invalid level filter', async () => {
      await request(app.getHttpServer())
        .get('/lessons?level=INVALID')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);
    });

    it('should reject requests without authentication', async () => {
      await request(app.getHttpServer()).get('/lessons').expect(401);
    });
  });

  describe('GET /lessons/:id', () => {
    let lessonId: number;

    beforeAll(async () => {
      // Get a lesson ID from the database
      const result = await dataSource.query('SELECT id FROM lessons LIMIT 1');
      if (result.length > 0) {
        lessonId = result[0].id;
      }
    });

    it('should return a specific lesson by ID', async () => {
      if (!lessonId) {
        console.warn('No lessons found in database, skipping test');
        return;
      }

      const response = await request(app.getHttpServer())
        .get(`/lessons/${lessonId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('id', lessonId);
      expect(response.body).toHaveProperty('title');
      expect(response.body).toHaveProperty('skill');
      expect(response.body).toHaveProperty('level');
      expect(response.body).toHaveProperty('description');
      expect(response.body).toHaveProperty('audioUrl');
      expect(response.body).toHaveProperty('meta');
    });

    it('should return 404 for non-existent lesson', async () => {
      await request(app.getHttpServer())
        .get('/lessons/999999')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });

    it('should return 400 for invalid lesson ID format', async () => {
      await request(app.getHttpServer())
        .get('/lessons/invalid')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);
    });
  });

  describe('GET /lessons/:id/exercises', () => {
    let lessonId: number;

    beforeAll(async () => {
      // Get a lesson ID that has exercises
      const result = await dataSource.query(
        `SELECT DISTINCT l.id 
         FROM lessons l 
         INNER JOIN exercises e ON e.lesson_id = l.id 
         LIMIT 1`,
      );
      if (result.length > 0) {
        lessonId = result[0].id;
      }
    });

    it('should return exercises for a specific lesson', async () => {
      if (!lessonId) {
        console.warn('No lessons with exercises found, skipping test');
        return;
      }

      const response = await request(app.getHttpServer())
        .get(`/lessons/${lessonId}/exercises`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThan(0);

      // Verify exercise structure
      const exercise = response.body[0];
      expect(exercise).toHaveProperty('id');
      expect(exercise).toHaveProperty('lessonId', lessonId);
      expect(exercise).toHaveProperty('type');
      expect(exercise).toHaveProperty('question');
      expect([
        'mcq',
        'fill_blank',
        'speaking',
        'listening',
        'vocabulary',
      ]).toContain(exercise.type);
    });

    it('should return empty array for lesson without exercises', async () => {
      // Create a lesson without exercises for testing
      const result = await dataSource.query(
        `INSERT INTO lessons (skill, title, level, description) 
         VALUES ($1, $2, $3, $4) 
         RETURNING id`,
        ['Test', 'Empty Lesson', 'A1', 'Test lesson without exercises'],
      );
      const emptyLessonId = result[0].id;

      const response = await request(app.getHttpServer())
        .get(`/lessons/${emptyLessonId}/exercises`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBe(0);

      // Clean up
      await dataSource.query('DELETE FROM lessons WHERE id = $1', [
        emptyLessonId,
      ]);
    });

    it('should return 404 for exercises of non-existent lesson', async () => {
      await request(app.getHttpServer())
        .get('/lessons/999999/exercises')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });

  describe('Complete Lesson Retrieval Flow', () => {
    it('should retrieve lesson list, select one, and get its exercises', async () => {
      // Step 1: Get all lessons
      const lessonsResponse = await request(app.getHttpServer())
        .get('/lessons?level=A1')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(lessonsResponse.body.length).toBeGreaterThan(0);
      const selectedLesson = lessonsResponse.body[0];

      // Step 2: Get specific lesson details
      const lessonResponse = await request(app.getHttpServer())
        .get(`/lessons/${selectedLesson.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(lessonResponse.body.id).toBe(selectedLesson.id);

      // Step 3: Get exercises for the lesson
      const exercisesResponse = await request(app.getHttpServer())
        .get(`/lessons/${selectedLesson.id}/exercises`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(exercisesResponse.body)).toBe(true);

      // Verify all exercises belong to the lesson
      exercisesResponse.body.forEach((exercise: any) => {
        expect(exercise.lessonId).toBe(selectedLesson.id);
      });
    });
  });
});
