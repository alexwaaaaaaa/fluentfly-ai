# Requirements Document

## Introduction

FluentFly is a production-ready, AI-powered English learning mobile application designed for Hindi speakers. The system combines structured lesson flows (vocabulary, listening, speaking, quiz, feedback) with real-time AI conversation practice using an animated avatar. The application features gamification elements (XP, streaks, badges), offline caching, Azure Speech Services for TTS/STT, OpenAI/Gemini for natural language processing, and a secure NestJS backend with PostgreSQL database.

## Glossary

- **FluentFly System**: The complete full-stack application including Flutter mobile client, NestJS backend API, PostgreSQL database, and third-party integrations
- **AI Tutor**: The animated avatar-based conversational agent powered by OpenAI GPT-4o or Gemini 1.5 Flash
- **Lesson Flow**: The structured sequence of learning activities: vocabulary introduction, listening practice, speaking practice, quiz, and feedback
- **Azure Speech Service**: Microsoft Azure Cognitive Services for text-to-speech (TTS) and speech-to-text (STT) processing
- **XP System**: Experience points mechanism for tracking user progress and achievements
- **Streak**: Consecutive days of user engagement with the application
- **LiveKit**: Real-time communication platform for avatar-based voice chat
- **User**: An authenticated learner using the FluentFly mobile application
- **Backend API**: The NestJS server providing REST endpoints and business logic
- **Mobile Client**: The Flutter-based mobile application running on iOS/Android devices
- **Lesson**: A structured learning unit containing exercises and activities
- **Exercise**: An individual learning activity within a lesson (MCQ, fill-in-blank, speaking, etc.)
- **Feedback Engine**: The AI-powered system that analyzes pronunciation, fluency, and grammar
- **Session**: A single interaction period between the User and the AI Tutor

## Requirements

### Requirement 1: User Authentication and Authorization

**User Story:** As a new user, I want to sign up using Google OAuth or phone OTP, so that I can securely access my personalized learning experience

#### Acceptance Criteria

1. WHEN a User initiates signup, THE FluentFly System SHALL provide options for Google OAuth authentication and phone-based OTP authentication
2. WHEN a User completes authentication, THE Backend API SHALL generate a JWT token with expiration time of 7 days
3. WHEN a User accesses protected endpoints, THE Backend API SHALL validate the JWT token and reject requests with invalid or expired tokens
4. WHEN authentication fails after 5 attempts within 15 minutes, THE FluentFly System SHALL temporarily block the account for 30 minutes
5. THE Backend API SHALL store user credentials securely using bcrypt hashing with salt rounds of 12

### Requirement 2: Lesson Content Management

**User Story:** As a user, I want to access structured lessons with vocabulary, listening, speaking, and quiz activities, so that I can learn English systematically

#### Acceptance Criteria

1. THE Mobile Client SHALL display lessons organized by skill level (A1, A2, B1, B2, C1, C2)
2. WHEN a User selects a lesson, THE Backend API SHALL return lesson data including vocabulary list, audio URLs, exercises, and metadata within 2 seconds
3. THE FluentFly System SHALL provide seed data for at least 10 lessons covering topics including A1 greetings, A2 travel, B1 daily routine, and other common scenarios
4. WHEN a User completes a lesson activity, THE Mobile Client SHALL save progress locally and sync with the Backend API within 5 seconds
5. WHILE offline, THE Mobile Client SHALL allow access to previously cached lessons and exercises

### Requirement 3: AI-Powered Conversation Practice

**User Story:** As a user, I want to practice speaking English with an AI tutor that provides natural responses and corrections, so that I can improve my conversational skills

#### Acceptance Criteria

1. WHEN a User speaks during a conversation session, THE Azure Speech Service SHALL convert speech to text with word-level confidence scores
2. WHEN the Backend API receives user text input, THE AI Tutor SHALL generate a contextually appropriate response within 3 seconds using OpenAI GPT-4o or Gemini 1.5 Flash
3. THE AI Tutor SHALL return responses in JSON format containing reply text, emotion state (happy, neutral, encouraging), and optional hints
4. WHEN the AI Tutor generates a text response, THE Azure Speech Service SHALL convert it to speech using the en-US-JennyNeural voice with cheerful style
5. THE Backend API SHALL cache TTS audio output in S3 storage using hash(text+voice) as the key to avoid redundant generation

### Requirement 4: Real-Time Speech Analysis and Feedback

**User Story:** As a user, I want to receive detailed feedback on my pronunciation, fluency, and grammar after speaking practice, so that I can identify areas for improvement

#### Acceptance Criteria

1. WHEN a User completes a conversation session, THE Feedback Engine SHALL analyze the full transcript for pronunciation accuracy using Azure STT word confidence scores
2. THE Feedback Engine SHALL calculate fluency score (0-100) based on speech pace, pause frequency, and hesitation patterns
3. THE Feedback Engine SHALL evaluate grammar correctness using the AI Tutor LLM and return a score (0-100)
4. THE Backend API SHALL return feedback JSON containing fluency score, pronunciation score, grammar score, and actionable tips array within 5 seconds
5. THE Mobile Client SHALL display feedback results with visual indicators and specific improvement suggestions

### Requirement 5: Gamification and Progress Tracking

**User Story:** As a user, I want to earn XP, maintain streaks, and unlock badges, so that I stay motivated to practice daily

#### Acceptance Criteria

1. WHEN a User answers a question correctly, THE FluentFly System SHALL award 10 XP points
2. WHEN a User completes a full lesson, THE FluentFly System SHALL award 25 XP points
3. WHEN a User practices on consecutive days, THE FluentFly System SHALL increment the streak counter and award 5 bonus XP per day
4. THE Backend API SHALL track and store user XP, streak count, level, and earned badges in the PostgreSQL database
5. THE Mobile Client SHALL display XP animations, streak indicators, and badge notifications using Lottie animations

### Requirement 6: Animated Avatar Integration

**User Story:** As a user, I want to see an animated AI tutor avatar that responds visually during conversations, so that the learning experience feels more engaging and human-like

#### Acceptance Criteria

1. THE Mobile Client SHALL display an animated avatar using Lottie animation files during conversation sessions
2. WHEN the AI Tutor is speaking, THE Mobile Client SHALL play the ai_tutor_talking.json animation synchronized with audio playback
3. WHEN the AI Tutor emotion state is "happy", THE Mobile Client SHALL display corresponding positive visual feedback
4. THE Mobile Client SHALL preload all avatar animation files (ai_tutor_talking.json, happy_feedback_star.json, sad_robot_retry.json) before starting a session
5. WHERE LiveKit integration is enabled, THE FluentFly System SHALL support real-time video avatar rendering

### Requirement 7: Offline Capability and Performance

**User Story:** As a user, I want to access recently studied lessons and practice offline, so that I can learn even without internet connectivity

#### Acceptance Criteria

1. THE Mobile Client SHALL cache the 5 most recently accessed lessons locally using Hive or Sqflite
2. WHEN network connectivity is unavailable, THE Mobile Client SHALL display cached lessons and allow offline practice
3. THE Mobile Client SHALL use low-bitrate MP3 format (48kbps) for audio files to optimize for 2G networks
4. WHEN network connectivity is restored, THE Mobile Client SHALL synchronize offline progress with the Backend API within 10 seconds
5. THE Mobile Client SHALL preload audio files and Lottie animations for the next lesson to ensure smooth transitions

### Requirement 8: User Interface and Branding

**User Story:** As a user, I want a modern, visually appealing dark-themed interface with smooth animations, so that the app is enjoyable to use

#### Acceptance Criteria

1. THE Mobile Client SHALL implement a dark theme with primary color #00BFFF (Sky Blue), accent color #39FF14 (Neon Green), and background color #0A0E12
2. THE Mobile Client SHALL use Poppins or Inter font family throughout the application
3. THE Mobile Client SHALL display a bottom navigation bar with 5 sections: Home, Speak, Review, Progress, Profile
4. THE Mobile Client SHALL include 10 Lottie animation files: app_intro_plane.json, ai_tutor_talking.json, success_confetti.json, blue_wave_loader.json, flying_xp_coins.json, audio_wave_mic.json, happy_feedback_star.json, sad_robot_retry.json, floating_shapes_bg.json, progress_trophy.json
5. THE Mobile Client SHALL support theme switching between dark and light modes with persistent user preference

### Requirement 9: Backend API Architecture

**User Story:** As a system administrator, I want a secure, scalable NestJS backend with proper validation and error handling, so that the application is reliable and maintainable

#### Acceptance Criteria

1. THE Backend API SHALL implement 8 modules: auth, users, lessons, progress, gamification, chat_ai, speech, rtc, storage
2. THE Backend API SHALL validate all incoming requests using class-validator decorators and reject invalid data with HTTP 400 status
3. THE Backend API SHALL implement rate limiting of 100 requests per minute per user on LLM and TTS endpoints
4. THE Backend API SHALL configure CORS to accept requests only from authorized client origins
5. THE Backend API SHALL provide Swagger documentation at /api/docs endpoint

### Requirement 10: Database Schema and Data Management

**User Story:** As a developer, I want a well-structured PostgreSQL database schema with proper relationships, so that data integrity is maintained

#### Acceptance Criteria

1. THE Backend API SHALL create a users table with columns: id (SERIAL PRIMARY KEY), email (TEXT), phone (TEXT), name (TEXT), xp (INT), streak (INT), level (TEXT)
2. THE Backend API SHALL create a lessons table with columns: id (SERIAL PRIMARY KEY), skill (TEXT), title (TEXT), level (TEXT), audio_url (TEXT), meta (JSONB)
3. THE Backend API SHALL create an exercises table with columns: id (SERIAL PRIMARY KEY), lesson_id (INT), type (TEXT), question (TEXT), options (JSONB), answer (JSONB)
4. THE Backend API SHALL create a progress table with columns: id (SERIAL PRIMARY KEY), user_id (INT), lesson_id (INT), score (JSONB)
5. THE Backend API SHALL create a chat_sessions table with columns: id (SERIAL PRIMARY KEY), user_id (INT), topic (TEXT), transcript (JSONB), feedback (JSONB)

### Requirement 11: Azure Speech Services Integration

**User Story:** As a user, I want high-quality text-to-speech and speech-to-text conversion, so that I can practice speaking and listening effectively

#### Acceptance Criteria

1. THE Backend API SHALL integrate Azure Cognitive Services SDK for TTS and STT operations
2. WHEN generating speech, THE Azure Speech Service SHALL use voice en-US-JennyNeural with cheerful style and output format audio-24khz-48kbitrate-mono-mp3
3. WHEN processing user speech, THE Azure Speech Service SHALL use real-time STT mode with language en-US and return word-level confidence scores
4. THE Backend API SHALL cache generated TTS audio files in S3 or Cloudflare R2 storage with hash-based keys
5. WHEN TTS audio is requested for previously generated text, THE Backend API SHALL return the cached audio URL within 500 milliseconds

### Requirement 12: AI Language Model Integration

**User Story:** As a system administrator, I want a dual AI model system with Gemini as primary and OpenAI as fallback, so that the system maintains high availability and reliability

#### Acceptance Criteria

1. THE Backend API SHALL use Gemini 1.5 Flash as the primary AI model for chat interactions
2. WHEN Gemini 1.5 Flash fails or times out after 3 seconds, THE Backend API SHALL automatically fallback to OpenAI GPT-4o-mini
3. WHEN processing chat requests, THE AI Tutor SHALL use the system prompt: "You are FluentFly, an empathetic English tutor for Hindi speakers. Encourage, correct gently, reply in ≤2 sentences. JSON output: { reply, emotion, hint }"
4. THE AI Tutor SHALL generate responses with maximum length of 2 sentences (approximately 50 words)
5. THE Backend API SHALL parse AI responses as JSON containing reply, emotion (happy, neutral, encouraging), and hint fields

### Requirement 13: Leaderboard and Social Features

**User Story:** As a user, I want to see how my progress compares to other learners, so that I feel motivated to improve

#### Acceptance Criteria

1. THE Backend API SHALL provide a GET /api/leaderboard endpoint returning top 100 users ranked by XP
2. THE Backend API SHALL return leaderboard data containing user name, XP total, and rank position
3. THE Backend API SHALL update leaderboard rankings within 1 minute of XP changes
4. THE Mobile Client SHALL display the leaderboard with user avatars, ranks, and XP scores
5. THE FluentFly System SHALL anonymize user data in leaderboard display unless user opts in to public profile

### Requirement 14: Deployment and DevOps

**User Story:** As a DevOps engineer, I want containerized deployment with Docker and clear setup instructions, so that the application can be deployed consistently across environments

#### Acceptance Criteria

1. THE FluentFly System SHALL include a Dockerfile for the Backend API with multi-stage build optimization
2. THE FluentFly System SHALL include a docker-compose.yml file orchestrating api, postgres, redis, and livekit services
3. THE Backend API SHALL start successfully with npm run start:dev command without manual configuration edits
4. THE FluentFly System SHALL include a .env.example file documenting all required environment variables
5. THE FluentFly System SHALL include a README.md file with setup instructions, architecture overview, and API documentation links

### Requirement 15: Error Handling and Resilience

**User Story:** As a user, I want the app to handle errors gracefully without crashes, so that I have a smooth learning experience

#### Acceptance Criteria

1. THE Mobile Client SHALL wrap all async operations in try-catch blocks with user-friendly error messages
2. WHEN network requests fail, THE Mobile Client SHALL display a retry option and fallback to cached data where available
3. WHEN the Backend API encounters errors, THE Backend API SHALL return valid JSON responses with appropriate HTTP status codes (400, 401, 403, 404, 500)
4. THE Mobile Client SHALL display fallback UI components when Lottie animations fail to load
5. THE Backend API SHALL log all errors with stack traces to a centralized logging service for debugging

### Requirement 16: Lesson Flow Implementation

**User Story:** As a user, I want to progress through lessons in a structured sequence with clear transitions, so that I can learn systematically

#### Acceptance Criteria

1. WHEN a User starts a lesson, THE Mobile Client SHALL display the sequence: vocabulary introduction, listening practice, speaking practice, quiz, feedback screen
2. THE Mobile Client SHALL play TTS audio with synchronized animations during vocabulary introduction
3. WHEN a User completes each lesson stage, THE Mobile Client SHALL unlock the next stage and save progress
4. WHEN a User completes all lesson stages, THE Mobile Client SHALL display the success_confetti.json animation and award XP
5. THE Mobile Client SHALL allow users to navigate back to previous stages within the current lesson

### Requirement 17: Badge System

**User Story:** As a user, I want to earn badges for achievements, so that I feel recognized for my progress

#### Acceptance Criteria

1. THE Backend API SHALL define badge types including "Streak Starter" (7-day streak), "Vocabulary Hero" (100 words learned), and "Fluent Flyer" (50 lessons completed)
2. WHEN a User meets badge criteria, THE Backend API SHALL award the badge and store it in the database
3. THE Mobile Client SHALL display newly earned badges with animations and congratulatory messages
4. THE Mobile Client SHALL show all earned badges in the user profile section
5. THE Backend API SHALL prevent duplicate badge awards for the same achievement

### Requirement 18: State Management and Persistence

**User Story:** As a user, I want my app state and preferences to persist across sessions, so that I don't lose my progress

#### Acceptance Criteria

1. THE Mobile Client SHALL implement state management using Riverpod or Provider
2. THE Mobile Client SHALL persist user preferences (theme, notification settings) locally using shared_preferences
3. WHEN the Mobile Client restarts, THE Mobile Client SHALL restore the last active screen and user state
4. THE Mobile Client SHALL synchronize local state with Backend API data on app launch
5. THE Mobile Client SHALL handle state conflicts by prioritizing server data over local data

### Requirement 19: Audio Recording and Playback

**User Story:** As a user, I want to record my speech and hear it played back, so that I can self-assess my pronunciation

#### Acceptance Criteria

1. WHEN a User taps the microphone button, THE Mobile Client SHALL request microphone permissions and start audio recording
2. THE Mobile Client SHALL display the audio_wave_mic.json animation during active recording
3. WHEN recording completes, THE Mobile Client SHALL save the audio file locally and upload it to the Backend API
4. THE Backend API SHALL process the audio file with Azure STT and return the transcribed text within 5 seconds
5. THE Mobile Client SHALL allow users to replay their recorded audio before submission

### Requirement 20: Security and Data Protection

**User Story:** As a user, I want my personal data and learning progress to be secure, so that my privacy is protected

#### Acceptance Criteria

1. THE Backend API SHALL encrypt sensitive user data (email, phone) at rest using AES-256 encryption
2. THE Backend API SHALL transmit all data over HTTPS with TLS 1.3 protocol
3. THE Backend API SHALL implement input sanitization to prevent SQL injection and XSS attacks
4. THE Backend API SHALL comply with GDPR requirements by allowing users to export and delete their data
5. THE Backend API SHALL rotate JWT secrets every 90 days and invalidate old tokens

### Requirement 21: Testing and Quality Assurance

**User Story:** As a developer, I want comprehensive automated tests for both frontend and backend, so that the application is reliable and maintainable

#### Acceptance Criteria

1. THE Backend API SHALL include at least 10 Jest unit tests covering auth, lessons, chat_ai, speech, and gamification modules
2. THE Mobile Client SHALL include at least 5 widget tests covering lesson_card, avatar_widget, feedback_card, mic_button, and navigation components
3. WHEN tests are executed with npm test or flutter test commands, THE FluentFly System SHALL pass all tests on first run without manual fixes
4. THE Backend API SHALL include integration tests for the complete AI chat pipeline from STT to LLM to TTS
5. THE FluentFly System SHALL achieve minimum 80% code coverage for critical business logic

### Requirement 22: Health Monitoring and Observability

**User Story:** As a system administrator, I want health check endpoints and centralized error handling, so that I can monitor system status and troubleshoot issues

#### Acceptance Criteria

1. THE Backend API SHALL provide a GET /health endpoint returning status 200 with system health metrics (database connection, Redis connection, external service availability)
2. THE Backend API SHALL implement centralized error handling middleware that catches all unhandled exceptions and returns consistent error responses
3. THE Backend API SHALL log all errors with stack traces, request context, and timestamps to a centralized logging system
4. THE Backend API SHALL implement rate limiting of 100 requests per minute per user on AI and TTS endpoints
5. THE Backend API SHALL track and expose metrics for API response times, error rates, and external service latency

### Requirement 23: Branding Assets and Visual Identity

**User Story:** As a user, I want consistent branding throughout the app with the FluentFly visual identity, so that the experience feels cohesive and professional

#### Acceptance Criteria

1. THE Mobile Client SHALL use the color scheme: primary #00BFFF (Sky Blue), accent #39FF14 (Neon Green), dark background #0A0E12
2. THE Mobile Client SHALL apply gradient linear(145deg, #00BFFF → #39FF14) to key UI elements including buttons and headers
3. THE Mobile Client SHALL use Inter or Poppins font family with weights 400 (regular), 600 (semibold), and 700 (bold)
4. THE FluentFly System SHALL include a logo design featuring a paper plane made from sound waves
5. THE Mobile Client SHALL implement soft-shadow minimalism design style with fluid Lottie motion throughout the interface

### Requirement 24: Deployment Automation and Documentation

**User Story:** As a DevOps engineer, I want complete deployment automation with Docker and comprehensive documentation, so that the application can be deployed without manual intervention

#### Acceptance Criteria

1. THE FluentFly System SHALL include a Dockerfile for the Backend API with multi-stage build that produces an optimized production image under 200MB
2. THE FluentFly System SHALL include a docker-compose.yml file that orchestrates api, postgres, redis, and livekit services with proper networking and volume configuration
3. THE FluentFly System SHALL include a seed.sql file with sample data for 10 lessons across different skill levels
4. THE FluentFly System SHALL include a README.md file with setup commands, architecture diagrams, API documentation links, and troubleshooting guide
5. THE Backend API SHALL start successfully with npm run start:dev command using only environment variables from .env.example without requiring manual configuration edits

### Requirement 25: Zero-Error Production Readiness

**User Story:** As a developer, I want the entire codebase to be production-ready with zero compilation or runtime errors, so that deployment is seamless

#### Acceptance Criteria

1. THE Mobile Client SHALL compile successfully with flutter build apk and flutter build ios commands without errors or warnings
2. THE Backend API SHALL start successfully with npm run start:dev command and pass all TypeScript compilation checks
3. THE FluentFly System SHALL have zero null or undefined variable errors through proper null-safety implementation in Flutter and TypeScript
4. THE Mobile Client SHALL wrap all async operations in try-catch blocks with user-friendly error messages and fallback UI
5. THE FluentFly System SHALL reference all Lottie animation files safely with fallback to fallback_pulse.json when animations fail to load
