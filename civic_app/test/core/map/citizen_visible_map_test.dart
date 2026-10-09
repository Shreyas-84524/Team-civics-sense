import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/auth/auth_service_locator.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/map/civic_map_canvas.dart';
import 'package:civic_app/core/map/map_config.dart';
import 'package:civic_app/core/map/spatial_data_service.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/repositories/complaint_repository.dart';
import 'package:civic_app/core/repositories/hazard_repository.dart';
import 'package:civic_app/core/repositories/repository_locator.dart';
import 'package:civic_app/User UI/screens/hazard_map_screen.dart';
import 'package:civic_app/User UI/services/mock_auth_service.dart';
import 'package:civic_app/User UI/services/location_service.dart';
import 'package:civic_app/User UI/widgets/hazard_map/hazard_info_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuth;
  late MockComplaintRepository mockComplaintRepo;

  const citizenAId = 'citizen_user_aaa';
  const citizenBId = 'citizen_user_bbb';

  final publicHazardComplaint = ComplaintModel(
    id: 'cmp_pub_001',
    citizenId: citizenBId,
    ticketNumber: 'CF-2026-000101',
    title: 'Open Manhole on Link Road',
    description: 'Dangerous open manhole near junction',
    category: CivicCategory.defaultCategories[2], // Drainage / Manhole
    status: ComplaintStatus.reported,
    priority: ComplaintPriority.emergency,
    location: const CivicLocation(
      latitude: 19.1136,
      longitude: 72.8697,
      address: 'Link Road, Andheri West',
      ward: 'K/West',
    ),
    isHazard: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  final citizenAOwnComplaint = ComplaintModel(
    id: 'cmp_own_001',
    citizenId: citizenAId,
    ticketNumber: 'CF-2026-000102',
    title: 'Street Light Flickering',
    description: 'Street light pole #14 is flickering at night',
    category: CivicCategory.defaultCategories[4], // Streetlights
    status: ComplaintStatus.inProgress,
    priority: ComplaintPriority.medium,
    location: const CivicLocation(
      latitude: 19.0760,
      longitude: 72.8777,
      address: 'Station Road, Dadar',
      ward: 'G/North',
    ),
    isHazard: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
  );

  final citizenBOtherComplaint = ComplaintModel(
    id: 'cmp_other_001',
    citizenId: citizenBId,
    ticketNumber: 'CF-2026-000103',
    title: 'Garbage Dump Near School',
    description: 'Commercial waste dumped on sidewalk',
    category: CivicCategory.defaultCategories[3], // Waste Management
    status: ComplaintStatus.reported,
    priority: ComplaintPriority.low,
    location: const CivicLocation(
      latitude: 19.1726,
      longitude: 72.8426,
      address: 'SV Road, Malad',
      ward: 'P/North',
    ),
    isHazard: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
  );

  setUp(() {
    MapConfig.setApiKeyForTesting('');
    mockAuth = MockAuthService();
    mockAuth.resetForTesting();
    mockAuth.setMockUser(const UserModel(
      id: citizenAId,
      fullName: 'Citizen Alpha',
      email: 'alpha@civicfix.test',
      phone: '+91 98765 00001',
    ));
    AuthServiceLocator.citizenAuth = mockAuth;

    mockComplaintRepo = MockComplaintRepository();
    RepositoryLocator.reset();
  });

  tearDown(() {
    mockAuth.resetForTesting();
    RepositoryLocator.reset();
    MapConfig.resetForTesting();
  });

  group('Citizen Visible Location Map Tests', () {
    test('HazardModel.fromComplaint correctly preserves coordinates, identifiers and attributes', () {
      final derived = HazardModel.fromComplaint(publicHazardComplaint);

      expect(derived.id, equals('haz_${publicHazardComplaint.id}'));
      expect(derived.complaintId, equals(publicHazardComplaint.id));
      expect(derived.ticketNumber, equals(publicHazardComplaint.ticketNumber));
      expect(derived.title, equals(publicHazardComplaint.title));
      expect(derived.latitude, equals(19.1136));
      expect(derived.longitude, equals(72.8697));
      expect(derived.address, equals('Link Road, Andheri West'));
      expect(derived.ward, equals('K/West'));
      expect(derived.status, equals(ComplaintStatus.reported));
    });

    test('SpatialDataService builds GeoJSON with [longitude, latitude] coordinate ordering', () {
      const spatialService = SpatialDataService();
      final featureCollection = spatialService.buildFeatureCollection(
        complaints: [publicHazardComplaint, citizenAOwnComplaint],
      );

      expect(featureCollection['type'], equals('FeatureCollection'));
      final features = featureCollection['features'] as List;
      expect(features.length, equals(2));

      final firstGeometry = features[0]['geometry'] as Map<String, dynamic>;
      expect(firstGeometry['type'], equals('Point'));
      final firstCoords = firstGeometry['coordinates'] as List;
      // GeoJSON standard: [longitude, latitude]
      expect(firstCoords[0], equals(72.8697));
      expect(firstCoords[1], equals(19.1136));
    });

    test('getCitizenVisibleComplaints returns public hazards and signed-in citizen reports, isolating other non-hazards', () async {
      await mockComplaintRepo.saveOfflineComplaint(publicHazardComplaint);
      await mockComplaintRepo.saveOfflineComplaint(citizenAOwnComplaint);
      await mockComplaintRepo.saveOfflineComplaint(citizenBOtherComplaint);

      final visibleForCitizenA = await mockComplaintRepo.getCitizenVisibleComplaints(
        citizenId: citizenAId,
      );

      // Should contain publicHazardComplaint and citizenAOwnComplaint, but NOT citizenBOtherComplaint
      final ids = visibleForCitizenA.map((c) => c.id).toSet();
      expect(ids.contains(publicHazardComplaint.id), isTrue, reason: 'Public hazard should be visible to citizen');
      expect(ids.contains(citizenAOwnComplaint.id), isTrue, reason: 'Own complaint should be visible to citizen');
      expect(ids.contains(citizenBOtherComplaint.id), isFalse, reason: "Other citizen's private non-hazard must not be exposed");
    });

    test('Deduplication prevents duplicate markers when complaint is both isHazard and owned by citizen', () async {
      final ownHazardComplaint = ComplaintModel(
        id: 'cmp_own_hazard_001',
        citizenId: citizenAId,
        ticketNumber: 'CF-2026-000109',
        title: 'Deep Waterlogging on Main Road',
        description: 'Road submerged under 2 feet of water',
        category: CivicCategory.defaultCategories[1],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.high,
        location: const CivicLocation(
          latitude: 19.0178,
          longitude: 72.8478,
          address: 'Hindmata, Dadar East',
        ),
        isHazard: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await mockComplaintRepo.saveOfflineComplaint(ownHazardComplaint);

      final visible = await mockComplaintRepo.getCitizenVisibleComplaints(
        citizenId: citizenAId,
      );

      final matching = visible.where((c) => c.id == ownHazardComplaint.id).toList();
      expect(matching.length, equals(1));
    });

    testWidgets('CivicMapCanvas renders markers from complaints property fallback', (tester) async {
      final haz1 = HazardModel.fromComplaint(publicHazardComplaint);
      final haz2 = HazardModel.fromComplaint(citizenAOwnComplaint);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              hazards: const [],
              complaints: [publicHazardComplaint, citizenAOwnComplaint],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Markers rendered via fallback basemap
      expect(find.byIcon(haz1.categoryIcon), findsOneWidget);
      expect(find.byIcon(haz2.categoryIcon), findsOneWidget);
    });

    testWidgets('HazardMapScreen renders citizen complaints reactively and supports marker selection', (tester) async {
      final haz1 = HazardModel.fromComplaint(publicHazardComplaint);
      final haz2 = HazardModel.fromComplaint(citizenAOwnComplaint);
      final hazardController = StreamController<List<HazardModel>>.broadcast();
      final mockHazardRepo = _TestHazardRepository(
        stream: hazardController.stream,
        initialHazards: [haz1, haz2],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HazardMapScreen(
            hazardRepository: mockHazardRepo,
            complaintRepository: mockComplaintRepo,
            locationService: MockLocationService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both markers should appear on the map
      expect(find.byIcon(haz1.categoryIcon), findsOneWidget);
      expect(find.byIcon(haz2.categoryIcon), findsOneWidget);

      // Tap on public hazard marker
      await tester.tap(find.byIcon(haz1.categoryIcon));
      await tester.pumpAndSettle();

      // Hazard info card should appear with complaint details
      expect(find.byType(HazardInfoCard), findsOneWidget);
      expect(find.text(publicHazardComplaint.title), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);

      await hazardController.close();
    });

    testWidgets('HazardInfoCard navigates to complaint details when View Details is pressed', (tester) async {
      await mockComplaintRepo.saveOfflineComplaint(publicHazardComplaint);
      final hazard = HazardModel.fromComplaint(publicHazardComplaint);

      bool navigated = false;

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == '/complaint-details') {
              navigated = true;
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Complaint Details Screen')),
              );
            }
            return null;
          },
          home: Scaffold(
            body: HazardInfoCard(
              hazard: hazard,
              onClose: () {},
              complaintRepository: mockComplaintRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('View Details'), findsOneWidget);
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      expect(navigated, isTrue);
    });

    testWidgets('HazardMapScreen zoom in and zoom out buttons execute without crashing or matrix conflicts', (tester) async {
      final haz1 = HazardModel.fromComplaint(publicHazardComplaint);
      final hazardController = StreamController<List<HazardModel>>.broadcast();
      final mockHazardRepo = _TestHazardRepository(
        stream: hazardController.stream,
        initialHazards: [haz1],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HazardMapScreen(
            hazardRepository: mockHazardRepo,
            complaintRepository: mockComplaintRepo,
            locationService: MockLocationService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Zoom In button
      expect(find.byTooltip('Zoom In'), findsOneWidget);
      await tester.tap(find.byTooltip('Zoom In'));
      await tester.pumpAndSettle();

      // Tap Zoom Out button
      expect(find.byTooltip('Zoom Out'), findsOneWidget);
      await tester.tap(find.byTooltip('Zoom Out'));
      await tester.pumpAndSettle();

      await hazardController.close();
    });

    testWidgets('HazardMapScreen locate-me centers on user location and shows confirmation SnackBar', (tester) async {
      final haz1 = HazardModel.fromComplaint(publicHazardComplaint);
      final hazardController = StreamController<List<HazardModel>>.broadcast();
      final mockHazardRepo = _TestHazardRepository(
        stream: hazardController.stream,
        initialHazards: [haz1],
      );

      const testUserLoc = CivicLocation(
        latitude: 19.0760,
        longitude: 72.8777,
        address: 'Dadar, Mumbai',
        ward: 'G/North',
        city: 'Mumbai',
        source: LocationSource.gps,
      );

      final mockLocService = MockLocationService(
        customGpsLocation: testUserLoc,
        permissionStatus: CivicPermissionStatus.granted,
        isServiceEnabled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HazardMapScreen(
            hazardRepository: mockHazardRepo,
            complaintRepository: mockComplaintRepo,
            locationService: mockLocService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Locate Me button
      expect(find.byTooltip('Use My Location'), findsOneWidget);
      await tester.tap(find.byTooltip('Use My Location'));
      await tester.pumpAndSettle();

      // Verify SnackBar appears with ward name
      expect(find.text('Centered on your location in G/North'), findsOneWidget);

      await hazardController.close();
    });

    testWidgets('HazardMapScreen locate-me displays polite warning when location service is disabled', (tester) async {
      final haz1 = HazardModel.fromComplaint(publicHazardComplaint);
      final hazardController = StreamController<List<HazardModel>>.broadcast();
      final mockHazardRepo = _TestHazardRepository(
        stream: hazardController.stream,
        initialHazards: [haz1],
      );

      final mockLocService = MockLocationService(
        isServiceEnabled: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HazardMapScreen(
            hazardRepository: mockHazardRepo,
            complaintRepository: mockComplaintRepo,
            locationService: mockLocService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Locate Me button
      await tester.tap(find.byTooltip('Use My Location'));
      await tester.pumpAndSettle();

      // Verify warning message is displayed
      expect(find.text('Location services are disabled on your device.'), findsOneWidget);

      await hazardController.close();
    });
  });
}

class _TestHazardRepository extends HazardRepository {
  final Stream<List<HazardModel>> stream;
  final List<HazardModel> initialHazards;

  _TestHazardRepository({required this.stream, required this.initialHazards});

  @override
  Future<List<HazardModel>> getHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  }) async {
    return initialHazards;
  }

  @override
  Future<HazardModel?> getHazardById(String id) async {
    try {
      return initialHazards.firstWhere((h) => h.id == id || h.complaintId == id);
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
    return initialHazards;
  }

  @override
  Stream<List<HazardModel>> watchHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  }) async* {
    yield initialHazards;
    yield* stream;
  }

  @override
  Stream<HazardModel?> watchHazardById(String id) async* {
    yield await getHazardById(id);
  }
}
