import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../ai/models/ai_analysis_status.dart';
import '../ai/models/ai_authenticity_result.dart';
import '../auth/auth_service_locator.dart';
import '../evidence/evidence_bytes.dart';
import '../firebase/errors/firestore_exception.dart';
import '../firebase/firestore/firebase_complaint_data_source.dart';
import '../firebase/storage/evidence_storage_models.dart';
import '../firebase/storage/evidence_storage_service.dart';
import '../firebase/storage/storage_error_handler.dart';
import '../location/location_model.dart';
import '../models/category_model.dart';
import '../models/complaint_model.dart';
import '../models/complaint_upvote_result.dart';
import '../network/connectivity_service.dart';
import '../services/complaint_routing_service.dart';
import '../storage/supabase_evidence_storage_service.dart';
import '../sync/models/sync_queue_item.dart';
import '../sync/sync_manager.dart';
import 'complaint_repository.dart';
import 'hive_complaint_repository.dart';

/// Unified offline-first complaint repository for CivicFix.
///
/// Coordinates:
/// 1. **Remote-First Online Pipeline** ([FirebaseComplaintDataSource] & [EvidenceStorageService]) for real-time cloud creation.
/// 2. **Hive Local Cache & Persistence** ([HiveComplaintRepository]) for instant UI reads and offline fallback resilience.
/// 3. **SyncManager Orchestration Engine** ([SyncManager]) for reliable background offline-to-online queue draining.
/// 4. **Connectivity Detection** ([ConnectivityService]) for intelligent remote-first routing and stale-while-revalidate caching.
class OfflineFirstComplaintRepository implements ComplaintRepository {
  final HiveComplaintRepository _localRepo;
  final FirebaseComplaintDataSource _remoteDataSource;
  final EvidenceStorageService _evidenceStorageService;
  final SyncManager _syncManager;
  final ConnectivityService _connectivity;
  final ComplaintRoutingService _routingService;

  int _localTicketCounter = 24;
  DateTime? _lastRefreshedAt;

  OfflineFirstComplaintRepository({
    HiveComplaintRepository? localRepository,
    FirebaseComplaintDataSource? remoteDataSource,
    EvidenceStorageService? evidenceStorageService,
    SyncManager? syncManager,
    ConnectivityService? connectivity,
    ComplaintRoutingService? routingService,
  }) : _localRepo = localRepository ?? HiveComplaintRepository(),
       _remoteDataSource = remoteDataSource ?? FirebaseComplaintDataSource(),
       _evidenceStorageService =
           evidenceStorageService ?? SupabaseEvidenceStorageService.instance,
       _syncManager = syncManager ?? SyncManager(),
       _connectivity = connectivity ?? AppConnectivityService(),
       _routingService = routingService ?? ComplaintRoutingService();

  DateTime? get lastRefreshedAt => _lastRefreshedAt ?? _localRepo.lastCachedAt;
  HiveComplaintRepository get localRepository => _localRepo;
  FirebaseComplaintDataSource get remoteDataSource => _remoteDataSource;
  EvidenceStorageService get evidenceStorageService => _evidenceStorageService;
  SyncManager get syncManager => _syncManager;
  ConnectivityService get connectivity => _connectivity;
  ComplaintRoutingService get routingService => _routingService;

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
        final remotePage = await _remoteDataSource.getCitizenComplaints(
          citizenId: citizenId,
        );
        final merged = _mergeComplaints(localList, remotePage.items);
        await _localRepo.cacheComplaints(merged);
        _lastRefreshedAt = DateTime.now();
        return merged;
      } catch (e) {
        debugPrint(
          '[OfflineFirstComplaintRepository] Background citizen complaints refresh failed (using cache): $e',
        );
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
        final remotePage = await _remoteDataSource.getGovernmentComplaints(
          limit: 50,
        );
        final merged = _mergeComplaints(localList, remotePage.items);
        await _localRepo.cacheComplaints(merged);
        _lastRefreshedAt = DateTime.now();
        return merged;
      } catch (e) {
        debugPrint(
          '[OfflineFirstComplaintRepository] Background all complaints refresh failed (using cache): $e',
        );
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
          final remote = await _remoteDataSource.getComplaintById(
            remoteTargetId,
          );
          if (remote != null) {
            final merged = _mergeSingleComplaint(local, remote);
            await _localRepo.cacheComplaints([merged]);
            return merged;
          }
        } catch (e) {
          debugPrint(
            '[OfflineFirstComplaintRepository] Remote single getComplaintById failed: $e',
          );
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
        debugPrint(
          '[OfflineFirstComplaintRepository] Remote fallback lookup failed for $id: $e',
        );
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
        final remote = await _remoteDataSource.getComplaintByTicketNumber(
          ticketId,
        );
        if (remote != null) {
          await _localRepo.cacheComplaints([remote]);
          return remote;
        }
      } catch (e) {
        debugPrint(
          '[OfflineFirstComplaintRepository] Remote getComplaintByTicketId lookup failed: $e',
        );
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
        return merged
            .where(
              (c) =>
                  c.isHazard ||
                  c.priority == ComplaintPriority.emergency ||
                  c.priority == ComplaintPriority.high,
            )
            .toList();
      } catch (e) {
        debugPrint(
          '[OfflineFirstComplaintRepository] Remote hazards refresh failed: $e',
        );
      }
    }

    return localHazards;
  }

  @override
  Future<List<ComplaintModel>> getCitizenVisibleComplaints({
    String? citizenId,
    int limit = 100,
  }) async {
    final effectiveCitizenId = citizenId ?? AuthServiceLocator.citizenAuth.currentUid ?? '';
    final localComplaints = await _localRepo.getComplaints();
    final localVisible = localComplaints
        .where(
          (c) =>
              c.isHazard ||
              c.priority == ComplaintPriority.emergency ||
              c.priority == ComplaintPriority.high ||
              (effectiveCitizenId.isNotEmpty && c.citizenId == effectiveCitizenId),
        )
        .toList();

    if (_connectivity.isOnline) {
      try {
        final remoteComplaints = await _remoteDataSource.getCitizenVisibleComplaints(
          citizenId: effectiveCitizenId,
          limit: limit,
        );
        final merged = _mergeComplaints(localVisible, remoteComplaints);
        await _localRepo.cacheComplaints(merged);
        _lastRefreshedAt = DateTime.now();
        return merged
            .where(
              (c) =>
                  c.isHazard ||
                  c.priority == ComplaintPriority.emergency ||
                  c.priority == ComplaintPriority.high ||
                  (effectiveCitizenId.isNotEmpty && c.citizenId == effectiveCitizenId),
            )
            .toList();
      } catch (e) {
        debugPrint(
          '[OfflineFirstComplaintRepository] Remote citizen visible complaints refresh failed: $e',
        );
      }
    }

    return localVisible;
  }

  // ===========================================================================
  // WRITE STRATEGY: Remote-First Online Execution + Hive Offline Fallback
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
    // 1. REMOTE-FIRST: When online, perform direct foreground cloud submission
    if (_connectivity.isOnline) {
      try {
        final now = DateTime.now();
        final suffix = List.generate(12, (_) => Random.secure().nextInt(16).toRadixString(16)).join();
        final ticketNum = 'CF-${now.year}-${now.microsecondsSinceEpoch}-$suffix';
        final newId =
            'cmp_${now.microsecondsSinceEpoch}_$suffix';

        // 1a. Upload local media evidence if present.
        //
        // STRICT RULE: If ANY local file upload fails, abort the entire remote creation
        // attempt and fall through to Hive offline fallback.
        // A raw filesystem path (e.g. /data/user/0/...) must NEVER be written to Firestore.
        final List<String> remoteImageUrls = [];
        for (int i = 0; i < imageUrls.length; i++) {
          final imgRef = imageUrls[i];
          if (imgRef.startsWith('http://') || imgRef.startsWith('https://')) {
            // Already a remote URL (e.g. previously uploaded evidence) — include as-is.
            remoteImageUrls.add(imgRef);
          } else {
            final uploadUrl = await _uploadLocalMedia(
              complaintId: newId,
              ticketNumber: ticketNum,
              citizenId: citizenId,
              mediaRef: imgRef,
              index: i,
            );
            if (uploadUrl != null) {
              remoteImageUrls.add(uploadUrl);
            } else {
              // Upload returned null — treat as a recoverable transient failure.
              // Throw to trigger the offline fallback below; DO NOT add local path to Firestore.
              throw StorageException(
                code: 'upload-failed',
                message:
                    'Evidence upload for index $i returned null. Aborting remote creation.',
                userMessage:
                    'Unable to upload photo evidence. Saving complaint offline for retry.',
                isRecoverable: true,
              );
            }
          }
        }

        // 1b. Construct initial domain complaint
        final initialRemoteComplaint = ComplaintModel(
          id: newId,
          citizenId: citizenId,
          ticketNumber: ticketNum,
          title: title.trim(),
          description: description.trim(),
          category: category,
          status: ComplaintStatus.underVerification,
          priority: priority,
          location: location,
          imageUrls: List.unmodifiable(remoteImageUrls),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isHazard: isHazard,
          upvotes: 0,
          syncStatus: SyncStatus.synced,
          evidenceVerificationStatus: 'pending',
          departmentVerificationStatus: 'pending',
          verificationStage: 'evidence',
          timeline: [
            TimelineEvent(
              title: 'Grievance Submitted',
              description:
                  'Complaint submitted and queued for two-stage verification.',
              timestamp: DateTime.now(),
              status: ComplaintStatus.underVerification,
              updatedBy: citizenId,
            ),
          ],
        );

        // 1c. Create initial complaint document in Firestore (citizen authorization)
        final created = await _remoteDataSource.createComplaint(
          initialRemoteComplaint,
        );

        final syncedComplaint = created.copyWith(
          syncStatus: SyncStatus.synced,
          serverId: created.id,
        );

        // 1d. Cache synced result in Hive without enqueuing in SyncManager
        await _localRepo.cacheComplaints([syncedComplaint]);

        return syncedComplaint;
      } catch (e) {
        if (_isRetryableError(e)) {
          debugPrint(
            '[OfflineFirstComplaintRepository] Online submission failed due to network/transient error: $e. Falling back to Hive offline persistence.',
          );
          // Fall through to offline fallback below
        } else {
          debugPrint(
            '[OfflineFirstComplaintRepository] Online submission failed due to non-retryable error: $e. Propagating to UI.',
          );
          rethrow;
        }
      }
    }

    // 2. OFFLINE FALLBACK: Save locally to Hive with pending status and enqueue into SyncManager
    return _saveToLocalOfflineQueue(
      citizenId: citizenId,
      title: title,
      description: description,
      category: category,
      location: location,
      priority: priority,
      imageUrls: imageUrls,
      isHazard: isHazard,
    );
  }

  Future<ComplaintModel> _saveToLocalOfflineQueue({
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
    final newId =
        'cmp_local_${DateTime.now().microsecondsSinceEpoch}_$formattedCounter';

    final initialComplaint = ComplaintModel(
      id: newId,
      citizenId: citizenId,
      ticketNumber: localRef,
      localId: localRef,
      title: title.trim(),
      description: description.trim(),
      category: category,
      status: ComplaintStatus.underVerification,
      priority: priority,
      location: location,
      imageUrls: List.unmodifiable(imageUrls),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isHazard: isHazard,
      upvotes: 0,
      syncStatus: SyncStatus.pending,
      evidenceVerificationStatus: 'pending',
      departmentVerificationStatus: 'pending',
      verificationStage: 'evidence',
      timeline: [
        TimelineEvent(
          title: 'Grievance Submitted (Offline)',
          description: 'Saved locally on device. Will be submitted for verification when connection is restored.',
          timestamp: DateTime.now(),
          status: ComplaintStatus.underVerification,
          updatedBy: citizenId,
        ),
      ],
    );

    // 1. Save immediately to Hive local storage & memory (status: underVerification)
    final saved = await _localRepo.saveOfflineComplaint(initialComplaint);

    // 2. Enqueue into SyncManager for remote synchronization
    await _syncManager.queueComplaintCreation(saved);

    // 3. Return domain model immediately
    return saved;
  }

  /// Uploads local media bytes or test mock payload to cloud evidence storage.
  Future<String?> _uploadLocalMedia({
    required String complaintId,
    String? ticketNumber,
    String? citizenId,
    required String mediaRef,
    required int index,
  }) async {
    Uint8List? bytes = evidenceDataBytes(mediaRef);
    String fileName = 'evidence_${index + 1}.jpg';

    if (mediaRef.startsWith('mock://') || mediaRef.startsWith('memory://')) {
      final dummy = List<int>.filled(256, 0);
      dummy[0] = 0xFF;
      dummy[1] = 0xD8;
      dummy[2] = 0xFF;
      bytes = Uint8List.fromList(dummy);
      fileName = 'photo_${index + 1}.jpg';
    } else {
      if (!kIsWeb && bytes == null) {
        final file = File(mediaRef);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
          fileName = file.uri.pathSegments.isNotEmpty
              ? file.uri.pathSegments.last
              : fileName;
        }
      }
    }

    if (bytes == null || bytes.isEmpty) {
      debugPrint(
        '[OfflineFirstComplaintRepository] Media file $mediaRef not accessible locally.',
      );
      return null;
    }

    final effectiveTicket = ticketNumber ?? complaintId;
    final deterministicFileName = evidenceFileName(bytes, index + 1);
    final uploadResult = await _evidenceStorageService.uploadComplaintEvidence(
      complaintId: complaintId,
      ticketNumber: effectiveTicket,
      evidenceIndex: index + 1,
      fileName: deterministicFileName,
      fileBytes: bytes,
      metadata: EvidenceMetadata(
        complaintId: complaintId,
        uploaderId: citizenId ?? 'user_citizen',
      ),
    );

    return uploadResult.downloadUrl;
  }

  /// Determines whether a submission exception represents a transient/recoverable network failure.
  bool _isRetryableError(dynamic error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException) {
      return true;
    }
    if (error is FirestoreException) {
      return error.isRecoverable;
    }
    if (error is StorageException) {
      return error.isRecoverable;
    }
    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      return code == 'unavailable' ||
          code == 'deadline-exceeded' ||
          code == 'network-request-failed' ||
          code == 'retry-limit-exceeded' ||
          code == 'timeout';
    }
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('network') ||
        errStr.contains('timeout') ||
        errStr.contains('unavailable') ||
        errStr.contains('connection refused') ||
        errStr.contains('connection closed') ||
        errStr.contains('502') ||
        errStr.contains('503') ||
        errStr.contains('504')) {
      return true;
    }
    return false;
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
    AiAuthenticityResult? aiAuthenticity,
    AiAnalysisStatus? aiAnalysisStatus,
  }) async {
    await _localRepo.updateSyncStatus(
      complaintId,
      status,
      serverId: serverId,
      aiAuthenticity: aiAuthenticity,
      aiAnalysisStatus: aiAnalysisStatus,
    );
  }

  @override
  Future<ComplaintUpvoteResult> upvoteComplaint(String id) async {
    final userId =
        AuthServiceLocator.citizenAuth.currentUid ??
        AuthServiceLocator.citizenAuth.currentUser?.id ??
        '';
    if (userId.isEmpty) {
      throw StateError('You must be signed in to support a complaint.');
    }

    final complaint = await _localRepo.getComplaintById(id);
    final targetServerId = complaint?.serverId ?? id;
    final complaintIds = <String>{
      id,
      targetServerId,
      if (complaint != null) complaint.id,
      if (complaint?.localId != null) complaint!.localId!,
      if (complaint != null) complaint.ticketNumber,
    };

    // The local marker prevents repeated offline taps and survives app restarts.
    if (await _localRepo.hasRecordedUpvote(userId, complaintIds)) {
      return ComplaintUpvoteResult(
        added: false,
        upvotes: complaint?.upvotes ?? 0,
      );
    }

    // Online votes are server-first so the UI only adopts an authoritative
    // count and a repeated vote never inflates the local cache.
    if (_connectivity.isOnline) {
      try {
        final result = await _remoteDataSource.upvoteComplaint(
          targetServerId,
          userId: userId,
        );
        await _localRepo.recordUpvote(userId, complaintIds);
        await _localRepo.setUpvoteCount(id, result.upvotes);
        return result;
      } catch (e) {
        if (!_isRetryableError(e)) rethrow;
        debugPrint(
          '[OfflineFirstComplaintRepository] Remote upvote failed, will queue: $e',
        );
      }
    }

    if (complaint == null) {
      throw StateError('Complaint is not available offline.');
    }

    final result = await _localRepo.upvoteComplaint(id);
    await _localRepo.recordUpvote(userId, complaintIds);
    await _queueUpvoteOperation(targetServerId, userId);
    return result;
  }

  Future<void> _queueUpvoteOperation(String complaintId, String userId) async {
    final alreadyQueued = await _syncManager.queue.hasPendingEntity(
      'upvote',
      complaintId,
      SyncOperation.upvoteComplaint,
    );
    if (alreadyQueued) return;

    final item = SyncQueueItem(
      id: 'upvote_${userId}_$complaintId',
      entityType: 'upvote',
      entityId: complaintId,
      operation: SyncOperation.upvoteComplaint,
      payload: {'complaintId': complaintId, 'userId': userId},
      createdAt: DateTime.now(),
      status: SyncQueueStatus.pending,
    );
    await _syncManager.queue.enqueue(item);
  }

  /// Delete a complaint from both local storage and sync queue.
  Future<void> deleteComplaint(String id) async {
    await _localRepo.deleteComplaint(id);
  }

  /// Purge old temporary complaints from local cache that exceed maxAge.
  ///
  /// STRICT RULE: NEVER purges pending offline complaints (syncStatus == pending).
  Future<void> clearStaleComplaints({
    Duration maxAge = const Duration(days: 14),
  }) async {
    await _localRepo.clearStaleComplaints(maxAge: maxAge);
  }

  /// Explicitly force a remote refresh of citizen complaints.
  Future<List<ComplaintModel>> refreshCitizenComplaints(
    String citizenId,
  ) async {
    if (!_connectivity.isOnline) {
      return _localRepo.getCitizenComplaints(citizenId);
    }

    final localList = await _localRepo.getCitizenComplaints(citizenId);
    final remotePage = await _remoteDataSource.getCitizenComplaints(
      citizenId: citizenId,
    );
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
      if (a.syncStatus == SyncStatus.pending &&
          b.syncStatus != SyncStatus.pending) {
        return -1;
      }
      if (b.syncStatus == SyncStatus.pending &&
          a.syncStatus != SyncStatus.pending) {
        return 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return result;
  }

  /// Merges a single local complaint record with an authoritative remote record.
  ComplaintModel _mergeSingleComplaint(
    ComplaintModel local,
    ComplaintModel remote,
  ) {
    if (local.syncStatus == SyncStatus.pending ||
        local.syncStatus == SyncStatus.syncing) {
      // Local is actively pending: preserve local title, description, and images,
      // but adopt server ticketNumber, status, and serverId if available.
      return local.copyWith(
        serverId: remote.id,
        ticketNumber:
            remote.ticketNumber.isNotEmpty &&
                !remote.ticketNumber.startsWith('LOCAL-')
            ? remote.ticketNumber
            : local.ticketNumber,
        status: remote.status,
        assignedTo: remote.assignedTo ?? local.assignedTo,
        departmentName: remote.departmentName ?? local.departmentName,
        wardId: remote.wardId ?? local.wardId,
        assignedDepartmentId: remote.assignedDepartmentId ?? local.assignedDepartmentId,
        assignedDepartmentLeadId: remote.assignedDepartmentLeadId ?? local.assignedDepartmentLeadId,
        assignedCrewMemberId: remote.assignedCrewMemberId ?? local.assignedCrewMemberId,
        routingStatus: remote.routingStatus,
        assignmentStatus: remote.assignmentStatus,
        currentDepartmentAssignedAt: remote.currentDepartmentAssignedAt ?? local.currentDepartmentAssignedAt,
        lastReassignedAt: remote.lastReassignedAt ?? local.lastReassignedAt,
        reassignmentCount: remote.reassignmentCount > local.reassignmentCount
            ? remote.reassignmentCount
            : local.reassignmentCount,
        assignedFieldOfficerId: remote.assignedFieldOfficerId ?? local.assignedFieldOfficerId,
        assignedFieldOfficerAt: remote.assignedFieldOfficerAt ?? local.assignedFieldOfficerAt,
        assignedFieldOfficerNameSnapshot: remote.assignedFieldOfficerNameSnapshot ?? local.assignedFieldOfficerNameSnapshot,
        assignedFieldOfficerDesignationSnapshot: remote.assignedFieldOfficerDesignationSnapshot ?? local.assignedFieldOfficerDesignationSnapshot,
        workStartedAt: remote.workStartedAt ?? local.workStartedAt,
        workStartedBy: remote.workStartedBy ?? local.workStartedBy,
        beforeWorkPhoto: remote.beforeWorkPhoto ?? local.beforeWorkPhoto,
        beforeWorkNotes: remote.beforeWorkNotes ?? local.beforeWorkNotes,
        afterWorkPhoto: remote.afterWorkPhoto ?? local.afterWorkPhoto,
        resolutionRemarks: remote.resolutionRemarks ?? local.resolutionRemarks,
        resolvedBy: remote.resolvedBy ?? local.resolvedBy,
        blockedAt: remote.blockedAt ?? local.blockedAt,
        blockedBy: remote.blockedBy ?? local.blockedBy,
        blockedReason: remote.blockedReason ?? local.blockedReason,
        reopenedAt: remote.reopenedAt ?? local.reopenedAt,
        reopenedBy: remote.reopenedBy ?? local.reopenedBy,
        reopenReason: remote.reopenReason ?? local.reopenReason,
        previousResolvedAt: remote.previousResolvedAt ?? local.previousResolvedAt,
        previousResolutionEvidence: remote.previousResolutionEvidence.isNotEmpty
            ? remote.previousResolutionEvidence
            : local.previousResolutionEvidence,
        reopenCount: remote.reopenCount > local.reopenCount ? remote.reopenCount : local.reopenCount,
        officerNotes: remote.officerNotes ?? local.officerNotes,
        resolvedAt: remote.resolvedAt ?? local.resolvedAt,
        upvotes: remote.upvotes > local.upvotes
            ? remote.upvotes
            : local.upvotes,
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
      yield* _remoteDataSource.watchComplaint(remoteTargetId).asyncMap((
        remote,
      ) async {
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
      debugPrint(
        '[OfflineFirstComplaintRepository] watchComplaint fallback to local: $e',
      );
      yield* _localRepo.watchComplaint(id);
    }
  }

  @override
  Stream<List<TimelineEvent>> watchComplaintTimeline(
    String complaintId,
  ) async* {
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
      yield* _remoteDataSource.watchComplaintTimeline(remoteTargetId).asyncMap((
        timeline,
      ) async {
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
      debugPrint(
        '[OfflineFirstComplaintRepository] watchComplaintTimeline fallback: $e',
      );
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
      yield* _remoteDataSource
          .watchCitizenComplaints(citizenId: citizenId)
          .asyncMap((remoteList) async {
            final currentLocal = await _localRepo.getCitizenComplaints(
              citizenId,
            );
            final merged = _mergeComplaints(currentLocal, remoteList);
            await _localRepo.cacheComplaints(merged);
            _lastRefreshedAt = DateTime.now();
            return merged;
          });
    } catch (e) {
      debugPrint(
        '[OfflineFirstComplaintRepository] watchCitizenComplaints fallback: $e',
      );
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
      yield* _remoteDataSource.watchGovernmentComplaints().asyncMap((
        remoteList,
      ) async {
        final currentLocal = await _localRepo.getComplaints();
        final merged = _mergeComplaints(currentLocal, remoteList);
        await _localRepo.cacheComplaints(merged);
        _lastRefreshedAt = DateTime.now();
        return merged;
      });
    } catch (e) {
      debugPrint(
        '[OfflineFirstComplaintRepository] watchComplaints fallback: $e',
      );
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
      yield* _remoteDataSource.watchNearbyHazards().asyncMap((
        remoteHazards,
      ) async {
        final currentLocal = await _localRepo.getNearbyHazards();
        final merged = _mergeComplaints(currentLocal, remoteHazards);
        await _localRepo.cacheComplaints(merged);
        _lastRefreshedAt = DateTime.now();
        return merged
            .where(
              (c) =>
                  c.isHazard ||
                  c.priority == ComplaintPriority.emergency ||
                  c.priority == ComplaintPriority.high,
            )
            .toList();
      });
    } catch (e) {
      debugPrint(
        '[OfflineFirstComplaintRepository] watchNearbyHazards fallback: $e',
      );
      yield* _localRepo.watchNearbyHazards();
    }
  }

  @override
  Stream<List<ComplaintModel>> watchCitizenVisibleComplaints({
    String? citizenId,
    int limit = 100,
  }) async* {
    final effectiveCitizenId = citizenId ?? AuthServiceLocator.citizenAuth.currentUid ?? '';
    final localList = await getCitizenVisibleComplaints(citizenId: effectiveCitizenId, limit: limit);
    yield localList;

    if (!_connectivity.isOnline) {
      yield* _localRepo.watchComplaints().map((list) {
        return list
            .where(
              (c) =>
                  c.isHazard ||
                  c.priority == ComplaintPriority.emergency ||
                  c.priority == ComplaintPriority.high ||
                  (effectiveCitizenId.isNotEmpty && c.citizenId == effectiveCitizenId),
            )
            .toList();
      });
      return;
    }

    try {
      yield* _remoteDataSource
          .watchCitizenVisibleComplaints(citizenId: effectiveCitizenId, limit: limit)
          .asyncMap((remoteList) async {
            final currentLocal = await _localRepo.getComplaints();
            final merged = _mergeComplaints(currentLocal, remoteList);
            await _localRepo.cacheComplaints(merged);
            _lastRefreshedAt = DateTime.now();
            return merged
                .where(
                  (c) =>
                      c.isHazard ||
                      c.priority == ComplaintPriority.emergency ||
                      c.priority == ComplaintPriority.high ||
                      (effectiveCitizenId.isNotEmpty && c.citizenId == effectiveCitizenId),
                )
                .toList();
          });
    } catch (e) {
      debugPrint(
        '[OfflineFirstComplaintRepository] watchCitizenVisibleComplaints fallback: $e',
      );
      yield* _localRepo.watchComplaints().map((list) {
        return list
            .where(
              (c) =>
                  c.isHazard ||
                  c.priority == ComplaintPriority.emergency ||
                  c.priority == ComplaintPriority.high ||
                  (effectiveCitizenId.isNotEmpty && c.citizenId == effectiveCitizenId),
            )
            .toList();
      });
    }
  }
}
