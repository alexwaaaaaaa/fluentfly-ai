import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();
  final _logger = Logger();

  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService._internal();

  /// Initialize connectivity monitoring
  Future<void> init() async {
    // Check initial connectivity
    await _updateConnectivityStatus();

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _handleConnectivityChange(results);
    });

    _logger.d('Connectivity service initialized');
  }

  Future<void> _updateConnectivityStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      _logger.e('Error checking connectivity: $e');
      _isOnline = false;
      _connectivityController.add(false);
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // Check if any connection is available
    _isOnline = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );

    // Only emit if status changed
    if (wasOnline != _isOnline) {
      _logger.d('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
      _connectivityController.add(_isOnline);
    }
  }

  /// Check if device is currently online
  Future<bool> checkConnectivity() async {
    await _updateConnectivityStatus();
    return _isOnline;
  }

  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
