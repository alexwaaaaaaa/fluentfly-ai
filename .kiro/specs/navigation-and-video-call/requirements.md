# Requirements Document

## Introduction

This specification defines the requirements for adding bottom navigation bar and AI video call functionality to the FluentFly mobile application. These features will enhance user experience by providing easy navigation between main screens and enabling real-time video conversations with an AI tutor.

## Glossary

- **Mobile App**: The FluentFly Flutter mobile application
- **Bottom Navigation Bar**: A persistent navigation component at the bottom of the screen
- **AI Video Call**: Real-time video communication with an AI-powered language tutor
- **LiveKit**: WebRTC infrastructure for real-time video/audio communication
- **RTC Service**: Backend service that manages real-time communication sessions

## Requirements

### Requirement 1: Bottom Navigation Bar

**User Story:** As a user, I want a bottom navigation bar so that I can easily switch between Home, Progress, and Profile screens.

#### Acceptance Criteria

1. WHEN THE Mobile App displays any main screen, THE Mobile App SHALL show a bottom navigation bar with three tabs: Home, Progress, and Profile
2. WHEN a user taps on a navigation tab, THE Mobile App SHALL navigate to the corresponding screen within 200 milliseconds
3. WHEN THE Mobile App displays a screen, THE Mobile App SHALL highlight the active tab in the bottom navigation bar
4. WHEN a user is in a lesson flow, THE Mobile App SHALL hide the bottom navigation bar to provide full-screen experience
5. THE Mobile App SHALL persist the selected tab state when the app is backgrounded and resumed

### Requirement 2: Navigation Tab Icons and Labels

**User Story:** As a user, I want clear icons and labels on navigation tabs so that I can easily identify each section.

#### Acceptance Criteria

1. THE Mobile App SHALL display a home icon and "Home" label for the lessons screen tab
2. THE Mobile App SHALL display a chart/graph icon and "Progress" label for the progress tracking tab
3. THE Mobile App SHALL display a person icon and "Profile" label for the user profile tab
4. WHEN a tab is active, THE Mobile App SHALL display the icon and label in the primary theme color
5. WHEN a tab is inactive, THE Mobile App SHALL display the icon and label in a muted gray color

### Requirement 3: AI Video Call Initiation

**User Story:** As a user, I want to start a video call with an AI tutor during speaking practice so that I can have real-time conversations.

#### Acceptance Criteria

1. WHEN a user is on the speaking practice screen, THE Mobile App SHALL display a "Video Call with AI Tutor" button
2. WHEN a user taps the video call button, THE Mobile App SHALL request camera and microphone permissions if not already granted
3. IF permissions are denied, THEN THE Mobile App SHALL display an error message explaining that permissions are required
4. WHEN permissions are granted, THE Mobile App SHALL connect to the RTC Service within 3 seconds
5. WHEN connection is established, THE Mobile App SHALL display the video call interface with the user's camera feed

### Requirement 4: Video Call Interface

**User Story:** As a user, I want a clear video call interface so that I can see myself and interact with the AI tutor.

#### Acceptance Criteria

1. THE Mobile App SHALL display the user's camera feed in a large video view
2. THE Mobile App SHALL display an AI tutor avatar or animated character overlay
3. THE Mobile App SHALL show visual indicators when the AI is speaking (e.g., animated avatar, sound waves)
4. THE Mobile App SHALL display call controls including mute, camera toggle, and end call buttons
5. WHEN the AI tutor speaks, THE Mobile App SHALL display real-time captions or subtitles

### Requirement 5: Real-Time AI Conversation

**User Story:** As a user, I want to have natural conversations with the AI tutor so that I can practice speaking English.

#### Acceptance Criteria

1. WHEN a user speaks during the video call, THE Mobile App SHALL capture and stream audio to the RTC Service
2. THE RTC Service SHALL process speech-to-text conversion within 500 milliseconds
3. THE RTC Service SHALL generate AI responses using the chat AI service within 2 seconds
4. THE RTC Service SHALL convert AI text responses to speech using text-to-speech service
5. THE Mobile App SHALL play AI speech responses through the device speaker with synchronized avatar animations

### Requirement 6: Video Call Quality Management

**User Story:** As a user, I want stable video call quality so that I can have uninterrupted conversations.

#### Acceptance Criteria

1. THE Mobile App SHALL adapt video quality based on network bandwidth
2. WHEN network quality is poor, THE Mobile App SHALL display a warning indicator
3. THE Mobile App SHALL automatically reconnect if the connection drops for less than 5 seconds
4. IF reconnection fails after 3 attempts, THEN THE Mobile App SHALL end the call and display an error message
5. THE Mobile App SHALL log connection quality metrics for debugging purposes

### Requirement 7: Video Call Session Management

**User Story:** As a user, I want to control my video call session so that I can end it when I'm done practicing.

#### Acceptance Criteria

1. WHEN a user taps the end call button, THE Mobile App SHALL terminate the RTC connection within 1 second
2. WHEN a call ends, THE Mobile App SHALL display a summary showing call duration and practice statistics
3. THE Mobile App SHALL save conversation history and feedback to the backend
4. WHEN a call is interrupted (e.g., incoming phone call), THE Mobile App SHALL pause the session and allow resumption
5. THE Mobile App SHALL automatically end calls that exceed 30 minutes duration

### Requirement 8: Backend RTC Token Generation

**User Story:** As a system, I need to generate secure RTC tokens so that users can join video call sessions.

#### Acceptance Criteria

1. WHEN THE Mobile App requests a video call, THE RTC Service SHALL generate a unique room identifier
2. THE RTC Service SHALL create a LiveKit access token with appropriate permissions
3. THE RTC Service SHALL set token expiration to 1 hour from creation time
4. THE RTC Service SHALL return the token and room details to THE Mobile App within 500 milliseconds
5. THE RTC Service SHALL log all token generation requests for security auditing

### Requirement 9: AI Agent in Video Call

**User Story:** As a system, I need an AI agent to participate in video calls so that users can practice conversations.

#### Acceptance Criteria

1. WHEN a user joins a video call room, THE RTC Service SHALL spawn an AI agent participant
2. THE AI agent SHALL listen to user audio streams in real-time
3. WHEN the user stops speaking for 1 second, THE AI agent SHALL process the speech and generate a response
4. THE AI agent SHALL use the existing chat AI service for generating contextual responses
5. THE AI agent SHALL publish audio responses back to the room for the user to hear

### Requirement 10: Video Call Analytics

**User Story:** As a user, I want to see my speaking practice statistics so that I can track my improvement.

#### Acceptance Criteria

1. THE Mobile App SHALL track total speaking time during video calls
2. THE Mobile App SHALL count the number of conversation turns (user speaks, AI responds)
3. THE Mobile App SHALL calculate speaking fluency metrics (words per minute, pause frequency)
4. WHEN a call ends, THE Mobile App SHALL display these metrics in the summary screen
5. THE Mobile App SHALL save analytics data to the progress tracking system
