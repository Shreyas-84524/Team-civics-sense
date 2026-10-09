import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/complaint_model.dart';
import '../../models/complaint_upvote_result.dart';
import '../../location/location_model.dart';
import '../errors/firestore_error_handler.dart';
import '../firebase_constants.dart';
import '../mappers/complaint_firestore_mapper.dart';
import '../mappers/firestore_mapper_helpers.dart';
import 'firestore_pagination.dart';

/// Remote Firestore Data Source for managing Civic Grievance complaints and timeline updates.
class FirebaseComplaintDataSource {
  final FirebaseFirestore? _firestore;

  FirebaseComplaintDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _complaintsRef =>
      _db.collection(FirestoreCollections.complaints);

  /// Creates a new complaint document and initial status update atomically in a single batch.
  Future<ComplaintModel> createComplaint(ComplaintModel complaint) async {
    try {
      final docRef = complaint.id.isNotEmpty && !complaint.id.startsWith('cmp_')
          ? _complaintsRef.doc(complaint.id)
          : _complaintsRef.doc();

      final data = ComplaintFirestoreMapper.toFirestore(
        complaint,
        isCreate: true,
      );
      data['localId'] = complaint.id;

      final initialStatus = complaint.status == ComplaintStatus.underVerification
          ? ComplaintStatus.underVerification
          : ComplaintStatus.reported;
      data['status'] = initialStatus.name;
      data['upvotes'] = 0;

      // Create initial timeline audit event
      final initialEvent = TimelineEvent(
        title: initialStatus == ComplaintStatus.underVerification ? 'Grievance Submitted' : 'Issue Reported',
        description:
            'Ticket created and queued for two-stage verification.',
        timestamp: DateTime.now(),
        status: initialStatus,
        updatedBy: complaint.citizenId,
      );

      final timelineRef = docRef
          .collection(FirestoreCollections.complaintUpdates)
          .doc();
      final timelineData = ComplaintFirestoreMapper.timelineEventToFirestore(
        initialEvent,
      );

      // Perform atomic batch write ensuring complaint and timeline are created together
      final batch = _db.batch();
      batch.set(docRef, data);
      batch.set(timelineRef, timelineData);
      await batch.commit();

      return ComplaintFirestoreMapper.fromFirestore(
        documentId: docRef.id,
        data: data,
        timeline: [initialEvent],
      );
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Fetches a single complaint document by ID with its chronological timeline updates.
  Future<ComplaintModel?> getComplaintById(
    String id, {
    bool includeTimeline = true,
  }) async {
    try {
      final doc = await _complaintsRef.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        // Fallback: search by ticketNumber or localId
        return await getComplaintByTicketNumber(id);
      }

      List<TimelineEvent> timeline = [];
      if (includeTimeline) {
        timeline = await getComplaintTimeline(id);
      }

      return ComplaintFirestoreMapper.fromFirestore(
        documentId: doc.id,
        data: doc.data()!,
        timeline: timeline,
      );
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Queries a complaint by human-readable ticket number (e.g. 'CF-2026-000024').
  Future<ComplaintModel?> getComplaintByTicketNumber(
    String ticketNumber,
  ) async {
    try {
      final query = await _complaintsRef
          .where('ticketNumber', isEqualTo: ticketNumber)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      final timeline = await getComplaintTimeline(doc.id);

      return ComplaintFirestoreMapper.fromFirestore(
        documentId: doc.id,
        data: doc.data(),
        timeline: timeline,
      );
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Retrieves chronological complaints filed by a specific citizen with cursor pagination.
  Future<FirestorePage<ComplaintModel>> getCitizenComplaints({
    required String citizenId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _complaintsRef
          .where('citizenId', isEqualTo: citizenId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final items = snapshot.docs.map((doc) {
        return ComplaintFirestoreMapper.fromFirestore(
          documentId: doc.id,
          data: doc.data(),
        );
      }).toList();

      final hasMore = snapshot.docs.length == limit;
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return FirestorePage(
        items: items,
        hasMore: hasMore,
        lastDocument: lastDoc,
        totalCount: items.length,
      );
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Retrieves filtered complaints for the Government portal dashboard and triage lists.
  Future<FirestorePage<ComplaintModel>> getGovernmentComplaints({
    String? departmentId,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    String? assignedTo,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _complaintsRef;

      if (departmentId != null &&
          departmentId.isNotEmpty &&
          departmentId != 'all') {
        query = query.where('departmentId', isEqualTo: departmentId);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (priority != null) {
        query = query.where('priority', isEqualTo: priority.name);
      }

      if (assignedTo != null && assignedTo.isNotEmpty) {
        query = query.where('assignedTo', isEqualTo: assignedTo);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final items = snapshot.docs.map((doc) {
        return ComplaintFirestoreMapper.fromFirestore(
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

  /// Fetches subcollection timeline entries for a complaint.
  Future<List<TimelineEvent>> getComplaintTimeline(String complaintId) async {
    try {
      final snapshot = await _complaintsRef
          .doc(complaintId)
          .collection(FirestoreCollections.complaintUpdates)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map(
            (d) =>
                ComplaintFirestoreMapper.timelineEventFromFirestore(d.data()),
          )
          .toList();
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Appends a new immutable timeline audit event.
  Future<void> addTimelineEvent(String complaintId, TimelineEvent event) async {
    try {
      await _complaintsRef
          .doc(complaintId)
          .collection(FirestoreCollections.complaintUpdates)
          .add(ComplaintFirestoreMapper.timelineEventToFirestore(event));
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Updates allowed citizen-editable fields on an existing reported/verified complaint.
  Future<void> updateCitizenComplaint(
    String complaintId, {
    String? title,
    String? description,
    List<String>? imageUrls,
    CivicLocation? location,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (imageUrls != null) updates['imageUrls'] = imageUrls;
      if (location != null) {
        updates['location'] = FirestoreMapperHelpers.locationToMap(location);
      }

      await _complaintsRef.doc(complaintId).update(updates);
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Updates government administrative workflow status, assignment, and officer notes.
  Future<void> updateGovernmentWorkflow(
    String complaintId, {
    ComplaintStatus? status,
    ComplaintPriority? priority,
    String? assignedTo,
    String? departmentId,
    String? departmentName,
    String? officerNotes,
    DateTime? resolvedAt,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status != null) updates['status'] = status.name;
      if (priority != null) updates['priority'] = priority.name;
      if (assignedTo != null) updates['assignedTo'] = assignedTo;
      if (departmentId != null) updates['departmentId'] = departmentId;
      if (departmentName != null) updates['departmentName'] = departmentName;
      if (officerNotes != null) updates['officerNotes'] = officerNotes;
      if (resolvedAt != null) {
        updates['resolvedAt'] = FirestoreMapperHelpers.dateTimeToTimestamp(
          resolvedAt,
        );
      }

      await _complaintsRef.doc(complaintId).update(updates);
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Atomic community upvote increment on a complaint with user deduplication.
  Future<ComplaintUpvoteResult> upvoteComplaint(
    String complaintId, {
    required String userId,
  }) async {
    try {
      if (userId.trim().isEmpty) {
        throw StateError('You must be signed in to support a complaint.');
      }

      final docRef = _complaintsRef.doc(complaintId);
      final upvoteRef = docRef.collection('upvotes').doc(userId);

      return await _db.runTransaction((transaction) async {
        // Firestore transactions require every read to happen before writes.
        final complaintSnapshot = await transaction.get(docRef);
        final upvoteSnapshot = await transaction.get(upvoteRef);

        if (!complaintSnapshot.exists) {
          throw StateError('Complaint not found.');
        }

        final currentCount =
            (complaintSnapshot.data()?['upvotes'] as num?)?.toInt() ?? 0;
        if (upvoteSnapshot.exists) {
          return ComplaintUpvoteResult(added: false, upvotes: currentCount);
        }

        final updatedCount = currentCount + 1;
        transaction.set(upvoteRef, {
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        transaction.update(docRef, {
          'upvotes': updatedCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return ComplaintUpvoteResult(added: true, upvotes: updatedCount);
      });
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Checks if a user has already upvoted a complaint.
  Future<bool> hasUserUpvoted(String complaintId, String userId) async {
    try {
      if (userId.isEmpty) return false;
      final doc = await _complaintsRef
          .doc(complaintId)
          .collection('upvotes')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Fetches active community hazards directly from complaints marked isHazard == true.
  Future<List<ComplaintModel>> getNearbyHazards({int limit = 50}) async {
    try {
      final snapshot = await _complaintsRef
          .where('isHazard', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => ComplaintFirestoreMapper.fromFirestore(
              documentId: doc.id,
              data: doc.data(),
            ),
          )
          .toList();
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  // ===========================================================================
  // REAL-TIME FIRESTORE SNAPSHOT STREAMS (Prompt 8)
  // ===========================================================================

  /// Subscribes to real-time document snapshots for an individual complaint.
  Stream<ComplaintModel?> watchComplaint(String id) {
    try {
      return _complaintsRef.doc(id).snapshots().asyncMap((doc) async {
        if (!doc.exists || doc.data() == null) return null;
        final timeline = await getComplaintTimeline(doc.id);
        return ComplaintFirestoreMapper.fromFirestore(
          documentId: doc.id,
          data: doc.data()!,
          timeline: timeline,
        );
      });
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Subscribes to real-time updates for a complaint's timeline subcollection.
  Stream<List<TimelineEvent>> watchComplaintTimeline(String complaintId) {
    try {
      return _complaintsRef
          .doc(complaintId)
          .collection(FirestoreCollections.complaintUpdates)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map(
                  (d) => ComplaintFirestoreMapper.timelineEventFromFirestore(
                    d.data(),
                  ),
                )
                .toList();
          });
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Subscribes to real-time complaints filed by a specific authenticated citizen.
  Stream<List<ComplaintModel>> watchCitizenComplaints({
    required String citizenId,
    int limit = 50,
  }) {
    try {
      return _complaintsRef
          .where('citizenId', isEqualTo: citizenId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return ComplaintFirestoreMapper.fromFirestore(
                documentId: doc.id,
                data: doc.data(),
              );
            }).toList();
          });
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Subscribes to real-time filtered complaints for municipal government triage.
  Stream<List<ComplaintModel>> watchGovernmentComplaints({
    String? departmentId,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    String? assignedTo,
    int limit = 50,
  }) {
    try {
      Query<Map<String, dynamic>> query = _complaintsRef;

      if (departmentId != null &&
          departmentId.isNotEmpty &&
          departmentId != 'all') {
        query = query.where('departmentId', isEqualTo: departmentId);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (priority != null) {
        query = query.where('priority', isEqualTo: priority.name);
      }

      if (assignedTo != null && assignedTo.isNotEmpty) {
        query = query.where('assignedTo', isEqualTo: assignedTo);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return ComplaintFirestoreMapper.fromFirestore(
            documentId: doc.id,
            data: doc.data(),
          );
        }).toList();
      });
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Fetches citizen-visible complaints (public hazards where isHazard == true + current citizen's own complaints)
  /// without triggering Firestore PERMISSION_DENIED on unfiltered collection scans.
  Future<List<ComplaintModel>> getCitizenVisibleComplaints({
    String? citizenId,
    int limit = 100,
  }) async {
    try {
      if (citizenId == null || citizenId.isEmpty) {
        return await getNearbyHazards(limit: limit);
      }

      final futures = await Future.wait([
        getNearbyHazards(limit: limit),
        _complaintsRef
            .where('citizenId', isEqualTo: citizenId)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get(),
      ]);

      final hazards = futures[0] as List<ComplaintModel>;
      final ownDocs = futures[1] as QuerySnapshot<Map<String, dynamic>>;
      final ownComplaints = ownDocs.docs.map((doc) {
        return ComplaintFirestoreMapper.fromFirestore(
          documentId: doc.id,
          data: doc.data(),
        );
      }).toList();

      final Map<String, ComplaintModel> dedup = {};
      for (final c in hazards) {
        dedup[c.id] = c;
      }
      for (final c in ownComplaints) {
        dedup[c.id] = c;
      }

      final merged = dedup.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (merged.length > limit) {
        return merged.sublist(0, limit);
      }
      return merged;
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Subscribes to real-time community hazards.
  Stream<List<ComplaintModel>> watchNearbyHazards({int limit = 50}) {
    try {
      return _complaintsRef
          .where('isHazard', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return ComplaintFirestoreMapper.fromFirestore(
                documentId: doc.id,
                data: doc.data(),
              );
            }).toList();
          });
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }

  /// Subscribes to real-time citizen-visible complaints (public hazards + citizen's own complaints).
  Stream<List<ComplaintModel>> watchCitizenVisibleComplaints({
    String? citizenId,
    int limit = 100,
  }) {
    try {
      // Validate Firestore reference access
      final _ = _complaintsRef;

      if (citizenId == null || citizenId.isEmpty) {
        return watchNearbyHazards(limit: limit);
      }

      late StreamController<List<ComplaintModel>> controller;
      StreamSubscription<List<ComplaintModel>>? hazardsSub;
      StreamSubscription<List<ComplaintModel>>? ownSub;
      List<ComplaintModel> latestHazards = [];
      List<ComplaintModel> latestOwn = [];

      void emitMerged() {
        if (controller.isClosed) return;
        final Map<String, ComplaintModel> dedupMap = {};
        for (final c in latestHazards) {
          dedupMap[c.id] = c;
        }
        for (final c in latestOwn) {
          dedupMap[c.id] = c;
        }
        final merged = dedupMap.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (merged.length > limit) {
          controller.add(merged.sublist(0, limit));
        } else {
          controller.add(merged);
        }
      }

      controller = StreamController<List<ComplaintModel>>.broadcast(
        onListen: () {
          try {
            hazardsSub = watchNearbyHazards(limit: limit).listen(
              (hazards) {
                latestHazards = hazards;
                emitMerged();
              },
              onError: (err, st) {
                if (!controller.isClosed) controller.addError(err, st);
              },
            );
          } catch (e, st) {
            if (!controller.isClosed) controller.addError(e, st);
          }

          try {
            ownSub = watchCitizenComplaints(citizenId: citizenId, limit: limit).listen(
              (own) {
                latestOwn = own;
                emitMerged();
              },
              onError: (err, st) {
                if (!controller.isClosed) controller.addError(err, st);
              },
            );
          } catch (e, st) {
            if (!controller.isClosed) controller.addError(e, st);
          }
        },
        onCancel: () async {
          await hazardsSub?.cancel();
          await ownSub?.cancel();
        },
      );

      return controller.stream;
    } catch (e, st) {
      throw FirestoreErrorHandler.handle(e, st);
    }
  }
}
