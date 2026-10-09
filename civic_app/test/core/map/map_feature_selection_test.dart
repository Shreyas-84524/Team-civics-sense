import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:civic_app/core/map/civic_map_canvas.dart';
import 'package:civic_app/core/map/map_config.dart';
import 'package:civic_app/core/map/map_constants.dart';
import 'package:civic_app/core/map/spatial_feature.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/hazard_model.dart';
import 'package:civic_app/User UI/widgets/hazard_map/hazard_info_card.dart';

// No native view/network: exercise the configured MapLibre widget's callbacks.
class _ViewPlatform extends MapLibrePlatform {
  @override
  Widget buildView(Map<String, dynamic> params,
      OnPlatformViewCreatedCallback callback,
      Set<Factory<OneSequenceGestureRecognizer>>? gestures) => const SizedBox.expand();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Controller implements MapLibreMapController {
  List features = [];
  List clusters = [];
  final queries = <List<String>>[];
  math.Point<double>? lastPoint;
  int animations = 0;
  Completer<List>? pending;
  @override
  Future<List> queryRenderedFeatures(math.Point<double> point, List<String> layers, List<Object>? filter) async {
    queries.add(layers);
    lastPoint = point;
    if (layers.contains(MapConstants.clusterPointsLayerId)) return clusters;
    return pending == null ? features : await pending!.future;
  }
  @override
  Future<bool?> animateCamera(CameraUpdate update, {Duration? duration}) async {
    animations++;
    return true;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final originalFactory = MapLibrePlatform.createInstance;
  setUp(() {
    MapConfig.setApiKeyForTesting('map-selection-test');
    MapLibrePlatform.createInstance = () => _ViewPlatform();
  });
  tearDown(() {
    MapConfig.resetForTesting();
    MapLibrePlatform.createInstance = originalFactory;
  });
  final first = HazardModel(
    id: 'haz_document-a', complaintId: 'document-a', ticketNumber: 'CF-display-a',
    title: 'First issue', category: CivicCategory.defaultCategories.first,
    status: ComplaintStatus.reported, latitude: 19.076, longitude: 72.8777,
    address: 'Test street', createdAt: DateTime(2026, 10, 9), updatedAt: DateTime(2026, 10, 9),
  );
  final second = first.copyWith(id: 'haz_document-b', complaintId: 'document-b', title: 'Second issue');

  testWidgets('interactive MapLibre taps select exact feature, update card, expand cluster and dismiss', (tester) async {
    final controller = _Controller();
    HazardModel? selected;
    await tester.pumpWidget(MaterialApp(home: StatefulBuilder(builder: (context, setState) {
      return Scaffold(body: Stack(children: [
        CivicMapCanvas(hazards: [first, second],
          onHazardSelected: (value) => setState(() => selected = value),
          onMapTap: () => setState(() => selected = null)),
        if (selected != null) Align(alignment: Alignment.bottomCenter,
          child: HazardInfoCard(hazard: selected!, onClose: () => setState(() => selected = null))),
      ]));
    })));
    var map = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
    expect(map.featureTapsTriggersMapClick, isTrue,
      reason: 'Web suppresses onMapClick for interactive circles unless this is enabled');
    map.onMapCreated!(controller);
    controller.features = [SpatialFeature.fromHazard(first)!.toGeoJsonFeature()];
    map.onMapClick!(const math.Point(100.0, 120.0), MapConstants.mumbaiCenter);
    await tester.pumpAndSettle();
    expect(selected?.complaintId, 'document-a');
    expect(find.text('First issue'), findsOneWidget);
    expect(find.byType(HazardInfoCard), findsOneWidget);
    expect(controller.lastPoint, const math.Point(100.0, 120.0));
    expect(controller.queries.last, [MapConstants.unclusteredPointsLayerId]);
    controller.features = [SpatialFeature.fromHazard(second)!.toGeoJsonFeature()];
    map = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
    map.onMapClick!(const math.Point(200.0, 120.0), MapConstants.mumbaiCenter);
    await tester.pumpAndSettle();
    expect(selected?.complaintId, 'document-b');
    expect(find.text('Second issue'), findsOneWidget);
    controller.clusters = [{'properties': {'cluster': true, 'point_count': 3}}];
    map.onMapClick!(const math.Point(150.0, 120.0), MapConstants.mumbaiCenter);
    await tester.pumpAndSettle();
    expect(controller.animations, 1);
    expect(selected, isNull);
    controller.clusters = [];
    controller.features = [];
    map.onMapClick!(const math.Point(1.0, 1.0), MapConstants.mumbaiCenter);
    await tester.pumpAndSettle();
    expect(selected, isNull, reason: 'No proximity fallback may select hidden/clustered points');
    expect(find.byType(HazardInfoCard), findsNothing);
  });

  testWidgets('a late feature query cannot reselect after dataset replacement', (tester) async {
    final controller = _Controller();
    HazardModel? selected;
    Widget view(List<HazardModel> hazards) => MaterialApp(home: CivicMapCanvas(
      hazards: hazards, enableClustering: false, onHazardSelected: (value) => selected = value));
    await tester.pumpWidget(view([first]));
    final map = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
    map.onMapCreated!(controller);
    controller.pending = Completer<List>();
    map.onMapClick!(const math.Point(100.0, 120.0), MapConstants.mumbaiCenter);
    await tester.pumpWidget(view([second]));
    controller.pending!.complete([SpatialFeature.fromHazard(first)!.toGeoJsonFeature()]);
    await tester.pumpAndSettle();
    expect(selected, isNull);
  });
}
