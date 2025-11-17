import 'package:logger/logger.dart';
import '../models/progress.dart';
import 'api_service.dart';

class ProgressService {
  final ApiService _apiService;
  final Logger _logger = Logger();

  ProgressService(this._apiService);

  /// Save lesson progress
  Future<Progress> saveProgress({
    required int lessonId,
    required Map<String, dynamic> score,
    required bool completed,
    int? timeSpent,
  }) async {
    try {
      final response = await _apiService.post(
        '/progress',
        data: {
          'lessonId': lessonId,
          'score': score,
          'completed': completed,
          'timeSpent': timeSpent,
        },
      );

      return Progress.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _logger.e('Failed to save progress', error: e);
      rethrow;
    }
  }

  /// Get all user progress
  Future<List<Progress>> getProgress() async {
    try {
      final response = await _apiService.get('/progress');
      final data = response.data as List;
      return data
          .map((e) => Progress.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Failed to get progress', error: e);
      rethrow;
    }
  }

  /// Get progress for a specific lesson
  Future<Progress?> getProgressByLesson(int lessonId) async {
    try {
      final response = await _apiService.get('/progress/lesson/$lessonId');
      if (response.data == null) return null;
      return Progress.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _logger.e('Failed to get lesson progress', error: e);
      rethrow;
    }
  }

  /// Get aggregated progress statistics
  Future<ProgressStats> getStats() async {
    try {
      final response = await _apiService.get('/progress/stats');
      return ProgressStats.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      _logger.e('Failed to get progress stats', error: e);
      rethrow;
    }
  }
}
