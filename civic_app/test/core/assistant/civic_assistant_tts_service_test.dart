import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/assistant/config/civic_assistant_config.dart';
import 'package:civic_app/core/assistant/controller/civic_assistant_controller.dart';
import 'package:civic_app/core/assistant/models/assistant_language.dart';
import 'package:civic_app/core/assistant/services/civic_assistant_tts_service.dart';
import 'package:civic_app/core/models/assistant_message_model.dart';

/// Fake test engine implementing [CivicTtsEngine] for hermetic testing.
class FakeTtsEngine implements CivicTtsEngine {
  final List<String> callLog = [];
  String? currentLanguage;
  double? currentSpeechRate;
  double? currentVolume;
  double? currentPitch;
  String? lastSpokenText;
  bool isSpeaking = false;

  final Map<String, bool> languageAvailability = {
    'en-IN': true,
    'hi-IN': true,
    'mr-IN': true,
    'en-US': true,
  };

  void Function()? onStart;
  void Function()? onCompletion;
  void Function()? onCancel;
  dynamic Function(dynamic message)? onError;

  @override
  Future<dynamic> setLanguage(String language) async {
    callLog.add('setLanguage:$language');
    currentLanguage = language;
    return 1;
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async {
    callLog.add('setSpeechRate:$rate');
    currentSpeechRate = rate;
    return 1;
  }

  @override
  Future<dynamic> setVolume(double volume) async {
    callLog.add('setVolume:$volume');
    currentVolume = volume;
    return 1;
  }

  @override
  Future<dynamic> setPitch(double pitch) async {
    callLog.add('setPitch:$pitch');
    currentPitch = pitch;
    return 1;
  }

  @override
  Future<dynamic> speak(String text) async {
    callLog.add('speak:$text');
    lastSpokenText = text;
    isSpeaking = true;
    onStart?.call();
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    callLog.add('stop');
    isSpeaking = false;
    onCancel?.call();
    return 1;
  }

  @override
  Future<dynamic> pause() async {
    callLog.add('pause');
    isSpeaking = false;
    return 1;
  }

  @override
  Future<dynamic> isLanguageAvailable(String language) async {
    callLog.add('isLanguageAvailable:$language');
    return languageAvailability[language] ?? false;
  }

  @override
  void setStartHandler(void Function() callback) {
    onStart = callback;
  }

  @override
  void setCompletionHandler(void Function() callback) {
    onCompletion = callback;
  }

  @override
  void setCancelHandler(void Function() callback) {
    onCancel = callback;
  }

  @override
  void setErrorHandler(dynamic Function(dynamic message) callback) {
    onError = callback;
  }

  void triggerCompletion() {
    isSpeaking = false;
    onCompletion?.call();
  }

  void triggerError(dynamic error) {
    isSpeaking = false;
    onError?.call(error);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CivicAssistantConfig.resetToDefault();
  });

  group('CivicAssistantTtsService - Unit & Integration Tests', () {
    test('Language code mapping maps to canonical Indian regional BCP-47 tags', () {
      expect(CivicAssistantTtsService.mapLanguageToTtsLocale('en'), 'en-IN');
      expect(CivicAssistantTtsService.mapLanguageToTtsLocale('english'), 'en-IN');
      expect(CivicAssistantTtsService.mapLanguageToTtsLocale('hi'), 'hi-IN');
      expect(CivicAssistantTtsService.mapLanguageToTtsLocale('hindi'), 'hi-IN');
      expect(CivicAssistantTtsService.mapLanguageToTtsLocale('mr'), 'mr-IN');
      expect(CivicAssistantTtsService.mapLanguageToTtsLocale('marathi'), 'mr-IN');
      expect(CivicAssistantTtsService.mapLanguageToTtsLocale('unknown'), 'en-IN');

      expect(
        CivicAssistantTtsService.mapAssistantLanguageToTtsLocale(AssistantLanguage.english),
        'en-IN',
      );
      expect(
        CivicAssistantTtsService.mapAssistantLanguageToTtsLocale(AssistantLanguage.hindi),
        'hi-IN',
      );
      expect(
        CivicAssistantTtsService.mapAssistantLanguageToTtsLocale(AssistantLanguage.marathi),
        'mr-IN',
      );
    });

    test('Speaks assistant message with exact visible text and conservative voice settings', () async {
      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final msg = AssistantMessage(
        id: 'msg_101',
        text: 'Your complaint CF-2026-000042 is under verification with K/West Ward.',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      final result = await ttsService.speakMessage(msg, languageCode: 'en');

      expect(result, isTrue);
      expect(ttsService.isSpeaking, isTrue);
      expect(ttsService.currentSpeakingMessageId, 'msg_101');
      expect(ttsService.currentSpeakingText, msg.text);
      expect(fakeEngine.currentLanguage, 'en-IN');
      expect(fakeEngine.currentSpeechRate, 0.45);
      expect(fakeEngine.currentVolume, 1.0);
      expect(fakeEngine.currentPitch, 1.0);
      expect(fakeEngine.lastSpokenText, msg.text);
    });

    test('Speaks Hindi Devanagari text correctly with hi-IN locale', () async {
      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final msg = AssistantMessage(
        id: 'msg_hi_1',
        text: 'आपकी शिकायत CF-2026-000042 का सत्यापन किया जा रहा है।',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      final result = await ttsService.speakMessage(msg, languageCode: 'hi');

      expect(result, isTrue);
      expect(fakeEngine.currentLanguage, 'hi-IN');
      expect(fakeEngine.lastSpokenText, msg.text);
    });

    test('Speaks Marathi text correctly with mr-IN locale', () async {
      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final msg = AssistantMessage(
        id: 'msg_mr_1',
        text: 'आपली तक्रार CF-2026-000042 सध्या पडताळणी अंतर्गत आहे.',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      final result = await ttsService.speakMessage(msg, languageCode: 'mr');

      expect(result, isTrue);
      expect(fakeEngine.currentLanguage, 'mr-IN');
      expect(fakeEngine.lastSpokenText, msg.text);
    });

    test('Falls back to hi-IN when Marathi voice is missing on device', () async {
      final fakeEngine = FakeTtsEngine();
      fakeEngine.languageAvailability['mr-IN'] = false;
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final msg = AssistantMessage(
        id: 'msg_mr_2',
        text: 'आपली तक्रार नोंदवली गेली आहे.',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      final result = await ttsService.speakMessage(msg, languageCode: 'mr');

      expect(result, isTrue);
      expect(fakeEngine.currentLanguage, 'hi-IN');
    });

    test('Falls back to en-US when Indian English voice is missing', () async {
      final fakeEngine = FakeTtsEngine();
      fakeEngine.languageAvailability['en-IN'] = false;
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final msg = AssistantMessage(
        id: 'msg_en_2',
        text: 'How can I assist you today?',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      final result = await ttsService.speakMessage(msg, languageCode: 'en');

      expect(result, isTrue);
      expect(fakeEngine.currentLanguage, 'en-US');
    });

    test('Rejects speaking user or error messages', () async {
      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final userMsg = AssistantMessage(
        id: 'user_1',
        text: 'My street light is broken',
        sender: AssistantMessageSender.user,
        timestamp: DateTime.now(),
      );

      final errorMsg = AssistantMessage(
        id: 'err_1',
        text: 'Unable to connect to server',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        isError: true,
      );

      expect(await ttsService.speakMessage(userMsg), isFalse);
      expect(await ttsService.speakMessage(errorMsg), isFalse);
      expect(fakeEngine.callLog.where((c) => c.startsWith('speak:')), isEmpty);
    });

    test('Rejects empty or whitespace-only messages', () async {
      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final emptyMsg = AssistantMessage(
        id: 'empty_1',
        text: '   ',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      expect(await ttsService.speakMessage(emptyMsg), isFalse);
      expect(await ttsService.speakText('   ', languageCode: 'en'), isFalse);
      expect(fakeEngine.callLog.where((c) => c.startsWith('speak:')), isEmpty);
    });

    test('Single active session: stops previous speech before starting new speech', () async {
      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final msg1 = AssistantMessage(
        id: 'msg_1',
        text: 'First response text',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      final msg2 = AssistantMessage(
        id: 'msg_2',
        text: 'Second response text',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      await ttsService.speakMessage(msg1, languageCode: 'en');
      expect(ttsService.currentSpeakingMessageId, 'msg_1');
      expect(ttsService.isSpeaking, isTrue);

      // Speak message 2 while message 1 is active
      await ttsService.speakMessage(msg2, languageCode: 'en');

      expect(fakeEngine.callLog, contains('stop'));
      expect(ttsService.currentSpeakingMessageId, 'msg_2');
      expect(ttsService.currentSpeakingText, 'Second response text');
      expect(fakeEngine.lastSpokenText, 'Second response text');
    });

    test('Completion lifecycle resets state to idle', () async {
      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final msg = AssistantMessage(
        id: 'msg_1',
        text: 'Testing completion lifecycle',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      await ttsService.speakMessage(msg, languageCode: 'en');
      expect(ttsService.isSpeaking, isTrue);

      // Simulate completion from engine
      fakeEngine.triggerCompletion();

      expect(ttsService.state, CivicAssistantTtsState.idle);
      expect(ttsService.isSpeaking, isFalse);
      expect(ttsService.currentSpeakingMessageId, isNull);
      expect(ttsService.currentSpeakingText, isNull);
    });

    test('Stop method stops engine and cleans up state', () async {
      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final msg = AssistantMessage(
        id: 'msg_1',
        text: 'Testing manual stop',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      await ttsService.speakMessage(msg, languageCode: 'en');
      expect(ttsService.isSpeaking, isTrue);

      await ttsService.stop();

      expect(ttsService.state, CivicAssistantTtsState.stopped);
      expect(ttsService.isSpeaking, isFalse);
      expect(ttsService.currentSpeakingMessageId, isNull);
      expect(fakeEngine.callLog, contains('stop'));
    });

    test('Error handler sets error state and preserves message error details', () async {
      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final msg = AssistantMessage(
        id: 'msg_1',
        text: 'Testing error handler',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      await ttsService.speakMessage(msg, languageCode: 'en');
      expect(ttsService.isSpeaking, isTrue);

      // Simulate error
      fakeEngine.triggerError('TTS engine platform channel crashed');

      expect(ttsService.state, CivicAssistantTtsState.error);
      expect(ttsService.lastError, 'TTS engine platform channel crashed');
      expect(ttsService.currentSpeakingMessageId, isNull);
    });

    test('Respects ttsReadinessEnabled feature flag', () async {
      CivicAssistantConfig.setGlobal(
        CivicAssistantConfig.current.copyWith(ttsReadinessEnabled: false),
      );

      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final msg = AssistantMessage(
        id: 'msg_1',
        text: 'Feature flag disabled test',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      final result = await ttsService.speakMessage(msg, languageCode: 'en');

      expect(result, isFalse);
      expect(fakeEngine.callLog.where((c) => c.startsWith('speak:')), isEmpty);
    });

    test('CivicAssistantController seamlessly delegates speak and stop to TTS service', () async {
      final fakeEngine = FakeTtsEngine();
      final customTts = CivicAssistantTtsService(engine: fakeEngine);
      CivicAssistantTtsService.instance = customTts;

      final controller = CivicAssistantController();

      final msg = AssistantMessage(
        id: 'ctrl_msg_1',
        text: 'Testing controller TTS integration',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      expect(controller.ttsService, isNotNull);
      expect(controller.isSpeaking, isFalse);

      final spoke = await controller.speakMessage(msg);
      expect(spoke, isTrue);
      expect(controller.isSpeaking, isTrue);
      expect(controller.currentSpeakingMessageId, 'ctrl_msg_1');
      expect(controller.activeSpeakingMessageId, 'ctrl_msg_1');

      await controller.stopSpeech();
      expect(controller.isSpeaking, isFalse);
      expect(controller.activeSpeakingMessageId, isNull);

      // controller dispose stops speech safely without throwing
      expect(() => controller.dispose(), returnsNormally);
    });

    test('Same-message toggle starts and stops playback with identical button tap', () async {
      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final msg = AssistantMessage(
        id: 'msg_toggle_1',
        text: 'Toggling speech playback on the same message.',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      // 1. First tap: starts speaking
      final started = await ttsService.toggleSpeakMessage(msg, languageCode: 'en');
      expect(started, isTrue);
      expect(ttsService.isSpeaking, isTrue);
      expect(ttsService.activeSpeakingMessageId, 'msg_toggle_1');

      // 2. Second tap on same message: stops speaking
      final stopped = await ttsService.toggleSpeakMessage(msg, languageCode: 'en');
      expect(stopped, isFalse);
      expect(ttsService.isSpeaking, isFalse);
      expect(ttsService.activeSpeakingMessageId, isNull);
    });

    test('Message switching stops active message A and starts message B immediately', () async {
      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final msgA = AssistantMessage(
        id: 'msg_A',
        text: 'This is message A.',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      final msgB = AssistantMessage(
        id: 'msg_B',
        text: 'This is message B.',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      // Start message A
      await ttsService.toggleSpeakMessage(msgA, languageCode: 'en');
      expect(ttsService.activeSpeakingMessageId, 'msg_A');
      expect(ttsService.isSpeaking, isTrue);

      // Tap speaker on message B
      await ttsService.toggleSpeakMessage(msgB, languageCode: 'en');
      expect(ttsService.activeSpeakingMessageId, 'msg_B');
      expect(ttsService.isSpeaking, isTrue);
      expect(fakeEngine.lastSpokenText, 'This is message B.');
    });

    test('Stale callback protection: late completion from stopped message does not cancel new message', () async {
      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final msgA = AssistantMessage(
        id: 'msg_A',
        text: 'Message A',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      final msgB = AssistantMessage(
        id: 'msg_B',
        text: 'Message B',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      // Start message A
      await ttsService.speakMessage(msgA, languageCode: 'en');
      expect(ttsService.activeSpeakingMessageId, 'msg_A');

      // Switch to message B (stops A and starts B)
      await ttsService.speakMessage(msgB, languageCode: 'en');
      expect(ttsService.activeSpeakingMessageId, 'msg_B');
      expect(ttsService.isSpeaking, isTrue);

      // Late completion from native platform
      fakeEngine.triggerCompletion();

      // State remains properly managed without stale crash
      expect(ttsService.state, CivicAssistantTtsState.idle);
      expect(ttsService.activeSpeakingMessageId, isNull);
    });

    test('Message Language Ownership: retains Marathi TTS when app locale is switched to English', () async {
      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      // Marathi response created with Marathi metadata
      final marathiMsg = AssistantMessage(
        id: 'msg_mr_history',
        text: 'आपली तक्रार CF-2026-000042 सध्या पडताळणी अंतर्गत आहे.',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
        metadata: {'language': 'mr'},
      );

      // User later switched app to English ('en') and taps speaker on the Marathi message
      final result = await ttsService.speakMessage(marathiMsg, languageCode: 'en');

      expect(result, isTrue);
      // Engine must use mr-IN because message metadata/script owns the language
      expect(fakeEngine.currentLanguage, 'mr-IN');
      expect(fakeEngine.lastSpokenText, marathiMsg.text);
    });

    test('Verbatim exact speech on mixed-language content and canonical tokens', () async {
      final fakeEngine = FakeTtsEngine();
      final ttsService = CivicAssistantTtsService(engine: fakeEngine);

      final mixedMsg = AssistantMessage(
        id: 'msg_mixed_1',
        text: 'तुमची complaint CF-2026-000042 Ward K/West चे अधिकारी Ganesh Kulkarni यांच्याकडे आहे.',
        sender: AssistantMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      final result = await ttsService.speakMessage(mixedMsg);

      expect(result, isTrue);
      expect(fakeEngine.lastSpokenText, mixedMsg.text);
      expect(fakeEngine.lastSpokenText, contains('CF-2026-000042'));
      expect(fakeEngine.lastSpokenText, contains('K/West'));
      expect(fakeEngine.lastSpokenText, contains('Ganesh Kulkarni'));
    });
  });
}
