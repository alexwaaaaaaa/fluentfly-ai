import '../models/badge.dart';
import '../models/leaderboard_entry.dart';
import 'api_service.dart';

class GamificationService {
  final ApiService _apiService;

  GamificationService(this._apiService);

  Future<Map<String, dynamic>> awardXp(int amount, String reason) async {
    try {
      final response = await _apiService.post(
        '/gamification/award-xp',
        data: {'amount': amount, 'reason': reason},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to award XP: $e');
    }
  }

  Future<Map<String, dynamic>> checkStreak() async {
    try {
      final response = await _apiService.post(
        '/gamification/check-streak',
        data: {},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to check streak: $e');
    }
  }

  Future<List<LeaderboardEntry>> getLeaderboard({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await _apiService.get(
        '/gamification/leaderboard',
        queryParameters: {'page': page, 'limit': limit},
      );

      final List<dynamic> data = response.data;
      return data.map((json) => LeaderboardEntry.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch leaderboard: $e');
    }
  }

  Future<List<Badge>> getUserBadges() async {
    try {
      final response = await _apiService.get('/gamification/badges');

      final List<dynamic> data = response.data;
      return data.map((json) => Badge.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch badges: $e');
    }
  }
}
