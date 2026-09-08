import 'dart:async';
import 'package:flutter/foundation.dart';

/// Technology-agnostic interface for observing network connectivity state.
abstract class ConnectivityService {
  /// Whether the device currently has active internet connectivity.
  bool get isOnline;

  /// Whether the device is currently offline.
  bool get isOffline => !isOnline;

  /// Stream emitting connectivity status changes (true for online, false for offline).
  Stream<bool> get onConnectivityChanged;

  /// Manually override or toggle connectivity status (useful for simulation and testing).
  void setOnline(bool online);
}

/// Default in-memory / app connectivity service implementation.
class AppConnectivityService implements ConnectivityService {
  static final AppConnectivityService _instance = AppConnectivityService._internal();
  factory AppConnectivityService() => _instance;

  AppConnectivityService._internal();

  bool _isOnline = true;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  bool get isOnline => _isOnline;

  @override
  bool get isOffline => !_isOnline;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  void setOnline(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      debugPrint('[CivicFix Connectivity] Network state changed: ${online ? "ONLINE" : "OFFLINE"}');
      _controller.add(online);
    }
  }

  /// Reset to online state for test isolation.
  @visibleForTesting
  void resetForTesting({bool initialOnline = true}) {
    _isOnline = initialOnline;
  }
}
