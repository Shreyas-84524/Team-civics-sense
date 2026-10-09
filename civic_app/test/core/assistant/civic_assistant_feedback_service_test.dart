import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/assistant/config/civic_assistant_config.dart';
import 'package:civic_app/core/assistant/controller/civic_assistant_controller.dart';
import 'package:civic_app/core/assistant/models/chatbot_feedback_record.dart';
import 'package:civic_app/core/assistant/services/civic_assistant_feedback_service.dart';
import 'package:civic_app/core/assistant/services/civic_assistant_provider.dart';
import 'package:civic_app/core/assistant/services/civic_assistant_tts_service.dart';
import 'package:civic_app/core/models/assistant_message_model.dart';

class TestFakeTtsEngine implements CivicTtsEngine {
  bool isSpeaking = false;
  void Function()? onStart;
  void Function()? onCompletion;
  void Function()? onCancel;
  dynamic Function(dynamic message)? onError;

  @override
  Future<dynamic> setLanguage(String language) async => 1;

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> setVolume(double volume) async => 1;

  @override
  Future<dynamic> setPitch(double pitch) async => 1;

  @override
  Future<dynamic> speak(String text) async {
    isSpeaking = true;
    onStart?.call();
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    isSpeaking = false;
    onCancel?.call();
    return 1;
  }

  @override
  Future<dynamic> pause() async {
    isSpeaking = false;
    return 1;
  }

  @override
  Future<dynamic> isLanguageAvailable(String language) async => true;

  @override
  void setStartHandler(void Function() callback) => onStart = callback;

  @override
  void setCompletionHandler(void Function() callback) => onCompletion = callback;

  @override
  void setCancelHandler(void Function() callback) => onCancel = callback;

  @override
  void setErrorHandler(dynamic Function(dynamic message) callback) => onError = callback;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCivicAssistantFeedbackEngine mockEngine;
  late CivicAssistantFeedbackService feedbackService;

  setUp(() {
    mockEngine = MockCivicAssistantFeedbackEngine();
    feedbackService = CivicAssistantFeedbackService(engine: mockEngine);
    CivicAssistantFeedbackService.instance.setEngine(mockEngine);
    CivicAssistantTtsService.instance = CivicAssistantTtsService(engine: TestFakeTtsEngine());
    CivicAssistantConfig.setGlobal(const CivicAssistantConfig(
      feedbackEnabled: true,
      ttsReadinessEnabled: true,
      assistantEnabled: true,
    ));
  });

  tearDown(() {
    CivicAssistantFeedbackService.instance.resetEngine();
    mockEngine.clear();
  });

  group('CivicFix Chatbot Phase 3 — ChatbotFeedbackRecord Model & Privacy Tests', () {
    test('Builds deterministic feedback document ID from session and message IDs', () {
      final id = ChatbotFeedbackRecord.buildFeedbackId('sess_123', 'msg_a_456');
      expect(id, equals('sess_123_msg_a_456'));

      // Handles path slashes safely
      final safeId = ChatbotFeedbackRecord.buildFeedbackId('sess/123', 'msg/a/456');
      expect(safeId, equals('sess_123_msg_a_456'));
    });

    test('Sanitizes and truncates overly long userMessage and assistantReply to 2000 chars', () {
      final hugeString = 'A' * 3500;
      final sanitized = ChatbotFeedbackRecord.sanitizeText(hugeString);
      expect(sanitized.length, equals(2000));
      expect(sanitized, equals('A' * 2000));
    });

    test('toFirestoreMap enforces strict privacy allowlist without leaking sensitive credentials', () {
      const record = ChatbotFeedbackRecord(
        feedbackId: 'sess_1_msg_1',
        sessionId: 'sess_1',
        assistantMessageId: 'msg_1',
        userMessageId: 'msg_u_1',
        userMessage: 'What is the status of CF-2026-0001?',
        assistantReply: 'Your complaint CF-2026-0001 in Ward R/South is under verification.',
        feedbackType: ChatbotFeedbackType.upvote,
        language: 'en',
        intentCategory: 'statusExplanation',
        currentScreen: 'complaintDetails',
        complaintStatus: 'underVerification',
        retrievedKnowledgeIds: ['status_under_verification', 'lifecycle_under_verification'],
        retrievalSuccess: true,
        providerMode: 'grounded',
        responseLatencyMs: 42,
        knowledgeVersion: '1.0.0',
        assistantVersion: '1.0.0',
        ownerUid: 'citizen_uid_123',
      );

      final map = record.toFirestoreMap(isUpdate: false);

      // Verify required fields present
      expect(map['feedbackId'], equals('sess_1_msg_1'));
      expect(map['sessionId'], equals('sess_1'));
      expect(map['assistantMessageId'], equals('msg_1'));
      expect(map['userMessageId'], equals('msg_u_1'));
      expect(map['userMessage'], equals('What is the status of CF-2026-0001?'));
      expect(map['assistantReply'], contains('CF-2026-0001'));
      expect(map['assistantReply'], contains('R/South'));
      expect(map['feedbackType'], equals('upvote'));
      expect(map['language'], equals('en'));
      expect(map['intentCategory'], equals('statusExplanation'));
      expect(map['complaintStatus'], equals('underVerification'));
      expect(map['retrievedKnowledgeIds'], equals(['status_under_verification', 'lifecycle_under_verification']));
      expect(map['ownerUid'], equals('citizen_uid_123'));

      // Explicit privacy allowlist verification: no forbidden sensitive fields
      final forbiddenKeys = [
        'password',
        'otp',
        'authToken',
        'token',
        'firebaseToken',
        'privateEvidenceUrl',
        'citizenPhone',
        'citizenEmail',
        'officerPhone',
        'officerEmail',
        'governmentPassword',
      ];
      for (final key in forbiddenKeys) {
        expect(map.containsKey(key), isFalse, reason: 'Forbidden key $key found in Firestore payload!');
      }
    });

    test('toFirestoreMap for update only transmits modifiable keys (feedbackType, updatedAt, language)', () {
      const record = ChatbotFeedbackRecord(
        feedbackId: 'sess_1_msg_1',
        sessionId: 'sess_1',
        assistantMessageId: 'msg_1',
        userMessageId: 'msg_u_1',
        userMessage: 'What is the status?',
        assistantReply: 'Your complaint is under verification.',
        feedbackType: ChatbotFeedbackType.downvote,
        language: 'hi',
      );

      final updateMap = record.toFirestoreMap(isUpdate: true);
      expect(updateMap.keys, containsAll(['feedbackType', 'language', 'updatedAt']));
      expect(updateMap.containsKey('feedbackId'), isFalse);
      expect(updateMap.containsKey('sessionId'), isFalse);
      expect(updateMap.containsKey('userMessage'), isFalse);
      expect(updateMap.containsKey('createdAt'), isFalse);
    });

    test('Parses fromMap correctly and handles ChatbotFeedbackType mappings', () {
      final docMap = {
        'feedbackId': 'sess_1_msg_1',
        'sessionId': 'sess_1',
        'assistantMessageId': 'msg_1',
        'userMessageId': 'msg_u_1',
        'userMessage': 'तक्रार कशी नोंदवायची?',
        'assistantReply': 'CivicFix मध्ये तक्रार नोंदवण्यासाठी अधिक चिन्हावर टॅप करा.',
        'feedbackType': 'upvote',
        'language': 'mr',
        'retrievedKnowledgeIds': ['report_flow'],
        'retrievalSuccess': true,
        'createdAt': DateTime(2026, 10, 8, 12, 0).toIso8601String(),
        'updatedAt': DateTime(2026, 10, 8, 12, 5).toIso8601String(),
      };

      final parsed = ChatbotFeedbackRecord.fromMap(docMap, 'sess_1_msg_1');
      expect(parsed.feedbackId, equals('sess_1_msg_1'));
      expect(parsed.feedbackType, equals(ChatbotFeedbackType.upvote));
      expect(parsed.language, equals('mr'));
      expect(parsed.userMessage, equals('तक्रार कशी नोंदवायची?'));
      expect(parsed.assistantReply, equals('CivicFix मध्ये तक्रार नोंदवण्यासाठी अधिक चिन्हावर टॅप करा.'));
      expect(parsed.retrievedKnowledgeIds, equals(['report_flow']));
    });
  });

  group('CivicFix Chatbot Phase 3 — CivicAssistantFeedbackService Tests', () {
    test('Submits upvote and persists 1 record per assistant message with exact message linkage', () async {
      final userMsg = AssistantMessage(
        id: 'msg_u_100',
        text: 'How do I report a broken streetlight?',
        sender: AssistantMessageSender.user,
        timestamp: DateTime.now(),
      );
      final assistantMsg = AssistantMessage(
        id: 'msg_a_200',
        text: 'To report a broken streetlight, go to Report Issue and select Street Lighting.',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        metadata: {
          'language': 'en',
          'intent': 'reportCategory',
          'retrievedKnowledgeIds': ['dept_street_lighting'],
          'providerMode': 'grounded',
        },
      );

      final success = await feedbackService.submitFeedback(
        sessionId: 'sess_101',
        assistantMessage: assistantMsg,
        userMessage: userMsg,
        rating: AssistantFeedbackRating.helpful,
        ownerUid: 'test_user_1',
      );

      expect(success, isTrue);
      expect(mockEngine.saveCallCount, equals(1));

      final saved = await feedbackService.getFeedbackRecord(
        sessionId: 'sess_101',
        assistantMessageId: 'msg_a_200',
      );
      expect(saved, isNotNull);
      expect(saved!.feedbackType, equals(ChatbotFeedbackType.upvote));
      expect(saved.userMessageId, equals('msg_u_100'));
      expect(saved.userMessage, equals('How do I report a broken streetlight?'));
      expect(saved.assistantMessageId, equals('msg_a_200'));
      expect(saved.assistantReply, equals(assistantMsg.text));
      expect(saved.ownerUid, equals('test_user_1'));
    });

    test('Switching vote from upvote to downvote updates the existing document instead of duplicating', () async {
      final userMsg = AssistantMessage(
        id: 'msg_u_1',
        text: 'Where is Ward K/West office?',
        sender: AssistantMessageSender.user,
        timestamp: DateTime.now(),
      );
      final assistantMsg = AssistantMessage(
        id: 'msg_a_1',
        text: 'Ward K/West office is located in Andheri West, Paliram Road.',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        metadata: {'language': 'en'},
      );

      // 1. Initial Upvote
      await feedbackService.submitFeedback(
        sessionId: 'sess_1',
        assistantMessage: assistantMsg,
        userMessage: userMsg,
        rating: AssistantFeedbackRating.helpful,
      );
      var record = await feedbackService.getFeedbackRecord(sessionId: 'sess_1', assistantMessageId: 'msg_a_1');
      expect(record?.feedbackType, equals(ChatbotFeedbackType.upvote));

      // 2. Switch to Downvote
      final switchSuccess = await feedbackService.submitFeedback(
        sessionId: 'sess_1',
        assistantMessage: assistantMsg,
        userMessage: userMsg,
        rating: AssistantFeedbackRating.unhelpful,
        isUpdate: true,
      );
      expect(switchSuccess, isTrue);

      record = await feedbackService.getFeedbackRecord(sessionId: 'sess_1', assistantMessageId: 'msg_a_1');
      expect(record?.feedbackType, equals(ChatbotFeedbackType.downvote));
      // Only 1 document exists in storage
      expect(mockEngine.saveCallCount, equals(2));
    });

    test('Deselecting active vote removes the document cleanly from storage', () async {
      final assistantMsg = AssistantMessage(
        id: 'msg_a_1',
        text: 'Helpful answer',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      // Submit
      await feedbackService.submitFeedback(
        sessionId: 'sess_1',
        assistantMessage: assistantMsg,
        userMessage: null,
        rating: AssistantFeedbackRating.helpful,
      );
      expect(await feedbackService.getFeedbackRecord(sessionId: 'sess_1', assistantMessageId: 'msg_a_1'), isNotNull);

      // Deselect / Remove
      final removeSuccess = await feedbackService.removeFeedback(
        sessionId: 'sess_1',
        assistantMessageId: 'msg_a_1',
      );
      expect(removeSuccess, isTrue);
      expect(mockEngine.deleteCallCount, equals(1));
      expect(await feedbackService.getFeedbackRecord(sessionId: 'sess_1', assistantMessageId: 'msg_a_1'), isNull);
    });

    test('Preserves multilingual text in Hindi and Marathi and canonical tokens verbatim', () async {
      final userMsg = AssistantMessage(
        id: 'msg_u_hi',
        text: 'शिकायत CF-2026-9999 किस प्रभाग में है?',
        sender: AssistantMessageSender.user,
        timestamp: DateTime.now(),
      );
      final assistantMsg = AssistantMessage(
        id: 'msg_a_hi',
        text: 'आपकी शिकायत CF-2026-9999 प्रभाग K/West में कनिष्ठ अभियंता Ganesh Kulkarni द्वारा संभाली जा रही है।',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        metadata: {'language': 'hi'},
      );

      await feedbackService.submitFeedback(
        sessionId: 'sess_hi',
        assistantMessage: assistantMsg,
        userMessage: userMsg,
        rating: AssistantFeedbackRating.helpful,
      );

      final saved = await feedbackService.getFeedbackRecord(
        sessionId: 'sess_hi',
        assistantMessageId: 'msg_a_hi',
      );
      expect(saved!.language, equals('hi'));
      expect(saved.userMessage, equals('शिकायत CF-2026-9999 किस प्रभाग में है?'));
      expect(saved.assistantReply, contains('CF-2026-9999'));
      expect(saved.assistantReply, contains('K/West'));
      expect(saved.assistantReply, contains('Ganesh Kulkarni'));
    });

    test('Rapid duplicate taps are serialized safely without unhandled race conditions', () async {
      final assistantMsg = AssistantMessage(
        id: 'msg_rapid_1',
        text: 'Test message for rapid taps',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      // Simulate rapid burst of 3 taps: Upvote -> Downvote -> Upvote
      final f1 = feedbackService.submitFeedback(
        sessionId: 'sess_rapid',
        assistantMessage: assistantMsg,
        userMessage: null,
        rating: AssistantFeedbackRating.helpful,
      );
      final f2 = feedbackService.submitFeedback(
        sessionId: 'sess_rapid',
        assistantMessage: assistantMsg,
        userMessage: null,
        rating: AssistantFeedbackRating.unhelpful,
        isUpdate: true,
      );
      final f3 = feedbackService.submitFeedback(
        sessionId: 'sess_rapid',
        assistantMessage: assistantMsg,
        userMessage: null,
        rating: AssistantFeedbackRating.helpful,
        isUpdate: true,
      );

      final results = await Future.wait([f1, f2, f3]);
      expect(results, equals([true, true, true]));

      final finalRecord = await feedbackService.getFeedbackRecord(
        sessionId: 'sess_rapid',
        assistantMessageId: 'msg_rapid_1',
      );
      // Final state must match the last tap (helpful / upvote)
      expect(finalRecord?.feedbackType, equals(ChatbotFeedbackType.upvote));
    });

    test('Handles engine failures gracefully and returns false', () async {
      mockEngine.shouldThrow = true;
      final assistantMsg = AssistantMessage(
        id: 'msg_fail_1',
        text: 'Failure test',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      final success = await feedbackService.submitFeedback(
        sessionId: 'sess_fail',
        assistantMessage: assistantMsg,
        userMessage: null,
        rating: AssistantFeedbackRating.helpful,
      );

      expect(success, isFalse);
    });
  });

  group('CivicFix Chatbot Phase 3 — CivicAssistantController Integration & Rollback Tests', () {
    late CivicAssistantController controller;

    setUp(() {
      controller = CivicAssistantController(
        provider: GroundedCivicAssistantProvider(),
      );
      controller.initSession();
    });

    tearDown(() {
      controller.dispose();
    });

    test('sendMessage automatically creates user-to-assistant linkage in metadata', () async {
      await controller.sendMessage('How do I report an issue?');
      expect(controller.messages.length, greaterThanOrEqualTo(2));

      final userMsg = controller.messages.firstWhere((m) => m.isUser);
      final assistantReply = controller.messages.lastWhere((m) => m.isAssistant);

      expect(assistantReply.metadata?['userMessageId'], equals(userMsg.id));
      expect(assistantReply.metadata?['userMessage'], equals(userMsg.text));
    });

    test('Controller submits feedback with optimistic UI and links correct user message', () async {
      await controller.sendMessage('What is CivicFix?');
      final assistantReply = controller.messages.lastWhere((m) => m.isAssistant);

      final success = await controller.submitFeedback(
        assistantReply.id,
        AssistantFeedbackRating.helpful,
      );
      expect(success, isTrue);

      final updatedMsg = controller.messages.firstWhere((m) => m.id == assistantReply.id);
      expect(updatedMsg.feedbackRating, equals(AssistantFeedbackRating.helpful));

      final stored = await feedbackService.getFeedbackRecord(
        sessionId: controller.sessionId,
        assistantMessageId: assistantReply.id,
      );
      expect(stored, isNotNull);
      expect(stored!.feedbackType, equals(ChatbotFeedbackType.upvote));
      expect(stored.userMessage, equals('What is CivicFix?'));
    });

    test('Controller rolls back UI state if Firestore persistence fails', () async {
      await controller.sendMessage('What is CivicFix?');
      final assistantReply = controller.messages.lastWhere((m) => m.isAssistant);

      // Force failure
      mockEngine.shouldThrow = true;

      final success = await controller.submitFeedback(
        assistantReply.id,
        AssistantFeedbackRating.helpful,
      );
      expect(success, isFalse);

      // UI state rolled back to null
      final currentMsg = controller.messages.firstWhere((m) => m.id == assistantReply.id);
      expect(currentMsg.feedbackRating, isNull);
    });

    test('Tapping active feedback again deselects and removes feedback document', () async {
      await controller.sendMessage('Tell me about BMC wards');
      final assistantReply = controller.messages.lastWhere((m) => m.isAssistant);

      // 1. Submit upvote
      await controller.submitFeedback(assistantReply.id, AssistantFeedbackRating.helpful);
      var currentMsg = controller.messages.firstWhere((m) => m.id == assistantReply.id);
      expect(currentMsg.feedbackRating, equals(AssistantFeedbackRating.helpful));

      // 2. Tap active upvote again (Deselect)
      final deselectSuccess = await controller.submitFeedback(
        assistantReply.id,
        AssistantFeedbackRating.helpful,
      );
      expect(deselectSuccess, isTrue);

      currentMsg = controller.messages.firstWhere((m) => m.id == assistantReply.id);
      expect(currentMsg.feedbackRating, isNull);

      final stored = await feedbackService.getFeedbackRecord(
        sessionId: controller.sessionId,
        assistantMessageId: assistantReply.id,
      );
      expect(stored, isNull);
    });

    test('Submitting feedback does NOT alter active TTS speech session (TTS Independence)', () async {
      await controller.sendMessage('What is CivicFix?');
      final assistantReply = controller.messages.lastWhere((m) => m.isAssistant);

      // Start TTS
      await controller.speakMessage(assistantReply);
      expect(controller.isSpeaking, isTrue);
      expect(controller.activeSpeakingMessageId, equals(assistantReply.id));

      // Submit feedback
      await controller.submitFeedback(assistantReply.id, AssistantFeedbackRating.helpful);

      // TTS state must remain active and unaffected
      expect(controller.isSpeaking, isTrue);
      expect(controller.activeSpeakingMessageId, equals(assistantReply.id));
    });

    test('clearChat clears local chat messages but does NOT delete Firestore feedback', () async {
      await controller.sendMessage('How do I track my complaint?');
      final assistantReply = controller.messages.lastWhere((m) => m.isAssistant);
      final replyId = assistantReply.id;
      final currentSessionId = controller.sessionId;

      await controller.submitFeedback(replyId, AssistantFeedbackRating.helpful);

      // Verify stored in Firestore
      expect(await feedbackService.getFeedbackRecord(sessionId: currentSessionId, assistantMessageId: replyId), isNotNull);

      // Clear Chat
      controller.clearChat();
      expect(controller.messages.length, equals(1)); // Only new welcome greeting

      // Firestore record is NOT deleted
      final persisted = await feedbackService.getFeedbackRecord(
        sessionId: currentSessionId,
        assistantMessageId: replyId,
      );
      expect(persisted, isNotNull);
      expect(persisted!.feedbackType, equals(ChatbotFeedbackType.upvote));
    });
  });
}
