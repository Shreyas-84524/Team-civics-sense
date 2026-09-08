import 'dart:math';
import 'package:flutter/foundation.dart';
import '../local/hive/hive_boxes.dart';
import '../local/hive/hive_storage_service.dart';
import '../local/local_storage_service.dart';
import '../local/mock_data_source.dart';
import '../local/models/hazard_local_model.dart';
import '../models/complaint_model.dart';
import '../models/hazard_model.dart';
import 'hazard_repository.dart';

/// Hive-backed cache-aware repository for civic hazards and map data.
class HiveHazardRepository implements HazardRepository {
  final LocalStorageService _storage;
  final MockDataSource _dataSource;
  DateTime? _lastCachedAt;

  HiveHazardRepository({
    LocalStorageService? storage,
    MockDataSource? dataSource,
  })  : _storage = storage ?? HiveStorageService.instance,
        _dataSource = dataSource ?? MockDataSource() {
    _initFromCache();
  }

  DateTime? get lastCachedAt => _lastCachedAt;

  Future<void> _initFromCache() async {
    if (_storage.isInitialized) {
      try {
        final cached = await _storage.getAll<HazardLocalModel>(HiveBoxes.hazards);
        if (cached.isNotEmpty) {
          _dataSource.hazards
            ..clear()
            ..addAll(cached.map((e) => e.toDomain()));
          _lastCachedAt = DateTime.now();
        } else {
          // Prime cache with default hazards
          await cacheHazards(_dataSource.hazards);
        }
      } catch (e) {
        debugPrint('Warning: HiveHazardRepository failed reading cache: $e');
      }
    }
  }

  /// Bulk cache hazards snapshot from server into Hive.
  Future<void> cacheHazards(List<HazardModel> hazards) async {
    if (_storage.isInitialized) {
      try {
        final Map<String, HazardLocalModel> entries = {
          for (final h in hazards) h.id: HazardLocalModel.fromDomain(h),
        };
        await _storage.putAll<HazardLocalModel>(HiveBoxes.hazards, entries);
        _lastCachedAt = DateTime.now();
      } catch (e) {
        debugPrint('Warning: HiveHazardRepository.cacheHazards fallback: $e');
      }
    }

    _dataSource.hazards
      ..clear()
      ..addAll(hazards);
  }

  /// Purge old temporary hazard cache data that exceeds the max age.
  Future<void> clearStaleHazards({Duration maxAge = const Duration(hours: 2)}) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = nowMs - maxAge.inMilliseconds;

    if (_storage.isInitialized) {
      try {
        final all = await _storage.getAll<HazardLocalModel>(HiveBoxes.hazards);

        for (final item in all) {
          // If updated earlier than cutoff and resolved, purge
          if (item.updatedAtEpochMs < cutoffMs && item.status == 'resolved') {
            await _storage.delete(HiveBoxes.hazards, item.id);
          }
        }
      } catch (e) {
        debugPrint('Warning: HiveHazardRepository.clearStaleHazards error: $e');
      }
    }

    _dataSource.hazards.removeWhere((h) =>
        h.updatedAt.millisecondsSinceEpoch < cutoffMs &&
        h.status == ComplaintStatus.resolved);
  }

  @override
  Future<List<HazardModel>> getHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  }) async {
    List<HazardModel> results = [];

    if (_storage.isInitialized) {
      try {
        final cached = await _storage.getAll<HazardLocalModel>(HiveBoxes.hazards);
        if (cached.isNotEmpty) {
          results = cached.map((e) => e.toDomain()).toList();
        }
      } catch (e) {
        debugPrint('Warning: HiveHazardRepository.getHazards reading error: $e');
      }
    }

    if (results.isEmpty) {
      results = List<HazardModel>.from(_dataSource.hazards);
    }

    // 1. Category Filter
    if (categoryId != null && categoryId.isNotEmpty && categoryId.toLowerCase() != 'all') {
      results = results.where((h) {
        return h.category.id.toLowerCase() == categoryId.toLowerCase() ||
            h.category.name.toLowerCase() == categoryId.toLowerCase();
      }).toList();
    }

    // 2. Status Filter
    if (status != null) {
      results = results.where((h) => h.status == status).toList();
    }

    // 3. Severity Filter
    if (severity != null) {
      results = results.where((h) => h.severity == severity).toList();
    }

    // 4. Search Filter
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      results = results.where((h) {
        final matchesTitle = h.title.toLowerCase().contains(query);
        final matchesTicket = (h.ticketNumber ?? '').toLowerCase().contains(query);
        final matchesCategory = h.category.name.toLowerCase().contains(query);
        final matchesAddress = h.address.toLowerCase().contains(query);
        final matchesLandmark = (h.landmark ?? '').toLowerCase().contains(query);
        final matchesWard = (h.ward ?? '').toLowerCase().contains(query);
        return matchesTitle || matchesTicket || matchesCategory || matchesAddress || matchesLandmark || matchesWard;
      }).toList();
    }

    return results;
  }

  @override
  Future<HazardModel?> getHazardById(String id) async {
    if (_storage.isInitialized) {
      try {
        final cached = await _storage.get<HazardLocalModel>(HiveBoxes.hazards, id);
        if (cached != null) {
          return cached.toDomain();
        }

        // Search by complaintId or ticketNumber
        final all = await _storage.getAll<HazardLocalModel>(HiveBoxes.hazards);
        for (final h in all) {
          if (h.id == id || h.complaintId == id || h.ticketNumber == id) {
            return h.toDomain();
          }
        }
      } catch (e) {
        debugPrint('Warning: HiveHazardRepository.getHazardById error: $e');
      }
    }

    try {
      return _dataSource.hazards.firstWhere((h) => h.id == id || h.complaintId == id || h.ticketNumber == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<HazardModel>> getNearbyHazards({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final all = await getHazards();

    return all.where((h) {
      if (h.status == ComplaintStatus.resolved) return false;
      final distance = _calculateDistanceKm(latitude, longitude, h.latitude, h.longitude);
      return distance <= radiusKm;
    }).toList();
  }

  /// Calculates approximate great-circle distance between two GPS coordinates in kilometers.
  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
