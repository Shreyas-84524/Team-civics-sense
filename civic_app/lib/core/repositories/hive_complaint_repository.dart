import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../local/hive/hive_boxes.dart';
import '../local/hive/hive_storage_service.dart';
import '../local/local_storage_service.dart';
import '../local/mock_data_source.dart';
import '../local/models/complaint_local_model.dart';
import '../local/models/hazard_local_model.dart';
import '../local/models/pending_sync_local_model.dart';
import '../location/location_model.dart';
import '../models/category_model.dart';
import '../models/complaint_model.dart';
import '../models/hazard_model.dart';
import 'complaint_repository.dart';

/// Hive-backed persistence repository for civic complaints and offline sync drafts.
class HiveComplaintRepository implements ComplaintRepository {
  final LocalStorageService _storage;
  final MockDataSource _dataSource;
  int _ticketCounter = 24;

  HiveComplaintRepository({
    LocalStorageService? storage,
    MockDataSource? dataSource,
  })  : _storage = storage ?? HiveStorageService.instance,
        _dataSource = dataSource ?? MockDataSource();

  @override
  Future<ComplaintModel> saveOfflineComplaint(ComplaintModel complaint) async {
    final localRef = complaint.localId ?? complaint.ticketNumber;
    final offlineComplaint = complaint.copyWith(
      syncStatus: SyncStatus.pending,
      localId: localRef,
    );

    // 1-3. Attempt to save persistently to Hive boxes
    if (_storage.isInitialized) {
      try {
        // 1. Save to Hive 'complaints' box
        final localModel = ComplaintLocalModel.fromDomain(offlineComplaint);
        await _storage.put<ComplaintLocalModel>(
          HiveBoxes.complaints,
          offlineComplaint.id,
          localModel,
        );

        // 2. Queue mutation in Hive 'pending_sync' box
        final syncItem = PendingSyncLocalModel(
          id: 'sync_${offlineComplaint.id}',
          entityType: 'complaint',
          entityId: offlineComplaint.id,
          action: 'create',
          payloadJson: jsonEncode({
            'id': offlineComplaint.id,
            'localId': offlineComplaint.localId,
            'title': offlineComplaint.title,
            'description': offlineComplaint.description,
            'categoryId': offlineComplaint.category.id,
            'priority': offlineComplaint.priority.name,
            'isHazard': offlineComplaint.isHazard,
            'latitude': offlineComplaint.location.latitude,
            'longitude': offlineComplaint.location.longitude,
            'address': offlineComplaint.location.address,
            'imageUrls': offlineComplaint.imageUrls,
          }),
          createdAtEpochMs: DateTime.now().millisecondsSinceEpoch,
          syncStatus: 'pending',
          idempotencyKey: 'complaint_${offlineComplaint.id}_create',
        );

        await _storage.put<PendingSyncLocalModel>(
          HiveBoxes.pendingSync,
          syncItem.id,
          syncItem,
        );

        // 3. If hazard, save to Hive 'hazards' box
        if (offlineComplaint.isHazard) {
          final hazardLocal = HazardLocalModel(
            id: 'haz_${offlineComplaint.id}',
            complaintId: offlineComplaint.id,
            ticketNumber: offlineComplaint.ticketNumber,
            title: offlineComplaint.title,
            categoryId: offlineComplaint.category.id,
            categoryName: offlineComplaint.category.name,
            categoryDescription: offlineComplaint.category.description,
            status: offlineComplaint.status.name,
            latitude: offlineComplaint.location.latitude,
            longitude: offlineComplaint.location.longitude,
            address: offlineComplaint.location.address,
            landmark: offlineComplaint.location.landmark,
            ward: offlineComplaint.location.ward,
            severity: offlineComplaint.priority == ComplaintPriority.emergency
                ? 'critical'
                : offlineComplaint.priority == ComplaintPriority.high
                    ? 'high'
                    : 'medium',
            imageUrl: offlineComplaint.imageUrls.isNotEmpty ? offlineComplaint.imageUrls.first : null,
            createdAtEpochMs: offlineComplaint.createdAt.millisecondsSinceEpoch,
            updatedAtEpochMs: offlineComplaint.updatedAt.millisecondsSinceEpoch,
          );

          await _storage.put<HazardLocalModel>(
            HiveBoxes.hazards,
            hazardLocal.id,
            hazardLocal,
          );
        }
      } catch (e) {
        debugPrint('Warning: Hive local persistence not active, stored in-memory fallback: $e');
      }
    }

    // 4. Update in-memory fallback data source for instantaneous UI responsiveness
    final existingIndex = _dataSource.complaints.indexWhere(
      (c) => c.id == offlineComplaint.id || c.localId == offlineComplaint.localId,
    );
    if (existingIndex != -1) {
      _dataSource.complaints[existingIndex] = offlineComplaint;
    } else {
      _dataSource.complaints.insert(0, offlineComplaint);
    }

    // Update user stats
    final updatedUser = _dataSource.currentUser.copyWith(
      reportsSubmitted: _dataSource.currentUser.reportsSubmitted + 1,
      civicPoints: _dataSource.currentUser.civicPoints + 20,
    );
    _dataSource.currentUser = updatedUser;

    return offlineComplaint;
  }

  @override
  Future<List<ComplaintModel>> getPendingComplaints() async {
    if (_storage.isInitialized) {
      try {
        final storedList = await _storage.getAll<ComplaintLocalModel>(HiveBoxes.complaints);
        if (storedList.isNotEmpty) {
          return storedList
              .map((e) => e.toDomain())
              .where((c) => c.syncStatus == SyncStatus.pending)
              .toList();
        }
      } catch (e) {
        debugPrint('Warning: Failed reading pending complaints from Hive: $e');
      }
    }

    return _dataSource.complaints.where((c) => c.syncStatus == SyncStatus.pending).toList();
  }

  @override
  Future<void> updateSyncStatus(
    String complaintId,
    SyncStatus status, {
    String? serverId,
  }) async {
    // 1. Update in Hive 'complaints' box
    if (_storage.isInitialized) {
      try {
        ComplaintLocalModel? stored =
            await _storage.get<ComplaintLocalModel>(HiveBoxes.complaints, complaintId);

        // Search by ticketNumber / localId if direct key not found
        if (stored == null) {
          final all = await _storage.getAll<ComplaintLocalModel>(HiveBoxes.complaints);
          for (final item in all) {
            if (item.id == complaintId || item.ticketNumber == complaintId || item.localId == complaintId) {
              stored = item;
              break;
            }
          }
        }

        if (stored != null) {
          final updated = stored.copyWith(
            syncStatus: status.name,
            serverId: serverId ?? stored.serverId,
          );
          await _storage.put<ComplaintLocalModel>(HiveBoxes.complaints, updated.id, updated);
        }
      } catch (e) {
        debugPrint('Warning: Failed updating sync status in Hive: $e');
      }

      // 2. If status is synced, remove or update from pending_sync box
      try {
        final syncKey = 'sync_$complaintId';
        if (status == SyncStatus.synced) {
          await _storage.delete(HiveBoxes.pendingSync, syncKey);
        } else {
          final syncItem = await _storage.get<PendingSyncLocalModel>(HiveBoxes.pendingSync, syncKey);
          if (syncItem != null) {
            await _storage.put<PendingSyncLocalModel>(
              HiveBoxes.pendingSync,
              syncKey,
              syncItem.copyWith(syncStatus: status.name),
            );
          }
        }
      } catch (e) {
        debugPrint('Warning: Failed updating pending_sync box: $e');
      }
    }

    // 3. Update in-memory data source
    final index = _dataSource.complaints.indexWhere(
      (c) => c.id == complaintId || c.localId == complaintId || c.ticketNumber == complaintId,
    );
    if (index != -1) {
      final current = _dataSource.complaints[index];
      _dataSource.complaints[index] = current.copyWith(
        syncStatus: status,
        serverId: serverId ?? current.serverId,
      );
    }
  }

  @override
  Future<List<ComplaintModel>> getCitizenComplaints(String citizenId) async {
    if (_storage.isInitialized) {
      try {
        final localComplaints = await _storage.getAll<ComplaintLocalModel>(HiveBoxes.complaints);
        if (localComplaints.isNotEmpty) {
          final domainComplaints = localComplaints.map((e) => e.toDomain()).toList();
          // Sort newest first
          domainComplaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return domainComplaints.where((c) {
            if (citizenId.isEmpty) return true;
            return c.citizenId == citizenId ||
                c.citizenId == 'user_citizen_001' ||
                c.citizenId == 'user_001';
          }).toList();
        }
      } catch (e) {
        debugPrint('Warning: Failed to fetch citizen complaints from Hive: $e');
      }
    }

    // Fallback to in-memory dataSource
    return List.unmodifiable(
      _dataSource.complaints.where((c) {
        if (citizenId.isEmpty) return true;
        return c.citizenId == citizenId ||
            c.citizenId == 'user_citizen_001' ||
            c.citizenId == 'user_001';
      }).toList(),
    );
  }

  @override
  Future<List<ComplaintModel>> getComplaints() async {
    if (_storage.isInitialized) {
      try {
        final localComplaints = await _storage.getAll<ComplaintLocalModel>(HiveBoxes.complaints);
        if (localComplaints.isNotEmpty) {
          final list = localComplaints.map((e) => e.toDomain()).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        }
      } catch (e) {
        debugPrint('Warning: Failed to fetch all complaints from Hive: $e');
      }
    }

    return List.unmodifiable(_dataSource.complaints);
  }

  @override
  Future<ComplaintModel?> getComplaintById(String id) async {
    if (_storage.isInitialized) {
      try {
        final local = await _storage.get<ComplaintLocalModel>(HiveBoxes.complaints, id);
        if (local != null) {
          return local.toDomain();
        }

        // Check all items for ticket number or localId match
        final all = await _storage.getAll<ComplaintLocalModel>(HiveBoxes.complaints);
        for (final item in all) {
          if (item.id == id || item.ticketNumber == id || item.localId == id) {
            return item.toDomain();
          }
        }
      } catch (e) {
        debugPrint('Warning: Failed finding complaint by ID from Hive: $e');
      }
    }

    try {
      return _dataSource.complaints.firstWhere(
        (c) => c.id == id || c.ticketNumber == id || c.localId == id,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ComplaintModel?> getComplaintByTicketId(String ticketId) async {
    if (_storage.isInitialized) {
      try {
        final all = await _storage.getAll<ComplaintLocalModel>(HiveBoxes.complaints);
        for (final item in all) {
          if (item.ticketNumber.toLowerCase() == ticketId.toLowerCase() ||
              item.id.toLowerCase() == ticketId.toLowerCase() ||
              (item.localId != null && item.localId!.toLowerCase() == ticketId.toLowerCase())) {
            return item.toDomain();
          }
        }
      } catch (e) {
        debugPrint('Warning: Failed finding complaint by ticketId from Hive: $e');
      }
    }

    try {
      return _dataSource.complaints.firstWhere(
        (c) =>
            c.ticketNumber.toLowerCase() == ticketId.toLowerCase() ||
            c.id == ticketId ||
            (c.localId != null && c.localId!.toLowerCase() == ticketId.toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }

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
    _ticketCounter++;
    final formattedCounter = _ticketCounter.toString().padLeft(6, '0');
    final ticketNum = 'CF-2026-$formattedCounter';
    final newId = 'cmp_${DateTime.now().millisecondsSinceEpoch}';

    final newComplaint = ComplaintModel(
      id: newId,
      citizenId: citizenId,
      ticketNumber: ticketNum,
      title: title,
      description: description,
      category: category,
      status: ComplaintStatus.reported,
      priority: priority,
      location: location,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isHazard: isHazard,
      syncStatus: SyncStatus.synced,
      timeline: [
        TimelineEvent(
          title: 'Issue Reported',
          description: 'Ticket created and assigned to Ward ${location.ward ?? "Central"}.',
          timestamp: DateTime.now(),
          status: ComplaintStatus.reported,
        ),
      ],
    );

    // Save to Hive
    if (_storage.isInitialized) {
      try {
        await _storage.put<ComplaintLocalModel>(
          HiveBoxes.complaints,
          newComplaint.id,
          ComplaintLocalModel.fromDomain(newComplaint),
        );
      } catch (e) {
        debugPrint('Warning: Failed saving new complaint to Hive: $e');
      }
    }

    _dataSource.complaints.insert(0, newComplaint);

    if (isHazard) {
      final hazard = HazardModel(
        id: 'haz_${newComplaint.id}',
        complaintId: newComplaint.id,
        ticketNumber: newComplaint.ticketNumber,
        title: newComplaint.title,
        category: newComplaint.category,
        status: newComplaint.status,
        latitude: newComplaint.location.latitude,
        longitude: newComplaint.location.longitude,
        address: newComplaint.location.address,
        landmark: newComplaint.location.landmark,
        ward: newComplaint.location.ward,
        severity: newComplaint.priority == ComplaintPriority.emergency
            ? HazardSeverity.critical
            : newComplaint.priority == ComplaintPriority.high
                ? HazardSeverity.high
                : HazardSeverity.medium,
        imageUrl: newComplaint.imageUrls.isNotEmpty ? newComplaint.imageUrls.first : null,
        createdAt: newComplaint.createdAt,
        updatedAt: newComplaint.updatedAt,
      );
      _dataSource.hazards.insert(0, hazard);
    }

    // Update user stats
    final updatedUser = _dataSource.currentUser.copyWith(
      reportsSubmitted: _dataSource.currentUser.reportsSubmitted + 1,
      civicPoints: _dataSource.currentUser.civicPoints + 20,
    );
    _dataSource.currentUser = updatedUser;

    return newComplaint;
  }

  @override
  Future<void> upvoteComplaint(String id) async {
    final complaint = await getComplaintById(id);
    if (complaint != null) {
      final updated = complaint.copyWith(upvotes: complaint.upvotes + 1);
      if (_storage.isInitialized) {
        try {
          await _storage.put<ComplaintLocalModel>(
            HiveBoxes.complaints,
            updated.id,
            ComplaintLocalModel.fromDomain(updated),
          );
        } catch (e) {
          debugPrint('Warning: Failed saving upvote to Hive: $e');
        }
      }

      final index = _dataSource.complaints.indexWhere((c) => c.id == id || c.ticketNumber == id);
      if (index != -1) {
        _dataSource.complaints[index] = updated;
      }
    }
  }

  DateTime? _lastCachedAt;
  DateTime? get lastCachedAt => _lastCachedAt;

  /// Bulk cache a snapshot of complaints from server into Hive.
  Future<void> cacheComplaints(List<ComplaintModel> complaints) async {
    if (_storage.isInitialized) {
      try {
        final Map<String, ComplaintLocalModel> entries = {
          for (final c in complaints) c.id: ComplaintLocalModel.fromDomain(c),
        };
        await _storage.putAll<ComplaintLocalModel>(HiveBoxes.complaints, entries);
        _lastCachedAt = DateTime.now();
      } catch (e) {
        debugPrint('Warning: HiveComplaintRepository.cacheComplaints fallback: $e');
      }
    }

    for (final c in complaints) {
      final index = _dataSource.complaints.indexWhere((item) => item.id == c.id);
      if (index != -1) {
        _dataSource.complaints[index] = c;
      } else {
        _dataSource.complaints.add(c);
      }
    }
  }

  /// Delete a complaint from persistent cache and in-memory data source.
  Future<void> deleteComplaint(String id) async {
    if (_storage.isInitialized) {
      try {
        await _storage.delete(HiveBoxes.complaints, id);
        await _storage.delete(HiveBoxes.pendingSync, 'sync_$id');
        await _storage.delete(HiveBoxes.hazards, 'haz_$id');
      } catch (e) {
        debugPrint('Warning: HiveComplaintRepository.deleteComplaint error: $e');
      }
    }

    _dataSource.complaints.removeWhere((c) => c.id == id || c.ticketNumber == id || c.localId == id);
    _dataSource.hazards.removeWhere((h) => h.complaintId == id || h.id == 'haz_$id');
  }

  /// Purge old temporary complaints cache that exceeds maxAge.
  /// 
  /// STRICT RULE: NEVER deletes pending offline complaints (syncStatus == pending).
  Future<void> clearStaleComplaints({Duration maxAge = const Duration(days: 14)}) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = nowMs - maxAge.inMilliseconds;

    if (_storage.isInitialized) {
      try {
        final all = await _storage.getAll<ComplaintLocalModel>(HiveBoxes.complaints);

        for (final item in all) {
          // Never purge pending sync items!
          if (item.syncStatus == 'pending') continue;

          // If synced and older than cutoff
          if (item.updatedAtEpochMs < cutoffMs && item.status == 'resolved') {
            await _storage.delete(HiveBoxes.complaints, item.id);
          }
        }
      } catch (e) {
        debugPrint('Warning: HiveComplaintRepository.clearStaleComplaints error: $e');
      }
    }

    _dataSource.complaints.removeWhere((c) =>
        c.syncStatus != SyncStatus.pending &&
        c.updatedAt.millisecondsSinceEpoch < cutoffMs &&
        c.status == ComplaintStatus.resolved);
  }

  @override
  Future<List<ComplaintModel>> getNearbyHazards() async {
    try {
      final all = await getComplaints();
      return all
          .where((c) =>
              c.isHazard ||
              c.priority == ComplaintPriority.emergency ||
              c.priority == ComplaintPriority.high)
          .toList();
    } catch (_) {
      return _dataSource.complaints
          .where((c) =>
              c.isHazard ||
              c.priority == ComplaintPriority.emergency ||
              c.priority == ComplaintPriority.high)
          .toList();
    }
  }
}
