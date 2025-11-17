import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';
import { JwtService } from '@nestjs/jwt';

describe('Progress Tracking and XP Awarding (e2e)', () => {
  let app: INestApplication;
  let dataSource: DataSource;
  let authToken: string;
  let testUserId: number;
  let lessonId: number;
  let jwtService: JwtService;

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
    jwtService = app.get(JwtService);

    // Create a test user with unique phone number
    const uniquePhone = `+1555${Math.floor(Math.random() * 10000000)}`;
    const userResult = await dataSource.query(
      `INSERT INTO users (name, phone, xp, streak, level, last_active_date) 
       VALUES ($1, $2, $3, $4, $5, CURRENT_DATE) 
       RETURNING id`,
      ['Test Progress User', uniquePhone, 0, 0, 'A1'],
    );
    testUserId = userResult[0].id;

    // Generate auth token
    authToken = jwtService.sign({ sub: testUserId, phone: uniquePhone });

    // Get a lesson ID for testing
    const lessonResult = await dataSource.query('SELECT id FROM lessons LIMIT 1');
    if (lessonResult.length > 0) {
      lessonId = lessonResult[0].id;
    }
  });

  afterAll(async () => {
    // Clean up test data
    if (dataSource && testUserId) {
      await dataSource.query('DELETE FROM progress WHERE user_id = $1', [testUserId]);
      await dataSource.query('DELETE FROM user_badges WHERE user_id = $1', [testUserId]);
      await dataSource.query('DELETE FROM users WHERE id = $1', [testUserId]);
    }
    await app.close();
  });

  describe('Progress Tracking', () => {
    it('should save lesson progress for authenticated user', async () => {
      if (!lessonId) {
        console.warn('No lessons found, skipping test');
        return;
      }

      const progressData = {
        lessonId,
        score: {
          correct: 8,
          total: 10,
          percentage: 80,
        },
        completed: true,
        timeSpent: 300, // 5 minutes
      };

      const response = await request(app.getHttpServer())
        .post('/progress')
        .set('Authorization', `Bearer ${authToken}`)
        .send(progressData)
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('userId', testUserId);
      expect(response.body).toHaveProperty('lessonId', lessonId);
      expect(response.body).toHaveProperty('score');
      expect(response.body.score).toEqual(progressData.score);
      expect(response.body).toHaveProperty('completed', true);
      expect(response.body).toHaveProperty('timeSpent', 300);
    });

    it('should reject progress save without authentication', async () => {
      await request(app.getHttpServer())
        .post('/progress')
        .send({
          lessonId: 1,
          score: { correct: 5, total: 10 },
          completed: false,
          timeSpent: 100,
        })
        .expect(401);
    });

    it('should retrieve user progress', async () => {
      const response = await request(app.getHttpServer())
        .get('/progress')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      
      if (response.body.length > 0) {
        const progress = response.body[0];
        expect(progress).toHaveProperty('id');
        expect(progress).toHaveProperty('userId', testUserId);
        expect(progress).toHaveProperty('lessonId');
        expect(progress).toHaveProperty('score');
        expect(progress).toHaveProperty('completed');
      }
    });

    it('should retrieve progress statistics', async () => {
      const response = await request(app.getHttpServer())
        .get('/progress/stats')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('totalLessonsCompleted');
      expect(response.body).toHaveProperty('totalTimeSpent');
      expect(response.body).toHaveProperty('averageScore');
      expect(response.body).toHaveProperty('lessonsInProgress');
      expect(response.body).toHaveProperty('totalXpEarned');
      expect(response.body).toHaveProperty('recentProgress');
      expect(Array.isArray(response.body.recentProgress)).toBe(true);
    });

    it('should update existing progress for same lesson', async () => {
      if (!lessonId) {
        return;
      }

      const updatedProgress = {
        lessonId,
        score: {
          correct: 10,
          total: 10,
          percentage: 100,
        },
        completed: true,
        timeSpent: 400,
      };

      const response = await request(app.getHttpServer())
        .post('/progress')
        .set('Authorization', `Bearer ${authToken}`)
        .send(updatedProgress)
        .expect(201);

      expect(response.body.score.percentage).toBe(100);
      expect(response.body.timeSpent).toBe(400);
    });
  });

  describe('XP Awarding', () => {
    let initialXp: number;

    beforeAll(async () => {
      // Get initial XP
      const result = await dataSource.query(
        'SELECT xp FROM users WHERE id = $1',
        [testUserId]
      );
      initialXp = result[0].xp;
    });

    it('should award XP for correct answer', async () => {
      const response = await request(app.getHttpServer())
        .post('/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 10,
          reason: 'correct_answer',
        })
        .expect(200);

      expect(response.body).toHaveProperty('xpAwarded');
      expect(response.body.xpAwarded).toBeGreaterThanOrEqual(10);
      expect(response.body).toHaveProperty('totalXp');
      expect(response.body.totalXp).toBeGreaterThan(initialXp);
      expect(response.body).toHaveProperty('leveledUp');
      expect(response.body).toHaveProperty('newLevel');
    });

    it('should award XP for lesson completion', async () => {
      const response = await request(app.getHttpServer())
        .post('/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 25,
          reason: 'lesson_completed',
        })
        .expect(200);

      expect(response.body.xpAwarded).toBeGreaterThanOrEqual(25);
      expect(response.body).toHaveProperty('totalXp');
    });

    it('should include streak bonus in XP calculation', async () => {
      // Set a streak for the user
      await dataSource.query(
        'UPDATE users SET streak = $1 WHERE id = $2',
        [5, testUserId]
      );

      const response = await request(app.getHttpServer())
        .post('/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 10,
          reason: 'test_with_streak',
        })
        .expect(200);

      // Should award base XP (10) + streak bonus (5 * 5 = 25) = 35
      expect(response.body.xpAwarded).toBeGreaterThanOrEqual(35);
    });

    it('should reject XP award without authentication', async () => {
      await request(app.getHttpServer())
        .post('/gamification/award-xp')
        .send({
          amount: 10,
          reason: 'test',
        })
        .expect(401);
    });

    it('should reject negative XP amounts', async () => {
      await request(app.getHttpServer())
        .post('/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: -10,
          reason: 'invalid',
        })
        .expect(400);
    });

    it('should reject XP award without reason', async () => {
      await request(app.getHttpServer())
        .post('/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 10,
        })
        .expect(400);
    });
  });

  describe('Streak Management', () => {
    it('should check and update daily streak', async () => {
      const response = await request(app.getHttpServer())
        .post('/gamification/check-streak')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('streak');
      expect(response.body).toHaveProperty('streakIncremented');
      expect(response.body).toHaveProperty('bonusXp');
      expect(typeof response.body.streak).toBe('number');
      expect(typeof response.body.streakIncremented).toBe('boolean');
    });

    it('should maintain streak on consecutive days', async () => {
      // Set last active date to yesterday using JavaScript date
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      yesterday.setHours(0, 0, 0, 0);
      
      await dataSource.query(
        `UPDATE users 
         SET last_active_date = $1,
             streak = 3
         WHERE id = $2`,
        [yesterday, testUserId]
      );

      const response = await request(app.getHttpServer())
        .post('/gamification/check-streak')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.streakIncremented).toBe(true);
      expect(response.body.streak).toBe(4); // Should increment
    });

    it('should reset streak if day was missed', async () => {
      // Set last active date to 3 days ago using JavaScript date
      const threeDaysAgo = new Date();
      threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);
      threeDaysAgo.setHours(0, 0, 0, 0);
      
      await dataSource.query(
        `UPDATE users 
         SET last_active_date = $1,
             streak = 5
         WHERE id = $2`,
        [threeDaysAgo, testUserId]
      );

      const response = await request(app.getHttpServer())
        .post('/gamification/check-streak')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.streakIncremented).toBe(true);
      expect(response.body.streak).toBe(1); // Should reset to 1
    });
  });

  describe('Complete Progress and XP Flow', () => {
    it('should complete full lesson flow: save progress and award XP', async () => {
      if (!lessonId) {
        return;
      }

      // Step 1: Save lesson progress
      const progressResponse = await request(app.getHttpServer())
        .post('/progress')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          lessonId,
          score: {
            correct: 9,
            total: 10,
            percentage: 90,
          },
          completed: true,
          timeSpent: 600,
        })
        .expect(201);

      expect(progressResponse.body.completed).toBe(true);

      // Step 2: Award XP for lesson completion
      const xpResponse = await request(app.getHttpServer())
        .post('/gamification/award-xp')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: 25,
          reason: 'lesson_completed',
        })
        .expect(200);

      expect(xpResponse.body.xpAwarded).toBeGreaterThanOrEqual(25);

      // Step 3: Check streak
      const streakResponse = await request(app.getHttpServer())
        .post('/gamification/check-streak')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(streakResponse.body).toHaveProperty('streak');

      // Step 4: Verify progress stats reflect the changes
      const statsResponse = await request(app.getHttpServer())
        .get('/progress/stats')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(statsResponse.body.totalLessonsCompleted).toBeGreaterThan(0);
      expect(statsResponse.body.totalXpEarned).toBeGreaterThan(0);
    });
  });

  describe('Leaderboard', () => {
    it('should retrieve leaderboard with user rankings', async () => {
      const response = await request(app.getHttpServer())
        .get('/gamification/leaderboard')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      
      if (response.body.length > 0) {
        const entry = response.body[0];
        expect(entry).toHaveProperty('userId');
        expect(entry).toHaveProperty('name');
        expect(entry).toHaveProperty('xp');
        expect(entry).toHaveProperty('level');
        expect(entry).toHaveProperty('rank');
      }
    });

    it('should support leaderboard pagination', async () => {
      const response = await request(app.getHttpServer())
        .get('/gamification/leaderboard?limit=5&page=1')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeLessThanOrEqual(5);
    });
  });

  describe('Badges', () => {
    it('should retrieve user badges', async () => {
      const response = await request(app.getHttpServer())
        .get('/gamification/badges')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      
      // User may or may not have badges yet
      if (response.body.length > 0) {
        const badge = response.body[0];
        expect(badge).toHaveProperty('id');
        expect(badge).toHaveProperty('name');
        expect(badge).toHaveProperty('description');
        expect(badge).toHaveProperty('earnedAt');
      }
    });
  });
});
