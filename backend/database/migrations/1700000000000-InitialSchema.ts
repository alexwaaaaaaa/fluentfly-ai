import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitialSchema1700000000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Users table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE,
        phone VARCHAR(20) UNIQUE,
        name VARCHAR(255) NOT NULL,
        xp INTEGER DEFAULT 0,
        streak INTEGER DEFAULT 0,
        level VARCHAR(10) DEFAULT 'A1',
        last_active_date DATE,
        profile_image_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Lessons table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS lessons (
        id SERIAL PRIMARY KEY,
        skill VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        level VARCHAR(10) NOT NULL,
        audio_url TEXT,
        description TEXT,
        meta JSONB,
        order_index INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Exercises table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS exercises (
        id SERIAL PRIMARY KEY,
        lesson_id INTEGER REFERENCES lessons(id) ON DELETE CASCADE,
        type VARCHAR(50) NOT NULL,
        question TEXT NOT NULL,
        options JSONB,
        answer JSONB,
        audio_url TEXT,
        order_index INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Progress table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS progress (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        lesson_id INTEGER REFERENCES lessons(id) ON DELETE CASCADE,
        score JSONB,
        completed BOOLEAN DEFAULT FALSE,
        time_spent INTEGER,
        completed_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, lesson_id)
      )
    `);

    // Chat sessions table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS chat_sessions (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        topic VARCHAR(255),
        transcript JSONB,
        feedback JSONB,
        duration INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Badges table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS badges (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL UNIQUE,
        description TEXT,
        icon_url TEXT,
        criteria JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // User badges junction table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS user_badges (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        badge_id INTEGER REFERENCES badges(id) ON DELETE CASCADE,
        earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, badge_id)
      )
    `);

    // Create indexes
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_lessons_level ON lessons(level)`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_progress_user_id ON progress(user_id)`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_chat_sessions_user_id ON chat_sessions(user_id)`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_users_xp ON users(xp DESC)`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS user_badges CASCADE`);
    await queryRunner.query(`DROP TABLE IF EXISTS badges CASCADE`);
    await queryRunner.query(`DROP TABLE IF EXISTS chat_sessions CASCADE`);
    await queryRunner.query(`DROP TABLE IF EXISTS progress CASCADE`);
    await queryRunner.query(`DROP TABLE IF EXISTS exercises CASCADE`);
    await queryRunner.query(`DROP TABLE IF EXISTS lessons CASCADE`);
    await queryRunner.query(`DROP TABLE IF EXISTS users CASCADE`);
  }
}
