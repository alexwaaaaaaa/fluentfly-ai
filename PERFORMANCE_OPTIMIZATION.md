# FluentFly Performance Optimization Guide

This document outlines the performance optimizations implemented in the FluentFly application.

## Backend Optimizations

### 1. Database Indexing

Comprehensive indexes have been added to optimize query performance:

**Lessons Table:**
- `idx_lessons_level` - Filter by skill level
- `idx_lessons_order` - Sort by order
- `idx_lessons_level_order` - Composite index for level + order queries

**Exercises Table:**
- `idx_exercises_lesson_id` - Foreign key lookup
- `idx_exercises_lesson_order` - Composite index for lesson + order queries

**Progress Table:**
- `idx_progress_user_id` - User progress lookup
- `idx_progress_lesson_id` - Lesson progress lookup
- `idx_progress_user_lesson` - Composite index for user + lesson queries
- `idx_progress_completed` - Filter completed lessons

**Users Table:**
- `idx_users_xp` - Leaderboard queries (DESC order)
- `idx_users_email` - Email lookup for authentication
- `idx_users_phone` - Phone lookup for authentication

**Chat Sessions Table:**
- `idx_chat_sessions_user_id` - User chat history
- `idx_chat_sessions_created` - Recent chats (DESC order)

**Badges Tables:**
- `idx_user_badges_user_id` - User badges lookup
- `idx_user_badges_badge_id` - Badge users lookup
- `idx_badges_name` - Badge name lookup

### 2. Redis Caching

**Lessons Service:**
- Lesson list queries cached for 1 hour
- Individual lessons cached for 1 hour
- Lesson with exercises cached for 1 hour
- Cache invalidation on lesson updates

**Gamification Service:**
- Leaderboard cached for 1 minute
- Cache invalidation on XP awards

**Speech Service:**
- TTS audio cached in S3/R2 with hash-based keys
- Permanent caching to avoid regeneration

### 3. Query Optimization

**Lessons Service:**
- Uses QueryBuilder for efficient filtering
- Eager loading of exercises with relations
- Proper sorting by orderIndex

**Gamification Service:**
- Efficient leaderboard queries with pagination
- Optimized XP calculation with streak bonuses

## Mobile Optimizations

### 1. Skeleton Screens

Implemented skeleton loaders for better perceived performance:
- `LessonCardSkeleton` - Loading state for lesson cards
- `LeaderboardEntrySkeleton` - Loading state for leaderboard entries
- `BadgeSkeleton` - Loading state for badges
- Generic `SkeletonLoader` widget with shimmer animation

### 2. Lazy Loading

**Lesson Provider:**
- Cache-first strategy for lesson data
- Automatic caching of fetched lessons
- Preloading of lesson audio files

**Home Screen:**
- Skeleton screens during initial load
- Pull-to-refresh for manual updates
- Efficient ListView.builder for large lists

### 3. Asset Optimization

**Animation Preloading:**
- Critical Lottie animations preloaded on app startup
- Fallback animations for error states
- Lazy loading of non-critical animations

**Audio Caching:**
- Local caching of audio files with Hive
- 7-day TTL for cached audio
- Automatic cleanup of expired cache

### 4. Build Size Optimization

**Flutter Build Configuration:**
- Tree-shaking enabled for unused code removal
- Obfuscation for production builds
- Split debug info for smaller APK size

**Asset Compression:**
- Lottie JSON files optimized
- Audio files use low-bitrate MP3 (48kbps)
- Images optimized for mobile screens

### 5. State Management Optimization

**Riverpod Providers:**
- Family providers for parameterized queries
- AutoDispose for automatic cleanup
- Selective rebuilds with watch/select

**Cache Service:**
- Hive for fast local storage
- Automatic cache expiration
- Background sync on network restore

## Network Optimization

### 1. API Request Optimization

**Retry Logic:**
- Exponential backoff for failed requests
- Maximum 3 retry attempts
- Timeout configuration (30s normal, 60s AI)

**Request Batching:**
- Lesson exercises fetched with lesson data
- Progress updates batched when possible

### 2. Offline Support

**Cache Strategy:**
- 5 most recent lessons cached locally
- Audio files cached for offline playback
- Automatic sync on network restore

**Connectivity Handling:**
- Real-time connectivity monitoring
- Offline indicator in UI
- Graceful degradation to cached data

## Monitoring and Metrics

### Backend Metrics

**Health Endpoint:**
- Database connection status
- Redis connection status
- External service availability

**Logging:**
- Request/response logging
- Error tracking with stack traces
- Performance metrics for slow queries

### Mobile Metrics

**Error Tracking:**
- Centralized error handler
- User-friendly error messages
- Fallback UI components

**Performance Monitoring:**
- Cache hit/miss rates
- API response times
- Animation frame rates

## Best Practices

### Backend

1. **Always use indexes** for frequently queried columns
2. **Cache expensive queries** with appropriate TTL
3. **Use pagination** for large result sets
4. **Optimize N+1 queries** with eager loading
5. **Monitor slow queries** and add indexes as needed

### Mobile

1. **Implement skeleton screens** for all loading states
2. **Use lazy loading** for lists and images
3. **Cache aggressively** with proper invalidation
4. **Preload critical assets** on app startup
5. **Optimize images and animations** for mobile

### General

1. **Profile before optimizing** - measure first
2. **Optimize critical paths** - focus on user-facing features
3. **Monitor in production** - track real-world performance
4. **Test on low-end devices** - ensure broad compatibility
5. **Balance performance and maintainability** - don't over-optimize

## Performance Targets

### Backend

- API response time: < 200ms (p95)
- Database query time: < 50ms (p95)
- Cache hit rate: > 80%
- Concurrent users: 1000+

### Mobile

- App startup time: < 2s
- Screen transition: < 300ms
- Animation frame rate: 60 FPS
- APK size: < 50MB

## Future Optimizations

### Backend

- [ ] Implement database connection pooling
- [ ] Add CDN for static assets
- [ ] Implement GraphQL for flexible queries
- [ ] Add database read replicas for scaling

### Mobile

- [ ] Implement image lazy loading
- [ ] Add progressive image loading
- [ ] Optimize bundle size with code splitting
- [ ] Implement background sync for offline changes

## Conclusion

These optimizations ensure FluentFly delivers a fast, responsive experience across all devices and network conditions. Regular monitoring and profiling help identify new optimization opportunities as the application scales.
