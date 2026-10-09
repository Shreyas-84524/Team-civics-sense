import 'dart:async';
import 'package:flutter/foundation.dart';
import '../auth/auth_service_locator.dart';
import '../firebase/firestore/firebase_complaint_data_source.dart';
import '../firebase/firestore/firebase_hazard_data_source.dart';
import '../models/complaint_model.dart';
import '../models/hazard_model.dart';
import '../network/connectivity_service.dart';
import 'hazard_repository.dart';
import 'hive_hazard_repository.dart';
import 'repository_locator.dart';

/// Offline-first cache-aware repository for Civic Hazards GIS & map data.
class OfflineFirstHazardRepository extends HazardRepository {
  final HiveHazardRepository _localRepo;
  final FirebaseHazardDataSource _remoteDataSource;
  final FirebaseComplaintDataSource _complaintDataSource;
  final ConnectivityService _connectivity;

  OfflineFirstHazardRepository({
    HiveHazardRepository? localRepository,
    FirebaseHazardDataSource? remoteDataSource,
    FirebaseComplaintDataSource? complaintDataSource,
    ConnectivityService? connectivity,
  })  : _localRepo = localRepository ?? HiveHazardRepository(),
        _remoteDataSource = remoteDataSource ?? FirebaseHazardDataSource(),
        _complaintDataSource = complaintDataSource ?? FirebaseComplaintDataSource(),
        _connectivity = connectivity ?? AppConnectivityService();

  @override
  Future<List<HazardModel>> getHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  }) async {
    // 1. Get from local Hive cache
    var results = await _localRepo.getHazards(
      categoryId: categoryId,
      status: status,
      severity: severity,
      searchQuery: searchQuery,
    );

    // 2. If online and Firebase is initialized, fetch remote complaints and hazards and refresh cache
    if (_connectivity.isOnline && RepositoryLocator.isFirebaseReady) {
      try {
        final citizenUid = AuthServiceLocator.citizenAuth.currentUid;
        final complaints = await _complaintDataSource.getCitizenVisibleComplaints(
          citizenId: citizenUid,
          limit: 100,
        );

        final derivedHazards = complaints.map((c) => HazardModel.fromComplaint(c)).toList();

        // Also fetch from /hazards collection if present
        try {
          final remotePage = await _remoteDataSource.getHazards(
            categoryId: categoryId,
            status: status,
            severity: severity,
            limit: 100,
          );
          for (final h in remotePage.items) {
            if (!derivedHazards.any((d) => d.id == h.id || (h.complaintId != null && d.complaintId == h.complaintId))) {
              derivedHazards.add(h);
            }
          }
        } catch (_) {}

        if (derivedHazards.isNotEmpty) {
          await _localRepo.cacheHazards(derivedHazards);
          results = await _localRepo.getHazards(
            categoryId: categoryId,
            status: status,
            severity: severity,
            searchQuery: searchQuery,
          );
        }
      } catch (e) {
        debugPrint('[OfflineFirstHazardRepository] Remote hazards fetch failed (using cache): $e');
      }
    }

    return results;
  }

  final Set<String> _cachedRemoteChunkIds = {};

  @override
  Future<List<HazardModel>> getHazardsInChunks({
    required List<String> chunkIds,
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  }) async {
    if (chunkIds.isEmpty) return [];
    final chunkSet = chunkIds.toSet();

    // 1. Get from local Hive cache matching chunks
    var localHazards = await _localRepo.getHazards(
      categoryId: categoryId,
      status: status,
      severity: severity,
      searchQuery: searchQuery,
    );
    var filtered = localHazards.where((h) => chunkSet.contains(h.computedSpatialChunkId)).toList();

    // 2. Identify missing chunks not yet fetched from remote
    final missingChunks = chunkIds.where((c) => !_cachedRemoteChunkIds.contains(c)).toList();

    if (missingChunks.isNotEmpty && _connectivity.isOnline && RepositoryLocator.isFirebaseReady) {
      try {
        final citizenUid = AuthServiceLocator.citizenAuth.currentUid;
        final complaints = await _complaintDataSource.getComplaintsBySpatialChunks(
          chunkIds: missingChunks,
          citizenId: citizenUid,
          limit: 100,
        );

        final derivedHazards = complaints.map((c) => HazardModel.fromComplaint(c)).toList();

        // Also check remote hazards collection
        try {
          final remoteHazards = await _remoteDataSource.getHazardsBySpatialChunks(
            chunkIds: missingChunks,
            limit: 100,
          );
          for (final h in remoteHazards) {
            if (!derivedHazards.any((d) => d.id == h.id || (h.complaintId != null && d.complaintId == h.complaintId))) {
              derivedHazards.add(h);
            }
          }
        } catch (_) {}

        if (derivedHazards.isNotEmpty) {
          await _localRepo.cacheHazards(derivedHazards);
        }
        _cachedRemoteChunkIds.addAll(missingChunks);

        // Re-read updated local cache
        localHazards = await _localRepo.getHazards(
          categoryId: categoryId,
          status: status,
          severity: severity,
          searchQuery: searchQuery,
        );
        filtered = localHazards.where((h) => chunkSet.contains(h.computedSpatialChunkId)).toList();
      } catch (e) {
        debugPrint('[OfflineFirstHazardRepository] Remote chunk fetch failed (using cache): $e');
      }
    }

    return filtered;
  }

  @override
  Future<HazardModel?> getHazardById(String id) async {
    final local = await _localRepo.getHazardById(id);
    if (local != null) return local;

    if (_connectivity.isOnline && RepositoryLocator.isFirebaseReady) {
      try {
        final complaint = await _complaintDataSource.getComplaintById(id);
        if (complaint != null) {
          final hazard = HazardModel.fromComplaint(complaint);
          await _localRepo.cacheHazards([hazard]);
          return hazard;
        }

        final remote = await _remoteDataSource.getHazardById(id);
        if (remote != null) {
          await _localRepo.cacheHazards([remote]);
          return remote;
        }
      } catch (_) {}
    }

    return null;
  }

  @override
  Future<List<HazardModel>> getNearbyHazards({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    // If online, refresh hazards from remote
    if (_connectivity.isOnline && RepositoryLocator.isFirebaseReady) {
      try {
        final citizenUid = AuthServiceLocator.citizenAuth.currentUid;
        final complaints = await _complaintDataSource.getCitizenVisibleComplaints(
          citizenId: citizenUid,
          limit: 100,
        );
        final derived = complaints.map((c) => HazardModel.fromComplaint(c)).toList();
        if (derived.isNotEmpty) {
          await _localRepo.cacheHazards(derived);
        }
      } catch (e) {
        debugPrint('[OfflineFirstHazardRepository] Remote hazards fetch in getNearbyHazards failed: $e');
      }
    }

    return _localRepo.getNearbyHazards(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }

  // ===========================================================================
  // REAL-TIME HAZARD STREAMS (Prompt 8)
  // ===========================================================================

  @override
  Stream<List<HazardModel>> watchHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  }) async* {
    final localList = await _localRepo.getHazards(
      categoryId: categoryId,
      status: status,
      severity: severity,
      searchQuery: searchQuery,
    );
    yield localList;

    if (!_connectivity.isOnline || !RepositoryLocator.isFirebaseReady) {
      yield* _localRepo.watchHazards(
        categoryId: categoryId,
        status: status,
        severity: severity,
        searchQuery: searchQuery,
      );
      return;
    }

    try {
      final citizenUid = AuthServiceLocator.citizenAuth.currentUid;
      yield* _complaintDataSource
          .watchCitizenVisibleComplaints(
            citizenId: citizenUid,
            limit: 100,
          )
          .asyncMap((complaintsList) async {
            final derived = complaintsList.map((c) => HazardModel.fromComplaint(c)).toList();
            if (derived.isNotEmpty) {
              await _localRepo.cacheHazards(derived);
            }
            return _localRepo.getHazards(
              categoryId: categoryId,
              status: status,
              severity: severity,
              searchQuery: searchQuery,
            );
          })
          .handleError((e) {
            debugPrint('[OfflineFirstHazardRepository] watchHazards stream error: $e');
          });
    } catch (e) {
      debugPrint('[OfflineFirstHazardRepository] watchHazards fallback: $e');
      yield* _localRepo.watchHazards(
        categoryId: categoryId,
        status: status,
        severity: severity,
        searchQuery: searchQuery,
      );
    }
  }

  @override
  Stream<HazardModel?> watchHazardById(String id) async* {
    final local = await _localRepo.getHazardById(id);
    if (local != null) yield local;

    if (!_connectivity.isOnline || !RepositoryLocator.isFirebaseReady) {
      yield* _localRepo.watchHazardById(id);
      return;
    }

    try {
      yield* _complaintDataSource.watchComplaint(id).asyncMap((complaint) async {
        if (complaint != null) {
          final found = HazardModel.fromComplaint(complaint);
          await _localRepo.cacheHazards([found]);
          return found;
        }
        return await _localRepo.getHazardById(id);
      }).handleError((e) {
        debugPrint('[OfflineFirstHazardRepository] watchHazardById stream error: $e');
      });
    } catch (e) {
      debugPrint('[OfflineFirstHazardRepository] watchHazardById fallback: $e');
      yield* _localRepo.watchHazardById(id);
    }
  }
}

