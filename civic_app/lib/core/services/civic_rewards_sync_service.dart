import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Authoritative response status from the backend reward pipeline.
class RewardSyncResponse {
  final String status; // 'committed', 'already_awarded', 'pending', 'failed'
  final int pointsAwarded;
  final String? stage;
  final String? reason;
  final int? newTotalPoints;
  final String? achievement;
  final int? supportedCount;

  const RewardSyncResponse({
    required this.status,
    this.pointsAwarded = 0,
    this.stage,
    this.reason,
    this.newTotalPoints,
    this.achievement,
    this.supportedCount,
  });

  bool get isCommitted => status == 'committed';
  bool get isAlreadyAwarded => status == 'already_awarded';
  bool get isSuccess => isCommitted || isAlreadyAwarded;
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'pending';

  factory RewardSyncResponse.fromJson(Map<String, dynamic> json) {
    return RewardSyncResponse(
      status: json['status'] as String? ?? 'failed',
      pointsAwarded: (json['pointsAwarded'] as num?)?.toInt() ?? 0,
      stage: json['stage'] as String?,
      reason: json['reason'] as String?,
      newTotalPoints: (json['newTotalPoints'] as num?)?.toInt(),
      achievement: json['achievement'] as String?,
      supportedCount: (json['supportedCount'] as num?)?.toInt(),
    );
  }

  factory RewardSyncResponse.failed(String reason) {
    return RewardSyncResponse(status: 'failed', reason: reason);
  }

  factory RewardSyncResponse.pending() {
    return const RewardSyncResponse(status: 'pending');
  }

  @override
  String toString() =>
      'RewardSyncResponse(status: $status, pointsAwarded: $pointsAwarded, stage: $stage, reason: $reason)';
}

/// Requests evaluation of saved server data; clients never specify points.
class CivicRewardsSyncService {
  static const String _endpointUrl =
      'https://hkgwsqasmboadvpjckbj.supabase.co/functions/v1/sync-civic-rewards';

  /// Records a lifecycle stage progression action on a complaint with the authoritative backend.
  static Future<RewardSyncResponse> recordLifecycleAction({
    required String complaintId,
    required String action,
    http.Client? client,
  }) async {
    try {
      String? token;
      try {
        token = await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (_) {}
      if (token == null) {
        return RewardSyncResponse.failed('User not authenticated');
      }

      final httpClient = client ?? http.Client();
      try {
        final response = await httpClient.post(
          Uri.parse(_endpointUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'complaintId': complaintId,
            'action': action,
          }),
        ).timeout(const Duration(seconds: 40));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return RewardSyncResponse.fromJson(data);
        } else {
          try {
            final dynamic errorBody = jsonDecode(response.body);
            final reason = (errorBody is Map ? (errorBody['message'] ?? errorBody['error']) : null) ??
                'Server responded with status ${response.statusCode}';
            return RewardSyncResponse.failed(reason.toString());
          } catch (_) {
            return RewardSyncResponse.failed('Server responded with status ${response.statusCode}');
          }
        }
      } finally {
        if (client == null) {
          httpClient.close();
        }
      }
    } catch (e) {
      debugPrint('[CivicRewardsSyncService] recordLifecycleAction error: $e');
      return RewardSyncResponse.failed(e.toString());
    }
  }

  /// Records a community upvote action with the authoritative backend.
  static Future<RewardSyncResponse> recordUpvoteAction({
    required String complaintId,
    http.Client? client,
  }) async {
    return recordLifecycleAction(
      complaintId: complaintId,
      action: 'upvote',
      client: client,
    );
  }

  /// Explicit administrative or manual historical reconciliation.
  /// (Does not run automatically upon viewing the rewards screen).
  static Future<RewardSyncResponse> reconcile({
    String? citizenId,
    http.Client? client,
  }) async {
    try {
      String? token;
      try {
        token = await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (_) {}
      if (token == null) {
        return RewardSyncResponse.failed('User not authenticated');
      }

      final httpClient = client ?? http.Client();
      try {
        final response = await httpClient.post(
          Uri.parse(_endpointUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'mode': 'reconcile',
            'citizenId': ?citizenId,
          }),
        ).timeout(const Duration(seconds: 40));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return RewardSyncResponse.fromJson(data);
        } else {
          return RewardSyncResponse.failed('Reconciliation failed: ${response.statusCode}');
        }
      } finally {
        if (client == null) {
          httpClient.close();
        }
      }
    } catch (e) {
      return RewardSyncResponse.failed(e.toString());
    }
  }

  /// Backwards-compatible legacy sync call.
  /// Deprecated: Prefer [recordLifecycleAction] or explicit [reconcile].
  static Future<bool> sync({String? complaintId}) async {
    if (complaintId != null) {
      final res = await recordLifecycleAction(complaintId: complaintId, action: 'submitted');
      return res.isSuccess;
    }
    // Opening screen without complaintId must NOT silently trigger backfill.
    return true;
  }
}

