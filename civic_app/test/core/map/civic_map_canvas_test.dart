import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/map/civic_map_canvas.dart';
import 'package:civic_app/core/map/map_config.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';
import 'package:civic_app/Govt UI/widgets/map/govt_map_canvas.dart';

void main() {
  final sampleHazards = [
    HazardModel(
      id: 'haz_001',
      complaintId: 'cmp_001',
      ticketNumber: 'CF-2026-000001',
      title: 'Major Pothole on Western Express Highway',
      category: CivicCategory.defaultCategories[0],
      severity: HazardSeverity.high,
      status: ComplaintStatus.inProgress,
      latitude: 19.0760,
      longitude: 72.8777,
      address: 'Near Dadar Flyover',
      ward: 'G/North',
      createdAt: DateTime(2026, 9, 20),
      updatedAt: DateTime(2026, 9, 20),
    ),
    HazardModel(
      id: 'haz_002',
      complaintId: 'cmp_002',
      ticketNumber: 'CF-2026-000002',
      title: 'Waterlogging at Hindmata Cinema',
      category: CivicCategory.defaultCategories[1],
      severity: HazardSeverity.critical,
      status: ComplaintStatus.assigned,
      latitude: 19.0178,
      longitude: 72.8478,
      address: 'Hindmata, Dadar East',
      ward: 'F/South',
      createdAt: DateTime(2026, 9, 21),
      updatedAt: DateTime(2026, 9, 21),
    ),
  ];

  const sampleUserLocation = CivicLocation(
    latitude: 19.0596,
    longitude: 72.8295,
    address: 'Bandra Bandstand, Mumbai',
    ward: 'H/West',
    city: 'Mumbai',
    source: LocationSource.gps,
    accuracyMeters: 5.0,
  );

  tearDown(() {
    MapConfig.resetForTesting();
  });

  group('CivicMapCanvas Widget Tests', () {
    testWidgets('Renders fallback basemap and dev banner when MapTiler key is not configured', (tester) async {
      MapConfig.setApiKeyForTesting('');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              hazards: sampleHazards,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('MapTiler vector basemap active'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Renders hazard markers and triggers selection callback on tap', (tester) async {
      HazardModel? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              hazards: sampleHazards,
              onHazardSelected: (hazard) => selected = hazard,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find marker icons
      expect(find.byIcon(sampleHazards[0].categoryIcon), findsOneWidget);
      expect(find.byIcon(sampleHazards[1].categoryIcon), findsOneWidget);

      // Tap on first hazard marker
      await tester.tap(find.byIcon(sampleHazards[0].categoryIcon));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, equals('haz_001'));
    });

    testWidgets('Renders user GPS location marker with semantic accessibility label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              hazards: [],
              userLocation: sampleUserLocation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Your Current GPS Location'), findsOneWidget);
    });

    testWidgets('Camera navigation methods (animateTo, zoomIn, zoomOut, recenterMumbai) update camera state', (tester) async {
      final canvasKey = GlobalKey<CivicMapCanvasState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              key: canvasKey,
              hazards: sampleHazards,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = canvasKey.currentState;
      expect(state, isNotNull);

      // Zoom In
      await state!.zoomIn();
      await tester.pumpAndSettle();

      // Zoom Out
      await state.zoomOut();
      await tester.pumpAndSettle();

      // Animate to custom coordinate
      await state.animateTo(latitude: 19.1136, longitude: 72.8697, zoom: 14.0);
      await tester.pumpAndSettle();

      // Recenter to Mumbai
      await state.recenterMumbai();
      await tester.pumpAndSettle();

      // Verify GeoJSON feature collection is populated correctly
      final geoJson = state.currentGeoJson;
      expect(geoJson['type'], equals('FeatureCollection'));
      expect((geoJson['features'] as List).length, equals(2));

      // Trigger sync
      await state.syncSpatialGeoJsonSource();
      await tester.pumpAndSettle();
    });
  });

  group('GovtMapCanvas Widget Tests', () {
    testWidgets('GovtMapCanvas renders government markers and user inspection location', (tester) async {
      final transformCtrl = TransformationController();
      HazardModel? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GovtMapCanvas(
              hazards: sampleHazards,
              selectedHazard: null,
              onHazardSelected: (h) => selected = h,
              transformationController: transformCtrl,
              userLocation: sampleUserLocation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Your Current Government Inspection Location'), findsOneWidget);
      expect(find.byType(GovtMapCanvas), findsOneWidget);

      // Tap hazard marker
      await tester.tap(find.byIcon(sampleHazards[0].categoryIcon));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, equals('haz_001'));
    });
  });
}
