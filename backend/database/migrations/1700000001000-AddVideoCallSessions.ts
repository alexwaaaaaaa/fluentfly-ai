import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddVideoCallSessions1700000001000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create video_call_sessions table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS video_call_sessions (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        lesson_id INTEGER REFERENCES lessons(id) ON DELETE SET NULL,
        room_name VARCHAR(255) NOT NULL,
        start_time TIMESTAMP NOT NULL,
        end_time TIMESTAMP,
        duration INTEGER,
        analytics JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create conversation_turns table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS conversation_turns (
        id SERIAL PRIMARY KEY,
        session_id INTEGER REFERENCES video_call_sessions(id) ON DELETE CASCADE,
        speaker VARCHAR(10) NOT NULL,
        text TEXT NOT NULL,
        timestamp TIMESTAMP NOT NULL,
        audio_url TEXT,
        word_count INTEGER,
        duration_ms INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create indexes
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS idx_video_call_sessions_user_id ON video_call_sessions(user_id)
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS idx_video_call_sessions_lesson_id ON video_call_sessions(lesson_id)
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS idx_video_call_sessions_user_lesson ON video_call_sessions(user_id, lesson_id)
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS idx_conversation_turns_session_id ON conversation_turns(session_id)
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop indexes
    await queryRunner.query(
      `DROP INDEX IF EXISTS idx_conversation_turns_session_id`,
    );
    await queryRunner.query(
      `DROP INDEX IF EXISTS idx_video_call_sessions_user_lesson`,
    );
    await queryRunner.query(
      `DROP INDEX IF EXISTS idx_video_call_sessions_lesson_id`,
    );
    await queryRunner.query(
      `DROP INDEX IF EXISTS idx_video_call_sessions_user_id`,
    );

    // Drop tables
    await queryRunner.query(`DROP TABLE IF EXISTS conversation_turns`);
    await queryRunner.query(`DROP TABLE IF EXISTS video_call_sessions`);
  }
}
