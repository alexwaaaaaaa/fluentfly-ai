import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Logger _logger = Logger();

  AuthNotifier(this._authService) : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isAuth = await _authService.isAuthenticated();
    if (isAuth) {
      // In a real app, you'd fetch the user data from the API
      // For now, we just mark as authenticated
      _logger.i('User is authenticated');
    }
  }

  Future<void> googleAuth(String idToken) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authResponse = await _authService.googleAuth(idToken);
      state = state.copyWith(user: authResponse.user, isLoading: false);
      _logger.i('Google authentication successful');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      _logger.e('Google authentication failed', error: e);
    }
  }

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _authService.sendOtp(phone);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      _logger.e('Failed to send OTP', error: e);
      return false;
    }
  }

  Future<void> verifyOtp(
    String phone,
    String otp, {
    String? name,
    String? learningPurpose,
    String? englishLevel,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authResponse = await _authService.verifyOtp(
        phone,
        otp,
        name: name,
        learningPurpose: learningPurpose,
        englishLevel: englishLevel,
      );
      state = state.copyWith(user: authResponse.user, isLoading: false);
      _logger.i('OTP verification successful');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      _logger.e('OTP verification failed', error: e);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
    _logger.i('User logged out');
  }

  Future<void> updateUserName(String name) async {
    if (state.user == null) return;

    try {
      // Update user name locally
      final updatedUser = User(
        id: state.user!.id,
        email: state.user!.email,
        phone: state.user!.phone,
        name: name,
        xp: state.user!.xp,
        streak: state.user!.streak,
        level: state.user!.level,
        profileImageUrl: state.user!.profileImageUrl,
      );

      state = state.copyWith(user: updatedUser);
      _logger.i('User name updated to: $name');

      // TODO: In a real app, you'd also update this on the backend
      // await _authService.updateUserProfile(name);
    } catch (e) {
      _logger.e('Failed to update user name', error: e);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('401')) {
      return 'Invalid credentials';
    } else if (error.toString().contains('400')) {
      return 'Invalid request. Please check your input.';
    } else if (error.toString().contains('Too many')) {
      return 'Too many attempts. Please try again later.';
    } else if (error.toString().contains('Network')) {
      return 'Network error. Please check your connection.';
    }
    return 'An error occurred. Please try again.';
  }
}

// Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
