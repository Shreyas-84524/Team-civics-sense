import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/map/map_config.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';
import 'package:civic_app/core/repositories/complaint_repository.dart';
import 'package:civic_app/core/repositories/hazard_repository.dart';
import 'package:civic_app/core/routing/app_routes.dart';
import 'package:civic_app/User UI/screens/hazard_map_screen.dart';
import 'package:civic_app/User UI/services/location_service.dart';
import 'package:civic_app/User UI/widgets/hazard_map/hazard_info_card.dart';
import 'package:civic_app/User UI/widgets/hazard_map/hazard_marker.dart';

class _MockHazardRepo extends HazardRepository {
  final StreamController<List<HazardModel>> _controller = StreamController<List<HazardModel>>.broadcast();
  List<HazardModel> _current = [];

  _MockHazardRepo(List<HazardModel> initial) {
    _current = initial;
  }

  void emit(List<HazardModel> list) {
    _current = list;
    _controller.add(list);
  }

  @override
  Stream<List<HazardModel>> watchHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  }) async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<List<HazardModel>> getHazards({
    String? categoryId,
    ComplaintStatus? status,
    HazardSeverity? severity,
    String? searchQuery,
  }) async {
    return _current;
  }

  @override
  Future<HazardModel?> getHazardById(String id) async {
    try {
      return _current.firstWhere((h) => h.id == id);
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
    return _current;
  }

  @override
  Stream<HazardModel?> watchHazardById(String id) {
    return _controller.stream.map((list) {
      try {
        return list.firstWhere((h) => h.id == id);
      } catch (_) {
        return null;
      }
    });
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
    return _current;
  }

  void dispose() {
    _controller.close();
  }
}

class _MockComplaintRepo implements ComplaintRepository {
  final Map<String, ComplaintModel> _complaints = {};

  void add(ComplaintModel c) {
    _complaints[c.id] = c;
    if (c.ticketNumber.isNotEmpty) {
      _complaints[c.ticketNumber] = c;
    }
  }

  @override
  Future<ComplaintModel?> getComplaintById(String id) async => _complaints[id];

  @override
  Future<ComplaintModel?> getComplaintByTicketId(String ticketId) async => _complaints[ticketId];

  @override
  Stream<ComplaintModel?> watchComplaint(String id) {
    return Stream.value(_complaints[id]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testReportDate = DateTime.now().subtract(const Duration(minutes: 18));

  final complaintA = ComplaintModel(
    id: 'cmp_road_001',
    ticketNumber: 'CF-2026-000101',
    title: 'Broken Road on Link Road',
    description: 'Deep potholes and broken pavement',
    category: CivicCategory.defaultCategories[0], // Potholes
    status: ComplaintStatus.inProgress,
    priority: ComplaintPriority.high,
    location: const CivicLocation(
      latitude: 19.0760,
      longitude: 72.8777,
      address: 'Link Road, Andheri West',
      ward: 'K/West',
    ),
    isHazard: true,
    createdAt: testReportDate,
    updatedAt: testReportDate,
  );

  final complaintB = ComplaintModel(
    id: 'cmp_drain_002',
    ticketNumber: 'CF-2026-000102',
    title: 'Open Drain Near Metro',
    description: 'Hazardous uncovered drainage pit',
    category: CivicCategory.defaultCategories[2], // Drainage
    status: ComplaintStatus.verified,
    priority: ComplaintPriority.emergency,
    location: const CivicLocation(
      latitude: 19.1136,
      longitude: 72.8697,
      address: 'Metro Station Gate 2, Andheri',
      ward: 'K/East',
    ),
    isHazard: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  final hazardA = HazardModel.fromComplaint(complaintA);
  final hazardB = HazardModel.fromComplaint(complaintB);

  setUp(() {
    MapConfig.setApiKeyForTesting('');
  });

  tearDown(() {
    MapConfig.resetForTesting();
  });

  group('Complaint Floating Info Card & Touch Interaction Tests', () {
    testWidgets('HazardInfoCard renders real title, formatted reported timestamp, and readable status badge', (tester) async {
      final mockRepo = _MockComplaintRepo();
      mockRepo.add(complaintA);

      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HazardInfoCard(
              hazard: hazardA,
              complaintRepository: mockRepo,
              onClose: () => closed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Complaint / Report Title
      expect(find.text('Broken Road on Link Road'), findsOneWidget);

      // 2. Reported Timestamp (createdAt)
      expect(find.text('Reported 18m ago'), findsOneWidget);

      // 3. Current Working Phase
      expect(find.text('Current Phase'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Text && (w.data == 'Work In Progress' || w.data == 'In Progress')), findsOneWidget);

      // 4. Ticket number & Category
      expect(find.text('CF-2026-000101'), findsOneWidget);
      expect(find.text(complaintA.category.name), findsOneWidget);

      // 5. Close button test
      final closeBtn = find.byTooltip('Close complaint card');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      expect(closed, isTrue);
    });

    testWidgets('CamelCase complaint statuses are converted to readable status labels', (tester) async {
      expect(ComplaintStatus.reported.label, equals('Reported'));
      expect(ComplaintStatus.verified.label, equals('Verified'));
      expect(ComplaintStatus.assigned.label, equals('Assigned'));
      expect(ComplaintStatus.inProgress.label, anyOf(equals('Work In Progress'), equals('In Progress')));
      expect(ComplaintStatus.resolved.label, equals('Resolved'));
      expect(ComplaintStatus.rejected.label, equals('Rejected'));
    });

    testWidgets('Tapping View Details navigates to complaint details route with arguments', (tester) async {
      final mockRepo = _MockComplaintRepo();
      mockRepo.add(complaintA);

      bool detailsNavigated = false;
      Object? receivedArgs;

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.complaintDetails) {
              detailsNavigated = true;
              receivedArgs = settings.arguments;
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Complaint Details View')),
              );
            }
            return null;
          },
          home: Scaffold(
            body: HazardInfoCard(
              hazard: hazardA,
              complaintRepository: mockRepo,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('View Details'), findsOneWidget);
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      expect(detailsNavigated, isTrue);
      expect(receivedArgs, isNotNull);
    });

    testWidgets('HazardMapScreen: Tapping complaint A shows card A, tapping B replaces with card B, empty tap dismisses card', (tester) async {
      final mockHazardRepo = _MockHazardRepo([hazardA, hazardB]);
      final mockComplaintRepo = _MockComplaintRepo();
      mockComplaintRepo.add(complaintA);
      mockComplaintRepo.add(complaintB);

      await tester.pumpWidget(
        MaterialApp(
          home: HazardMapScreen(
            hazardRepository: mockHazardRepo,
            complaintRepository: mockComplaintRepo,
            locationService: MockLocationService(),
          ),
        ),
      );
      // Emit initial list
      mockHazardRepo.emit([hazardA, hazardB]);
      await tester.pumpAndSettle();

      // Initially no floating card is visible
      expect(find.byType(HazardInfoCard), findsNothing);

      // Tap Complaint Marker A
      await tester.tap(find.byWidgetPredicate((w) => w is HazardMarker && w.hazard.id == hazardA.id));
      await tester.pumpAndSettle();

      // Card A is displayed
      expect(find.byType(HazardInfoCard), findsOneWidget);
      expect(find.text('Broken Road on Link Road'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Text && (w.data == 'Work In Progress' || w.data == 'In Progress')), findsOneWidget);

      // Tap Complaint Marker B
      await tester.tap(find.byWidgetPredicate((w) => w is HazardMarker && w.hazard.id == hazardB.id));
      await tester.pumpAndSettle();

      // Card B replaces Card A
      expect(find.byType(HazardInfoCard), findsOneWidget);
      expect(find.text('Open Drain Near Metro'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Broken Road on Link Road'), findsNothing);

      // Tap Close button on Card B
      await tester.tap(find.byTooltip('Close complaint card'));
      await tester.pumpAndSettle();
      expect(find.byType(HazardInfoCard), findsNothing);

      // Re-select Card A
      await tester.tap(find.byWidgetPredicate((w) => w is HazardMarker && w.hazard.id == hazardA.id));
      await tester.pumpAndSettle();
      expect(find.byType(HazardInfoCard), findsOneWidget);

      // Tap on empty map area (dismiss card)
      await tester.tapAt(const Offset(50, 250));
      await tester.pumpAndSettle();
      expect(find.byType(HazardInfoCard), findsNothing);

      mockHazardRepo.dispose();
    });

    testWidgets('Live Status Update: Firestore/Stream update refreshes active selected card status', (tester) async {
      final mockHazardRepo = _MockHazardRepo([hazardA]);
      final mockComplaintRepo = _MockComplaintRepo();
      mockComplaintRepo.add(complaintA);

      await tester.pumpWidget(
        MaterialApp(
          home: HazardMapScreen(
            hazardRepository: mockHazardRepo,
            complaintRepository: mockComplaintRepo,
            locationService: MockLocationService(),
          ),
        ),
      );
      mockHazardRepo.emit([hazardA]);
      await tester.pumpAndSettle();

      // Tap Complaint Marker A (currently In Progress)
      await tester.tap(find.byWidgetPredicate((w) => w is HazardMarker && w.hazard.id == hazardA.id));
      await tester.pumpAndSettle();

      expect(find.byType(HazardInfoCard), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Text && (w.data == 'Work In Progress' || w.data == 'In Progress')), findsOneWidget);

      // Simulate backend updating complaint status to Resolved
      final resolvedComplaintA = complaintA.copyWith(status: ComplaintStatus.resolved);
      final resolvedHazardA = HazardModel.fromComplaint(resolvedComplaintA);

      mockHazardRepo.emit([resolvedHazardA]);
      await tester.pumpAndSettle();

      // Selected card must now reflect Resolved status automatically
      expect(find.byType(HazardInfoCard), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('In Progress'), findsNothing);
      expect(find.text('Work In Progress'), findsNothing);

      mockHazardRepo.dispose();
    });

    testWidgets('Basemap switch preserves active selected card and map interactions', (tester) async {
      final mockHazardRepo = _MockHazardRepo([hazardA]);
      final mockComplaintRepo = _MockComplaintRepo();

      await tester.pumpWidget(
        MaterialApp(
          home: HazardMapScreen(
            hazardRepository: mockHazardRepo,
            complaintRepository: mockComplaintRepo,
            locationService: MockLocationService(),
          ),
        ),
      );
      mockHazardRepo.emit([hazardA]);
      await tester.pumpAndSettle();

      // Select Complaint A
      await tester.tap(find.byWidgetPredicate((w) => w is HazardMarker && w.hazard.id == hazardA.id));
      await tester.pumpAndSettle();
      expect(find.byType(HazardInfoCard), findsOneWidget);

      // Open Basemap selector sheet
      expect(find.byTooltip('Basemap Style (Streets)'), findsOneWidget);
      await tester.tap(find.byTooltip('Basemap Style (Streets)'));
      await tester.pumpAndSettle();

      // Switch to Satellite mode
      expect(find.text('Satellite'), findsOneWidget);
      await tester.tap(find.text('Satellite'));
      await tester.pumpAndSettle();

      // Floating card is retained cleanly
      expect(find.byType(HazardInfoCard), findsOneWidget);
      expect(find.text('Broken Road on Link Road'), findsOneWidget);

      mockHazardRepo.dispose();
    });
  });
}
