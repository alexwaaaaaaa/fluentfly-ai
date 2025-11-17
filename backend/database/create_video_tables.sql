-- Create video call sessions table
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
);

-- Create conversation turns table
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
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_user_id ON video_call_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_lesson_id ON video_call_sessions(lesson_id);
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_user_lesson ON video_call_sessions(user_id, lesson_id);
CREATE INDEX IF NOT EXISTS idx_conversation_turns_session_id ON conversation_turns(session_id);
