import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';
import '../utils/error_handler.dart';
import '../utils/logger.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to requests
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          logger.logRequest(options.method, options.path);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          logger.logResponse(
            response.requestOptions.method,
            response.requestOptions.path,
            response.statusCode ?? 0,
          );
          return handler.next(response);
        },
        onError: (error, handler) async {
          logger.error(
            'API request failed: ${error.requestOptions.method} ${error.requestOptions.path}',
            error: error,
          );

          // Log detailed error information
          ErrorHandler.logError(
            error,
            context: 'API Request',
            additionalData: {
              'path': error.requestOptions.path,
              'method': error.requestOptions.method,
              'statusCode': error.response?.statusCode,
            },
          );

          // Handle 401 Unauthorized - try to refresh token
          // But don't retry if this IS the refresh endpoint or auth endpoints
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/')) {
            try {
              final refreshToken = await _storage.read(key: 'refresh_token');
              if (refreshToken != null && !_isRefreshing) {
                _isRefreshing = true;
                try {
                  final newTokens = await _refreshToken(refreshToken);
                  await _storage.write(
                    key: 'access_token',
                    value: newTokens['accessToken'],
                  );
                  await _storage.write(
                    key: 'refresh_token',
                    value: newTokens['refreshToken'],
                  );

                  // Retry the original request
                  final opts = Options(
                    method: error.requestOptions.method,
                    headers: {
                      ...error.requestOptions.headers,
                      'Authorization': 'Bearer ${newTokens['accessToken']}',
                    },
                  );
                  final response = await _dio.request(
                    error.requestOptions.path,
                    options: opts,
                    data: error.requestOptions.data,
                    queryParameters: error.requestOptions.queryParameters,
                  );
                  return handler.resolve(response);
                } finally {
                  _isRefreshing = false;
                }
              }
            } catch (e) {
              logger.error('Token refresh failed', error: e);
              // Clear tokens and redirect to login
              await _storage.delete(key: 'access_token');
              await _storage.delete(key: 'refresh_token');
              _isRefreshing = false;
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _refreshToken(String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Execute request with retry logic
  Future<Response> _executeWithRetry(
    Future<Response> Function() request, {
    bool enableRetry = true,
  }) async {
    if (!enableRetry) {
      return await request();
    }

    return await ErrorHandler.withRetry(
      request,
      maxAttempts: maxRetries,
      initialDelay: retryDelay,
      shouldRetry: (error) => ErrorHandler.isRetryable(error),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool enableRetry = true,
  }) {
    return _executeWithRetry(
      () => _dio.get(path, queryParameters: queryParameters),
      enableRetry: enableRetry,
    );
  }

  Future<Response> post(String path, {dynamic data, bool enableRetry = true}) {
    return _executeWithRetry(
      () => _dio.post(path, data: data),
      enableRetry: enableRetry,
    );
  }

  Future<Response> put(String path, {dynamic data, bool enableRetry = true}) {
    return _executeWithRetry(
      () => _dio.put(path, data: data),
      enableRetry: enableRetry,
    );
  }

  Future<Response> delete(String path, {bool enableRetry = false}) {
    return _executeWithRetry(() => _dio.delete(path), enableRetry: enableRetry);
  }

  Future<Response> uploadFile(String path, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    return _dio.post(path, data: formData);
  }

  /// Upload audio file for speech-to-text
  Future<Response> uploadAudio(String filePath) async {
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(filePath),
    });
    return _dio.post('/speech/stt', data: formData);
  }

  /// Get text-to-speech audio URL
  Future<String> getTextToSpeech(String text) async {
    final response = await _dio.post('/speech/tts', data: {'text': text});
    return response.data['audioUrl'] as String;
  }
}
