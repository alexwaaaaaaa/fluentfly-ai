# Implementation Plan

- [x] 1. Set up bottom navigation infrastructure
  - Create `BottomNavBar` widget with three tabs (Home, Progress, Profile)
  - Create `MainScreen` wrapper to manage navigation state
  - Update app routing to use MainScreen as entry point after login
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 1.1 Create bottom navigation bar widget
  - Implement `BottomNavBar` widget in `mobile/lib/widgets/bottom_nav_bar.dart`
  - Add icons for Home (home), Progress (trending_up), Profile (person)
  - Style active/inactive states with theme colors
  - Handle tap events to switch tabs
  - _Requirements: 1.1, 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 1.2 Create main screen wrapper
  - Implement `MainScreen` in `mobile/lib/screens/main_screen.dart`
  - Manage current tab index state
  - Display appropriate screen based on selected tab
  - Preserve state when switching tabs using IndexedStack
  - _Requirements: 1.2, 1.5_

- [x] 1.3 Update app routing
  - Modify `mobile/lib/config/routes.dart` to navigate to MainScreen after login
  - Update splash screen logic to check auth and route accordingly
  - Test navigation flow from login to main screen
  - _Requirements: 1.1, 1.2_

- [x] 2. Implement LiveKit integration for mobile
  - Add `livekit_client` package to `pubspec.yaml`
  - Create `LiveKitService` in `mobile/lib/services/livekit_service.dart`
  - Implement room connection, track publishing, and event handling
  - _Requirements: 3.4, 4.1, 4.2_

- [x] 2.1 Add LiveKit dependencies
  - Add `livekit_client: ^2.0.0` to `pubspec.yaml`
  - Run `flutter pub get` to install package
  - Update Android permissions for camera and microphone
  - Update iOS Info.plist for camera and microphone permissions
  - _Requirements: 3.2, 3.3_

- [x] 2.2 Create LiveKit service
  - Implement `LiveKitService` class with connection methods
  - Add `connectToRoom(token, url)` method
  - Add `publishTracks()` method for local audio/video
  - Add `subscribeToRemoteTracks()` for AI agent audio
  - Add `disconnect()` method for cleanup
  - _Requirements: 3.4, 3.5, 4.1, 4.2_

- [x] 2.3 Implement connection state management
  - Create `VideoCallProvider` using Riverpod
  - Track connection state (connecting, connected, disconnected)
  - Track call duration with timer
  - Track conversation turns
  - Handle connection quality monitoring
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 3. Create video call screen UI
  - Implement `VideoCallScreen` in `mobile/lib/screens/video_call_screen.dart`
  - Add video view for local camera feed
  - Add AI avatar overlay
  - Add call control buttons (mute, camera, end call)
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 3.1 Implement video view
  - Use LiveKit's VideoView widget for local camera
  - Position video view to fill screen
  - Add mirror effect for front camera
  - Handle camera switching (front/back)
  - _Requirements: 4.1, 4.2_

- [x] 3.2 Add AI avatar overlay
  - Create animated avatar widget
  - Position avatar in corner or as overlay
  - Animate avatar when AI is speaking
  - Show visual indicators (sound waves, lip sync)
  - _Requirements: 4.2, 4.3_

- [x] 3.3 Implement call controls
  - Create control bar at bottom of screen
  - Add mute button with toggle state
  - Add camera on/off button
  - Add end call button with confirmation
  - Style controls with theme colors
  - _Requirements: 4.4, 7.1_

- [x] 3.4 Add real-time captions
  - Display AI speech as text captions
  - Position captions at bottom of screen
  - Auto-hide captions after 5 seconds
  - Support multi-line text wrapping
  - _Requirements: 4.5_

- [x] 4. Implement backend RTC token generation
  - Update `RtcController` in `backend/src/modules/rtc/rtc.controller.ts`
  - Implement `getToken()` endpoint to generate LiveKit tokens
  - Add LiveKit SDK to backend dependencies
  - Configure LiveKit credentials in environment variables
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 4.1 Add LiveKit server SDK
  - Add `livekit-server-sdk` package to backend
  - Configure LiveKit API key and secret in `.env`
  - Create LiveKit client instance in RTC service
  - _Requirements: 8.1, 8.2_

- [x] 4.2 Implement token generation endpoint
  - Create `GET /api/rtc/token` endpoint
  - Accept `lessonId` and `userId` as parameters
  - Generate unique room name (e.g., `lesson-{lessonId}-{userId}-{timestamp}`)
  - Create LiveKit access token with video/audio permissions
  - Set token expiration to 1 hour
  - Return token, URL, and room name
  - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [x] 4.3 Add token validation
  - Verify user is authenticated before generating token
  - Check user has access to the lesson
  - Rate limit token generation (max 10 per user per day)
  - Log token generation for security audit
  - _Requirements: 8.5_

- [x] 5. Implement AI agent service
  - Create `AiAgentService` in `backend/src/modules/rtc/ai-agent.service.ts`
  - Implement agent spawning logic
  - Connect to LiveKit room as participant
  - Listen to user audio streams
  - _Requirements: 9.1, 9.2, 9.3_

- [x] 5.1 Create AI agent participant
  - Implement `spawnAgent(roomName, context)` method
  - Connect to LiveKit room using server SDK
  - Subscribe to user audio tracks
  - Set up audio processing pipeline
  - _Requirements: 9.1, 9.2_

- [x] 5.2 Implement speech processing
  - Capture user audio in real-time
  - Detect when user stops speaking (1 second silence)
  - Convert audio to text using existing speech service
  - Send text to chat AI service for response generation
  - _Requirements: 9.3, 9.4, 5.1, 5.2_

- [x] 5.3 Generate and publish AI responses
  - Receive AI text response from chat service
  - Convert text to speech using existing TTS service
  - Publish audio track back to LiveKit room
  - Track conversation turns for analytics
  - _Requirements: 9.5, 5.3, 5.4, 5.5_

- [x] 6. Implement call session management
  - Create session tracking in database
  - Save conversation history
  - Calculate and store analytics
  - Handle call end and cleanup
  - _Requirements: 7.2, 7.3, 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 6.1 Create session database schema
  - Add `video_call_sessions` table with session metadata
  - Add `conversation_turns` table for storing dialogue
  - Add indexes on userId and lessonId
  - Create TypeORM entities
  - _Requirements: 7.3, 10.5_

- [x] 6.2 Implement session start/end
  - Create session record when call starts
  - Update session with end time and duration when call ends
  - Save all conversation turns to database
  - Calculate analytics (speaking time, WPM, fluency)
  - _Requirements: 7.2, 7.3, 10.1, 10.2, 10.3, 10.4_

- [x] 6.3 Add session summary screen
  - Create `CallSummaryScreen` in mobile app
  - Display call duration and statistics
  - Show conversation transcript
  - Display fluency score and feedback
  - Add "Practice Again" button
  - _Requirements: 7.2, 10.4_

- [x] 7. Add error handling and reconnection
  - Implement connection quality monitoring
  - Add automatic reconnection logic
  - Handle permission errors gracefully
  - Display user-friendly error messages
  - _Requirements: 3.3, 6.2, 6.3, 6.4, 6.5_

- [x] 7.1 Implement connection monitoring
  - Track LiveKit connection state changes
  - Monitor network quality metrics
  - Display warning when quality is poor
  - Log connection events for debugging
  - _Requirements: 6.1, 6.2, 6.5_

- [x] 7.2 Add reconnection logic
  - Detect connection drops
  - Attempt automatic reconnection with exponential backoff
  - Max 3 reconnection attempts
  - Show reconnecting indicator to user
  - End call if reconnection fails
  - _Requirements: 6.3, 6.4_

- [x] 7.3 Handle permission errors
  - Check camera/microphone permissions before connecting
  - Show permission request dialog with explanation
  - Handle permission denial gracefully
  - Provide link to app settings if permanently denied
  - _Requirements: 3.2, 3.3_

- [x] 8. Integrate video call into speaking practice
  - Add "Video Call" button to speaking practice screen
  - Navigate to video call screen when button tapped
  - Pass lesson context to video call
  - Return to lesson flow after call ends
  - _Requirements: 3.1, 7.1_

- [x] 8.1 Update speaking practice screen
  - Add "Start Video Call with AI Tutor" button
  - Position button prominently on screen
  - Add icon and description
  - Handle button tap to navigate to video call
  - _Requirements: 3.1_

- [x] 8.2 Pass lesson context
  - Pass lessonId and topic to video call screen
  - Use context to generate relevant AI responses
  - Display lesson topic in video call header
  - _Requirements: 3.1, 9.4_

- [x] 8.3 Handle call completion
  - Navigate back to lesson flow after call ends
  - Mark speaking exercise as complete
  - Award XP for call duration
  - Update progress tracking
  - _Requirements: 7.2, 7.3_

- [x] 9. Add analytics and monitoring
  - Track video call usage metrics
  - Monitor call quality and errors
  - Log AI response times
  - Create admin dashboard for monitoring
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 9.1 Implement analytics tracking
  - Track total calls per user
  - Track average call duration
  - Track speaking time vs listening time
  - Calculate fluency improvements over time
  - _Requirements: 10.1, 10.2, 10.3_

- [x] 9.2 Add monitoring and logging
  - Log all connection events
  - Track error rates and types
  - Monitor AI response latency
  - Set up alerts for high error rates
  - _Requirements: 6.5_

- [x] 10. Testing and optimization
  - Write unit tests for key components
  - Perform integration testing
  - Test on multiple devices and network conditions
  - Optimize performance and battery usage
  - _Requirements: All_

- [x] 10.1 Write unit tests
  - Test bottom navigation state management
  - Test LiveKit service connection logic
  - Test AI agent response generation
  - Test analytics calculations
  - _Requirements: All_

- [x] 10.2 Integration testing
  - Test end-to-end video call flow
  - Test navigation between tabs
  - Test call interruption and resumption
  - Test concurrent calls from multiple users
  - _Requirements: All_

- [x] 10.3 Performance optimization
  - Optimize video quality based on device capabilities
  - Reduce battery consumption during calls
  - Minimize memory usage
  - Improve AI response time
  - _Requirements: 6.1, 5.2, 5.3_
