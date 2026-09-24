import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/map/heatmap_legend.dart';

void main() {
  group('HeatmapLegend Widget Tests', () {
    testWidgets('renders title, density gradient, and level labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeatmapLegend(),
          ),
        ),
      );

      expect(find.text('Issue Density Heatmap'), findsOneWidget);
      expect(find.text('LOW'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.textContaining('Higher intensity represents higher density'), findsOneWidget);
    });

    testWidgets('triggers onClose callback when close button is tapped', (tester) async {
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeatmapLegend(
              onClose: () {
                closed = true;
              },
            ),
          ),
        ),
      );

      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('adapts smoothly to dark theme styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: HeatmapLegend(),
          ),
        ),
      );

      expect(find.text('Issue Density Heatmap'), findsOneWidget);
      expect(find.byType(HeatmapLegend), findsOneWidget);
    });
  });
}
