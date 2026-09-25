import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/ai/models/ai_analysis_status.dart';
import 'package:civic_app/core/ai/models/ai_authenticity_enums.dart';
import 'package:civic_app/core/ai/models/ai_authenticity_result.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/Govt UI/screens/complaints/govt_complaint_details_screen.dart';
import 'package:civic_app/Govt UI/widgets/complaints/ai_authenticity_card.dart';

void main() {
  Widget buildTestableDetailsScreen(ComplaintModel complaint) {
    return MaterialApp(
      home: GovtComplaintDetailsScreen(
        complaint: complaint,
      ),
    );
  }

  ComplaintModel createComplaintWithAi({
    String id = 'cmp_govt_int_01',
    AiAuthenticityResult? aiAuthenticity,
    AiAnalysisStatus aiAnalysisStatus = AiAnalysisStatus.pending,
    ComplaintStatus status = ComplaintStatus.inProgress,
    List<String> imageUrls = const ['https://example.com/pothole.jpg'],
  }) {
    final now = DateTime.now();
    return ComplaintModel(
      id: id,
      citizenId: 'usr_citizen_01',
      ticketNumber: 'CF-2026-INT01',
      title: 'Pothole on Cross Road',
      description: 'Dangerous pothole damaging vehicles',
      category: CivicCategory.defaultCategories[0],
      status: status,
      priority: ComplaintPriority.high,
      location: const CivicLocation(
        latitude: 19.0760,
        longitude: 72.8777,
        address: 'Cross Road, Ward 14',
      ),
      imageUrls: imageUrls,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.synced,
      aiAuthenticity: aiAuthenticity,
      aiAnalysisStatus: aiAnalysisStatus,
    );
  }

  group('GovtComplaintDetailsScreen AI Authenticity Integration Tests', () {
    // -------------------------------------------------------------------------
    // Test 1 — Likely Real
    // -------------------------------------------------------------------------
    testWidgets('Test 1 — Likely Real renders "Likely Real" and confidence', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final complaint = createComplaintWithAi(
        aiAnalysisStatus: AiAnalysisStatus.completed,
        aiAuthenticity: AiAuthenticityResult(
          status: AiAuthenticityStatus.likelyReal,
          confidence: 0.88,
          reasoning: 'Image exhibits natural Bayer sensor pattern and genuine depth of field.',
          indicators: const ['natural_sensor_noise', 'consistent_directional_lighting'],
          model: 'gemini-3.6-flash',
          analyzedAt: DateTime.now(),
          isSuccess: true,
        ),
      );

      await tester.pumpWidget(buildTestableDetailsScreen(complaint));
      await tester.pumpAndSettle();

      // Verify the AI Authenticity Card is rendered in details screen
      expect(find.byType(AiAuthenticityCard), findsOneWidget);
      expect(find.text('AI IMAGE AUTHENTICITY'), findsOneWidget);
      expect(find.text('Likely Real'), findsOneWidget);
      expect(find.text('Confidence: 88%'), findsOneWidget);
      expect(find.textContaining('appears consistent with a genuine photograph'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 2 — Likely AI-Generated
    // -------------------------------------------------------------------------
    testWidgets('Test 2 — Likely AI-Generated renders advisory warning without prohibited wording', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final complaint = createComplaintWithAi(
        aiAnalysisStatus: AiAnalysisStatus.completed,
        aiAuthenticity: AiAuthenticityResult(
          status: AiAuthenticityStatus.likelyAiGenerated,
          confidence: 0.91,
          reasoning: 'Synthetic frequency artifacts and unnatural boundary smoothing detected.',
          indicators: const ['unnatural_smoothing', 'diffusion_frequency_signature'],
          model: 'gemini-3.6-flash',
          analyzedAt: DateTime.now(),
          isSuccess: true,
        ),
      );

      await tester.pumpWidget(buildTestableDetailsScreen(complaint));
      await tester.pumpAndSettle();

      expect(find.byType(AiAuthenticityCard), findsOneWidget);
      expect(find.text('Likely AI-Generated'), findsOneWidget);
      expect(find.text('Confidence: 91%'), findsOneWidget);
      expect(find.textContaining('visual characteristics associated with synthetic'), findsOneWidget);

      // Verify prohibited wording is absent
      expect(find.textContaining('Confirmed Fake'), findsNothing);
      expect(find.textContaining('confirmed fake'), findsNothing);
      expect(find.textContaining('Fake Image'), findsNothing);
      expect(find.textContaining('Fraudulent Complaint'), findsNothing);
      expect(find.textContaining('fraudulent'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 3 — Uncertain
    // -------------------------------------------------------------------------
    testWidgets('Test 3 — Uncertain renders neutral uncertain assessment', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final complaint = createComplaintWithAi(
        aiAnalysisStatus: AiAnalysisStatus.completed,
        aiAuthenticity: AiAuthenticityResult(
          status: AiAuthenticityStatus.uncertain,
          confidence: 0.35,
          reasoning: 'Heavy JPEG compression and extreme blurriness.',
          indicators: const ['heavy_jpeg_compression'],
          model: 'gemini-3.6-flash',
          analyzedAt: DateTime.now(),
          isSuccess: true,
        ),
      );

      await tester.pumpWidget(buildTestableDetailsScreen(complaint));
      await tester.pumpAndSettle();

      expect(find.byType(AiAuthenticityCard), findsOneWidget);
      expect(find.text('Uncertain'), findsOneWidget);
      expect(find.text('Confidence: 35%'), findsOneWidget);
      expect(find.textContaining('insufficient to reliably determine image authenticity'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 4 — Processing
    // -------------------------------------------------------------------------
    testWidgets('Test 4 — Processing renders non-blocking in-progress state', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final complaint = createComplaintWithAi(
        aiAnalysisStatus: AiAnalysisStatus.processing,
        aiAuthenticity: null,
      );

      await tester.pumpWidget(buildTestableDetailsScreen(complaint));
      await tester.pump();

      expect(find.byType(AiAuthenticityCard), findsOneWidget);
      expect(find.text('Analysis in progress...'), findsOneWidget);
      expect(find.text('Gemini is analyzing the submitted image.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 5 — Failed
    // -------------------------------------------------------------------------
    testWidgets('Test 5 — Failed renders Analysis Unavailable and does not imply AI-generated', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final complaint = createComplaintWithAi(
        aiAnalysisStatus: AiAnalysisStatus.failed,
        aiAuthenticity: AiAuthenticityResult.failure('Network timeout'),
      );

      await tester.pumpWidget(buildTestableDetailsScreen(complaint));
      await tester.pumpAndSettle();

      expect(find.byType(AiAuthenticityCard), findsOneWidget);
      expect(find.text('Analysis Unavailable'), findsOneWidget);
      expect(find.text('Authenticity analysis could not be completed.'), findsOneWidget);
      expect(find.text('The complaint itself remains valid and can still be reviewed.'), findsOneWidget);

      // Must NEVER display Likely AI-generated on failure
      expect(find.text('Likely AI-Generated'), findsNothing);
      expect(find.textContaining('AI-generated'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 6 — Legacy Complaint
    // -------------------------------------------------------------------------
    testWidgets('Test 6 — Legacy Complaint with aiAuthenticity = null displays "Not analyzed"', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final legacyComplaint = createComplaintWithAi(
        aiAuthenticity: null,
        aiAnalysisStatus: AiAnalysisStatus.pending,
      );

      await tester.pumpWidget(buildTestableDetailsScreen(legacyComplaint));
      await tester.pumpAndSettle();

      expect(find.byType(AiAuthenticityCard), findsOneWidget);
      expect(find.text('Not analyzed'), findsOneWidget);
      expect(
        find.text('Evidence image was submitted without AI authenticity verification.'),
        findsOneWidget,
      );
      // No crashes
      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // Test 7 — Existing Complaint Details
    // -------------------------------------------------------------------------
    testWidgets('Test 7 — Existing Complaint Details sections remain functional alongside authenticity card', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final complaint = createComplaintWithAi(
        aiAnalysisStatus: AiAnalysisStatus.completed,
        aiAuthenticity: AiAuthenticityResult(
          status: AiAuthenticityStatus.likelyReal,
          confidence: 0.90,
          reasoning: 'Authentic photograph.',
          indicators: const ['natural_sensor_noise'],
          model: 'gemini-3.6-flash',
          analyzedAt: DateTime.now(),
          isSuccess: true,
        ),
      );

      await tester.pumpWidget(buildTestableDetailsScreen(complaint));
      await tester.pumpAndSettle();

      // 1. Grievance Overview
      expect(find.text('Grievance Overview'), findsOneWidget);
      expect(find.text(complaint.title), findsOneWidget);
      expect(find.text(complaint.description), findsOneWidget);

      // 2. Photo & Geographic Evidence
      expect(find.text('Photo & Geographic Evidence'), findsOneWidget);

      // 3. Department & Crew Assignment
      expect(find.text('Department & Crew Assignment'), findsOneWidget);

      // 4. Status & Audit Trail (Timeline)
      expect(find.text('Status & Audit Trail'), findsOneWidget);

      // 5. AI Authenticity Card
      expect(find.byType(AiAuthenticityCard), findsOneWidget);
      expect(find.text('AI IMAGE AUTHENTICITY'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 8 — Responsive
    // -------------------------------------------------------------------------
    testWidgets('Test 8 — Responsive: Integrated screen and card do not overflow on narrow layouts', (tester) async {
      // Test on mobile viewport (width: 480)
      tester.view.physicalSize = const Size(480, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final complaint = createComplaintWithAi(
        aiAnalysisStatus: AiAnalysisStatus.completed,
        aiAuthenticity: AiAuthenticityResult(
          status: AiAuthenticityStatus.likelyAiGenerated,
          confidence: 0.93,
          reasoning: 'Synthetic diffusion texture detected across the road surface.',
          indicators: const ['unnatural_smoothing'],
          model: 'gemini-3.6-flash',
          analyzedAt: DateTime.now(),
          isSuccess: true,
        ),
      );

      await tester.pumpWidget(buildTestableDetailsScreen(complaint));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AiAuthenticityCard), findsOneWidget);
      expect(find.text('Likely AI-Generated'), findsOneWidget);
    });
  });
}
