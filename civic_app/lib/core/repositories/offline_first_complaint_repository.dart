import 'dart:async';
import 'package:flutter/foundation.dart';
import '../auth/auth_service_locator.dart';
import '../firebase/firestore/firebase_complaint_data_source.dart';
import '../location/location_model.dart';
import '../models/category_model.dart';
import '../models/complaint_model.dart';
import '../network/connectivity_service.dart';
import '../sync/models/sync_queue_item.dart';
import '../sync/sync_manager.dart';
import 'complaint_repository.dart';
import 'hive_complaint_repository.dart';

/// Unified offline-first complaint repository for CivicFix.
///
/// Coordinates:
/// 1. **Hive Local Cache & Persistence** ([HiveComplaintRepository]) for instant UI reads/writes.
/// 2. **Firebase Firestore Remote Data Source** ([FirebaseComplaintDataSource]) for cloud reads & remote sync.
/// 3. **SyncManager Orchestration Engine** ([SyncManager]) for reliable background offline-to-online queue draining.
/// 4. **Connectivity Detection** ([ConnectivityService]) for smart stale-while-revalidate caching.
class OfflineFirstComplaintRepository implements ComplaintRepository {
  final HiveComplaintRepository _localRepo;
  final FirebaseComplaintDataSource _remoteDataSource;
  final SyncManager _syncManager;
  final ConnectivityService _connectivity;

  int _localTicketCounter = 24;
  DateTime? _lastRefreshedAt;

  OfflineFirstComplaintRepository({
    HiveComplaintRepository? localRepository,
    FirebaseComplaintDataSource? remoteDataSource,
    SyncManager? syncManager,
    ConnectivityService? connectivity,
  })  : _localRepo = localRepository ?? HiveComplaintRepository(),
        _remoteDataSource = remoteDataSource ?? FirebaseComplaintDataSource(),
        _syncManager = syncManager ?? SyncManager(),
        _connectivity = connectivity ?? AppConnectivityService();

  DateTime? get lastRefreshedAt => _lastRefreshedAt ?? _localRepo.lastCachedAt;
  HiveComplaintRepository get localRepository => _localRepo;
  FirebaseComplaintDataSource get remoteDataSource => _remoteDataSource;
  SyncManager get syncManager => _syncManager;
  ConnectivityService get connectivity => _connectivity;

  // ===========================================================================
  // READ STRATEGY: Stale-While-Revalidate (Cache First + Background Revalidate)
  // ===========================================================================

  @override
  Future<List<ComplaintModel>> getCitizenComplaints(String citizenId) async {
    // 1. Immediately read from Hive local cache
    final localList = await _localRepo.getCitizenComplaints(citizenId);

    // 2. If online, trigger remote sync & cache revalidation
    if (_connectivity.isOnline) {
      try {
        final remotePage = await _remoteDataSource.getCitizenComplaints(citizenId: citizenId);
        final merged = _mergeComplaints(localList, remotePage.items);
        await _localRepo.cacheComplaints(merged);
        _lastRefreshedAt = DateTime.now();
        return merged;
      } catch (e) {
        debugPrint('[OfflineFirstComplaintRepository] Background citizen complaints refresh failed (using cache): $e');
      }
    }

    return localList;
  }

  @override
  Future<List<ComplaintModel>> getComplaints() async {
    // 1. Immediately read from Hive local cache
    final localList = await _localRepo.getComplaints();

    // 2. If online, trigger remote fetch and merge
    if (_connectivity.isOnline) {
      try {
        final remotePage = await _remoteDataSource.getGovernmentComplaints(limit: 50);
        final merged = _mergeComplaints(localList, remotePage.items);
        await _localRepo.cacheComplaints(merged);
        _lastRefreshedAt = DateTime.now();
        return merged;
      } catch (e) {
        debugPrint('[OfflineFirstComplaintRepository] Background all complaints refresh failed (using cache): $e');
      }
    }

    return localList;
  }

  @override
  Future<ComplaintModel?> getComplaintById(String id) async {
    // 1. Check local Hive cache
    final local = await _localRepo.getComplaintById(id);
    if (local != null) {
      // If synced and online, attempt a refresh in background/online check
      if (local.syncStatus == SyncStatus.synced && _connectivity.isOnline) {
        try {
          final remoteTargetId = local.serverId ?? local.id;
          final remote = await _remoteDataSource.getComplaintById(remoteTargetId);
          if (remote != null) {
            final merged = _mergeSingleComplaint(local, remote);
            await _localRepo.cacheComplaints([merged]);
            return merged;
          }
        } catch (e) {
          debugPrint('[OfflineFirstComplaintRepository] Remote single getComplaintById failed: $e');
        }
      }
      return local;
    }

    // 2. Not in local cache; if online, fetch from remote Firestore
    if (_connectivity.isOnline) {
      try {
        final remote = await _remoteDataSource.getComplaintById(id);
        if (remote != null) {
          await _localRepo.cacheComplaints([remote]);
          return remote;
        }
      } catch (e) {
        debugPrint('[OfflineFirstComplaintRepository] Remote fallback lookup failed for $id: $e');
      }
    }

    return null;
  }

  @override
  Future<ComplaintModel?> getComplaintByTicketId(String ticketId) async {
    // 1. Check local Hive cache
    final local = await _localRepo.getComplaintByTicketId(ticketId);
    if (local != null) return local;

    // 2. Query remote by ticket number
    if (_connectivity.isOnline) {
      try {
        final remote = await _remoteDataSource.getComplaintByTicketNumber(ticketId);
        if (remote != null) {
          await _localRepo.cacheComplaints([remote]);
          return remote;
        }
      } catch (e) {
        debugPrint('[OfflineFirstComplaintRepository] Remote getComplaintByTicketId lookup failed: $e');
      }
    }

    return null;
  }

  @override
  Future<List<ComplaintModel>> getNearbyHazards() async {
    final localHazards = await _localRepo.getNearbyHazards();

    if (_connectivity.isOnline) {
      try {
        final remoteHazards = await _remoteDataSource.getNearbyHazards();
        final merged = _mergeComplaints(localHazards, remoteHazards);
        await _localRepo.cacheComplaints(merged);
        _lastRefreshedAt = DateTime.now();
        return merged.where((c) => c.isHazard || c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high).toList();
      } catch (e) {
        debugPrint('[OfflineFirstComplaintRepository] Remote hazards refresh failed: $e');
      }
    }

    return localHazards;
  }

  // ===========================================================================
  // WRITE STRATEGY: Instant Local Persistence + SyncManager Queue Mutation
  // ===========================================================================

  @override
  Future<ComplaintModel> createComplaint({
    required String citizenId,
    required String title,
    required String description,
    required CivicCategory category,
    required CivicLocation location,
    required ComplaintPriority priority,
    List<String> imageUrls = const [],
    bool isHazard = false,
  }) async {
    _localTicketCounter++;
    final formattedCounter = _localTicketCounter.toString().padLeft(6, '0');
    final localRef = 'LOCAL-2026-$formattedCounter';
    final newId = 'cmp_local_${DateTime.now().microsecondsSinceEpoch}_$formattedCounter';

    final initialComplaint = ComplaintModel(
      id: newId,
      citizenId: citizenId,
      ticketNumber: localRef,
      localId: localRef,
      title: title.trim(),
      description: description.trim(),
      category: category,
      status: ComplaintStatus.reported,
      priority: priority,
      location: location,
      imageUrls: List.unmodifiable(imageUrls),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isHazard: isHazard,
      upvotes: 0,
      syncStatus: SyncStatus.pending,
      timeline: [
        TimelineEvent(
          title: 'Issue Recorded',
          description: 'Saved locally on device. Queued for municipal synchronization.',
          timestamp: DateTime.now(),
          status: ComplaintStatus.reported,
        ),
      ],
    );

    // 1. Save immediately to Hive local storage & memory
    final saved = await _localRepo.saveOfflineComplaint(initialComplaint);

    // 2. Enqueue into SyncManager for remote synchronization
    await _syncManager.queueComplaintCreation(saved);

    // 3. Return domain model immediately (zero UI latency)
    return saved;
  }

  @override
  Future<ComplaintModel> saveOfflineComplaint(ComplaintModel complaint) async {
    final localRef = complaint.localId ?? complaint.ticketNumber;
    final targetStatus = complaint.syncStatus == SyncStatus.failed
        ? SyncStatus.failed
        : SyncStatus.pending;
    final offlineComplaint = complaint.copyWith(
      syncStatus: targetStatus,
      localId: localRef,
    );

    // 1. Persist in Hive
    final saved = await _localRepo.saveOfflineComplaint(offlineComplaint);

    // 2. Enqueue into SyncManager
    await _syncManager.queueComplaintCreation(saved);

    return saved;
  }


  @override
  Future<List<ComplaintModel>> getPendingComplaints() async {
    return _localRepo.getPendingComplaints();
  }

  @override
  Future<void> updateSyncStatus(
    String complaintId,
    SyncStatus status, {
    String? serverId,
  }) async {
    await _localRepo.updateSyncStatus(complaintId, status, serverId: serverId);
  }

  @override
  Future<void> upvoteComplaint(String id) async {
    // 1. Optimistically upvote in local Hive storage
    await _localRepo.upvoteComplaint(id);

    // 2. If online, dispatch remote upvote; otherwise enqueue task
    if (_connectivity.isOnline) {
      try {
        final complaint = await _localRepo.getComplaintById(id);
        final targetServerId = complaint?.serverId ?? id;
        final currentUid = AuthServiceLocator.citizenAuth.currentUid ??
            AuthServiceLocator.citizenAuth.currentUser?.id;
        await _remoteDataSource.upvoteComplaint(targetServerId, userId: currentUid);
      } catch (e) {
        debugPrint('[OfflineFirstComplaintRepository] Remote upvote failed, will queue: $e');
        _queueUpvoteOperation(id);
      }
    } else {
      _queueUpvoteOperation(id);
    }
  }

  void _queueUpvoteOperation(String id) {
    final item = SyncQueueItem(
      id: 'upvote_${id}_${DateTime.now().millisecondsSinceEpoch}',
      entityType: 'complaint',
      entityId: id,
      operation: SyncOperation.upvoteComplaint,
      payload: {'complaintId': id},
      createdAt: DateTime.now(),
      status: SyncQueueStatus.pending,
    );
    _syncManager.queue.enqueue(item);
  }

  /// Delete a complaint from both local storage and sync queue.
  Future<void> deleteComplaint(String id) async {
    await _localRepo.deleteComplaint(id);
  }

  /// Purge old temporary complaints from local cache that exceed maxAge.
  ///
  /// STRICT RULE: NEVER purges pending offline complaints (syncStatus == pending).
  Future<void> clearStaleComplaints({Duration maxAge = const Duration(days: 14)}) async {
    await _localRepo.clearStaleComplaints(maxAge: maxAge);
  }

  /// Explicitly force a remote refresh of citizen complaints.
  Future<List<ComplaintModel>> refreshCitizenComplaints(String citizenId) async {
    if (!_connectivity.isOnline) {
      return _localRepo.getCitizenComplaints(citizenId);
    }

    final localList = await _localRepo.getCitizenComplaints(citizenId);
    final remotePage = await _remoteDataSource.getCitizenComplaints(citizenId: citizenId);
    final merged = _mergeComplaints(localList, remotePage.items);
    await _localRepo.cacheComplaints(merged);
    _lastRefreshedAt = DateTime.now();
    return merged;
  }

  // ===========================================================================
  // DATA MERGE & CONFLICT RESOLUTION
  // ===========================================================================

  /// Intelligently merges a list of remote complaints with local cache.
  ///
  /// Merge Rules:
  /// - Pending local drafts (`syncStatus == pending` or `syncing`) are NEVER overwritten by older server data.
  /// - Server-authoritative fields (`ticketNumber`, `status`, `assignedTo`, `departmentName`, `officerNotes`, `resolvedAt`, `upvotes`) are updated on synced records.
  /// - Un-synced local records are preserved at the top of the list.
  List<ComplaintModel> _mergeComplaints(
    List<ComplaintModel> localList,
    List<ComplaintModel> remoteList,
  ) {
    final Map<String, ComplaintModel> mergedMap = {};

    // 1. Index local complaints by their unique keys
    for (final local in localList) {
      final key = local.serverId ?? local.localId ?? local.id;
      mergedMap[key] = local;
    }

    // 2. Process remote complaints
    for (final remote in remoteList) {
      // Check if this remote complaint matches a local item by serverId, localId, id, or ticketNumber
      String? matchingLocalKey;
      for (final entry in mergedMap.entries) {
        if (entry.value.serverId == remote.id ||
            (remote.localId != null && entry.value.localId == remote.localId) ||
            entry.value.id == remote.id ||
            entry.value.ticketNumber == remote.ticketNumber) {
          matchingLocalKey = entry.key;
          break;
        }
      }

      if (matchingLocalKey != null) {
        final existingLocal = mergedMap[matchingLocalKey]!;
        final mergedSingle = _mergeSingleComplaint(existingLocal, remote);
        mergedMap.remove(matchingLocalKey);
        mergedMap[mergedSingle.id] = mergedSingle;
      } else {
        // Brand new remote complaint from server
        mergedMap[remote.id] = remote.copyWith(syncStatus: SyncStatus.synced);
      }
    }

    final result = mergedMap.values.toList();
    // Sort: Pending items first, then by createdAt newest first
    result.sort((a, b) {
      if (a.syncStatus == SyncStatus.pending && b.syncStatus != SyncStatus.pending) return -1;
      if (b.syncStatus == SyncStatus.pending && a.syncStatus != SyncStatus.pending) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return result;
  }

  /// Merges a single local complaint record with an authoritative remote record.
  ComplaintModel _mergeSingleComplaint(ComplaintModel local, ComplaintModel remote) {
    if (local.syncStatus == SyncStatus.pending || local.syncStatus == SyncStatus.syncing) {
      // Local is actively pending: preserve local title, description, and images,
      // but adopt server ticketNumber, status, and serverId if available.
      return local.copyWith(
        serverId: remote.id,
        ticketNumber: remote.ticketNumber.isNotEmpty && !remote.ticketNumber.startsWith('LOCAL-')
            ? remote.ticketNumber
            : local.ticketNumber,
        status: remote.status,
        assignedTo: remote.assignedTo ?? local.assignedTo,
        departmentName: remote.departmentName ?? local.departmentName,
        officerNotes: remote.officerNotes ?? local.officerNotes,
        resolvedAt: remote.resolvedAt ?? local.resolvedAt,
        upvotes: remote.upvotes > local.upvotes ? remote.upvotes : local.upvotes,
        timeline: remote.timeline.isNotEmpty ? remote.timeline : local.timeline,
      );
    }

    // Local is synced: remote is fully authoritative
    return remote.copyWith(
      syncStatus: SyncStatus.synced,
      localId: local.localId ?? remote.localId,
    );
  }

  // ===========================================================================
  // REAL-TIME SYNCHRONIZATION STREAMS (Prompt 8)
  // ===========================================================================

  @override
  Stream<ComplaintModel?> watchComplaint(String id) async* {
    // 1. Emit local Hive cache immediately for instant UI
    final local = await _localRepo.getComplaintById(id);
    if (local != null) yield local;

    // 2. If offline or not available, yield from local watch stream
    if (!_connectivity.isOnline) {
      yield* _localRepo.watchComplaint(id);
      return;
    }

    // 3. Listen to remote Firestore document snapshots
    final remoteTargetId = local?.serverId ?? id;
    try {
      yield* _remoteDataSource.watchComplaint(remoteTargetId).asyncMap((remote) async {
        if (remote == null) return local;

        final currentLocal = await _localRepo.getComplaintById(id) ?? local;
        final merged = currentLocal != null
            ? _mergeSingleComplaint(currentLocal, remote)
            : remote.copyWith(syncStatus: SyncStatus.synced);

        // Update local Hive cache without triggering a sync push
        await _localRepo.cacheComplaints([merged]);
        return merged;
      });
    } catch (e) {
      debugPrint('[OfflineFirstComplaintRepository] watchComplaint fallback to local: $e');
      yield* _localRepo.watchComplaint(id);
    }
  }

  @override
  Stream<List<TimelineEvent>> watchComplaintTimeline(String complaintId) async* {
    final local = await _localRepo.getComplaintById(complaintId);
    if (local != null && local.timeline.isNotEmpty) {
      yield local.timeline;
    }

    if (!_connectivity.isOnline) {
      yield* _localRepo.watchComplaintTimeline(complaintId);
      return;
    }

    final remoteTargetId = local?.serverId ?? complaintId;
    try {
      yield* _remoteDataSource.watchComplaintTimeline(remoteTargetId).asyncMap((timeline) async {
        if (timeline.isNotEmpty) {
          final currentLocal = await _localRepo.getComplaintById(complaintId);
          if (currentLocal != null) {
            final updated = currentLocal.copyWith(timeline: timeline);
            await _localRepo.cacheComplaints([updated]);
          }
        }
        return timeline;
      });
    } catch (e) {
      debugPrint('[OfflineFirstComplaintRepository] watchComplaintTimeline fallback: $e');
      yield* _localRepo.watchComplaintTimeline(complaintId);
    }
  }

  @override
  Stream<List<ComplaintModel>> watchCitizenComplaints(String citizenId) async* {
    // 1. Emit local cache immediately
    final localList = await _localRepo.getCitizenComplaints(citizenId);
    yield localList;

    if (!_connectivity.isOnline) {
      yield* _localRepo.watchCitizenComplaints(citizenId);
      return;
    }

    // 2. Listen to remote stream, merge on each event, update Hive cache
    try {
      yield* _remoteDataSource.watchCitizenComplaints(citizenId: citizenId).asyncMap((remoteList) async {
        final currentLocal = await _localRepo.getCitizenComplaints(citizenId);
        final merged = _mergeComplaints(currentLocal, remoteList);
        await _localRepo.cacheComplaints(merged);
        _lastRefreshedAt = DateTime.now();
        return merged;
      });
    } catch (e) {
      debugPrint('[OfflineFirstComplaintRepository] watchCitizenComplaints fallback: $e');
      yield* _localRepo.watchCitizenComplaints(citizenId);
    }
  }

  @override
  Stream<List<ComplaintModel>> watchComplaints() async* {
    final localList = await _localRepo.getComplaints();
    yield localList;

    if (!_connectivity.isOnline) {
      yield* _localRepo.watchComplaints();
      return;
    }

    try {
      yield* _remoteDataSource.watchGovernmentComplaints().asyncMap((remoteList) async {
        final currentLocal = await _localRepo.getComplaints();
        final merged = _mergeComplaints(currentLocal, remoteList);
        await _localRepo.cacheComplaints(merged);
        _lastRefreshedAt = DateTime.now();
        return merged;
      });
    } catch (e) {
      debugPrint('[OfflineFirstComplaintRepository] watchComplaints fallback: $e');
      yield* _localRepo.watchComplaints();
    }
  }

  @override
  Stream<List<ComplaintModel>> watchNearbyHazards() async* {
    final localHazards = await _localRepo.getNearbyHazards();
    yield localHazards;

    if (!_connectivity.isOnline) {
      yield* _localRepo.watchNearbyHazards();
      return;
    }

    try {
      yield* _remoteDataSource.watchNearbyHazards().asyncMap((remoteHazards) async {
        final currentLocal = await _localRepo.getNearbyHazards();
        final merged = _mergeComplaints(currentLocal, remoteHazards);
        await _localRepo.cacheComplaints(merged);
        _lastRefreshedAt = DateTime.now();
        return merged.where((c) => c.isHazard || c.priority == ComplaintPriority.emergency || c.priority == ComplaintPriority.high).toList();
      });
    } catch (e) {
      debugPrint('[OfflineFirstComplaintRepository] watchNearbyHazards fallback: $e');
      yield* _localRepo.watchNearbyHazards();
    }
  }
}

