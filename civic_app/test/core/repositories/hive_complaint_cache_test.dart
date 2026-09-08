import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/local/hive/hive_initializer.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/repositories/hive_complaint_repository.dart';

void main() {
  group('HiveComplaintRepository Cache & History Tests', () {
    late Directory tempDir;
    late HiveComplaintRepository repository;

    final baseComplaint = ComplaintModel(
      id: 'cmp_cache_001',
      citizenId: 'user_citizen_001',
      ticketNumber: 'CF-2026-000500',
      title: 'Broken Traffic Light Signal',
      description: 'Signal stuck on red light.',
      category: CivicCategory.defaultCategories[7], // Traffic
      status: ComplaintStatus.inProgress,
      priority: ComplaintPriority.high,
      location: const CivicLocation(
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'MG Road signal',
      ),
      imageUrls: const ['https://example.com/signal.jpg'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      syncStatus: SyncStatus.synced,
      timeline: [
        TimelineEvent(
          title: 'Issue Reported',
          description: 'Grievance submitted by citizen.',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          status: ComplaintStatus.reported,
        ),
        TimelineEvent(
          title: 'Verified by Triage',
          description: 'Verified as high priority safety hazard.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          status: ComplaintStatus.verified,
          updatedBy: 'Officer Verma',
        ),
        TimelineEvent(
          title: 'Assigned to Electrical Dept',
          description: 'Work order dispatched to field unit.',
          timestamp: DateTime.now().subtract(const Duration(hours: 12)),
          status: ComplaintStatus.assigned,
          updatedBy: 'AE Traffic Div',
        ),
        TimelineEvent(
          title: 'Work In Progress',
          description: 'Technician on site replacing control circuit.',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          status: ComplaintStatus.inProgress,
          updatedBy: 'Inspector Rao',
        ),
      ],
    );

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('civic_complaint_cache_test_');
      await HiveInitializer.initialize(customPath: tempDir.path, isTest: true);
      await HiveInitializer.openEssentialBoxes();
      repository = HiveComplaintRepository();
      await repository.cacheComplaints([baseComplaint]);
    });

    tearDown(() async {
      await HiveInitializer.resetForTesting();
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('cacheComplaints stores and getComplaintById restores complete 5-stage timeline history', () async {
      final retrieved = await repository.getComplaintById('cmp_cache_001');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Broken Traffic Light Signal'));
      expect(retrieved.status, equals(ComplaintStatus.inProgress));
      expect(retrieved.timeline.length, equals(4));
      expect(retrieved.timeline[0].status, equals(ComplaintStatus.reported));
      expect(retrieved.timeline[1].updatedBy, equals('Officer Verma'));
      expect(retrieved.timeline[2].status, equals(ComplaintStatus.assigned));
      expect(retrieved.timeline[3].updatedBy, equals('Inspector Rao'));
    });

    test('deleteComplaint removes item from cache and in-memory lists', () async {
      await repository.deleteComplaint('cmp_cache_001');

      final deleted = await repository.getComplaintById('cmp_cache_001');
      expect(deleted, isNull);

      final all = await repository.getComplaints();
      expect(all.any((c) => c.id == 'cmp_cache_001'), isFalse);
    });

    test('clearStaleComplaints NEVER purges pending offline complaints while cleaning stale resolved items', () async {
      // 1. Add pending offline complaint (must never be deleted even if old)
      final pendingOffline = ComplaintModel(
        id: 'cmp_offline_never_delete',
        ticketNumber: 'LOCAL-2026-999999',
        localId: 'LOCAL-2026-999999',
        title: 'Emergency Gas Leak',
        description: 'Smell of gas near pipeline.',
        category: CivicCategory.defaultCategories[1],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.emergency,
        location: const CivicLocation(latitude: 12.9, longitude: 77.6, address: 'Old Airport Rd'),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
        syncStatus: SyncStatus.pending,
      );
      await repository.saveOfflineComplaint(pendingOffline);

      // 2. Add old resolved complaint (safe to clean up)
      final oldResolved = ComplaintModel(
        id: 'cmp_old_resolved',
        ticketNumber: 'CF-2026-000111',
        title: 'Old Fixed Pothole',
        description: 'Fixed 3 weeks ago.',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.resolved,
        priority: ComplaintPriority.low,
        location: const CivicLocation(latitude: 12.9, longitude: 77.6, address: 'Residency Rd'),
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(days: 20)),
        syncStatus: SyncStatus.synced,
      );
      await repository.cacheComplaints([oldResolved]);

      // 3. Trigger stale cleanup (14-day maxAge)
      await repository.clearStaleComplaints(maxAge: const Duration(days: 14));

      // 4. Verify old resolved was removed
      final resolvedCheck = await repository.getComplaintById('cmp_old_resolved');
      expect(resolvedCheck, isNull);

      // 5. Verify pending offline complaint is STRICTLY preserved
      final pendingCheck = await repository.getComplaintById('cmp_offline_never_delete');
      expect(pendingCheck, isNotNull);
      expect(pendingCheck!.syncStatus, equals(SyncStatus.pending));
    });
  });
}
