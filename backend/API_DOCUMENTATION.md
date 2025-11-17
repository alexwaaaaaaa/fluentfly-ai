# FluentFly API Documentation

## Overview

FluentFly is an AI-powered English learning platform that provides structured lessons, gamification, and conversational AI practice. This document provides comprehensive API documentation for developers.

## Base URL

- **Development**: `http://localhost:3000`
- **Production**: `https://api.fluentfly.app`

## Interactive Documentation

Swagger UI is available at `/api/docs` for interactive API exploration and testing.

## Authentication

### Firebase JWT Authentication

Most endpoints require authentication using Firebase JWT tokens. Users authenticate via:
1. Phone/Email OTP authentication
2. Firebase generates a JWT token
3. Include token in all subsequent requests

**Header Format:**
```
Authorization: Bearer <firebase-jwt-token>
```

### Endpoints

#### POST /auth/send-otp
Send OTP to phone or email for authentication.

**Request Body:**
```json
{
  "phone": "+1234567890",
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "message": "OTP sent successfully"
}
```

#### POST /auth/verify-otp
Verify OTP and get Firebase token.

**Request Body:**
```json
{
  "phone": "+1234567890",
  "otp": "123456"
}
```

**Response:**
```json
{
  "token": "firebase-jwt-token",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "user@example.com",
    "xp": 150,
    "level": "A2",
    "streak": 5
  }
}
```

## Lessons

### GET /lessons
Get list of lessons with optional filtering.

**Query Parameters:**
- `level` (optional): Filter by CEFR level (A1, A2, B1, B2, C1, C2)
- `search` (optional): Search by title or skill

**Response:**
```json
[
  {
    "id": 1,
    "skill": "Greetings",
    "title": "Basic Greetings",
    "level": "A1",
    "description": "Learn common greetings",
    "audioUrl": "https://...",
    "orderIndex": 1
  }
]
```

### GET /lessons/:id
Get detailed lesson information.

**Response:**
```json
{
  "id": 1,
  "skill": "Greetings",
  "title": "Basic Greetings",
  "level": "A1",
  "description": "Learn common greetings",
  "audioUrl": "https://...",
  "orderIndex": 1,
  "meta": {
    "duration": 15,
    "difficulty": "beginner"
  }
}
```

### GET /lessons/:id/exercises
Get exercises for a specific lesson.

**Response:**
```json
[
  {
    "id": 1,
    "lessonId": 1,
    "type": "multiple_choice",
    "question": "How do you say hello?",
    "options": ["Hello", "Goodbye", "Thanks"],
    "answer": "Hello",
    "audioUrl": "https://...",
    "orderIndex": 1
  }
]
```

## Progress

### POST /progress
Save user progress for a lesson.

**Request Body:**
```json
{
  "lessonId": 1,
  "score": {
    "correct": 8,
    "total": 10,
    "percentage": 80
  },
  "completed": true,
  "timeSpent": 900
}
```

**Response:**
```json
{
  "id": 1,
  "userId": 1,
  "lessonId": 1,
  "score": { "correct": 8, "total": 10, "percentage": 80 },
  "completed": true,
  "timeSpent": 900,
  "completedAt": "2024-01-15T10:30:00Z"
}
```

### GET /progress
Get user's progress across all lessons.

**Response:**
```json
[
  {
    "id": 1,
    "lessonId": 1,
    "score": { "correct": 8, "total": 10, "percentage": 80 },
    "completed": true,
    "completedAt": "2024-01-15T10:30:00Z"
  }
]
```

## Gamification

### POST /gamification/xp
Award XP to user (typically called after lesson completion).

**Request Body:**
```json
{
  "amount": 50,
  "reason": "Completed lesson: Basic Greetings"
}
```

**Response:**
```json
{
  "xpAwarded": 75,
  "totalXp": 225,
  "leveledUp": true,
  "newLevel": "A2",
  "newBadges": [
    {
      "id": 1,
      "name": "First Steps",
      "description": "Complete your first lesson"
    }
  ]
}
```

### GET /gamification/streak
Check and update user's daily streak.

**Response:**
```json
{
  "streak": 7,
  "streakIncremented": true,
  "bonusXp": 35
}
```

### GET /gamification/leaderboard
Get leaderboard rankings.

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 100, max: 100)

**Response:**
```json
[
  {
    "rank": 1,
    "userId": 42,
    "name": "John Doe",
    "xp": 1500,
    "level": "B2",
    "streak": 15,
    "profileImageUrl": "https://..."
  }
]
```

### GET /gamification/badges
Get user's earned badges.

**Response:**
```json
[
  {
    "id": 1,
    "name": "First Steps",
    "description": "Complete your first lesson",
    "iconUrl": "https://...",
    "earnedAt": "2024-01-15T10:30:00Z"
  }
]
```

## AI Chat

### POST /chat/start
Start a new AI conversation session.

**Request Body:**
```json
{
  "topic": "Travel",
  "difficulty": "intermediate"
}
```

**Response:**
```json
{
  "sessionId": 1,
  "topic": "Travel",
  "initialMessage": "Hello! Let's practice talking about travel. Have you traveled anywhere recently?"
}
```

### POST /chat/message
Send a message in an ongoing conversation.

**Request Body:**
```json
{
  "sessionId": 1,
  "message": "Yes, I went to Paris last month."
}
```

**Response:**
```json
{
  "response": "That's wonderful! What did you enjoy most about Paris?",
  "feedback": {
    "grammar": "Excellent",
    "vocabulary": "Good",
    "suggestions": []
  }
}
```

### POST /chat/feedback
Get detailed feedback on conversation.

**Request Body:**
```json
{
  "sessionId": 1
}
```

**Response:**
```json
{
  "overallScore": 85,
  "grammar": {
    "score": 90,
    "feedback": "Great use of past tense"
  },
  "vocabulary": {
    "score": 80,
    "feedback": "Good variety of words"
  },
  "fluency": {
    "score": 85,
    "feedback": "Natural conversation flow"
  },
  "suggestions": [
    "Try using more descriptive adjectives"
  ]
}
```

## Speech

### POST /speech/tts
Convert text to speech.

**Request Body:**
```json
{
  "text": "Hello, how are you?",
  "voice": "en-US-Neural2-F",
  "speed": 1.0
}
```

**Response:**
```json
{
  "audioUrl": "https://storage.../audio.mp3",
  "duration": 2.5
}
```

### POST /speech/stt
Convert speech to text.

**Request Body:**
```json
{
  "audioUrl": "https://storage.../recording.mp3",
  "language": "en-US"
}
```

**Response:**
```json
{
  "text": "Hello, how are you?",
  "confidence": 0.95,
  "words": [
    { "word": "Hello", "confidence": 0.98 },
    { "word": "how", "confidence": 0.96 },
    { "word": "are", "confidence": 0.94 },
    { "word": "you", "confidence": 0.93 }
  ]
}
```

## Health

### GET /health
Check API health status.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00Z",
  "services": {
    "database": "healthy",
    "redis": "healthy",
    "firebase": "healthy"
  }
}
```

## Error Handling

### Error Response Format

All errors follow a consistent format:

```json
{
  "statusCode": 400,
  "message": "Validation failed",
  "error": "Bad Request",
  "details": {
    "field": "email",
    "issue": "Invalid email format"
  }
}
```

### Common Status Codes

- **200 OK**: Request succeeded
- **201 Created**: Resource created successfully
- **400 Bad Request**: Invalid request parameters
- **401 Unauthorized**: Missing or invalid authentication
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource not found
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Server error

## Rate Limiting

Rate limits are applied per user/IP address:

- **Standard endpoints**: 100 requests per minute
- **AI endpoints**: 20 requests per minute
- **Speech endpoints**: 30 requests per minute

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642248600
```

## Caching

Responses include cache headers for optimal performance:

```
Cache-Control: public, max-age=3600
ETag: "abc123"
```

Clients should:
1. Cache responses according to Cache-Control headers
2. Use ETags for conditional requests
3. Respect cache expiration times

## Webhooks

FluentFly can send webhooks for important events:

### Webhook Events

- `user.registered`: New user registration
- `lesson.completed`: User completed a lesson
- `badge.earned`: User earned a new badge
- `streak.milestone`: User reached streak milestone

### Webhook Payload

```json
{
  "event": "lesson.completed",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "userId": 1,
    "lessonId": 5,
    "score": 85
  }
}
```

## Best Practices

### 1. Authentication
- Store Firebase tokens securely
- Refresh tokens before expiration
- Handle 401 errors by re-authenticating

### 2. Error Handling
- Always check response status codes
- Parse error messages for user feedback
- Implement retry logic for transient errors

### 3. Performance
- Use caching headers appropriately
- Batch requests when possible
- Implement pagination for large lists

### 4. Offline Support
- Cache lesson content locally
- Queue progress updates when offline
- Sync when connection restored

## SDK Examples

### JavaScript/TypeScript

```typescript
import axios from 'axios';

const api = axios.create({
  baseURL: 'https://api.fluentfly.app',
  headers: {
    'Authorization': `Bearer ${firebaseToken}`
  }
});

// Get lessons
const lessons = await api.get('/lessons', {
  params: { level: 'A1' }
});

// Save progress
await api.post('/progress', {
  lessonId: 1,
  score: { correct: 8, total: 10, percentage: 80 },
  completed: true
});
```

### Flutter/Dart

```dart
import 'package:dio/dio.dart';

final dio = Dio(BaseOptions(
  baseUrl: 'https://api.fluentfly.app',
  headers: {'Authorization': 'Bearer $firebaseToken'},
));

// Get lessons
final response = await dio.get('/lessons', 
  queryParameters: {'level': 'A1'}
);

// Save progress
await dio.post('/progress', data: {
  'lessonId': 1,
  'score': {'correct': 8, 'total': 10, 'percentage': 80},
  'completed': true,
});
```

## Support

For API support and questions:
- Email: support@fluentfly.app
- Documentation: https://docs.fluentfly.app
- Status Page: https://status.fluentfly.app

## Changelog

### Version 1.0 (Current)
- Initial API release
- Authentication with Firebase
- Lessons and exercises
- Progress tracking
- Gamification system
- AI chat conversations
- Speech-to-text and text-to-speech
