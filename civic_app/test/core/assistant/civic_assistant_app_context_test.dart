import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/ai/models/ai_analysis_status.dart';
import 'package:civic_app/core/assistant/adapters/complaint_context_mapper.dart';
import 'package:civic_app/core/assistant/controller/civic_assistant_controller.dart';
import 'package:civic_app/core/assistant/models/assistant_app_context.dart';
import 'package:civic_app/core/assistant/models/civic_assistant_intent.dart';
import 'package:civic_app/core/assistant/retrieval/civic_assistant_hybrid_retriever.dart';
import 'package:civic_app/core/assistant/retrieval/retrieval_models.dart';
import 'package:civic_app/core/assistant/services/civic_assistant_provider.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';

void main() {
  group('CivicFix Chatbot Phase 5 — Live App Context & Complaint Awareness', () {
    final retriever = CivicAssistantHybridRetriever.instance;
    final provider = GroundedCivicAssistantProvider();

    // Helper dummy complaint builder with realistic production fields
    ComplaintModel createSampleComplaint({
      String id = 'doc_complaint_123',
      String ticketNumber = 'CF-2026-000024',
      ComplaintStatus status = ComplaintStatus.underVerification,
      CivicCategory? category,
      String? wardId = 'ward_r_south',
      String? departmentName = 'Maintenance (Roads & Traffic)',
      String? verificationStage = 'department',
      String evidenceStatus = 'passed',
      String departmentStatus = 'pending',
      String? assignedCrewMemberId,
      String? assignedJuniorEngineerNameSnapshot,
      String? assignedFieldOfficerId,
      String? assignedFieldOfficerNameSnapshot,
      DateTime? blockedAt,
      String? blockedReason,
      int reopenCount = 0,
      String? reopenReason,
      SyncStatus syncStatus = SyncStatus.synced,
    }) {
      return ComplaintModel(
        id: id,
        citizenId: 'uid_citizen_private_9999', // SENSITIVE UID (Must NOT leak)
        ticketNumber: ticketNumber,
        title: 'Deep pothole near Borivali station',
        description: 'Large crater causing vehicular slowdowns and vehicle damage',
        category: category ?? CivicCategory.defaultCategories.first,
        status: status,
        priority: ComplaintPriority.high,
        location: const CivicLocation(
          latitude: 19.2307,
          longitude: 72.8567,
          address: 'Station Road, Borivali West, Mumbai 400092',
        ),
        imageUrls: const [
          'https://storage.googleapis.com/private_bucket/secret_photo_1.jpg', // SENSITIVE PRIVATE URL
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        updatedAt: DateTime.now(),
        timeline: const [],
        upvotes: 5,
        isHazard: true,
        officerNotes: 'Internal confidential inspection notes', // SENSITIVE INTERNAL NOTES
        syncStatus: syncStatus,
        aiAnalysisStatus: AiAnalysisStatus.completed,
        evidenceVerificationStatus: evidenceStatus,
        departmentVerificationStatus: departmentStatus,
        verificationStage: verificationStage ?? 'evidence',
        wardId: wardId,
        departmentName: departmentName,
        assignedCrewMemberId: assignedCrewMemberId,
        assignedJuniorEngineerNameSnapshot: assignedJuniorEngineerNameSnapshot,
        assignedFieldOfficerId: assignedFieldOfficerId,
        assignedFieldOfficerNameSnapshot: assignedFieldOfficerNameSnapshot,
        blockedAt: blockedAt,
        blockedReason: blockedReason,
        reopenCount: reopenCount,
        reopenReason: reopenReason,
        slaStartedAt: DateTime.now().subtract(const Duration(hours: 4)),
        originalCreatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      );
    }

    // -------------------------------------------------------------
    // SECTION 1: SAFE CONTEXT MAPPING & PRIVACY ALLOWLIST
    // -------------------------------------------------------------
    group('Section 1: Safe Context Mapping & Privacy Allowlist', () {
      test('Maps ComplaintModel to safe AssistantAppContext without PII or sensitive keys', () {
        final complaint = createSampleComplaint(
          status: ComplaintStatus.assigned,
          assignedCrewMemberId: 'uid_engineer_private_8888',
          assignedJuniorEngineerNameSnapshot: 'S. Kadam',
          assignedFieldOfficerId: 'uid_officer_private_7777',
          assignedFieldOfficerNameSnapshot: 'Ganesh Kulkarni',
        );

        final context = ComplaintToAssistantContextMapper.mapFromComplaint(
          complaint,
          currentScreen: 'complaintDetails',
          selectedLanguage: 'en',
          userRole: 'citizen',
        );

        // Verify Allowed Safe Public Fields
        expect(context.ticketId, equals('CF-2026-000024'));
        expect(context.complaintStatus, equals('assigned'));
        expect(context.complaintCategory, equals('Roads'));
        expect(context.wardId, equals('R/SOUTH'));
        expect(context.departmentId, equals('Maintenance (Roads & Traffic)'));
        expect(context.hasJuniorEngineerAssigned, isTrue);
        expect(context.assignedJuniorEngineerName, equals('S. Kadam'));
        expect(context.hasFieldOfficerAssigned, isTrue);
        expect(context.assignedFieldOfficerName, equals('Ganesh Kulkarni'));
        expect(context.isGovernmentUser, isFalse);

        // Verify Strict Absence of SENSITIVE PII in Context & Prompt
        final promptContext = context.toPromptContextString();
        expect(promptContext, isNot(contains('uid_citizen_private_9999')));
        expect(promptContext, isNot(contains('uid_engineer_private_8888')));
        expect(promptContext, isNot(contains('uid_officer_private_7777')));
        expect(promptContext, isNot(contains('secret_photo_1.jpg')));
        expect(promptContext, isNot(contains('Internal confidential')));
        expect(promptContext, isNot(contains('password')));
        expect(promptContext, isNot(contains('otp')));
      });

      test('Prompt builder formats app context cleanly with only populated fields', () {
        final context = const AssistantAppContext(
          userRole: 'citizen',
          currentScreen: 'complaintDetails',
          selectedTicketNumber: 'CF-2026-000042',
          complaintStatus: 'underVerification',
          complaintCategory: 'Water Leakage',
          wardId: 'K/WEST',
          departmentId: 'Water Works',
        );

        final formatted = context.toPromptContextString();
        expect(formatted, contains('=== CURRENT CIVICFIX APP CONTEXT ==='));
        expect(formatted, contains('Referenced Complaint Ticket: CF-2026-000042'));
        expect(formatted, contains('Complaint Status: underVerification'));
        expect(formatted, contains('Category: Water Leakage'));
        expect(formatted, contains('Ward: K/WEST'));
        expect(formatted, contains('Department: Water Works'));
        expect(formatted, isNot(contains('Blocked Status')));
        expect(formatted, isNot(contains('Rework Count')));
      });
    });

    // -------------------------------------------------------------
    // SECTION 2: UNDER VERIFICATION SCENARIOS
    // -------------------------------------------------------------
    group('Section 2: Under Verification Context Scenarios', () {
      final underVerComplaint = createSampleComplaint(
        status: ComplaintStatus.underVerification,
        wardId: 'ward_r_south',
        departmentName: 'Maintenance (Roads & Traffic)',
      );
      final underVerContext = ComplaintToAssistantContextMapper.mapFromComplaint(
        underVerComplaint,
        currentScreen: 'complaintDetails',
      );

      test('"What happens next?" with Under Verification context explains stage 2 and next assignment', () async {
        final reply = await provider.generateResponse(
          query: 'What happens next?',
          languageCode: 'en',
          appContext: underVerContext,
        );

        expect(reply.text, contains('CF-2026-000024'));
        expect(reply.text, contains('Under Verification'));
        expect(reply.text, contains('Junior Engineer'));
      });

      test('"What is happening with my complaint?" provides specific Under Verification update', () async {
        final reply = await provider.generateResponse(
          query: 'What is happening with my complaint?',
          languageCode: 'en',
          appContext: underVerContext,
        );

        expect(reply.text, contains('CF-2026-000024'));
        expect(reply.text, contains('validating photo authenticity'));
      });
    });

    // -------------------------------------------------------------
    // SECTION 3: ASSIGNED & IN PROGRESS CONTEXT SCENARIOS
    // -------------------------------------------------------------
    group('Section 3: Assigned & In Progress Context Scenarios', () {
      test('Assigned context answers "Has work started?" accurately with "Not yet"', () async {
        final assignedComplaint = createSampleComplaint(
          status: ComplaintStatus.assigned,
          assignedCrewMemberId: 'je_1',
          assignedJuniorEngineerNameSnapshot: 'S. Kadam',
        );
        final assignedContext = ComplaintToAssistantContextMapper.mapFromComplaint(
          assignedComplaint,
        );

        final reply = await provider.generateResponse(
          query: 'Has work started on my complaint?',
          languageCode: 'en',
          appContext: assignedContext,
        );

        expect(reply.text, contains('Not yet'));
        expect(reply.text, contains('Junior Engineer'));
        expect(reply.text, contains('Field Execution Officer'));
      });

      test('Assigned context answers "Who is assigned?" using safe public snapshot', () async {
        final assignedComplaint = createSampleComplaint(
          status: ComplaintStatus.assigned,
          assignedCrewMemberId: 'je_1',
          assignedJuniorEngineerNameSnapshot: 'S. Kadam',
          assignedFieldOfficerId: 'fo_1',
          assignedFieldOfficerNameSnapshot: 'Ganesh Kulkarni',
        );
        final assignedContext = ComplaintToAssistantContextMapper.mapFromComplaint(
          assignedComplaint,
        );

        final reply = await provider.generateResponse(
          query: 'Who is assigned to my complaint?',
          languageCode: 'en',
          appContext: assignedContext,
        );

        expect(reply.text, contains('S. Kadam'));
        expect(reply.text, contains('Ganesh Kulkarni'));
      });

      test('In Progress context answers "What is happening now?" explaining active field work', () async {
        final inProgComplaint = createSampleComplaint(
          status: ComplaintStatus.inProgress,
          assignedCrewMemberId: 'je_1',
          assignedFieldOfficerId: 'fo_1',
        );
        final inProgContext = ComplaintToAssistantContextMapper.mapFromComplaint(
          inProgComplaint,
        );

        final reply = await provider.generateResponse(
          query: 'What is happening with my complaint now?',
          languageCode: 'en',
          appContext: inProgContext,
        );

        expect(reply.text, contains('Work In Progress'));
        expect(reply.text, contains('Field Execution Officer'));
      });
    });

    // -------------------------------------------------------------
    // SECTION 4: BLOCKED, RESOLVED, REWORK & OFFLINE SCENARIOS
    // -------------------------------------------------------------
    group('Section 4: Blocked, Resolved, Rework & Offline Scenarios', () {
      test('Blocked context explains obstacle on site and SLA continuity', () async {
        final blockedComplaint = createSampleComplaint(
          status: ComplaintStatus.inProgress,
          blockedAt: DateTime.now(),
          blockedReason: 'Water logging blocking access',
        );
        final blockedContext = ComplaintToAssistantContextMapper.mapFromComplaint(
          blockedComplaint,
        );

        final reply = await provider.generateResponse(
          query: 'Why is it blocked?',
          languageCode: 'en',
          appContext: blockedContext,
        );

        expect(reply.text, contains('Water logging blocking access'));
        expect(reply.text, contains('SLA countdown continues'));
      });

      test('Resolved context explains supervisory quality audit before closure', () async {
        final resolvedComplaint = createSampleComplaint(
          status: ComplaintStatus.resolved,
        );
        final resolvedContext = ComplaintToAssistantContextMapper.mapFromComplaint(
          resolvedComplaint,
        );

        final reply = await provider.generateResponse(
          query: 'Is my complaint finished?',
          languageCode: 'en',
          appContext: resolvedContext,
        );

        expect(reply.text, contains('Resolved (Stage 5), not yet Closed'));
        expect(reply.text, contains('Ward Department Lead'));
      });

      test('Closed context confirms complaint is fully completed', () async {
        final closedComplaint = createSampleComplaint(
          status: ComplaintStatus.closed,
        );
        final closedContext = ComplaintToAssistantContextMapper.mapFromComplaint(
          closedComplaint,
        );

        final reply = await provider.generateResponse(
          query: 'Is my complaint finished?',
          languageCode: 'en',
          appContext: closedContext,
        );

        expect(reply.text, contains('fully Closed'));
      });

      test('Rework context explains supervisory quality audit and SLA preservation', () async {
        final reworkComplaint = createSampleComplaint(
          status: ComplaintStatus.inProgress,
          reopenCount: 1,
          reopenReason: 'Asphalt surface uneven',
        );
        final reworkContext = ComplaintToAssistantContextMapper.mapFromComplaint(
          reworkComplaint,
        );

        final reply = await provider.generateResponse(
          query: 'Why was my complaint reopened for rework?',
          languageCode: 'en',
          appContext: reworkContext,
        );

        expect(reply.text, contains('Asphalt surface uneven'));
        expect(reply.text, contains('original SLA countdown is strictly preserved'));
      });

      test('Pending sync offline context explains local storage and auto-sync', () async {
        final offlineComplaint = createSampleComplaint(
          syncStatus: SyncStatus.pending,
        );
        final offlineContext = ComplaintToAssistantContextMapper.mapFromComplaint(
          offlineComplaint,
        );

        final reply = await provider.generateResponse(
          query: 'Why can\'t I track my complaint yet?',
          languageCode: 'en',
          appContext: offlineContext,
        );

        expect(reply.text, contains('offline queue'));
        expect(reply.text, contains('Pending Sync'));
      });
    });

    // -------------------------------------------------------------
    // SECTION 5: SCREEN CONTEXT & FALLBACKS
    // -------------------------------------------------------------
    group('Section 5: Screen Context, Contradictions & Fallbacks', () {
      test('Report Issue screen context answers "What do I do here?" with 4 steps', () async {
        final reportContext = ComplaintToAssistantContextMapper.mapForScreen(
          screenName: 'reportIssue',
        );

        final reply = await provider.generateResponse(
          query: 'What do I do here?',
          languageCode: 'en',
          appContext: reportContext,
        );

        expect(reply.text, contains('Report Issue'));
        expect(reply.text, contains('1. Issue Info'));
        expect(reply.text, contains('2. Evidence'));
        expect(reply.text, contains('3. Location'));
        expect(reply.text, contains('4. Review & Submit'));
      });

      test('Map screen context answers "How does this screen work?" explaining GIS pins and clusters', () async {
        final mapContext = ComplaintToAssistantContextMapper.mapForScreen(
          screenName: 'map',
        );

        final reply = await provider.generateResponse(
          query: 'How does this screen work?',
          languageCode: 'en',
          appContext: mapContext,
        );

        expect(reply.text, contains('Hazard Map'));
        expect(reply.text, contains('clustering'));
      });

      test('Contradiction guard: User says "My complaint is closed" when context is In Progress', () async {
        final inProgComplaint = createSampleComplaint(
          status: ComplaintStatus.inProgress,
        );
        final inProgContext = ComplaintToAssistantContextMapper.mapFromComplaint(
          inProgComplaint,
        );

        final reply = await provider.generateResponse(
          query: 'My complaint is closed already.',
          languageCode: 'en',
          appContext: inProgContext,
        );

        expect(reply.text, contains('still Work In Progress'));
      });

      test('Fallback: "What happens next?" with NO complaint context provides generic 5-stage overview', () async {
        final reply = await provider.generateResponse(
          query: 'What happens next?',
          languageCode: 'en',
          appContext: const AssistantAppContext(), // Empty context
        );

        expect(reply.text, contains('5-stage'));
        expect(reply.text, contains('Reported'));
        expect(reply.text, contains('Resolved'));
      });
    });

    // -------------------------------------------------------------
    // SECTION 6: CASUAL CONVERSATION BYPASS WITH ACTIVE CONTEXT
    // -------------------------------------------------------------
    group('Section 6: Casual Conversation Bypass With Active Context', () {
      final activeComplaint = createSampleComplaint(
        status: ComplaintStatus.underVerification,
      );
      final activeContext = ComplaintToAssistantContextMapper.mapFromComplaint(
        activeComplaint,
      );

      test('Casual greeting "Hello" with active complaint does NOT dump complaint info', () async {
        final reply = await provider.generateResponse(
          query: 'Hello',
          languageCode: 'en',
          appContext: activeContext,
        );

        expect(reply.text, contains('How can I help you today?'));
        expect(reply.text, isNot(contains('CF-2026-000024')));
        expect(reply.text, isNot(contains('underVerification')));
      });

      test('Casual small talk "How are you?" does NOT dump complaint info', () async {
        final reply = await provider.generateResponse(
          query: 'How are you?',
          languageCode: 'en',
          appContext: activeContext,
        );

        expect(reply.text, contains('doing well'));
        expect(reply.text, isNot(contains('CF-2026-000024')));
      });
    });

    // -------------------------------------------------------------
    // SECTION 7: RAG RETRIEVAL WITH APP CONTEXT HINTS
    // -------------------------------------------------------------
    group('Section 7: RAG Retrieval With App Context Hints', () {
      test('RAG retriever utilizes app context hints to prioritize underVerification lifecycle', () {
        final context = const AssistantAppContext(
          complaintStatus: 'underVerification',
          currentScreen: 'complaintDetails',
        );

        final result = retriever.retrieve(AssistantRetrievalRequest(
          query: 'What happens next?',
          intent: CivicAssistantIntent.civicfixProcess,
          appContext: context,
        ));

        expect(result.hasChunks, isTrue);
        expect(
          result.retrievedKnowledgeIds,
          anyOf(
            contains('status_under_verification'),
            contains('lifecycle_under_verification'),
            contains('faq_under_verification_meaning'),
            contains('lifecycle_overview'),
          ),
        );
      });

      test('RAG retriever utilizes app context hints to prioritize rework rules', () {
        final context = const AssistantAppContext(
          complaintStatus: 'reopened',
          reopenCount: 1,
          currentScreen: 'complaintDetails',
        );

        final result = retriever.retrieve(AssistantRetrievalRequest(
          query: 'Why are they fixing it again?',
          intent: CivicAssistantIntent.civicfixProcess,
          appContext: context,
        ));

        expect(result.hasChunks, isTrue);
        expect(
          result.retrievedKnowledgeIds,
          anyOf(
            contains('resolution_rework_workflow'),
            contains('rework_sla_preservation'),
            contains('faq_rework_defective_repair'),
          ),
        );
      });
    });

    // -------------------------------------------------------------
    // SECTION 8: CONTROLLER CONTEXT FRESHNESS & CLEARING
    // -------------------------------------------------------------
    group('Section 8: Controller Context Freshness & Clearing', () {
      test('Controller updates and clears complaint context reactively', () {
        final controller = CivicAssistantController();
        controller.initSession();

        expect(controller.hasComplaintContext, isFalse);

        final complaintA = createSampleComplaint(ticketNumber: 'CF-2026-000100');
        controller.updateComplaintContext(complaintA);

        expect(controller.hasComplaintContext, isTrue);
        expect(controller.appContext.ticketId, equals('CF-2026-000100'));

        // Freshness update to Complaint B
        final complaintB = createSampleComplaint(ticketNumber: 'CF-2026-000200');
        controller.updateComplaintContext(complaintB);

        expect(controller.appContext.ticketId, equals('CF-2026-000200'));

        // Clear complaint context
        controller.clearComplaintContext();
        expect(controller.hasComplaintContext, isFalse);
        expect(controller.appContext.ticketId, isNull);
      });
    });
  });
}
