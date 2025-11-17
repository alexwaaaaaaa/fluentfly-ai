import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';

export const getOptimizedDatabaseConfig = (
  configService: ConfigService,
): TypeOrmModuleOptions => {
  const isProduction = configService.get('NODE_ENV') === 'production';
  
  return {
    type: 'postgres',
    url: configService.get<string>('DATABASE_URL'),
    entities: [__dirname + '/../**/*.entity{.ts,.js}'],
    synchronize: false, // NEVER true in production
    logging: !isProduction ? ['error', 'warn'] : ['error'],
    
    // Connection pool optimization for high traffic
    extra: {
      // Connection pool settings
      max: isProduction ? 50 : 10, // Max connections
      min: isProduction ? 10 : 2, // Min connections
      idleTimeoutMillis: 30000, // Close idle connections after 30s
      connectionTimeoutMillis: 5000, // Connection timeout 5s
      
      // Performance optimizations
      statement_timeout: 30000, // 30s query timeout
      query_timeout: 30000,
      
      // SSL for production
      ssl: isProduction ? { rejectUnauthorized: false } : false,
      
      // Application name for monitoring
      application_name: 'fluentfly-api',
    },
    
    // Enable query result caching
    cache: {
      type: 'redis',
      options: {
        url: configService.get<string>('REDIS_URL'),
      },
      duration: 60000, // 1 minute default cache
    },
    
    // Migrations
    migrations: [__dirname + '/../database/migrations/*{.ts,.js}'],
    migrationsRun: isProduction,
    
    // Retry logic
    retryAttempts: 3,
    retryDelay: 3000,
  };
};

// Database indexes to add for performance
export const RECOMMENDED_INDEXES = `
-- Users table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- Lessons table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_lessons_level ON lessons(level);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_lessons_order ON lessons("order");
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_lessons_level_order ON lessons(level, "order");

-- Progress table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_progress_user_id ON progress(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_progress_lesson_id ON progress(lesson_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_progress_user_lesson ON progress(user_id, lesson_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_progress_completed ON progress(completed_at) WHERE completed_at IS NOT NULL;

-- Gamification indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_badges_user_id ON user_badges(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_badges_earned_at ON user_badges(earned_at DESC);

-- Video call sessions indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_video_call_sessions_user_id ON video_call_sessions(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_video_call_sessions_lesson_id ON video_call_sessions(lesson_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_video_call_sessions_started_at ON video_call_sessions(started_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_video_call_sessions_status ON video_call_sessions(status);

-- Conversation turns indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_conversation_turns_session_id ON conversation_turns(session_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_conversation_turns_timestamp ON conversation_turns(timestamp);

-- Chat sessions indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_chat_sessions_user_id ON chat_sessions(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_chat_sessions_lesson_id ON chat_sessions(lesson_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_chat_sessions_created_at ON chat_sessions(created_at DESC);

-- Composite indexes for common queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_progress_user_completed ON progress(user_id, completed_at) WHERE completed_at IS NOT NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_video_calls_user_status ON video_call_sessions(user_id, status);
`;
