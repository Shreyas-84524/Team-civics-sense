import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/ai/models/ai_analysis_status.dart';
import 'package:civic_app/core/ai/models/ai_authenticity_enums.dart';
import 'package:civic_app/core/ai/models/ai_authenticity_result.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/Govt UI/widgets/complaints/ai_authenticity_card.dart';

void main() {
  Widget buildTestableWidget(Widget child, {Size surfaceSize = const Size(800, 600)}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              width: surfaceSize.width,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('AiAuthenticityCard Widget Tests (Step 14 Requirements)', () {
    // -------------------------------------------------------------------------
    // Test 1: likely_real
    // -------------------------------------------------------------------------
    testWidgets('Test 1: likely_real verifies title, status, confidence, and reasoning availability', (tester) async {
      final auth = AiAuthenticityResult(
        status: AiAuthenticityStatus.likelyReal,
        confidence: 0.88,
        reasoning: 'Authentic camera noise pattern with standard Bayer sensor demosaicing artifacts.',
        indicators: const ['natural_sensor_noise', 'consistent_directional_lighting'],
        model: 'gemini-3.6-flash',
        analyzedAt: DateTime(2026, 9, 25, 10, 30),
        isSuccess: true,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          AiAuthenticityCard(
            authenticity: auth,
            analysisStatus: AiAnalysisStatus.completed,
          ),
        ),
      );

      // Verify title
      expect(find.text('AI IMAGE AUTHENTICITY'), findsOneWidget);

      // Verify status badge
      expect(find.text('Likely Real'), findsOneWidget);

      // Verify confidence
      expect(find.text('Confidence: 88%'), findsOneWidget);

      // Verify summary text
      expect(
        find.textContaining('appears consistent with a genuine photograph'),
        findsOneWidget,
      );

      // Verify View Analysis button exists and reasoning is hidden initially
      final viewAnalysisBtn = find.text('View Analysis');
      expect(viewAnalysisBtn, findsOneWidget);
      expect(find.text('Assessment'), findsNothing);

      // Tap View Analysis to expand
      await tester.tap(viewAnalysisBtn);
      await tester.pumpAndSettle();

      // Verify reasoning and indicators are now visible
      expect(find.text('Assessment'), findsOneWidget);
      expect(find.textContaining('Bayer sensor demosaicing'), findsOneWidget);
      expect(find.text('Observed indicators'), findsOneWidget);
      expect(find.text('Model: Gemini 3.6 Flash'), findsOneWidget);
      expect(find.text('Hide Analysis'), findsOneWidget);

      // Verify mandatory advisory disclaimer
      expect(find.text('AI-assisted assessment'), findsOneWidget);
      expect(find.textContaining('not forensic proof of image origin'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 2: likely_ai_generated
    // -------------------------------------------------------------------------
    testWidgets('Test 2: likely_ai_generated verifies correct display and no "confirmed fake" wording', (tester) async {
      final auth = AiAuthenticityResult(
        status: AiAuthenticityStatus.likelyAiGenerated,
        confidence: 0.91,
        reasoning: 'Smooth texture diffusion without physical sensor noise; synthetic edge blending detected.',
        indicators: const ['unnatural_smoothing', 'diffusion_frequency_signature'],
        model: 'gemini-3.6-flash',
        analyzedAt: DateTime(2026, 9, 25, 10, 35),
        isSuccess: true,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          AiAuthenticityCard(
            authenticity: auth,
            analysisStatus: AiAnalysisStatus.completed,
          ),
        ),
      );

      // Verify status badge
      expect(find.text('Likely AI-Generated'), findsOneWidget);

      // Verify confidence
      expect(find.text('Confidence: 91%'), findsOneWidget);

      // Verify advisory summary text
      expect(
        find.textContaining('visual characteristics associated with synthetic'),
        findsOneWidget,
      );

      // Strict requirement: Ensure wording does NOT say "confirmed fake" or "fake image" or "fraudulent"
      expect(find.textContaining('confirmed fake'), findsNothing);
      expect(find.textContaining('Fake image'), findsNothing);
      expect(find.textContaining('Fraudulent complaint'), findsNothing);
      expect(find.textContaining('Confirmed AI-generated'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 3: uncertain
    // -------------------------------------------------------------------------
    testWidgets('Test 3: uncertain verifies correct display', (tester) async {
      final auth = AiAuthenticityResult(
        status: AiAuthenticityStatus.uncertain,
        confidence: 0.35,
        reasoning: 'Low resolution and extreme compression; insufficient frequency detail to determine authenticity.',
        indicators: const ['heavy_jpeg_compression'],
        model: 'gemini-3.6-flash',
        analyzedAt: DateTime(2026, 9, 25, 10, 40),
        isSuccess: true,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          AiAuthenticityCard(
            authenticity: auth,
            analysisStatus: AiAnalysisStatus.completed,
          ),
        ),
      );

      expect(find.text('Uncertain'), findsOneWidget);
      expect(find.text('Confidence: 35%'), findsOneWidget);
      expect(
        find.text('The available visual evidence was insufficient to reliably determine image authenticity.'),
        findsOneWidget,
      );
    });

    // -------------------------------------------------------------------------
    // Test 4: processing
    // -------------------------------------------------------------------------
    testWidgets('Test 4: processing verifies loading state', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AiAuthenticityCard(
            analysisStatus: AiAnalysisStatus.processing,
          ),
        ),
      );

      expect(find.text('Analysis in progress...'), findsOneWidget);
      expect(find.text('Gemini is analyzing the submitted image.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('View Analysis'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 5: pending
    // -------------------------------------------------------------------------
    testWidgets('Test 5: pending verifies pending state', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AiAuthenticityCard(
            analysisStatus: AiAnalysisStatus.pending,
          ),
        ),
      );

      expect(find.text('Analysis Pending'), findsOneWidget);
      expect(find.text('Authenticity analysis has not been completed yet.'), findsOneWidget);
      expect(find.text('View Analysis'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 6: failed
    // -------------------------------------------------------------------------
    testWidgets('Test 6: failed verifies Analysis Unavailable and does NOT display Likely AI-generated', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AiAuthenticityCard(
            analysisStatus: AiAnalysisStatus.failed,
          ),
        ),
      );

      expect(find.text('Analysis Unavailable'), findsOneWidget);
      expect(find.text('Authenticity analysis could not be completed.'), findsOneWidget);
      expect(
        find.text('The complaint itself remains valid and can still be reviewed.'),
        findsOneWidget,
      );

      // Crucial requirement: Failure != AI-generated
      expect(find.text('Likely AI-Generated'), findsNothing);
      expect(find.textContaining('AI-generated'), findsNothing);
      expect(find.text('View Analysis'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 7: No AI data
    // -------------------------------------------------------------------------
    testWidgets('Test 7: No AI data verifies "Not analyzed" without a crash', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AiAuthenticityCard(
            authenticity: null,
          ),
        ),
      );

      expect(find.text('AI IMAGE AUTHENTICITY'), findsOneWidget);
      expect(find.text('Not analyzed'), findsOneWidget);
      expect(
        find.text('Evidence image was submitted without AI authenticity verification.'),
        findsOneWidget,
      );
      expect(find.text('View Analysis'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 8: Long reasoning
    // -------------------------------------------------------------------------
    testWidgets('Test 8: Long reasoning renders safely without layout overflow', (tester) async {
      final longReasoning = 'Detailed forensic evaluation conducted by Gemini multimodal processor. ' * 15;
      final auth = AiAuthenticityResult(
        status: AiAuthenticityStatus.likelyReal,
        confidence: 0.89,
        reasoning: longReasoning,
        indicators: const ['natural_sensor_noise'],
        model: 'gemini-3.6-flash',
        analyzedAt: DateTime.now(),
        isSuccess: true,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          AiAuthenticityCard(
            authenticity: auth,
            analysisStatus: AiAnalysisStatus.completed,
            initiallyExpanded: true,
          ),
          surfaceSize: const Size(400, 800),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Assessment'), findsOneWidget);
      expect(find.textContaining('Detailed forensic evaluation'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 9: Multiple indicators
    // -------------------------------------------------------------------------
    testWidgets('Test 9: Multiple indicators render correctly in bulleted list', (tester) async {
      final auth = AiAuthenticityResult(
        status: AiAuthenticityStatus.likelyReal,
        confidence: 0.95,
        reasoning: 'Clean optical photograph with coherent perspective geometry.',
        indicators: const [
          'natural_sensor_noise',
          'consistent_directional_lighting',
          'sharp_optical_depth_of_field',
          'absence_of_diffusion_artifacts',
        ],
        model: 'gemini-3.6-flash',
        analyzedAt: DateTime.now(),
        isSuccess: true,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          AiAuthenticityCard(
            authenticity: auth,
            analysisStatus: AiAnalysisStatus.completed,
            initiallyExpanded: true,
          ),
        ),
      );

      expect(find.text('Observed indicators'), findsOneWidget);
      expect(find.text('Natural Sensor Noise'), findsOneWidget);
      expect(find.text('Consistent Directional Lighting'), findsOneWidget);
      expect(find.text('Sharp Optical Depth Of Field'), findsOneWidget);
      expect(find.text('Absence Of Diffusion Artifacts'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 10: Missing confidence
    // -------------------------------------------------------------------------
    testWidgets('Test 10: Missing confidence displays "Confidence unavailable"', (tester) async {
      final auth = AiAuthenticityResult(
        status: AiAuthenticityStatus.likelyReal,
        confidence: 0.85,
        reasoning: 'Image appears genuine.',
        indicators: const [],
        model: 'gemini-3.6-flash',
        analyzedAt: DateTime.now(),
        isSuccess: true,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          AiAuthenticityCard(
            authenticity: auth,
            analysisStatus: AiAnalysisStatus.completed,
            forceMissingConfidence: true,
          ),
        ),
      );

      expect(find.text('Confidence unavailable'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 11: Responsive layout on narrow screen
    // -------------------------------------------------------------------------
    testWidgets('Test 11: Responsive layout does not overflow on a narrow (320px) viewport', (tester) async {
      final auth = AiAuthenticityResult(
        status: AiAuthenticityStatus.likelyAiGenerated,
        confidence: 0.94,
        reasoning: 'High-frequency spectral anomalies and diffusion texture blending detected across structural lines.',
        indicators: const ['diffusion_frequency_signature', 'unnatural_smoothing'],
        model: 'gemini-3.6-flash',
        analyzedAt: DateTime.now(),
        isSuccess: true,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          AiAuthenticityCard(
            authenticity: auth,
            analysisStatus: AiAnalysisStatus.completed,
            initiallyExpanded: true,
          ),
          surfaceSize: const Size(320, 600),
        ),
      );

      // Verify no overflow errors occurred
      expect(tester.takeException(), isNull);
      expect(find.text('Likely AI-Generated'), findsOneWidget);
      expect(find.text('Confidence: 94%'), findsOneWidget);
      expect(find.text('Assessment'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Factory constructor test: fromComplaint
    // -------------------------------------------------------------------------
    testWidgets('AiAuthenticityCard.fromComplaint adapts complaint model data accurately', (tester) async {
      final now = DateTime.now();
      final complaint = ComplaintModel(
        id: 'cmp_test_factory',
        citizenId: 'usr_factory',
        ticketNumber: 'CF-2026-F001',
        title: 'Factory Test Complaint',
        description: 'Testing factory constructor adaptation',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(latitude: 19.0, longitude: 72.8, address: 'Test St'),
        imageUrls: const ['img.jpg'],
        createdAt: now,
        updatedAt: now,
        aiAuthenticity: AiAuthenticityResult(
          status: AiAuthenticityStatus.likelyReal,
          confidence: 0.87,
          reasoning: 'Direct factory complaint photo test.',
          indicators: const ['natural_sensor_noise'],
          model: 'gemini-3.6-flash',
          analyzedAt: now,
          isSuccess: true,
        ),
        aiAnalysisStatus: AiAnalysisStatus.completed,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          AiAuthenticityCard.fromComplaint(complaint),
        ),
      );

      expect(find.text('Likely Real'), findsOneWidget);
      expect(find.text('Confidence: 87%'), findsOneWidget);
    });
  });
}
