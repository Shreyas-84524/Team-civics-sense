import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../models/notification_model.dart';
import '../routing/app_routes.dart';
import 'notification_service.dart';

/// In-app banner presenter and mock implementation of [NotificationService].
class MockNotificationService implements NotificationService {
  MockNotificationService({GlobalKey<NavigatorState>? navigatorKey})
      : _navigatorKey = navigatorKey;

  static final MockNotificationService _instance = MockNotificationService._internal();
  factory MockNotificationService.instance() => _instance;
  MockNotificationService._internal();

  GlobalKey<NavigatorState>? _navigatorKey;
  String? _mockToken = 'mock_fcm_token_device_001';
  final Set<String> _registeredUsers = {};

  final StreamController<String> _tokenRefreshController = StreamController<String>.broadcast();
  final StreamController<RemoteMessage> _messageController = StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> _messageOpenedAppController = StreamController<RemoteMessage>.broadcast();
  RemoteMessage? _initialMessage;

  // ===========================================================================
  // NOTIFICATION SERVICE CONTRACT IMPLEMENTATION
  // ===========================================================================

  @override
  Future<void> initialize({
    GlobalKey<NavigatorState>? navigatorKey,
    void Function(RemoteMessage)? onNotificationOpened,
    void Function(RemoteMessage)? onForegroundMessage,
  }) async {
    if (navigatorKey != null) {
      _navigatorKey = navigatorKey;
    }
  }

  @override
  Future<NotificationSettings?> requestPermission() async {
    // In mock/test environments, grant authorized permission
    return null;
  }

  @override
  Future<String?> getToken() async {
    return _mockToken;
  }

  @override
  Future<void> deleteToken() async {
    _mockToken = null;
  }

  @override
  Future<void> registerDeviceToken(String userId, {String? platform}) async {
    if (userId.isNotEmpty) {
      _registeredUsers.add(userId);
    }
  }

  @override
  Future<void> unregisterDeviceToken(String userId) async {
    _registeredUsers.remove(userId);
  }

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Stream<RemoteMessage> get onMessage => _messageController.stream;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => _messageOpenedAppController.stream;

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    return _initialMessage;
  }

  @override
  void handleNotificationNavigation(
    RemoteMessage message, {
    BuildContext? context,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    final nav = navigatorKey?.currentState ?? _navigatorKey?.currentState;
    final navContext = context ?? nav?.context;

    final data = message.data;
    final complaintId = data['complaintId'] as String?;
    final targetRoute = data['targetRoute'] as String?;
    final role = data['role'] as String?;
    final type = data['type'] as String?;

    if (targetRoute != null && targetRoute.isNotEmpty) {
      if (nav != null) {
        nav.pushNamed(targetRoute, arguments: complaintId ?? data);
      } else if (navContext != null) {
        Navigator.of(navContext).pushNamed(targetRoute, arguments: complaintId ?? data);
      }
      return;
    }

    if (complaintId != null && complaintId.isNotEmpty) {
      final isGovt = role == 'government' ||
          type == 'high_priority_complaint' ||
          type == 'new_complaint_assigned';

      final destinationRoute = isGovt ? AppRoutes.govtComplaintDetails : AppRoutes.complaintDetails;

      if (nav != null) {
        nav.pushNamed(destinationRoute, arguments: complaintId);
      } else if (navContext != null) {
        Navigator.of(navContext).pushNamed(destinationRoute, arguments: complaintId);
      }
      return;
    }

    if (nav != null) {
      nav.pushNamed(AppRoutes.notifications);
    } else if (navContext != null) {
      Navigator.of(navContext).pushNamed(AppRoutes.notifications);
    }
  }

  // ===========================================================================
  // TEST & SIMULATION HELPERS
  // ===========================================================================

  bool isUserRegistered(String userId) => _registeredUsers.contains(userId);

  void setMockToken(String? token) {
    _mockToken = token;
    if (token != null) {
      _tokenRefreshController.add(token);
    }
  }

  void setInitialMessage(RemoteMessage? message) {
    _initialMessage = message;
  }

  void simulateIncomingForegroundMessage(RemoteMessage message) {
    _messageController.add(message);
  }

  void simulateNotificationTapFromBackground(RemoteMessage message) {
    _messageOpenedAppController.add(message);
  }

  // ===========================================================================
  // IN-APP UI SNACKBAR BANNER (STATIC UTILITY)
  // ===========================================================================

  static void showInAppAlert(
    BuildContext context, {
    required String title,
    required String message,
    NotificationType type = NotificationType.statusUpdate,
    VoidCallback? onTap,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(CivicFixSpacing.lg),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.all(CivicFixSpacing.md),
          decoration: BoxDecoration(
            color: CivicFixColors.primary,
            borderRadius: CivicFixRadius.cardRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CivicFixSpacing.sm),
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.2),
                  borderRadius: CivicFixRadius.chipRadius,
                ),
                child: Icon(
                  type.icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              CivicFixSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: CivicFixTypography.bodySmallMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    CivicFixSpacing.vSpaceXs,
                    Text(
                      message,
                      style: CivicFixTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                TextButton(
                  onPressed: () {
                    scaffoldMessenger.hideCurrentSnackBar();
                    onTap();
                  },
                  child: Text(
                    'VIEW',
                    style: CivicFixTypography.captionMedium.copyWith(
                      color: CivicFixColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
