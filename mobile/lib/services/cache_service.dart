import 'dart:io';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../models/lesson.dart';

class CacheService {
  static const String _lessonsBox = 'lessons';
  static const String _audioBox = 'audio';
  static const String _recentLessonsKey = 'recent_lessons';
  static const int _cacheTTL = 7 * 24 * 60 * 60; // 7 days in seconds
  static const int _maxRecentLessons = 5;

  final _logger = Logger();
  final Dio _dio = Dio();

  Future<void> init() async {
    await Hive.openBox<Map>(_lessonsBox);
    await Hive.openBox<Map>(_audioBox);
  }

  Future<void> cacheLesson(Lesson lesson) async {
    try {
      final box = Hive.box<Map>(_lessonsBox);
      final cacheData = {
        'data': lesson.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await box.put('lesson_${lesson.id}', cacheData);

      // Update recent lessons list
      await _updateRecentLessons(lesson.id);

      _logger.d('Cached lesson ${lesson.id}: ${lesson.title}');
    } catch (e) {
      _logger.e('Error caching lesson: $e');
    }
  }

  /// Update the list of recently accessed lessons (max 5)
  Future<void> _updateRecentLessons(int lessonId) async {
    try {
      final box = Hive.box<Map>(_lessonsBox);
      final recentData = box.get(_recentLessonsKey);
      List<int> recentLessons = [];

      if (recentData != null) {
        recentLessons = List<int>.from(recentData['lessons'] as List);
      }

      // Remove if already exists
      recentLessons.remove(lessonId);

      // Add to front
      recentLessons.insert(0, lessonId);

      // Keep only the 5 most recent
      if (recentLessons.length > _maxRecentLessons) {
        recentLessons = recentLessons.sublist(0, _maxRecentLessons);
      }

      await box.put(_recentLessonsKey, {
        'lessons': recentLessons,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      _logger.e('Error updating recent lessons: $e');
    }
  }

  /// Get list of recently accessed lesson IDs
  Future<List<int>> getRecentLessonIds() async {
    try {
      final box = Hive.box<Map>(_lessonsBox);
      final recentData = box.get(_recentLessonsKey);

      if (recentData != null) {
        return List<int>.from(recentData['lessons'] as List);
      }
      return [];
    } catch (e) {
      _logger.e('Error getting recent lessons: $e');
      return [];
    }
  }

  Future<Lesson?> getCachedLesson(int id) async {
    try {
      final box = Hive.box<Map>(_lessonsBox);
      final cacheData = box.get('lesson_$id');

      if (cacheData == null) return null;

      final timestamp = cacheData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if cache is expired (7 days)
      if ((now - timestamp) / 1000 > _cacheTTL) {
        await box.delete('lesson_$id');
        _logger.d('Cache expired for lesson $id');
        return null;
      }

      _logger.d('Retrieved cached lesson $id');
      return Lesson.fromJson(
        Map<String, dynamic>.from(cacheData['data'] as Map),
      );
    } catch (e) {
      _logger.e('Error getting cached lesson: $e');
      return null;
    }
  }

  Future<void> cacheLessons(List<Lesson> lessons) async {
    try {
      final box = Hive.box<Map>(_lessonsBox);
      final cacheData = {
        'data': lessons.map((l) => l.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await box.put('all_lessons', cacheData);
      _logger.d('Cached ${lessons.length} lessons');
    } catch (e) {
      _logger.e('Error caching lessons: $e');
    }
  }

  Future<List<Lesson>?> getCachedLessons() async {
    try {
      final box = Hive.box<Map>(_lessonsBox);
      final cacheData = box.get('all_lessons');

      if (cacheData == null) return null;

      final timestamp = cacheData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if cache is expired (7 days)
      if ((now - timestamp) / 1000 > _cacheTTL) {
        await box.delete('all_lessons');
        _logger.d('Cache expired for all lessons');
        return null;
      }

      final lessons = (cacheData['data'] as List)
          .map(
            (json) => Lesson.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();

      _logger.d('Retrieved ${lessons.length} cached lessons');
      return lessons;
    } catch (e) {
      _logger.e('Error getting cached lessons: $e');
      return null;
    }
  }

  /// Cache audio file from URL
  Future<void> cacheAudio(String url) async {
    try {
      final box = Hive.box<Map>(_audioBox);

      // Check if already cached
      if (box.containsKey(url)) {
        _logger.d('Audio already cached: $url');
        return;
      }

      // Download audio file
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data != null) {
        final cacheData = {
          'data': response.data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        await box.put(url, cacheData);
        _logger.d('Cached audio: $url');
      }
    } catch (e) {
      _logger.e('Error caching audio: $e');
    }
  }

  /// Get cached audio file
  Future<Uint8List?> getCachedAudio(String url) async {
    try {
      final box = Hive.box<Map>(_audioBox);
      final cacheData = box.get(url);

      if (cacheData == null) return null;

      final timestamp = cacheData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if cache is expired (7 days)
      if ((now - timestamp) / 1000 > _cacheTTL) {
        await box.delete(url);
        _logger.d('Audio cache expired: $url');
        return null;
      }

      _logger.d('Retrieved cached audio: $url');
      return Uint8List.fromList(List<int>.from(cacheData['data'] as List));
    } catch (e) {
      _logger.e('Error getting cached audio: $e');
      return null;
    }
  }

  /// Save audio file to local storage and return file path
  Future<String?> saveAudioToFile(String url, Uint8List data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio');

      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      // Create filename from URL hash
      final filename = url.hashCode.abs().toString();
      final file = File('${audioDir.path}/$filename.mp3');

      await file.writeAsBytes(data);
      _logger.d('Saved audio file: ${file.path}');

      return file.path;
    } catch (e) {
      _logger.e('Error saving audio file: $e');
      return null;
    }
  }

  /// Preload audio files for a lesson
  Future<void> preloadLessonAudio(Lesson lesson) async {
    try {
      // Cache lesson audio URL if available
      if (lesson.audioUrl != null && lesson.audioUrl!.isNotEmpty) {
        await cacheAudio(lesson.audioUrl!);
      }

      // Cache exercise audio URLs
      if (lesson.exercises != null && lesson.exercises!.isNotEmpty) {
        for (final exercise in lesson.exercises!) {
          if (exercise.audioUrl != null && exercise.audioUrl!.isNotEmpty) {
            await cacheAudio(exercise.audioUrl!);
          }
        }
      }

      _logger.d('Preloaded audio for lesson ${lesson.id}');
    } catch (e) {
      _logger.e('Error preloading lesson audio: $e');
    }
  }

  Future<void> clearExpiredCache() async {
    try {
      // Clear expired lessons
      final lessonsBox = Hive.box<Map>(_lessonsBox);
      final now = DateTime.now().millisecondsSinceEpoch;
      final keysToDelete = <String>[];

      for (var key in lessonsBox.keys) {
        final cacheData = lessonsBox.get(key);
        if (cacheData != null && cacheData['timestamp'] != null) {
          final timestamp = cacheData['timestamp'] as int;
          if ((now - timestamp) / 1000 > _cacheTTL) {
            keysToDelete.add(key.toString());
          }
        }
      }

      for (var key in keysToDelete) {
        await lessonsBox.delete(key);
      }

      // Clear expired audio
      final audioBox = Hive.box<Map>(_audioBox);
      final audioKeysToDelete = <String>[];

      for (var key in audioBox.keys) {
        final cacheData = audioBox.get(key);
        if (cacheData != null && cacheData['timestamp'] != null) {
          final timestamp = cacheData['timestamp'] as int;
          if ((now - timestamp) / 1000 > _cacheTTL) {
            audioKeysToDelete.add(key.toString());
          }
        }
      }

      for (var key in audioKeysToDelete) {
        await audioBox.delete(key);
      }

      _logger.d(
        'Cleared ${keysToDelete.length} expired lessons and ${audioKeysToDelete.length} expired audio files',
      );
    } catch (e) {
      _logger.e('Error clearing expired cache: $e');
    }
  }

  Future<void> clearAllCache() async {
    try {
      final lessonsBox = Hive.box<Map>(_lessonsBox);
      final audioBox = Hive.box<Map>(_audioBox);

      await lessonsBox.clear();
      await audioBox.clear();

      _logger.d('Cleared all cache');
    } catch (e) {
      _logger.e('Error clearing all cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final lessonsBox = Hive.box<Map>(_lessonsBox);
      final audioBox = Hive.box<Map>(_audioBox);

      return {
        'lessonsCount': lessonsBox.length,
        'audioCount': audioBox.length,
        'recentLessons': await getRecentLessonIds(),
      };
    } catch (e) {
      _logger.e('Error getting cache stats: $e');
      return {};
    }
  }
}
