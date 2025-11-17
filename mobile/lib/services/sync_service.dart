import 'dart:async';
import 'package:logger/logger.dart';
import 'connectivity_service.dart';
import 'cache_service.dart';
import 'lesson_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;

  final _logger = Logger();
  final _connectivityService = ConnectivityService();
  final _cacheService = CacheService();

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  SyncService._internal();

  /// Initialize sync service
  Future<void> init(LessonService lessonService) async {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen((
      isOnline,
    ) {
      if (isOnline) {
        _logger.d('Network restored, triggering sync');
        syncData(lessonService);
      }
    });

    _logger.d('Sync service initialized');
  }

  /// Sync cached data with backend
  Future<void> syncData(LessonService lessonService) async {
    if (_isSyncing) {
      _logger.d('Sync already in progress, skipping');
      return;
    }

    if (!_connectivityService.isOnline) {
      _logger.d('Device is offline, skipping sync');
      return;
    }

    _isSyncing = true;
    _logger.d('Starting data sync');

    try {
      // Get recent lesson IDs
      final recentLessonIds = await _cacheService.getRecentLessonIds();

      // Sync recent lessons
      for (final lessonId in recentLessonIds) {
        try {
          final lesson = await lessonService.getLesson(lessonId);
          await _cacheService.cacheLesson(lesson);

          // Preload audio for the lesson
          await _cacheService.preloadLessonAudio(lesson);

          _logger.d('Synced lesson $lessonId');
        } catch (e) {
          _logger.e('Error syncing lesson $lessonId: $e');
        }
      }

      // Sync all lessons list
      try {
        final lessons = await lessonService.getLessons();
        await _cacheService.cacheLessons(lessons);
        _logger.d('Synced all lessons list');
      } catch (e) {
        _logger.e('Error syncing lessons list: $e');
      }

      // Clear expired cache
      await _cacheService.clearExpiredCache();

      _lastSyncTime = DateTime.now();
      _logger.d('Data sync completed successfully');
    } catch (e) {
      _logger.e('Error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Force sync now
  Future<void> forceSyncNow(LessonService lessonService) async {
    _logger.d('Force sync requested');
    await syncData(lessonService);
  }

  /// Check if sync is needed (e.g., hasn't synced in last hour)
  bool shouldSync() {
    if (_lastSyncTime == null) return true;

    final hoursSinceLastSync = DateTime.now()
        .difference(_lastSyncTime!)
        .inHours;
    return hoursSinceLastSync >= 1;
  }

  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _isSyncing;

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
