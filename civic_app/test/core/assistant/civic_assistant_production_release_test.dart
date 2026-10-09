import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/assistant/config/civic_assistant_config.dart';
import 'package:civic_app/core/assistant/controller/civic_assistant_controller.dart';
import 'package:civic_app/core/assistant/models/assistant_app_context.dart';
import 'package:civic_app/core/assistant/models/assistant_conversation_history.dart';
import 'package:civic_app/core/assistant/observability/assistant_analytics.dart';
import 'package:civic_app/core/assistant/observability/assistant_error_type.dart';
import 'package:civic_app/core/assistant/observability/assistant_observability.dart';
import 'package:civic_app/core/assistant/services/civic_assistant_feedback_service.dart';
import 'package:civic_app/core/assistant/services/civic_assistant_provider.dart';
import 'package:civic_app/core/models/assistant_message_model.dart';

/// Mock failing remote provider for testing fallback degradation
class FailingRemoteAssistantProvider implements CivicAssistantProvider {
  @override
  Future<AssistantMessage> generateResponse({
    required String query,
    required String languageCode,
    AssistantConversationHistory? history,
    AssistantAppContext? appContext,
    dynamic ragContext,
  }) async {
    throw Exception('Simulated remote AI server timeout / 503 Service Unavailable');
  }
}

void main() {
  setUp(() {
    CivicAssistantConfig.resetToDefault();
    CivicAssistantObservability.instance.reset();
    CivicAssistantAnalytics.instance.clear();
    CivicAssistantFeedbackService.instance.setEngine(MockCivicAssistantFeedbackEngine());
  });

  tearDown(() {
    CivicAssistantConfig.resetToDefault();
    CivicAssistantObservability.instance.reset();
    CivicAssistantAnalytics.instance.clear();
    CivicAssistantFeedbackService.instance.resetEngine();
  });

  group('CivicFix Chatbot Phase 8 — Production Release & Observability Suite', () {
    test('Section 1: Provider Architecture & Safe Local Grounding Baseline', () async {
      final provider = GroundedCivicAssistantProvider();
      final response = await provider.generateResponse(
        query: 'What is CivicFix?',
        languageCode: 'en',
      );

      expect(response.isError, isFalse);
      expect(response.text, contains('CivicFix'));
      expect(response.metadata, isNotNull);
      expect(response.metadata!['isGrounded'], isTrue);
      expect(response.metadata!['knowledgeVersion'], equals('v1.2.0-2026Q1'));
      expect(response.metadata!['assistantVersion'], equals('v1.8.0-phase8'));
      expect(response.metadata!['retrievalVersion'], equals('v1.4.0-hybrid'));
      expect(response.metadata!['latencyMs'], isA<int>());
    });

    test('Section 2: Composite Provider & Graceful Fallback Degradation', () async {
      // Configure remote AI enabled with a failing provider
      CivicAssistantConfig.setGlobal(
        CivicAssistantConfig.current.copyWith(remoteAiEnabled: true),
      );

      final compositeProvider = CompositeCivicAssistantProvider(
        remoteAiProvider: FailingRemoteAssistantProvider(),
      );

      // Query that routes to complex/fallback flow
      final response = await compositeProvider.generateResponse(
        query: 'How are complex multi-department civic grievances handled?',
        languageCode: 'en',
      );

      expect(response.isError, isFalse);
      expect(response.text.isNotEmpty, isTrue);
      expect(response.metadata!['isFallback'], isTrue);

      final metrics = CivicAssistantObservability.instance.getSnapshot();
      expect(metrics.totalRequests, greaterThanOrEqualTo(1));
      expect(metrics.fallbackCount, greaterThanOrEqualTo(1));
    });

    test('Section 3: Production Feature Flag Emergency Shutdown & Maintenance Mode', () async {
      // Disable assistant globally via feature flag
      CivicAssistantConfig.setGlobal(
        CivicAssistantConfig.current.copyWith(assistantEnabled: false),
      );

      final provider = CompositeCivicAssistantProvider();
      final responseEn = await provider.generateResponse(
        query: 'Hello',
        languageCode: 'en',
      );

      expect(responseEn.isError, isTrue);
      expect(responseEn.text, contains('scheduled maintenance'));

      final responseHi = await provider.generateResponse(
        query: 'नमस्ते',
        languageCode: 'hi',
      );
      expect(responseHi.isError, isTrue);
      expect(responseHi.text, contains('रखरखाव'));

      final responseMr = await provider.generateResponse(
        query: 'नमस्कार',
        languageCode: 'mr',
      );
      expect(responseMr.isError, isTrue);
      expect(responseMr.text, contains('देखभालीसाठी'));

      final metrics = CivicAssistantObservability.instance.getSnapshot();
      expect(metrics.errorTypeDistribution['assistantDisabled'], equals(3));
    });

    test('Section 4: Context-Aware Welcome & Suggestion Prompts across Screens', () {
      // Home context
      const homeContext = AssistantAppContext(currentScreen: 'home');
      final homeGreeting = CivicAssistantController.getWelcomeGreeting('en', context: homeContext);
      final homePrompts = CivicAssistantController.getSuggestedPrompts('en', context: homeContext);

      expect(homeGreeting, contains('How can I help you today?'));
      expect(homePrompts, contains('What is CivicFix?'));

      // Complaint Details context with ticket
      const complaintContext = AssistantAppContext(
        currentScreen: 'complaintDetails',
        selectedTicketNumber: 'CF-2026-000042',
        complaintStatus: 'underVerification',
      );
      final complaintGreeting =
          CivicAssistantController.getWelcomeGreeting('en', context: complaintContext);
      final complaintPrompts =
          CivicAssistantController.getSuggestedPrompts('en', context: complaintContext);

      expect(complaintGreeting, contains('CF-2026-000042'));
      expect(complaintPrompts, contains('What happens next?'));
      expect(complaintPrompts, contains('Who is handling this?'));

      // Report Issue context
      const reportContext = AssistantAppContext(currentScreen: 'reportIssue');
      final reportGreeting =
          CivicAssistantController.getWelcomeGreeting('en', context: reportContext);
      final reportPrompts =
          CivicAssistantController.getSuggestedPrompts('en', context: reportContext);

      expect(reportGreeting, contains('guide you through reporting'));
      expect(reportPrompts, contains('What should I enter here?'));
      expect(reportPrompts, contains('What evidence should I upload?'));

      // Map context
      const mapContext = AssistantAppContext(currentScreen: 'map');
      final mapGreeting = CivicAssistantController.getWelcomeGreeting('en', context: mapContext);
      final mapPrompts = CivicAssistantController.getSuggestedPrompts('en', context: mapContext);

      expect(mapGreeting, contains('Exploring civic issues on the map?'));
      expect(mapPrompts, contains('What do these markers mean?'));
      expect(mapPrompts, contains('How do clusters work?'));
    });

    test('Section 5: Multilingual Context Prompts in Hindi and Marathi', () {
      const complaintContext = AssistantAppContext(
        currentScreen: 'complaintDetails',
        selectedTicketNumber: 'CF-2026-000099',
        complaintStatus: 'assigned',
      );

      // Hindi
      final hiGreeting =
          CivicAssistantController.getWelcomeGreeting('hi', context: complaintContext);
      final hiPrompts =
          CivicAssistantController.getSuggestedPrompts('hi', context: complaintContext);
      expect(hiGreeting, contains('CF-2026-000099'));
      expect(hiPrompts, contains('आगे क्या प्रक्रिया होगी?'));
      expect(hiPrompts, contains('इसकी देखरेख कौन कर रहा है?'));

      // Marathi
      final mrGreeting =
          CivicAssistantController.getWelcomeGreeting('mr', context: complaintContext);
      final mrPrompts =
          CivicAssistantController.getSuggestedPrompts('mr', context: complaintContext);
      expect(mrGreeting, contains('CF-2026-000099'));
      expect(mrPrompts, contains('आता पुढे काय होईल?'));
      expect(mrPrompts, contains('हे कोणाकडे सोपवले आहे?'));
    });

    test('Section 6: Privacy-Safe Telemetry & Zero-PII Guarantee', () {
      final analytics = CivicAssistantAnalytics.instance;

      analytics.logSessionStarted(
        sessionId: 'sess_test_1',
        languageCode: 'en',
        currentScreen: 'home',
      );

      analytics.logQuerySubmitted(
        sessionId: 'sess_test_1',
        queryLength: 18,
        languageCode: 'en',
        currentScreen: 'home',
      );

      // Test PII parameter redaction
      analytics.logEvent(
        'custom_test_event',
        sessionId: 'sess_test_1',
        parameters: {
          'userPhone': '9820011223',
          'userEmail': 'citizen@mumbai.gov.in',
          'otpCode': 'OTP: 5821',
          'safeCategory': 'Pothole',
        },
      );

      final events = analytics.recentEvents;
      expect(events.length, equals(3));

      final piiEvent = events.firstWhere((e) => e.eventName == 'custom_test_event');
      expect(piiEvent.parameters['userPhone'], equals('[REDACTED_PII]'));
      expect(piiEvent.parameters['userEmail'], equals('[REDACTED_PII]'));
      expect(piiEvent.parameters['otpCode'], equals('[REDACTED_PII]'));
      expect(piiEvent.parameters['safeCategory'], equals('Pothole'));
    });

    test('Section 7: Quality Feedback Mechanism (Thumbs Up / Down) & Non-Auto-Training', () async {
      final controller = CivicAssistantController();
      controller.initSession(languageCode: 'en');

      final reply = await controller.sendMessage('What is CivicFix?');
      expect(reply.feedbackRating, isNull);

      // Citizen marks response as helpful
      await controller.submitFeedback(reply.id, AssistantFeedbackRating.helpful);

      final updatedMessage = controller.messages.firstWhere((m) => m.id == reply.id);
      expect(updatedMessage.feedbackRating, equals(AssistantFeedbackRating.helpful));

      final metrics = CivicAssistantObservability.instance.getSnapshot();
      expect(metrics.helpfulFeedbackCount, equals(1));
      expect(metrics.unhelpfulFeedbackCount, equals(0));
      expect(metrics.satisfactionRate, equals(100.0));
    });

    test('Section 8: Observability Snapshot & Latency Distribution', () async {
      final provider = GroundedCivicAssistantProvider();

      await provider.generateResponse(query: 'Hello', languageCode: 'en');
      await provider.generateResponse(query: 'How to report pothole?', languageCode: 'en');
      await provider.generateResponse(query: 'नमस्ते', languageCode: 'hi');

      final metrics = CivicAssistantObservability.instance.getSnapshot();
      expect(metrics.totalRequests, equals(3));
      expect(metrics.successfulRequests, equals(3));
      expect(metrics.failedRequests, equals(0));
      expect(metrics.successRate, equals(100.0));
      expect(metrics.averageLatencyMs, greaterThan(0.0));
      expect(metrics.p95LatencyMs, greaterThan(0.0));
      expect(metrics.localeDistribution['en'], equals(2));
      expect(metrics.localeDistribution['hi'], equals(1));
    });

    test('Section 9: Error Classification & Multilingual Error Mappings', () {
      const netError = AssistantErrorType.networkFailure;
      expect(netError.userFriendlyMessage('en'), contains('Network connection issue'));
      expect(netError.userFriendlyMessage('hi'), contains('नेटवर्क कनेक्शन'));
      expect(netError.userFriendlyMessage('mr'), contains('नेटवर्क कनेक्शनमध्ये'));

      const rateLimitError = AssistantErrorType.rateLimited;
      expect(rateLimitError.userFriendlyMessage('en'), contains('Too many requests'));
      expect(rateLimitError.userFriendlyMessage('hi'), contains('बहुत अधिक अनुरोध'));
      expect(rateLimitError.userFriendlyMessage('mr'), contains('खूप जास्त विनंत्या'));
    });

    test('Section 10: End-to-End Citizen Scenarios (A to F)', () async {
      final controller = CivicAssistantController();

      // SCENARIO A: Citizen opens Home and asks "What is CivicFix?"
      controller.clearComplaintContext();
      final replyA = await controller.sendMessage('What is CivicFix?');
      expect(replyA.text, contains('CivicFix'));
      expect(replyA.text, contains('grievance'));

      // SCENARIO B: Citizen opens Under Verification complaint -> "What happens next?"
      controller.updateAppContext(
        const AssistantAppContext(
          currentScreen: 'complaintDetails',
          selectedTicketNumber: 'CF-2026-000101',
          complaintStatus: 'underVerification',
        ),
      );
      final replyB = await controller.sendMessage('What happens next?');
      expect(replyB.text.toLowerCase(), contains('verification'));

      // SCENARIO C: Citizen opens Assigned complaint -> "Has work started?"
      controller.updateAppContext(
        const AssistantAppContext(
          currentScreen: 'complaintDetails',
          selectedTicketNumber: 'CF-2026-000102',
          complaintStatus: 'assigned',
          hasJuniorEngineerAssigned: true,
          assignedJuniorEngineerName: 'Ganesh Kulkarni',
        ),
      );
      final replyC = await controller.sendMessage('Has work started?');
      expect(replyC.text.toLowerCase(), contains('assigned'));
      expect(replyC.text, contains('Not yet'));
      expect(replyC.text, contains('Field Execution Officer'));

      // SCENARIO D: Citizen opens Resolved complaint -> "Is it finished?"
      controller.updateAppContext(
        const AssistantAppContext(
          currentScreen: 'complaintDetails',
          selectedTicketNumber: 'CF-2026-000103',
          complaintStatus: 'resolved',
        ),
      );
      final replyD = await controller.sendMessage('Is it finished?');
      expect(replyD.text, contains('Resolved'));
      expect(replyD.text, contains('Closed'));

      // SCENARIO E: Marathi contextual question "आता पुढे काय होईल?"
      controller.updateAppContext(
        const AssistantAppContext(
          currentScreen: 'complaintDetails',
          selectedTicketNumber: 'CF-2026-000104',
          complaintStatus: 'underVerification',
          selectedLanguage: 'mr',
        ),
      );
      final replyE = await controller.sendMessage('आता पुढे काय होईल?');
      expect(replyE.text, contains('पडताळणी'));

      // SCENARIO F: Clear chat resets context cleanly
      controller.clearChat();
      expect(controller.messages.length, equals(1));
      expect(controller.messages.first.isAssistant, isTrue);
    });
  });
}
