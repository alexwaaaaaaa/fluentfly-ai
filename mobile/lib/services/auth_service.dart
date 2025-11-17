import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../models/auth_response.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  final _logger = Logger();

  Future<AuthResponse> googleAuth(String idToken) async {
    try {
      final response = await _apiService.post(
        '/auth/google',
        data: {'idToken': idToken},
        enableRetry: false, // Don't retry auth requests
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _saveTokens(authResponse);
      return authResponse;
    } catch (e, stackTrace) {
      _logger.e(
        'Google authentication failed',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to authenticate with Google. Please try again.');
    }
  }

  Future<bool> sendOtp(String phone) async {
    try {
      final response = await _apiService.post(
        '/auth/phone/send-otp',
        data: {'phone': phone},
        enableRetry: true,
      );

      return response.data['success'] == true;
    } catch (e, stackTrace) {
      _logger.e('Failed to send OTP', error: e, stackTrace: stackTrace);
      throw Exception(
        'Failed to send OTP. Please check your phone number and try again.',
      );
    }
  }

  Future<AuthResponse> verifyOtp(
    String phone,
    String otp, {
    String? name,
    String? learningPurpose,
    String? englishLevel,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/phone/verify-otp',
        data: {
          'phone': phone,
          'otp': otp,
          if (name != null) 'name': name,
          if (learningPurpose != null) 'learningPurpose': learningPurpose,
          if (englishLevel != null) 'englishLevel': englishLevel,
        },
        enableRetry: false, // Don't retry OTP verification
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _saveTokens(authResponse);
      return authResponse;
    } catch (e, stackTrace) {
      _logger.e('OTP verification failed', error: e, stackTrace: stackTrace);
      throw Exception('Invalid OTP. Please check the code and try again.');
    }
  }

  Future<void> _saveTokens(AuthResponse authResponse) async {
    await _storage.write(key: 'access_token', value: authResponse.accessToken);
    await _storage.write(
      key: 'refresh_token',
      value: authResponse.refreshToken,
    );
    await _storage.write(
      key: 'user_id',
      value: authResponse.user.id.toString(),
    );
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');
    _logger.i('User logged out');
  }
}
