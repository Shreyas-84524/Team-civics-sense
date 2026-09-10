import 'dart:async';
import 'package:flutter/foundation.dart';
import '../firebase/firestore/firebase_hazard_data_source.dart';
import '../models/complaint_model.dart';
import '../models/hazard_model.dart';
import '../network/connectivity_service.dart';
import 'hazard_repository.dart';
import 'hive_hazard_repository.dart';

/// Offline-first cache-aware repository for Civic Hazards GIS & map data.
class OfflineFirstHazardRepository implements HazardRepository {
  final HiveHazardRepository _localRepo;
  final FirebaseHazardDataSource _remoteDataSource;
  final ConnectivityService _connectivity;

  OfflineFirstHazardRepository({
    HiveHazardRepository? localRepository,
    FirebaseHazardDataSource? remoteDataSource,
    ConnectivityService? connectivity,
  })  : _localRepo = localRepository ?? HiveHazardRepository(),
        _remoteDataSource = remoteDataSource ?? FirebaseHazardDataSource(),
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

    // 2. If online, fetch remote hazards and refresh cache
    if (_connectivity.isOnline) {
      try {
        final remotePage = await _remoteDataSource.getHazards(
          categoryId: categoryId,
          status: status,
          severity: severity,
          limit: 100,
        );

        if (remotePage.items.isNotEmpty) {
          await _localRepo.cacheHazards(remotePage.items);
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

  @override
  Future<HazardModel?> getHazardById(String id) async {
    final local = await _localRepo.getHazardById(id);
    if (local != null) return local;

    if (_connectivity.isOnline) {
      try {
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
    if (_connectivity.isOnline) {
      try {
        final remotePage = await _remoteDataSource.getHazards(limit: 100);
        if (remotePage.items.isNotEmpty) {
          await _localRepo.cacheHazards(remotePage.items);
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

    if (!_connectivity.isOnline) {
      yield* _localRepo.watchHazards(
        categoryId: categoryId,
        status: status,
        severity: severity,
        searchQuery: searchQuery,
      );
      return;
    }

    try {
      yield* _remoteDataSource
          .watchHazards(
            categoryId: categoryId,
            status: status,
            severity: severity,
            limit: 100,
          )
          .asyncMap((remoteList) async {
        if (remoteList.isNotEmpty) {
          await _localRepo.cacheHazards(remoteList);
        }
        return _localRepo.getHazards(
          categoryId: categoryId,
          status: status,
          severity: severity,
          searchQuery: searchQuery,
        );
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

    if (!_connectivity.isOnline) {
      yield* _localRepo.watchHazardById(id);
      return;
    }

    try {
      yield* _remoteDataSource.watchHazards(limit: 50).asyncMap((list) async {
        try {
          final found = list.firstWhere((h) => h.id == id || h.complaintId == id || h.ticketNumber == id);
          await _localRepo.cacheHazards([found]);
          return found;
        } catch (_) {
          return await _localRepo.getHazardById(id);
        }
      });
    } catch (e) {
      debugPrint('[OfflineFirstHazardRepository] watchHazardById fallback: $e');
      yield* _localRepo.watchHazardById(id);
    }
  }
}

