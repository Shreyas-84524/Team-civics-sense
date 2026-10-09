import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/ai/models/ai_analysis_status.dart';
import 'package:civic_app/core/ai/models/ai_authenticity_enums.dart';
import 'package:civic_app/core/ai/models/ai_authenticity_result.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/complaint_upvote_result.dart';
import 'package:civic_app/core/repositories/complaint_repository.dart';
import 'package:civic_app/core/routing/app_routes.dart';
import 'package:civic_app/User UI/models/complaint_draft.dart';
import 'package:civic_app/User UI/screens/complaint_details_screen.dart';
import 'package:civic_app/User UI/services/mock_auth_service.dart';
import 'package:civic_app/User UI/widgets/complaint_details/complaint_tracker.dart';

class _MockRejectionComplaintRepo implements ComplaintRepository {
  final Map<String, ComplaintModel> _store = {};
  final StreamController<ComplaintModel?> _streamController =
      StreamController<ComplaintModel?>.broadcast();

  void setComplaint(ComplaintModel c) {
    _store[c.id] = c;
    _store[c.ticketNumber] = c;
    _streamController.add(c);
  }

  @override
  Future<ComplaintModel?> getComplaintById(String id) async => _store[id];

  @override
  Future<ComplaintModel?> getComplaintByTicketId(String ticketId) async =>
      _store[ticketId];

  @override
  Stream<ComplaintModel?> watchComplaint(String id) {
    return _streamController.stream;
  }

  @override
  Future<List<ComplaintModel>> getCitizenComplaints(String citizenId) async =>
      _store.values.where((c) => c.citizenId == citizenId).toList();

  @override
  Future<List<ComplaintModel>> getComplaints() async => _store.values.toList();

  @override
  Future<ComplaintModel> createComplaint({
    required String citizenId,
    required String title,
    required String description,
    required CivicCategory category,
    required CivicLocation location,
    required ComplaintPriority priority,
    List<String> imageUrls = const [],
    bool isHazard = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ComplaintModel> saveOfflineComplaint(ComplaintModel complaint) async => complaint;

  @override
  Future<List<ComplaintModel>> getPendingComplaints() async => const [];

  @override
  Future<void> updateSyncStatus(
    String complaintId,
    SyncStatus status, {
    String? serverId,
    AiAuthenticityResult? aiAuthenticity,
    AiAnalysisStatus? aiAnalysisStatus,
  }) async {}

  @override
  Future<ComplaintUpvoteResult> upvoteComplaint(String id) async {
    return const ComplaintUpvoteResult(upvotes: 1, added: true);
  }

  @override
  Future<List<ComplaintModel>> getCitizenVisibleComplaints({
    String? citizenId,
    int limit = 100,
  }) async => _store.values.toList();

  @override
  Future<List<ComplaintModel>> getNearbyHazards() async =>
      _store.values.where((c) => c.isHazard).toList();

  @override
  Stream<List<ComplaintModel>> watchCitizenComplaints(String citizenId) async* {
    yield _store.values.where((c) => c.citizenId == citizenId).toList();
  }

  @override
  Stream<List<ComplaintModel>> watchCitizenVisibleComplaints({
    String? citizenId,
    int limit = 100,
  }) async* {
    yield _store.values.toList();
  }

  @override
  Stream<List<TimelineEvent>> watchComplaintTimeline(String complaintId) async* {
    yield _store[complaintId]?.timeline ?? const [];
  }

  @override
  Stream<List<ComplaintModel>> watchComplaints() async* {
    yield _store.values.toList();
  }

  @override
  Stream<List<ComplaintModel>> watchNearbyHazards() async* {
    yield _store.values.where((c) => c.isHazard).toList();
  }
}

void main() {
  final testCategory = CivicCategory.defaultCategories.first;

  const testLocation = CivicLocation(
    address: 'Linking Road, Bandra West, Mumbai',
    latitude: 19.0596,
    longitude: 72.8295,
    ward: 'H/West',
  );

  ComplaintModel createTestComplaint({
    String id = 'cmp_ai_test_001',
    ComplaintStatus status = ComplaintStatus.underVerification,
    String evidenceStatus = 'pending',
    String departmentStatus = 'pending',
    String verificationStage = 'evidence',
    AiAuthenticityResult? aiAuthenticity,
    String? lastAiFailureCode,
    String? verificationFailureReason,
  }) {
    return ComplaintModel(
      id: id,
      citizenId: 'user_citizen_001',
      ticketNumber: 'CF-2026-AI-TEST',
      title: 'Deep road crater on Linking Road',
      description: 'Severe pothole causing traffic obstruction',
      category: testCategory,
      status: status,
      priority: ComplaintPriority.high,
      location: testLocation,
      imageUrls: const ['https://example.com/ai_fake.jpg'],
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now(),
      evidenceVerificationStatus: evidenceStatus,
      departmentVerificationStatus: departmentStatus,
      verificationStage: verificationStage,
      aiAuthenticity: aiAuthenticity,
      lastAiFailureCode: lastAiFailureCode,
      verificationFailureReason: verificationFailureReason,
    );
  }

  group('ComplaintModel AI Evidence Rejection Model Tests', () {
    test('Correctly identifies AI-generated rejection from AiAuthenticityStatus.likelyAiGenerated', () {
      final complaint = createTestComplaint(
        status: ComplaintStatus.rejected,
        evidenceStatus: 'failed',
        verificationStage: 'evidence_failed',
        aiAuthenticity: AiAuthenticityResult(
          status: AiAuthenticityStatus.likelyAiGenerated,
          confidence: 0.94,
          reasoning: 'Synthetic textures and unnatural blending detected',
          indicators: const ['diffusion_artifacts'],
          model: 'gemini-3.5-flash',
          analyzedAt: DateTime.now(),
          isSuccess: true,
        ),
      );

      expect(complaint.isAiGeneratedEvidenceRejected, isTrue);
      expect(complaint.isEvidenceRejected, isTrue);
    });

    test('Correctly identifies AI-generated rejection from lastAiFailureCode', () {
      final complaint = createTestComplaint(
        status: ComplaintStatus.rejected,
        evidenceStatus: 'failed',
        verificationStage: 'evidence_failed',
        lastAiFailureCode: 'ai_generated',
      );

      expect(complaint.isAiGeneratedEvidenceRejected, isTrue);
      expect(complaint.isEvidenceRejected, isTrue);
    });

    test('Does NOT flag transient AI outage / timeout as AI-generated rejection', () {
      final complaint = createTestComplaint(
        status: ComplaintStatus.underVerification,
        evidenceStatus: 'temporarily_unavailable',
        departmentStatus: 'temporarily_unavailable',
        verificationStage: 'humanDepartmentReview',
        aiAuthenticity: AiAuthenticityResult.failure(
          '504 Gateway Timeout',
          model: 'gemini-3.5-flash',
          analyzedAt: DateTime.now(),
        ),
        lastAiFailureCode: 'AI_TEMPORARILY_UNAVAILABLE',
        verificationFailureReason: 'Verification timed out',
      );

      expect(complaint.isAiGeneratedEvidenceRejected, isFalse);
      expect(complaint.isHumanReviewPending, isTrue);
    });

    test('Does NOT flag genuine passed evidence as rejected', () {
      final complaint = createTestComplaint(
        status: ComplaintStatus.assigned,
        evidenceStatus: 'passed',
        departmentStatus: 'passed',
        verificationStage: 'completed',
        aiAuthenticity: AiAuthenticityResult(
          status: AiAuthenticityStatus.likelyReal,
          confidence: 0.95,
          reasoning: 'Authentic real world photo',
          indicators: const ['natural_lighting'],
          model: 'gemini-3.5-flash',
          analyzedAt: DateTime.now(),
          isSuccess: true,
        ),
      );

      expect(complaint.isAiGeneratedEvidenceRejected, isFalse);
      expect(complaint.isEvidenceRejected, isFalse);
    });
  });

  group('ComplaintTracker Widget Tests', () {
    testWidgets('Does not display internal AI Step 1 / Step 2 verification pill to citizens', (tester) async {
      final complaint = createTestComplaint(
        evidenceStatus: 'passed',
        departmentStatus: 'passed',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComplaintTracker(
                currentStatus: complaint.status,
                complaint: complaint,
              ),
            ),
          ),
        ),
      );

      // Verify canonical tracker stages are present
      expect(find.text('Progress Tracker'), findsOneWidget);
      expect(find.text('Under Verification'), findsOneWidget);
      expect(find.text('Verifying evidence & department routing'), findsOneWidget);

      // Verify internal Step 1 / Step 2 AI pills are NOT visible
      expect(find.textContaining('Step 1:'), findsNothing);
      expect(find.textContaining('Step 2:'), findsNothing);
      expect(find.textContaining('Gemini'), findsNothing);
    });

    testWidgets('Displays clean non-technical contextual message during verification', (tester) async {
      final complaint = createTestComplaint(
        status: ComplaintStatus.underVerification,
        evidenceStatus: 'processing',
        departmentStatus: 'pending',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComplaintTracker(
                currentStatus: complaint.status,
                complaint: complaint,
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('Under Verification: Validating grievance details and department routing.'),
        findsOneWidget,
      );
      expect(find.textContaining('Step 1:'), findsNothing);
      expect(find.textContaining('Step 2:'), findsNothing);
    });
  });

  group('ComplaintDetailsScreen Rejection Popup & Persistent Banner Tests', () {
    testWidgets('Shows rejection modal dialog and persistent banner for AI-generated complaint', (tester) async {
      final repo = _MockRejectionComplaintRepo();
      final auth = MockAuthService();

      final rejectedComplaint = createTestComplaint(
        id: 'cmp_ai_dialog_test',
        status: ComplaintStatus.rejected,
        evidenceStatus: 'failed',
        verificationStage: 'evidence_failed',
        aiAuthenticity: AiAuthenticityResult(
          status: AiAuthenticityStatus.likelyAiGenerated,
          confidence: 0.95,
          reasoning: 'AI image detected',
          indicators: const ['diffusion_artifacts'],
          model: 'gemini-3.5-flash',
          analyzedAt: DateTime.now(),
          isSuccess: true,
        ),
      );
      repo.setComplaint(rejectedComplaint);

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.reportIssue: (context) {
              final draft = ModalRoute.of(context)?.settings.arguments as ComplaintDraft?;
              return Scaffold(
                body: Text('Report Issue: ${draft?.title ?? ""}'),
              );
            },
          },
          home: ComplaintDetailsScreen(
            complaint: rejectedComplaint,
            repository: repo,
            authService: auth,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Rejection Dialog is rendered
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Complaint Rejected'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('authenticity verification and was identified as AI-generated'),
        ),
        findsOneWidget,
      );

      // Verify "Close" dismisses dialog
      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);

      // Verify persistent rejection banner remains visible
      expect(find.text('Complaint Rejected'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Report Again'), findsOneWidget);
    });

    testWidgets('Pop-up does not repeatedly trigger on subsequent rebuilds (Deduplication)', (tester) async {
      final repo = _MockRejectionComplaintRepo();
      final auth = MockAuthService();

      final rejectedComplaint = createTestComplaint(
        id: 'cmp_ai_dedup_test',
        status: ComplaintStatus.rejected,
        evidenceStatus: 'failed',
        verificationStage: 'evidence_failed',
        aiAuthenticity: AiAuthenticityResult(
          status: AiAuthenticityStatus.likelyAiGenerated,
          confidence: 0.95,
          reasoning: 'AI image detected',
          indicators: const ['diffusion_artifacts'],
          model: 'gemini-3.5-flash',
          analyzedAt: DateTime.now(),
          isSuccess: true,
        ),
      );
      repo.setComplaint(rejectedComplaint);

      await tester.pumpWidget(
        MaterialApp(
          home: ComplaintDetailsScreen(
            complaint: rejectedComplaint,
            repository: repo,
            authService: auth,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Dialog shown once
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      // Trigger a state change / rebuild on the screen
      await tester.tap(find.byIcon(Icons.thumb_up_alt_outlined));
      await tester.pumpAndSettle();

      // Dialog should NOT reappear
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
