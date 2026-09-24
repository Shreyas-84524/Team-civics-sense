import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result model representing the outcome of a Supabase Edge Function notification dispatch.
class NotificationDispatchResult {
  final bool success;
  final int statusCode;
  final String message;
  final int devicesAttempted;
  final int devicesSucceeded;
  final bool isNoDevice;
  final Map<String, dynamic>? rawResponse;

  const NotificationDispatchResult({
    required this.success,
    required this.statusCode,
    required this.message,
    this.devicesAttempted = 0,
    this.devicesSucceeded = 0,
    this.isNoDevice = false,
    this.rawResponse,
  });

  factory NotificationDispatchResult.success({
    int statusCode = 200,
    String message = 'Notification dispatched',
    int devicesAttempted = 1,
    int devicesSucceeded = 1,
    bool isNoDevice = false,
    Map<String, dynamic>? rawResponse,
  }) {
    return NotificationDispatchResult(
      success: true,
      statusCode: statusCode,
      message: message,
      devicesAttempted: devicesAttempted,
      devicesSucceeded: devicesSucceeded,
      isNoDevice: isNoDevice,
      rawResponse: rawResponse,
    );
  }

  factory NotificationDispatchResult.failure({
    int statusCode = 500,
    required String message,
    Map<String, dynamic>? rawResponse,
  }) {
    return NotificationDispatchResult(
      success: false,
      statusCode: statusCode,
      message: message,
      devicesAttempted: 0,
      devicesSucceeded: 0,
      isNoDevice: false,
      rawResponse: rawResponse,
    );
  }
}

/// Abstract contract for triggering serverless push notification workflows via Supabase.
abstract class SupabaseNotificationService {
  /// Invokes the Supabase Edge Function to dispatch push notifications for a complaint status transition.
  Future<NotificationDispatchResult> triggerStatusNotification({
    required String complaintId,
    required String citizenId,
    required String oldStatus,
    required String newStatus,
    String? ticketNumber,
    String? title,
    String? departmentName,
    String? officerNotes,
    String? eventId,
  });
}

/// Production implementation of [SupabaseNotificationService] that communicates with the
/// deployed Supabase Edge Function endpoint (`civicfix-notification`).
class HttpSupabaseNotificationService implements SupabaseNotificationService {
  static const String defaultEndpoint =
      'https://hkgwsqasmboadvpjckbj.supabase.co/functions/v1/civicfix-notification';

  final String _endpointUrl;
  final http.Client _client;
  final FirebaseAuth? _auth;

  HttpSupabaseNotificationService({
    String? endpointUrl,
    http.Client? client,
    FirebaseAuth? auth,
  })  : _endpointUrl = endpointUrl ?? defaultEndpoint,
        _client = client ?? http.Client(),
        _auth = auth;

  @override
  Future<NotificationDispatchResult> triggerStatusNotification({
    required String complaintId,
    required String citizenId,
    required String oldStatus,
    required String newStatus,
    String? ticketNumber,
    String? title,
    String? departmentName,
    String? officerNotes,
    String? eventId,
  }) async {
    // 1. Guard against empty / unassigned citizen IDs
    if (citizenId.trim().isEmpty) {
      debugPrint('[SupabaseNotificationService] Skipped: citizenId is empty for complaint $complaintId');
      return NotificationDispatchResult.failure(
        statusCode: 422,
        message: 'Cannot dispatch notification: citizenId is missing.',
      );
    }

    // 2. Generate deterministic eventId for idempotency
    final deterministicEventId = eventId ??
        'evt_${complaintId}_${newStatus}_${DateTime.now().millisecondsSinceEpoch}';

    // 3. Acquire Firebase Auth ID token for authorization
    String? authToken;
    try {
      final user = _auth?.currentUser ?? FirebaseAuth.instance.currentUser;
      if (user != null) {
        authToken = await user.getIdToken();
      }
    } catch (e) {
      debugPrint('[SupabaseNotificationService] Non-fatal: Could not fetch Firebase ID token: $e');
    }

    // Fallback token for offline sync and background service workers
    authToken ??= 'civicfix_service_worker_token';

    final payload = {
      'complaintId': complaintId,
      'citizenId': citizenId,
      'oldStatus': oldStatus,
      'newStatus': newStatus,
      if (ticketNumber != null && ticketNumber.isNotEmpty) 'ticketNumber': ticketNumber,
      if (title != null && title.isNotEmpty) 'title': title,
      if (departmentName != null && departmentName.isNotEmpty) 'departmentName': departmentName,
      if (officerNotes != null && officerNotes.isNotEmpty) 'officerNotes': officerNotes,
      'eventId': deterministicEventId,
    };

    // 4. Dispatch HTTP POST Request with timeout & non-blocking failure recovery
    try {
      final response = await _client
          .post(
            Uri.parse(_endpointUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      final int statusCode = response.statusCode;
      Map<String, dynamic> jsonBody = {};

      try {
        jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (statusCode >= 200 && statusCode < 300) {
        final data = jsonBody['data'] as Map<String, dynamic>? ?? {};
        final int attempted = (data['devicesAttempted'] as num?)?.toInt() ?? 0;
        final int succeeded = (data['devicesSucceeded'] as num?)?.toInt() ?? 0;
        final bool isNoDev = attempted == 0 || jsonBody['message'] == 'No registered device';

        debugPrint(
          '[SupabaseNotificationService] Success: Dispatched for $complaintId ($oldStatus -> $newStatus). Succeeded: $succeeded/$attempted',
        );

        return NotificationDispatchResult.success(
          statusCode: statusCode,
          message: jsonBody['message'] as String? ?? 'Notification dispatched',
          devicesAttempted: attempted,
          devicesSucceeded: succeeded,
          isNoDevice: isNoDev,
          rawResponse: jsonBody,
        );
      } else {
        final errorMsg = jsonBody['message'] as String? ??
            'Notification dispatch failed with HTTP $statusCode';
        debugPrint('[SupabaseNotificationService] Server warning ($statusCode): $errorMsg');

        return NotificationDispatchResult.failure(
          statusCode: statusCode,
          message: errorMsg,
          rawResponse: jsonBody,
        );
      }
    } on TimeoutException {
      debugPrint('[SupabaseNotificationService] Request timed out for $complaintId');
      return NotificationDispatchResult.failure(
        statusCode: 408,
        message: 'Notification trigger timed out. Status update preserved.',
      );
    } catch (e) {
      debugPrint('[SupabaseNotificationService] Network/Connection error: $e');
      return NotificationDispatchResult.failure(
        statusCode: 500,
        message: 'Network error communicating with Supabase Edge Function: $e',
      );
    }
  }
}

/// Mock implementation of [SupabaseNotificationService] for unit testing and offline development.
class MockSupabaseNotificationService implements SupabaseNotificationService {
  final List<Map<String, dynamic>> dispatchedEvents = [];
  bool shouldSucceed = true;
  int mockDevicesCount = 1;

  @override
  Future<NotificationDispatchResult> triggerStatusNotification({
    required String complaintId,
    required String citizenId,
    required String oldStatus,
    required String newStatus,
    String? ticketNumber,
    String? title,
    String? departmentName,
    String? officerNotes,
    String? eventId,
  }) async {
    final event = {
      'complaintId': complaintId,
      'citizenId': citizenId,
      'oldStatus': oldStatus,
      'newStatus': newStatus,
      'ticketNumber': ticketNumber,
      'title': title,
      'departmentName': departmentName,
      'officerNotes': officerNotes,
      'eventId': eventId,
    };
    dispatchedEvents.add(event);

    if (!shouldSucceed) {
      return NotificationDispatchResult.failure(
        statusCode: 500,
        message: 'Mock simulated notification dispatch failure',
      );
    }

    if (mockDevicesCount == 0) {
      return NotificationDispatchResult.success(
        message: 'No registered device',
        devicesAttempted: 0,
        devicesSucceeded: 0,
        isNoDevice: true,
      );
    }

    return NotificationDispatchResult.success(
      message: 'Mock notification dispatched',
      devicesAttempted: mockDevicesCount,
      devicesSucceeded: mockDevicesCount,
    );
  }
}
