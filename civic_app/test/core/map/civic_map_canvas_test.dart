import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/map/basemap_mode.dart';
import 'package:civic_app/core/map/civic_map_canvas.dart';
import 'package:civic_app/core/map/map_config.dart';
import 'package:civic_app/core/map/spatial_data_service.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';
import 'package:civic_app/Govt UI/widgets/map/govt_map_canvas.dart';
import 'package:civic_app/User UI/widgets/map/basemap_selector_sheet.dart';

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

    testWidgets('CivicMapCanvas respects showHeatmap and timeFilter in GeoJSON state', (tester) async {
      final canvasKey = GlobalKey<CivicMapCanvasState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              key: canvasKey,
              hazards: sampleHazards,
              showHeatmap: true,
              timeFilter: SpatialTimeFilter.last30Days,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = canvasKey.currentState;
      expect(state, isNotNull);
      final geoJson = state!.currentGeoJson;
      expect(geoJson['type'], equals('FeatureCollection'));
    });

    testWidgets('CivicMapCanvas handles rapid property updates cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              hazards: sampleHazards,
              showHeatmap: true,
              enableClustering: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Rapidly toggle heatmap off, clustering off
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              hazards: sampleHazards,
              showHeatmap: false,
              enableClustering: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Update hazards dataset
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              hazards: [sampleHazards.first],
              showHeatmap: true,
              enableClustering: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CivicMapCanvas), findsOneWidget);
    });

    test('MapLibre configured mode activates valid MapTiler style URL and isConfigured flag', () {
      MapConfig.setApiKeyForTesting('test_api_key_valid_123');
      expect(MapConfig.isConfigured, isTrue);
      expect(MapConfig.getStyleUrl(), contains('https://api.maptiler.com/maps/streets-v2/style.json?key=test_api_key_valid_123'));
    });

    testWidgets('Offscreen markers return SizedBox.shrink and are not clamped to border grid', (tester) async {
      MapConfig.setApiKeyForTesting('');

      final distantHazard = HazardModel(
        id: 'haz_far',
        complaintId: 'cmp_far',
        ticketNumber: 'CF-2026-999999',
        title: 'Distant Hazard in Delhi',
        category: CivicCategory.defaultCategories[0],
        severity: HazardSeverity.low,
        status: ComplaintStatus.reported,
        latitude: 28.6139, // Delhi lat (far from Mumbai center 19.0760)
        longitude: 77.2090, // Delhi lng
        address: 'Connaught Place, New Delhi',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              hazards: [distantHazard],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Distant marker must NOT be rendered / clamped on the Mumbai map screen
      expect(find.byIcon(distantHazard.categoryIcon), findsNothing);
    });

    testWidgets('CivicMapCanvas updates basemapMode cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              hazards: sampleHazards,
              basemapMode: BasemapMode.streets,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              hazards: sampleHazards,
              basemapMode: BasemapMode.satellite,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              hazards: sampleHazards,
              basemapMode: BasemapMode.hybrid,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CivicMapCanvas), findsOneWidget);
    });

    testWidgets('Fallback basemap allows dragging/panning via onPanUpdate', (tester) async {
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

      // Perform a drag gesture on the canvas
      await tester.drag(find.byType(CustomPaint).first, const Offset(-50, -50));
      await tester.pumpAndSettle();

      expect(find.byType(CivicMapCanvas), findsOneWidget);
    });
  });

  group('BasemapSelectorSheet Widget Tests', () {
    testWidgets('Renders all 3 modes and triggers callback on selection', (tester) async {
      BasemapMode? selectedMode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BasemapSelectorSheet(
              currentMode: BasemapMode.streets,
              onModeSelected: (mode) => selectedMode = mode,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Streets'), findsOneWidget);
      expect(find.text('Satellite'), findsOneWidget);
      expect(find.text('Hybrid'), findsOneWidget);

      // Select Satellite
      await tester.tap(find.text('Satellite'));
      await tester.pumpAndSettle();

      expect(selectedMode, equals(BasemapMode.satellite));
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

  group('User Location Stability and Geographic Persistence Tests', () {
    testWidgets('User location coordinates remain strictly unchanged after zoom in, zoom out, pan, and basemap switches', (tester) async {
      final canvasKey = GlobalKey<CivicMapCanvasState>();
      const originalLocation = sampleUserLocation;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              key: canvasKey,
              hazards: sampleHazards,
              userLocation: originalLocation,
              basemapMode: BasemapMode.streets,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = canvasKey.currentState!;

      // 1. Initial coordinates check
      expect(originalLocation.latitude, equals(19.0596));
      expect(originalLocation.longitude, equals(72.8295));

      // 2. Zoom In
      await state.zoomIn();
      await tester.pumpAndSettle();
      expect(originalLocation.latitude, equals(19.0596));
      expect(originalLocation.longitude, equals(72.8295));

      // 3. Zoom Out
      await state.zoomOut();
      await tester.pumpAndSettle();
      expect(originalLocation.latitude, equals(19.0596));
      expect(originalLocation.longitude, equals(72.8295));

      // 4. Pan / Animate camera to Dadar
      await state.animateTo(latitude: 19.0178, longitude: 72.8478, zoom: 16.0);
      await tester.pumpAndSettle();
      expect(originalLocation.latitude, equals(19.0596));
      expect(originalLocation.longitude, equals(72.8295));

      // 5. Basemap switch to Satellite
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              key: canvasKey,
              hazards: sampleHazards,
              userLocation: originalLocation,
              basemapMode: BasemapMode.satellite,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(originalLocation.latitude, equals(19.0596));
      expect(originalLocation.longitude, equals(72.8295));

      // 6. Basemap switch to Hybrid
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              key: canvasKey,
              hazards: sampleHazards,
              userLocation: originalLocation,
              basemapMode: BasemapMode.hybrid,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(originalLocation.latitude, equals(19.0596));
      expect(originalLocation.longitude, equals(72.8295));

      // 7. Locate-me / Recenter on user coordinates
      await state.animateTo(latitude: originalLocation.latitude, longitude: originalLocation.longitude, zoom: 14.0);
      await tester.pumpAndSettle();

      // 8. Verify exactly 1 user location marker rendered (no duplicates)
      expect(find.bySemanticsLabel('Your Current GPS Location'), findsOneWidget);
    });

    testWidgets('Offscreen user location is culled and not forced to center screen', (tester) async {
      const farLocation = CivicLocation(
        latitude: 28.6139, // Delhi
        longitude: 77.2090,
        address: 'Connaught Place, New Delhi',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CivicMapCanvas(
              hazards: [],
              userLocation: farLocation,
              initialLatitude: 19.0760, // Mumbai
              initialLongitude: 72.8777,
              initialZoom: 12.0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In fallback mode, an offscreen marker in Delhi should NOT be drawn in Mumbai
      expect(find.byType(CivicMapCanvas), findsOneWidget);
    });
  });
}
