import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lesson.dart';
import '../services/lesson_service.dart';
import '../services/cache_service.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';

// Service providers
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

final lessonServiceProvider = Provider<LessonService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  return LessonService(apiService, cacheService, connectivityService);
});

// Lessons list provider with caching
final lessonsProvider = FutureProvider.family<List<Lesson>, LessonQuery>((
  ref,
  query,
) async {
  final lessonService = ref.watch(lessonServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);

  // Try cache first if no filters
  if (query.level == null && query.search == null) {
    final cached = await cacheService.getCachedLessons();
    if (cached != null) {
      return cached;
    }
  }

  // Fetch from API
  final lessons = await lessonService.getLessons(
    level: query.level,
    search: query.search,
  );

  // Cache if no filters
  if (query.level == null && query.search == null) {
    await cacheService.cacheLessons(lessons);
  }

  return lessons;
});

// Single lesson provider with caching
final lessonProvider = FutureProvider.family<Lesson, int>((ref, id) async {
  final lessonService = ref.watch(lessonServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);

  // Try cache first
  final cached = await cacheService.getCachedLesson(id);
  if (cached != null) {
    return cached;
  }

  // Fetch from API
  final lesson = await lessonService.getLesson(id);

  // Cache the lesson
  await cacheService.cacheLesson(lesson);

  return lesson;
});

// Exercises provider
final exercisesProvider = FutureProvider.family<List<Exercise>, int>((
  ref,
  lessonId,
) async {
  final lessonService = ref.watch(lessonServiceProvider);
  return lessonService.getExercises(lessonId);
});

// Query class for filtering lessons
class LessonQuery {
  final String? level;
  final String? search;

  const LessonQuery({this.level, this.search});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonQuery &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          search == other.search;

  @override
  int get hashCode => level.hashCode ^ search.hashCode;
}
