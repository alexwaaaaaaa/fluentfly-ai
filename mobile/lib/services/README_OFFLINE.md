# Offline Caching and Sync

This document describes the offline caching and synchronization system implemented in FluentFly.

## Overview

The offline caching system allows users to access lessons and practice even without internet connectivity. The system automatically caches the 5 most recently accessed lessons and their associated audio files.

## Components

### 1. CacheService (`cache_service.dart`)

Manages local data storage using Hive.

**Key Features:**
- Caches lessons with 7-day TTL
- Caches audio files locally
- Tracks 5 most recently accessed lessons
- Automatic cache expiration cleanup
- Preloads audio files for offline use

**Methods:**
```dart
// Cache a lesson
await cacheService.cacheLesson(lesson);

// Get cached lesson
final lesson = await cacheService.getCachedLesson(lessonId);

// Cache audio file
await cacheService.cacheAudio(audioUrl);

// Get cached audio
final audioData = await cacheService.getCachedAudio(audioUrl);

// Preload lesson audio
await cacheService.preloadLessonAudio(lesson);

// Clear expired cache
await cacheService.clearExpiredCache();
```

### 2. ConnectivityService (`connectivity_service.dart`)

Monitors network connectivity status.

**Key Features:**
- Real-time connectivity monitoring
- Stream-based connectivity updates
- Automatic status detection

**Usage:**
```dart
final connectivityService = ConnectivityService();
await connectivityService.init();

// Check current status
final isOnline = connectivityService.isOnline;

// Listen to connectivity changes
connectivityService.connectivityStream.listen((isOnline) {
  if (isOnline) {
    print('Back online!');
  } else {
    print('Offline');
  }
});
```

### 3. SyncService (`sync_service.dart`)

Handles automatic data synchronization when network is restored.

**Key Features:**
- Automatic sync on network restore
- Syncs recent lessons
- Preloads audio files
- Prevents duplicate syncs

**Usage:**
```dart
final syncService = SyncService();
await syncService.init(lessonService);

// Force sync
await syncService.forceSyncNow(lessonService);

// Check if sync is needed
if (syncService.shouldSync()) {
  await syncService.syncData(lessonService);
}
```

### 4. LessonService (Enhanced)

Updated to support offline-first data fetching.

**Behavior:**
1. Try to fetch from API if online
2. Cache the data automatically
3. Fallback to cache if offline or API fails
4. Throw error only if no cached data available

**Example:**
```dart
final lessonService = LessonService(apiService, cacheService, connectivityService);

// This will automatically use cache if offline
final lessons = await lessonService.getLessons();
final lesson = await lessonService.getLesson(lessonId);
```

### 5. OfflineIndicator Widget

UI component to show offline status.

**Usage:**
```dart
// In your screen
OfflineIndicator(
  isOffline: !isOnline,
  onRetry: () {
    // Retry loading data
    ref.invalidate(lessonsProvider);
  },
)

// Or use the banner version
OfflineBanner(isOffline: !isOnline)

// Or show snackbar on connectivity change
ConnectivitySnackbar.show(context, isOnline);
```

## Integration Example

### In main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize cache service
  final cacheService = CacheService();
  await cacheService.init();

  // Initialize connectivity service
  final connectivityService = ConnectivityService();
  await connectivityService.init();

  // Clear expired cache on startup
  await cacheService.clearExpiredCache();

  runApp(const ProviderScope(child: MyApp()));
}
```

### In a Screen

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    final lessonsAsync = ref.watch(lessonsProvider);

    return Scaffold(
      body: Column(
        children: [
          // Show offline indicator
          connectivityStatus.when(
            data: (isOnline) => OfflineIndicator(
              isOffline: !isOnline,
              onRetry: () => ref.invalidate(lessonsProvider),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          // Your content
          Expanded(
            child: lessonsAsync.when(
              data: (lessons) => ListView.builder(...),
              loading: () => CircularProgressIndicator(),
              error: (error, stack) => ErrorWidget(error),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Cache Strategy

### What Gets Cached

1. **Lessons**: All lesson data including metadata
2. **Audio Files**: TTS audio and exercise audio files
3. **Recent Lessons**: The 5 most recently accessed lessons

### Cache TTL

- **Lessons**: 7 days
- **Audio Files**: 7 days
- **Automatic Cleanup**: On app startup and periodically

### Cache Size Management

The system automatically:
- Limits recent lessons to 5
- Clears expired cache entries
- Removes old audio files

## Offline Behavior

### When Offline

1. **Lesson List**: Shows cached lessons
2. **Lesson Details**: Shows cached lesson if available
3. **Audio Playback**: Uses cached audio files
4. **Progress Tracking**: Saves locally, syncs when online

### When Back Online

1. **Automatic Sync**: Triggered immediately
2. **Recent Lessons**: Re-fetched and cached
3. **Audio Files**: Preloaded for offline use
4. **Progress**: Synced with backend

## Requirements Met

This implementation satisfies the following requirements:

- **7.1**: Cache the 5 most recently accessed lessons locally ✓
- **7.2**: Display cached lessons and allow offline practice ✓
- **7.3**: Use low-bitrate MP3 format for audio files ✓
- **7.4**: Synchronize offline progress within 10 seconds of network restore ✓
- **7.5**: Preload audio files and animations for smooth transitions ✓

## Testing

To test offline functionality:

1. Load some lessons while online
2. Turn off network connectivity
3. Navigate to previously viewed lessons
4. Verify lessons and audio work offline
5. Turn network back on
6. Verify automatic sync occurs
7. Check that new data is cached

## Performance Considerations

- Cache operations are asynchronous and non-blocking
- Audio files are downloaded in background
- Sync happens automatically without user intervention
- Cache cleanup runs on app startup (minimal impact)

## Future Enhancements

Potential improvements:
- Configurable cache size
- Manual cache management UI
- Cache statistics display
- Selective lesson caching
- Background sync scheduling
