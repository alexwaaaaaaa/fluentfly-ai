import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/badge.dart';
import '../models/leaderboard_entry.dart';
import '../models/progress.dart';
import '../services/gamification_service.dart';
import '../services/progress_service.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return GamificationService(apiService);
});

final progressServiceProvider = Provider<ProgressService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProgressService(apiService);
});

final userBadgesProvider = FutureProvider<List<Badge>>((ref) async {
  final gamificationService = ref.watch(gamificationServiceProvider);
  return await gamificationService.getUserBadges();
});

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, int>((
  ref,
  page,
) async {
  final gamificationService = ref.watch(gamificationServiceProvider);
  return await gamificationService.getLeaderboard(page: page);
});

final userProgressListProvider = FutureProvider<List<Progress>>((ref) async {
  final progressService = ref.watch(progressServiceProvider);
  return await progressService.getProgress();
});

final progressStatsProvider = FutureProvider<ProgressStats>((ref) async {
  final progressService = ref.watch(progressServiceProvider);
  return await progressService.getStats();
});

final lessonProgressProvider = FutureProvider.family<Progress?, int>((
  ref,
  lessonId,
) async {
  final progressService = ref.watch(progressServiceProvider);
  return await progressService.getProgressByLesson(lessonId);
});

class ProgressState {
  final User? user;
  final List<Badge> badges;
  final bool isLoading;
  final String? error;

  ProgressState({
    this.user,
    this.badges = const [],
    this.isLoading = false,
    this.error,
  });

  ProgressState copyWith({
    User? user,
    List<Badge>? badges,
    bool? isLoading,
    String? error,
  }) {
    return ProgressState(
      user: user ?? this.user,
      badges: badges ?? this.badges,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  final GamificationService _gamificationService;
  final Ref _ref;

  ProgressNotifier(this._gamificationService, this._ref)
    : super(ProgressState());

  Future<void> loadUserProgress() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _ref.read(authProvider).user;
      final badges = await _gamificationService.getUserBadges();

      state = state.copyWith(user: user, badges: badges, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> checkStreak() async {
    try {
      await _gamificationService.checkStreak();
      await loadUserProgress();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> awardXp(int amount, String reason) async {
    try {
      await _gamificationService.awardXp(amount, reason);
      await loadUserProgress();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final progressProvider = StateNotifierProvider<ProgressNotifier, ProgressState>(
  (ref) {
    final gamificationService = ref.watch(gamificationServiceProvider);
    return ProgressNotifier(gamificationService, ref);
  },
);
