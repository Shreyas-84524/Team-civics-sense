import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:civic_app/core/map/map_chunk_manager.dart';
import 'package:civic_app/core/map/spatial_chunk.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';
import 'package:civic_app/core/repositories/hazard_repository.dart';
import 'package:civic_app/User UI/widgets/hazard_map/hazard_info_card.dart';

class MockTestHazardRepository extends HazardRepository {
  final List<HazardModel> cannedHazards;
  final List<List<String>> requestedChunkBatches = [];
  int fetchCallCount = 0;
  Duration delay = Duration.zero;

  MockTestHazardRepository({this.cannedHazards = const []});

  @override
  Future<List<HazardModel>> getNearbyHazards({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    return cannedHazards;
  }

  @override
  Future<List<HazardModel>> getHazardsInChunks({
    required List<String> chunkIds,
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
    int limit = 200,
  }) async {
    fetchCallCount++;
    requestedChunkBatches.add(List.from(chunkIds));
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return cannedHazards.where((h) => chunkIds.contains(h.computedSpatialChunkId)).toList();
  }

  @override
  Future<List<HazardModel>> getHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
    int limit = 100,
  }) async {
    return cannedHazards;
  }

  @override
  Stream<List<HazardModel>> watchHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  }) {
    return Stream.value(cannedHazards);
  }

  @override
  Future<HazardModel?> getHazardById(String id) async {
    try {
      return cannedHazards.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<HazardModel?> watchHazardById(String id) {
    try {
      return Stream.value(cannedHazards.firstWhere((h) => h.id == id));
    } catch (_) {
      return Stream.value(null);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeohashUtils & SpatialBounds', () {
    test('encode produces standard precision 5 geohashes for Mumbai coordinates', () {
      final hash = GeohashUtils.encode(19.0760, 72.8777, precision: 5);
      expect(hash.length, 5);
      expect(hash.startsWith('te7'), isTrue);
    });

    test('getChunksForBounds includes surrounding buffer when bufferRatio > 0', () {
      // Small Mumbai bounding box
      const minLat = 19.05;
      const minLng = 72.85;
      const maxLat = 19.10;
      const maxLng = 72.90;

      final chunksWithoutBuffer = GeohashUtils.getChunksForBounds(
        minLat: minLat,
        minLng: minLng,
        maxLat: maxLat,
        maxLng: maxLng,
        bufferRatio: 0.0,
      );

      final chunksWithBuffer = GeohashUtils.getChunksForBounds(
        minLat: minLat,
        minLng: minLng,
        maxLat: maxLat,
        maxLng: maxLng,
        bufferRatio: 0.25,
      );

      expect(chunksWithBuffer.length, greaterThanOrEqualTo(chunksWithoutBuffer.length));
      for (final chunk in chunksWithoutBuffer) {
        expect(chunksWithBuffer.contains(chunk), isTrue);
      }
    });

    test('decodeBounds returns valid bounding coordinates containing the center', () {
      const lat = 19.0760;
      const lng = 72.8777;
      final hash = GeohashUtils.encode(lat, lng, precision: 5);
      final bounds = GeohashUtils.decodeBounds(hash);

      expect(lat, greaterThanOrEqualTo(bounds.south));
      expect(lat, lessThanOrEqualTo(bounds.north));
      expect(lng, greaterThanOrEqualTo(bounds.west));
      expect(lng, lessThanOrEqualTo(bounds.east));
    });
  });

  group('MapChunkManager', () {
    late MapChunkManager chunkManager;
    late MockTestHazardRepository repo;
    late HazardModel sampleHazard1;
    late HazardModel sampleHazard2;

    setUp(() {
      chunkManager = MapChunkManager();

      sampleHazard1 = HazardModel(
        id: 'hz_101',
        complaintId: 'cmp_101',
        ticketNumber: 'CF-2026-00101',
        title: 'Deep Pothole at Bandra West',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.inProgress,
        latitude: 19.0596,
        longitude: 72.8295,
        address: 'Hill Road, Bandra West',
        severity: HazardSeverity.high,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      sampleHazard2 = HazardModel(
        id: 'hz_102',
        complaintId: 'cmp_102',
        ticketNumber: 'CF-2026-00102',
        title: 'Fallen Tree at Dadar',
        category: CivicCategory.defaultCategories[1],
        status: ComplaintStatus.underVerification,
        latitude: 19.0178,
        longitude: 72.8478,
        address: 'Dadar TT Circle',
        severity: HazardSeverity.critical,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      repo = MockTestHazardRepository(cannedHazards: [sampleHazard1, sampleHazard2]);
    });

    tearDown(() {
      chunkManager.dispose();
    });

    test('loads chunks for visible bounds and caches them in memory', () async {
      final bounds = LatLngBounds(
        southwest: const LatLng(19.04, 72.81),
        northeast: const LatLng(19.08, 72.85),
      );

      await chunkManager.onCameraIdle(
        bounds: bounds,
        repository: repo,
        debounce: Duration.zero,
      );

      expect(repo.fetchCallCount, 1);
      expect(chunkManager.loadedChunkCount, greaterThan(0));
      expect(chunkManager.allCachedHazards.any((h) => h.id == 'hz_101'), isTrue);

      // Re-invoking the same bounds should use cache and trigger 0 new network calls
      await chunkManager.onCameraIdle(
        bounds: bounds,
        repository: repo,
        debounce: Duration.zero,
      );

      expect(repo.fetchCallCount, 1); // No new network call
    });

    test('debounces camera idle events', () async {
      final bounds = LatLngBounds(
        southwest: const LatLng(19.04, 72.81),
        northeast: const LatLng(19.08, 72.85),
      );

      // Trigger 3 calls rapidly
      chunkManager.onCameraIdle(bounds: bounds, repository: repo, debounce: const Duration(milliseconds: 50));
      chunkManager.onCameraIdle(bounds: bounds, repository: repo, debounce: const Duration(milliseconds: 50));
      final future = chunkManager.onCameraIdle(bounds: bounds, repository: repo, debounce: const Duration(milliseconds: 50));

      await future;
      // Only 1 execution occurred after debounce completed
      expect(repo.fetchCallCount, 1);
    });

    test('updateHazard updates cache and notifies listeners', () async {
      chunkManager.seedInitialHazards([sampleHazard1]);
      expect(chunkManager.allCachedHazards.first.status, ComplaintStatus.inProgress);

      bool notified = false;
      chunkManager.addListener(() => notified = true);

      final updated = sampleHazard1.copyWith(status: ComplaintStatus.resolved);
      chunkManager.updateHazard(updated);

      expect(notified, isTrue);
      expect(chunkManager.allCachedHazards.first.status, ComplaintStatus.resolved);
      expect(chunkManager.allCachedHazards.first.citizenPhaseLabel, 'Resolved');
    });

    test('clearCache resets state and allows re-fetching', () async {
      chunkManager.seedInitialHazards([sampleHazard1]);
      expect(chunkManager.loadedChunkCount, greaterThan(0));

      chunkManager.clearCache();
      expect(chunkManager.loadedChunkCount, 0);
      expect(chunkManager.allCachedHazards, isEmpty);
    });
  });

  group('HazardInfoCard widget tests', () {
    testWidgets('renders issue title, category, relative time and mapped citizen phase label', (tester) async {
      final hazard = HazardModel(
        id: 'hz_test_99',
        ticketNumber: 'CF-2026-99999',
        title: 'Broken Water Pipeline',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.inProgress,
        latitude: 19.0760,
        longitude: 72.8777,
        address: 'MG Road, Fort',
        severity: HazardSeverity.high,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        updatedAt: DateTime.now(),
      );

      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HazardInfoCard(
              hazard: hazard,
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      expect(find.text('Broken Water Pipeline'), findsOneWidget);
      expect(find.text('CF-2026-99999'), findsOneWidget);
      expect(find.text('Current Phase'), findsOneWidget);
      expect(find.text('Work In Progress'), findsOneWidget); // Mapped citizen friendly label
      expect(find.textContaining('Reported'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);

      // Tap close button
      await tester.tap(find.byTooltip('Close complaint card'));
      expect(closed, isTrue);
    });

    testWidgets('renders Under Verification phase label correctly', (tester) async {
      final hazard = HazardModel(
        id: 'hz_test_uv',
        title: 'Hazard Under Verification',
        category: CivicCategory.defaultCategories[1],
        status: ComplaintStatus.underVerification,
        latitude: 19.0760,
        longitude: 72.8777,
        address: 'Bandra',
        severity: HazardSeverity.medium,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HazardInfoCard(
              hazard: hazard,
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('Under Verification'), findsOneWidget);
    });
  });
}
