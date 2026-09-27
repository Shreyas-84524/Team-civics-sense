import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_constants.dart';
import '../models/government_audit_log_model.dart';

/// Abstract service for recording immutable administrative audit logs.
abstract class GovernmentAuditService {
  Future<void> logAction({
    required String complaintId,
    required String action,
    required String actorId,
    required String actorRole,
    required String actorName,
    String? wardId,
    String? departmentId,
    Map<String, dynamic> details = const {},
  });

  Future<List<GovernmentAuditLog>> getLogsForComplaint(String complaintId);
}

/// In-memory and Firestore-capable implementation of [GovernmentAuditService].
class DefaultGovernmentAuditService implements GovernmentAuditService {
  static final DefaultGovernmentAuditService _instance =
      DefaultGovernmentAuditService._internal();
  factory DefaultGovernmentAuditService({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      _instance._firestore = firestore;
    }
    return _instance;
  }
  DefaultGovernmentAuditService._internal();

  FirebaseFirestore? _firestore;
  final List<GovernmentAuditLog> _inMemoryLogs = [];

  @override
  Future<void> logAction({
    required String complaintId,
    required String action,
    required String actorId,
    required String actorRole,
    required String actorName,
    String? wardId,
    String? departmentId,
    Map<String, dynamic> details = const {},
  }) async {
    final logId = 'audit_${DateTime.now().millisecondsSinceEpoch}_${_inMemoryLogs.length + 1}';
    final log = GovernmentAuditLog(
      id: logId,
      complaintId: complaintId,
      action: action,
      actorId: actorId,
      actorRole: actorRole,
      actorName: actorName,
      wardId: wardId,
      departmentId: departmentId,
      details: details,
      timestamp: DateTime.now(),
    );

    _inMemoryLogs.add(log);

    // If Firestore is available and initialized, attempt remote write
    if (_firestore != null) {
      try {
        await _firestore!
            .collection(FirestoreCollections.governmentAuditLogs)
            .doc(log.id)
            .set(log.toMap());
      } catch (_) {
        // Fallback gracefully to in-memory logging
      }
    }
  }

  @override
  Future<List<GovernmentAuditLog>> getLogsForComplaint(String complaintId) async {
    if (_firestore != null) {
      try {
        final query = await _firestore!
            .collection(FirestoreCollections.governmentAuditLogs)
            .where('complaintId', isEqualTo: complaintId)
            .orderBy('timestamp', descending: true)
            .get();

        if (query.docs.isNotEmpty) {
          return query.docs
              .map((d) => GovernmentAuditLog.fromMap(d.data()))
              .toList();
        }
      } catch (_) {
        // Fallback to in-memory
      }
    }

    return _inMemoryLogs
        .where((l) => l.complaintId == complaintId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Clears in-memory logs (for testing).
  void clear() {
    _inMemoryLogs.clear();
  }
}
