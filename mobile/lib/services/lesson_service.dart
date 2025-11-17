import 'package:logger/logger.dart';
import '../models/lesson.dart';
import 'api_service.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class LessonService {
  final ApiService _apiService;
  final CacheService _cacheService;
  final ConnectivityService _connectivityService;
  final _logger = Logger();

  LessonService(
    this._apiService,
    this._cacheService,
    this._connectivityService,
  );

  Future<List<Lesson>> getLessons({String? level, String? search}) async {
    try {
      // Try to fetch from API if online
      if (_connectivityService.isOnline) {
        final queryParams = <String, dynamic>{};
        if (level != null) queryParams['level'] = level;
        if (search != null) queryParams['search'] = search;

        final response = await _apiService.get(
          '/lessons',
          queryParameters: queryParams,
          enableRetry: true,
        );

        final lessons = (response.data as List)
            .map((json) => Lesson.fromJson(json as Map<String, dynamic>))
            .toList();

        // Cache the lessons
        try {
          await _cacheService.cacheLessons(lessons);
          _logger.d('Fetched and cached ${lessons.length} lessons from API');
        } catch (cacheError) {
          _logger.w('Failed to cache lessons: $cacheError');
          // Continue even if caching fails
        }

        return lessons;
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error fetching lessons from API',
        error: e,
        stackTrace: stackTrace,
      );
    }

    // Fallback to cache if offline or API failed
    _logger.d('Falling back to cached lessons');
    try {
      final cachedLessons = await _cacheService.getCachedLessons();

      if (cachedLessons != null && cachedLessons.isNotEmpty) {
        _logger.d('Retrieved ${cachedLessons.length} lessons from cache');
        return cachedLessons;
      }
    } catch (cacheError) {
      _logger.e('Error reading from cache', error: cacheError);
    }

    throw Exception(
      'Unable to load lessons. Please check your internet connection and try again.',
    );
  }

  Future<Lesson> getLesson(int id) async {
    try {
      // Try to fetch from API if online
      if (_connectivityService.isOnline) {
        final response = await _apiService.get('/lessons/$id');
        final lesson = Lesson.fromJson(response.data as Map<String, dynamic>);

        // Cache the lesson
        await _cacheService.cacheLesson(lesson);

        // Preload audio files for offline use
        await _cacheService.preloadLessonAudio(lesson);

        _logger.d('Fetched and cached lesson $id from API');

        return lesson;
      }
    } catch (e) {
      _logger.e('Error fetching lesson $id from API: $e');
    }

    // Fallback to cache if offline or API failed
    _logger.d('Falling back to cached lesson $id');
    final cachedLesson = await _cacheService.getCachedLesson(id);

    if (cachedLesson != null) {
      _logger.d('Retrieved lesson $id from cache');
      return cachedLesson;
    }

    throw Exception(
      'Failed to load lesson: No internet connection and no cached data available',
    );
  }

  Future<List<Exercise>> getExercises(int lessonId) async {
    try {
      // Try to fetch from API if online
      if (_connectivityService.isOnline) {
        final response = await _apiService.get('/lessons/$lessonId/exercises');
        final exercises = (response.data as List)
            .map((json) => Exercise.fromJson(json as Map<String, dynamic>))
            .toList();

        _logger.d('Fetched ${exercises.length} exercises for lesson $lessonId');
        return exercises;
      }
    } catch (e) {
      _logger.e('Error fetching exercises for lesson $lessonId: $e');
    }

    // Fallback to cached lesson's exercises
    _logger.d('Falling back to cached exercises for lesson $lessonId');
    final cachedLesson = await _cacheService.getCachedLesson(lessonId);

    if (cachedLesson != null && cachedLesson.exercises != null) {
      if (cachedLesson.exercises!.isNotEmpty) {
        _logger.d(
          'Retrieved ${cachedLesson.exercises!.length} exercises from cache',
        );
        return cachedLesson.exercises!;
      }
    }

    throw Exception(
      'Failed to load exercises: No internet connection and no cached data available',
    );
  }

  /// Get recently accessed lessons (for offline access)
  Future<List<Lesson>> getRecentLessons() async {
    final recentIds = await _cacheService.getRecentLessonIds();
    final lessons = <Lesson>[];

    for (final id in recentIds) {
      try {
        final lesson = await _cacheService.getCachedLesson(id);
        if (lesson != null) {
          lessons.add(lesson);
        }
      } catch (e) {
        _logger.e('Error loading recent lesson $id: $e');
      }
    }

    return lessons;
  }
}
