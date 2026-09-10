import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import '../errors/firestore_error_handler.dart';
import '../firebase_constants.dart';
import '../mappers/notification_firestore_mapper.dart';
import 'firestore_pagination.dart';

/// Remote Firestore Data Source for managing Citizen Notifications.
class FirebaseNotificationDataSource {
  final FirebaseFirestore? _firestore;

  FirebaseNotificationDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _db.collection(FirestoreCollections.notifications);

  /// Retrieves chronological notifications for a specific citizen with cursor pagination.
  Future<FirestorePage<NotificationModel>> getUserNotifications({
    required String userId,
    bool? unreadOnly,
    int limit = 30,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _notificationsRef
          .where('userId', isEqualTo: userId);

      if (unreadOnly == true) {
        query = query.where('isRead', isEqualTo: false);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final items = snapshot.docs.map((doc) {
        return NotificationFirestoreMapper.fromFirestore(
          documentId: doc.id,
          data: doc.data(),
        );
      }).toList();

      return FirestorePage(
        items: items,
        hasMore: snapshot.docs.length == limit,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        totalCount: items.length,
      );
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Batch marks all unread notifications for a citizen as read.
  Future<void> markAllAsRead(String userId) async {
    try {
      final unreadSnapshot = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .limit(100)
          .get();

      if (unreadSnapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in unreadSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Returns the total unread notification count for a citizen.
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  // ===========================================================================
  // REAL-TIME FIRESTORE SNAPSHOT STREAMS (Prompt 8)
  // ===========================================================================

  /// Subscribes to real-time chronological notifications for a specific citizen.
  Stream<List<NotificationModel>> watchUserNotifications({
    required String userId,
    bool? unreadOnly,
    int limit = 50,
  }) {
    try {
      Query<Map<String, dynamic>> query = _notificationsRef
          .where('userId', isEqualTo: userId);

      if (unreadOnly == true) {
        query = query.where('isRead', isEqualTo: false);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return NotificationFirestoreMapper.fromFirestore(
            documentId: doc.id,
            data: doc.data(),
          );
        }).toList();
      });
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Subscribes to the real-time unread notification count for a citizen.
  Stream<int> watchUnreadCount(String userId) {
    try {
      return _notificationsRef
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }
}

