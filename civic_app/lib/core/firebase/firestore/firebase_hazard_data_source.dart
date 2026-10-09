import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/complaint_model.dart';
import '../../models/hazard_model.dart';
import '../errors/firestore_error_handler.dart';
import '../firebase_constants.dart';
import '../mappers/hazard_firestore_mapper.dart';
import 'firestore_pagination.dart';

/// Remote Firestore Data Source for managing Live Hazard Map safety data.
class FirebaseHazardDataSource {
  final FirebaseFirestore? _firestore;

  FirebaseHazardDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _hazardsRef =>
      _db.collection(FirestoreCollections.hazards);

  /// Retrieves active community hazards with optional status, severity, and category filters.
  Future<FirestorePage<HazardModel>> getHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _hazardsRef;

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (severity != null) {
        query = query.where('severity', isEqualTo: severity.name);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      var items = snapshot.docs.map((doc) {
        return HazardFirestoreMapper.fromFirestore(
          documentId: doc.id,
          data: doc.data(),
        );
      }).toList();

      if (categoryId != null && categoryId.isNotEmpty && categoryId.toLowerCase() != 'all') {
        items = items.where((h) =>
            h.category.id.toLowerCase() == categoryId.toLowerCase() ||
            h.category.name.toLowerCase() == categoryId.toLowerCase()).toList();
      }

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

  /// Fetches hazards located in specific spatial chunks.
  Future<List<HazardModel>> getHazardsBySpatialChunks({
    required List<String> chunkIds,
    int limit = 100,
  }) async {
    try {
      if (chunkIds.isEmpty) return [];

      final List<List<String>> batches = [];
      for (var i = 0; i < chunkIds.length; i += 30) {
        batches.add(chunkIds.sublist(i, i + 30 > chunkIds.length ? chunkIds.length : i + 30));
      }

      final Map<String, HazardModel> dedup = {};

      for (final batch in batches) {
        final snap = await _hazardsRef
            .where('spatialChunkId', whereIn: batch)
            .limit(limit)
            .get();

        for (final doc in snap.docs) {
          dedup[doc.id] = HazardFirestoreMapper.fromFirestore(
            documentId: doc.id,
            data: doc.data(),
          );
        }
      }

      return dedup.values.toList();
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Fetches a single hazard document by ID.
  Future<HazardModel?> getHazardById(String id) async {
    try {
      final doc = await _hazardsRef.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        // Fallback: search by complaintId
        final query = await _hazardsRef.where('complaintId', isEqualTo: id).limit(1).get();
        if (query.docs.isNotEmpty) {
          return HazardFirestoreMapper.fromFirestore(
            documentId: query.docs.first.id,
            data: query.docs.first.data(),
          );
        }
        return null;
      }
      return HazardFirestoreMapper.fromFirestore(
        documentId: doc.id,
        data: doc.data()!,
      );
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Atomic community upvote increment on a hazard.
  Future<void> upvoteHazard(String hazardId) async {
    try {
      await _hazardsRef.doc(hazardId).update({
        'upvotes': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  // ===========================================================================
  // REAL-TIME FIRESTORE SNAPSHOT STREAMS (Prompt 8)
  // ===========================================================================

  /// Subscribes to real-time community hazards.
  Stream<List<HazardModel>> watchHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    int limit = 50,
  }) {
    try {
      Query<Map<String, dynamic>> query = _hazardsRef;

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (severity != null) {
        query = query.where('severity', isEqualTo: severity.name);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      return query.snapshots().map((snapshot) {
        var items = snapshot.docs.map((doc) {
          return HazardFirestoreMapper.fromFirestore(
            documentId: doc.id,
            data: doc.data(),
          );
        }).toList();

        if (categoryId != null &&
            categoryId.isNotEmpty &&
            categoryId.toLowerCase() != 'all') {
          items = items
              .where((h) =>
                  h.category.id.toLowerCase() == categoryId.toLowerCase() ||
                  h.category.name.toLowerCase() == categoryId.toLowerCase())
              .toList();
        }

        return items;
      });
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }
}

