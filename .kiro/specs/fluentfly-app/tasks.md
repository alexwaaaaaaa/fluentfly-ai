# FluentFly Implementation Plan

This implementation plan breaks down the FluentFly full-stack application into discrete, manageable coding tasks. Each task builds incrementally on previous tasks to create a production-ready AI-powered English learning platform.

## Task List

- [x] 1. Set up project structure and core infrastructure
  - Create NestJS backend project with TypeScript configuration
  - Create Flutter mobile project with null-safety enabled
  - Set up Docker and docker-compose configuration files
  - Create .env.example with all required environment variables
  - _Requirements: 24.1, 24.2, 24.3, 24.4, 24.5_

- [x] 1.1 Initialize NestJS backend with modules
  - Generate NestJS project with CLI
  - Create module structure: auth, users, lessons, progress, gamification, chat-ai, speech, rtc, storage
  - Configure TypeORM for PostgreSQL connection
  - Set up Redis connection module
  - Configure Swagger documentation at /api/docs
  - _Requirements: 9.1, 9.2, 9.5_

- [x] 1.2 Initialize Flutter mobile project
  - Create Flutter project with proper package structure
  - Set up lib/ directory with models, services, screens, widgets, providers folders
  - Configure pubspec.yaml with required dependencies (dio, riverpod, hive, lottie, audio_players, flutter_sound)
  - Create assets/ directory structure for lottie animations and images
  - _Requirements: 8.1, 8.2, 8.3_

- [x] 1.3 Set up database schema and migrations
  - Create PostgreSQL schema with users, lessons, exercises, progress, chat_sessions, badges, user_badges tables
  - Add indexes for performance optimization (users.xp, progress.user_id, lessons.level)
  - Create TypeORM entities for all database tables
  - Write database migration files
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 1.4 Create seed data for lessons
  - Write seed SQL file with 10 sample lessons across A1, A2, B1 levels
  - Include lessons for: Basic Greetings, Introductions, Travel, Shopping, Daily Routine, Food, Weather, Hobbies, Work, Family
  - Create exercises for each lesson (vocabulary, listening, speaking, quiz types)
  - Populate badges table with initial badge definitions
  - _Requirements: 2.3, 17.1_

- [x] 2. Implement authentication and authorization system
  - Create auth module with JWT strategy
  - Implement Google OAuth integration using Passport
  - Implement phone OTP authentication using Firebase Admin SDK
  - Create JWT token generation and validation logic
  - Implement refresh token mechanism
  - Create auth guards and decorators (@CurrentUser, @Public)
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2.1 Build Flutter authentication screens
  - Create login_screen.dart with Google and phone OTP options
  - Create otp_screen.dart for phone verification
  - Implement auth_service.dart for API communication
  - Create auth_provider.dart with Riverpod for state management
  - Implement secure token storage using flutter_secure_storage
  - _Requirements: 1.1, 1.2, 18.1, 18.2_

- [x] 2.2 Implement security measures
  - Add input validation using class-validator on all DTOs
  - Implement rate limiting with @nestjs/throttler (100 req/min)
  - Configure CORS with restricted origins
  - Add global exception filter for error handling
  - Implement request logging interceptor
  - _Requirements: 9.3, 9.4, 20.1, 20.2, 20.3, 20.5_

- [x] 3. Build lessons and exercises management system
  - Create lessons module with CRUD operations
  - Implement lessons controller with GET /lessons, GET /lessons/:id, GET /lessons/:id/exercises endpoints
  - Create lesson and exercise entities with TypeORM
  - Implement filtering by skill level and search functionality
  - Add Redis caching for lesson data (1 hour TTL)
  - _Requirements: 2.1, 2.2, 2.4_

- [x] 3.1 Build Flutter lesson screens
  - Create home_screen.dart with Duolingo-style lesson path
  - Create lesson_card.dart widget displaying lesson info and progress
  - Create lesson_overview_screen.dart showing lesson stages
  - Implement lesson_provider.dart for fetching and caching lesson data
  - Add offline support using Hive for caching recent lessons
  - _Requirements: 2.1, 2.2, 2.5, 7.1, 7.2_

- [x] 3.2 Implement lesson flow state machine
  - Create lesson state management with Riverpod (vocabulary → listening → speaking → quiz → feedback)
  - Build vocabulary_screen.dart with TTS audio playback
  - Build listening_screen.dart with audio MCQ exercises
  - Build quiz_screen.dart with MCQ and fill-in-blank questions
  - Implement navigation between lesson stages with progress tracking
  - _Requirements: 16.1, 16.2, 16.3, 16.5_

- [x] 4. Integrate Azure Speech Services
  - Install microsoft-cognitiveservices-speech-sdk package
  - Create speech module with TTS and STT services
  - Implement text-to-speech with en-US-JennyNeural voice and cheerful style
  - Implement speech-to-text with word-level confidence scores
  - Add TTS caching using hash(text+voice) as key
  - Create POST /speech/tts and POST /speech/stt endpoints
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 4.1 Implement S3/R2 storage for audio files
  - Create storage module with S3Client configuration
  - Implement uploadAudio() and getAudio() methods
  - Configure bucket with public read access for TTS files
  - Add audio file caching with 1-year cache-control headers
  - Integrate storage service with speech service for TTS caching
  - _Requirements: 11.5_

- [x] 4.2 Build Flutter audio service
  - Create audio_service.dart using flutter_sound for recording
  - Implement audio playback using audio_players package
  - Add microphone permission handling
  - Create waveform visualization for recording
  - Implement audio file upload to backend
  - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5_

- [x] 5. Implement AI chat pipeline with dual LLM providers
  - Install @google/generative-ai and openai packages
  - Create chat-ai module with Gemini and OpenAI providers
  - Implement GeminiProvider with gemini-1.5-flash model
  - Implement OpenAiProvider with gpt-4o-mini model as fallback
  - Create chat service with dual provider logic (try Gemini, fallback to OpenAI)
  - Store conversation context in Redis with 1-hour TTL
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [x] 5.1 Build chat turn endpoint
  - Create POST /chat/turn endpoint accepting user text
  - Implement system prompt for FluentFly AI tutor persona
  - Parse LLM JSON response (reply, emotion, hint)
  - Generate TTS audio for AI reply
  - Return ChatResponse with reply, ttsUrl, emotion, hint
  - Add error handling with fallback response
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 5.2 Implement feedback generation engine
  - Create POST /chat/feedback endpoint
  - Analyze pronunciation using Azure STT word confidence scores
  - Calculate fluency score based on words per minute and pause frequency
  - Evaluate grammar using LLM analysis
  - Generate actionable tips array
  - Return FeedbackResponse with scores and tips
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 6. Build speaking practice screen with AI avatar
  - Create speak_screen.dart with avatar and microphone UI
  - Create avatar_widget.dart with Lottie animation support
  - Create mic_button.dart with recording state management
  - Implement chat turn flow: record → STT → LLM → TTS → play
  - Add avatar animation sync with TTS audio playback
  - Display AI responses with emotion-based animations
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 6.1 Implement feedback screen
  - Create feedback_screen.dart displaying lesson completion results
  - Create feedback_card.dart showing fluency, pronunciation, grammar scores
  - Display actionable tips from feedback engine
  - Show success_confetti.json animation on lesson completion
  - Award XP and display flying_xp_coins.json animation
  - _Requirements: 4.4, 4.5, 16.4_

- [x] 7. Implement gamification system
  - Create gamification module with XP, streaks, badges logic
  - Implement POST /gamification/award-xp endpoint
  - Create XP calculation with streak bonuses (5 XP per streak day)
  - Implement level calculation based on total XP
  - Create badge checking logic for "Streak Starter", "Vocabulary Hero", "Fluent Flyer"
  - Implement POST /gamification/check-streak for daily streak tracking
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 17.1, 17.2, 17.3, 17.4, 17.5_

- [x] 7.1 Build leaderboard system
  - Create GET /gamification/leaderboard endpoint
  - Implement ranking query with pagination (top 100 users)
  - Add Redis caching for leaderboard (1-minute TTL)
  - Create GET /gamification/badges endpoint for user badges
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

- [x] 7.2 Build Flutter progress and gamification screens
  - Create progress_screen.dart showing XP, level, streaks, badges
  - Create xp_bar.dart widget with animated progress bar
  - Create streak_indicator.dart with fire icon and count
  - Create badge_widget.dart displaying earned badges
  - Display leaderboard with user rankings
  - Show progress_trophy.json animation on level up
  - _Requirements: 5.4, 5.5, 17.4_

- [x] 8. Implement progress tracking system
  - Create progress module with lesson completion tracking
  - Implement POST /progress endpoint to save lesson progress
  - Create GET /progress endpoint to retrieve user progress
  - Implement GET /progress/stats for aggregated statistics
  - Store exercise scores, time spent, and completion status
  - _Requirements: 2.4, 18.3, 18.4, 18.5_

- [x] 8.1 Build review screen
  - Create review_screen.dart for mistakes and vocabulary review
  - Display incorrectly answered exercises
  - Show vocabulary words from completed lessons
  - Implement spaced repetition logic for review items
  - Add audio playback for vocabulary review
  - _Requirements: 2.5_

- [x] 9. Implement LiveKit RTC integration
  - Install livekit-server-sdk package
  - Create rtc module with token generation service
  - Implement createToken() method with room and user identity
  - Create GET /rtc/token endpoint for client token requests
  - Configure LiveKit server in docker-compose.yml
  - _Requirements: 6.5_

- [x] 10. Build theme and branding system
  - Create theme.dart with FluentFly color scheme (#00BFFF, #39FF14, #0A0E12)
  - Implement gradient definitions (linear 145deg)
  - Configure Poppins/Inter font family
  - Create theme_provider.dart for dark/light mode switching
  - Implement theme persistence using shared_preferences
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 23.1, 23.2, 23.3, 23.5_

- [x] 10.1 Create and integrate Lottie animations
  - Add 10 Lottie JSON files to assets/lottie/ directory
  - Implement animation preloading in app initialization
  - Create fallback_pulse.json for error states
  - Add try-catch wrappers for all Lottie animations
  - Ensure animations sync with audio playback
  - _Requirements: 8.4, 15.4_

- [x] 11. Implement offline caching and sync
  - Set up Hive for local data storage
  - Create cache_service.dart with cacheLesson(), getCachedLesson() methods
  - Implement 7-day TTL for cached data
  - Cache audio files locally using Hive
  - Implement automatic sync on network restore
  - Add offline indicator in UI
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 12. Build navigation and app structure
  - Create app.dart with root widget and navigation setup
  - Implement bottom navigation bar with 5 tabs (Home, Speak, Review, Progress, Profile)
  - Create splash_screen.dart with app_intro_plane.json animation
  - Set up named routes in routes.dart
  - Implement deep linking for lesson navigation
  - _Requirements: 8.1, 8.3, 18.3_

- [x] 12.1 Build profile screen
  - Create profile_screen.dart with user info display
  - Show user stats (XP, level, streak, badges)
  - Implement theme toggle switch
  - Add logout functionality
  - Display user profile image with edit option
  - _Requirements: 8.5_

- [x] 13. Implement error handling and resilience
  - Create global exception filter in NestJS
  - Implement error_handler.dart in Flutter with user-friendly messages
  - Add try-catch blocks to all async operations
  - Implement retry logic with exponential backoff
  - Create fallback UI components for errors
  - Add centralized logging for all errors
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 25.3, 25.4, 25.5_

- [x] 14. Add health monitoring and logging
  - Create GET /health endpoint with service status checks
  - Implement logging interceptor for all requests
  - Add Winston logger for structured logging
  - Create logger utility in Flutter
  - Implement error tracking and reporting
  - _Requirements: 22.1, 22.2, 22.3_

- [x] 15. Write backend unit tests
  - Write Jest tests for auth service (login, OTP, JWT validation)
  - Write tests for chat-ai service (Gemini primary, OpenAI fallback)
  - Write tests for speech service (TTS caching, STT processing)
  - Write tests for gamification service (XP calculation, badge awarding)
  - Write tests for lessons service (CRUD, filtering)
  - Ensure 80% code coverage for critical modules
  - _Requirements: 21.1, 21.2, 21.3_

- [x] 16. Write backend integration tests
  - Write integration test for complete chat turn flow
  - Write integration test for lesson retrieval with exercises
  - Write integration test for progress tracking and XP awarding
  - Write integration test for authentication flow
  - Ensure all tests pass on first run
  - _Requirements: 21.3, 21.4_

- [x] 17. Write Flutter widget tests
  - Write widget test for lesson_card display and interaction
  - Write widget test for avatar_widget animation loading
  - Write widget test for feedback_card score display
  - Write widget test for mic_button recording state
  - Write widget test for navigation tab switching
  - _Requirements: 21.1, 21.2, 21.3_

- [x] 18. Write Flutter integration tests
  - Write integration test for complete lesson flow
  - Write integration test for authentication flow
  - Write integration test for speaking practice with AI
  - Ensure all tests pass without manual intervention
  - _Requirements: 21.3, 21.5_

- [x] 19. Create deployment configuration
  - Write Dockerfile for backend with multi-stage build
  - Create docker-compose.yml with api, postgres, redis, livekit services
  - Configure environment variables in .env.example
  - Set up database initialization scripts
  - Create README.md with setup and deployment instructions
  - _Requirements: 24.1, 24.2, 24.3, 24.4, 24.5, 25.2_

- [x] 19.1 Set up CI/CD pipeline
  - Create GitHub Actions workflow for backend tests
  - Create GitHub Actions workflow for Flutter tests
  - Add deployment automation for backend
  - Add APK build automation for mobile
  - Configure automated testing on pull requests
  - _Requirements: 24.5_

- [x] 20. Final integration and testing
  - Test complete user flow from signup to lesson completion
  - Verify all API endpoints return valid JSON
  - Test offline functionality and sync
  - Verify all Lottie animations load correctly
  - Test audio recording and playback on real devices
  - Verify XP, streaks, and badges work correctly
  - Test AI chat with both Gemini and OpenAI
  - Verify TTS caching and STT accuracy
  - _Requirements: 25.1, 25.2, 25.3, 25.4, 25.5_

- [x] 20.1 Performance optimization and polish
  - Optimize database queries with proper indexes
  - Implement Redis caching for frequently accessed data
  - Optimize image and audio asset sizes
  - Implement lazy loading for lesson content
  - Add loading states and skeleton screens
  - Optimize Flutter build size
  - _Requirements: 7.3, 7.4_

- [x] 20.2 Documentation and final polish
  - Complete API documentation in Swagger
  - Add code comments for complex logic
  - Create user guide for app features
  - Document environment variable requirements
  - Create troubleshooting guide
  - Verify zero compilation errors and warnings
  - _Requirements: 24.4, 24.5, 25.1, 25.2_
