import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/assistant_message_model.dart';
import '../config/civic_assistant_config.dart';
import '../models/assistant_language.dart';
import 'assistant_language_resolver.dart';

/// Operational state of the CivicFix Assistant TTS service.
enum CivicAssistantTtsState {
  idle,
  speaking,
  paused,
  stopped,
  error,
}

/// Abstract contract for the platform TTS engine (enables mocking in unit/widget tests).
abstract class CivicTtsEngine {
  Future<dynamic> setLanguage(String language);
  Future<dynamic> setSpeechRate(double rate);
  Future<dynamic> setVolume(double volume);
  Future<dynamic> setPitch(double pitch);
  Future<dynamic> speak(String text);
  Future<dynamic> stop();
  Future<dynamic> pause();
  Future<dynamic> isLanguageAvailable(String language);
  void setStartHandler(VoidCallback callback);
  void setCompletionHandler(VoidCallback callback);
  void setCancelHandler(VoidCallback callback);
  void setErrorHandler(dynamic Function(dynamic message) callback);
}

/// Default implementation wrapping official [FlutterTts] plugin with headless/unit test tolerance.
class DefaultFlutterTtsEngine implements CivicTtsEngine {
  FlutterTts? _flutterTts;
  bool _initialized = false;

  DefaultFlutterTtsEngine({FlutterTts? flutterTts}) : _flutterTts = flutterTts;

  FlutterTts? _getTtsSafe() {
    if (_flutterTts != null) return _flutterTts;
    if (_initialized) return null;
    try {
      _flutterTts = FlutterTts();
      _initialized = true;
      return _flutterTts;
    } catch (e) {
      _initialized = true;
      debugPrint('[CivicAssistantTTS] FlutterTts platform binding not active: $e');
      return null;
    }
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    try {
      return await _getTtsSafe()?.setLanguage(language);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async {
    try {
      return await _getTtsSafe()?.setSpeechRate(rate);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<dynamic> setVolume(double volume) async {
    try {
      return await _getTtsSafe()?.setVolume(volume);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<dynamic> setPitch(double pitch) async {
    try {
      return await _getTtsSafe()?.setPitch(pitch);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<dynamic> speak(String text) async {
    try {
      return await _getTtsSafe()?.speak(text);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<dynamic> stop() async {
    try {
      return await _getTtsSafe()?.stop();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<dynamic> pause() async {
    try {
      return await _getTtsSafe()?.pause();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<dynamic> isLanguageAvailable(String language) async {
    try {
      return await _getTtsSafe()?.isLanguageAvailable(language);
    } catch (_) {
      return false;
    }
  }

  @override
  void setStartHandler(VoidCallback callback) {
    try {
      _getTtsSafe()?.setStartHandler(callback);
    } catch (_) {}
  }

  @override
  void setCompletionHandler(VoidCallback callback) {
    try {
      _getTtsSafe()?.setCompletionHandler(callback);
    } catch (_) {}
  }

  @override
  void setCancelHandler(VoidCallback callback) {
    try {
      _getTtsSafe()?.setCancelHandler(callback);
    } catch (_) {}
  }

  @override
  void setErrorHandler(dynamic Function(dynamic message) callback) {
    try {
      _getTtsSafe()?.setErrorHandler(callback);
    } catch (_) {}
  }
}

/// Centralized Text-to-Speech (TTS) service for the CivicFix Assistant.
///
/// Features:
/// - Single active speech session: stopping previous playback before starting a new one.
/// - Exact displayed response speech without re-querying or re-translating.
/// - Symmetrical language mapping for Indian regional locales:
///   - English -> `en-IN` (fallback `en-US`)
///   - Hindi -> `hi-IN`
///   - Marathi -> `mr-IN` (fallback `hi-IN`)
/// - Conservative voice settings (rate 0.45, pitch 1.0, volume 1.0).
/// - Non-crashing graceful error handling and completion lifecycle tracking.
class CivicAssistantTtsService extends ChangeNotifier {
  static CivicAssistantTtsService instance = CivicAssistantTtsService._internal();

  final CivicTtsEngine _engine;

  CivicAssistantTtsState _state = CivicAssistantTtsState.idle;
  String? _currentSpeakingMessageId;
  String? _currentSpeakingText;
  String? _lastError;
  bool _isInitialized = false;
  int _sessionToken = 0;

  CivicAssistantTtsService({CivicTtsEngine? engine})
      : _engine = engine ?? DefaultFlutterTtsEngine() {
    _initEngine();
  }

  CivicAssistantTtsService._internal() : _engine = DefaultFlutterTtsEngine() {
    _initEngine();
  }

  CivicAssistantTtsState get state => _state;
  bool get isSpeaking => _state == CivicAssistantTtsState.speaking;
  String? get currentSpeakingMessageId => _currentSpeakingMessageId;
  String? get activeSpeakingMessageId => _currentSpeakingMessageId;
  String? get currentSpeakingText => _currentSpeakingText;
  String? get lastError => _lastError;

  void _initEngine() {
    if (_isInitialized) return;

    try {
      _engine.setStartHandler(() {
        if (_state != CivicAssistantTtsState.speaking) {
          _state = CivicAssistantTtsState.speaking;
          notifyListeners();
        }
      });

      _engine.setCompletionHandler(() {
        _state = CivicAssistantTtsState.idle;
        _currentSpeakingMessageId = null;
        _currentSpeakingText = null;
        notifyListeners();
      });

      _engine.setCancelHandler(() {
        _state = CivicAssistantTtsState.stopped;
        _currentSpeakingMessageId = null;
        _currentSpeakingText = null;
        notifyListeners();
      });

      _engine.setErrorHandler((msg) {
        debugPrint('[CivicAssistantTTS] Error: $msg');
        _state = CivicAssistantTtsState.error;
        _lastError = msg?.toString();
        _currentSpeakingMessageId = null;
        _currentSpeakingText = null;
        notifyListeners();
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('[CivicAssistantTTS] Initialization error: $e');
    }
  }

  /// Maps an assistant language code or enum to standard BCP-47 Indian regional TTS locale tags.
  static String mapLanguageToTtsLocale(String languageCode) {
    final clean = languageCode.trim().toLowerCase();
    switch (clean) {
      case 'hi':
      case 'hindi':
        return 'hi-IN';
      case 'mr':
      case 'marathi':
        return 'mr-IN';
      case 'en':
      case 'english':
      default:
        return 'en-IN';
    }
  }

  /// Resolves the TTS locale from an [AssistantLanguage] instance.
  static String mapAssistantLanguageToTtsLocale(AssistantLanguage language) {
    switch (language) {
      case AssistantLanguage.hindi:
        return 'hi-IN';
      case AssistantLanguage.marathi:
        return 'mr-IN';
      case AssistantLanguage.english:
        return 'en-IN';
    }
  }

  /// Toggles speech for an assistant message:
  /// - If this message is currently speaking -> stops speech.
  /// - If another message is speaking -> stops that message and starts this one.
  /// - If idle -> starts speaking this message.
  Future<bool> toggleSpeakMessage(
    AssistantMessage message, {
    String? languageCode,
  }) async {
    if (isSpeaking && _currentSpeakingMessageId == message.id) {
      await stop();
      return false;
    }
    return await speakMessage(message, languageCode: languageCode);
  }

  /// Reads an assistant message aloud using exact visible text and message language ownership.
  Future<bool> speakMessage(
    AssistantMessage message, {
    String? languageCode,
  }) async {
    // Only speak assistant messages
    if (message.isUser || message.isError) {
      return false;
    }

    final text = message.text.trim();
    if (text.isEmpty) return false;

    // Resolve language from message metadata first (Message Language Ownership)
    String targetLangCode = '';
    if (message.metadata?['language'] is String &&
        (message.metadata!['language'] as String).trim().isNotEmpty) {
      targetLangCode = message.metadata!['language'] as String;
    } else if (message.metadata?['locale'] is String &&
        (message.metadata!['locale'] as String).trim().isNotEmpty) {
      targetLangCode = message.metadata!['locale'] as String;
    }

    // If metadata is not present, inspect text script/lexicon
    if (targetLangCode.isEmpty) {
      final detected = AssistantLanguageResolver.detectQueryLanguage(text);
      if (detected != null) {
        targetLangCode = detected.code;
      }
    }

    // If still unresolved, fallback to provided languageCode or general resolver
    if (targetLangCode.isEmpty && languageCode != null && languageCode.trim().isNotEmpty) {
      targetLangCode = languageCode;
    }

    if (targetLangCode.isEmpty) {
      targetLangCode = AssistantLanguageResolver.resolve(query: text).code;
    }

    return await speakText(
      text,
      languageCode: targetLangCode,
      messageId: message.id,
    );
  }

  /// Speaks arbitrary text in the specified language tag while managing session concurrency.
  Future<bool> speakText(
    String text, {
    required String languageCode,
    String? messageId,
  }) async {
    if (!CivicAssistantConfig.current.ttsReadinessEnabled) {
      return false;
    }

    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;

    try {
      // 1. Enforce single active speech session: stop any in-flight playback
      if (_state == CivicAssistantTtsState.speaking) {
        await stop();
      }

      final currentToken = ++_sessionToken;
      _currentSpeakingMessageId = messageId;
      _currentSpeakingText = cleanText;
      _state = CivicAssistantTtsState.speaking;
      _lastError = null;
      notifyListeners();

      // 2. Configure voice settings
      await _engine.setSpeechRate(0.45);
      await _engine.setVolume(1.0);
      await _engine.setPitch(1.0);

      // 3. Set locale with safe regional fallbacks
      final primaryLocale = mapLanguageToTtsLocale(languageCode);
      var effectiveLocale = primaryLocale;

      try {
        final isAvailable = await _engine.isLanguageAvailable(primaryLocale);
        if (isAvailable != true && isAvailable != 1) {
          // If Marathi voice is missing on device, fallback to Hindi (Devanagari phonemes)
          if (primaryLocale == 'mr-IN') {
            effectiveLocale = 'hi-IN';
          } else if (primaryLocale == 'en-IN') {
            effectiveLocale = 'en-US';
          }
        }
      } catch (_) {
        // Platform query not supported; proceed with primary locale
      }

      // Check if session was cancelled or replaced during async configuration
      if (currentToken != _sessionToken) {
        return false;
      }

      await _engine.setLanguage(effectiveLocale);

      // Check again before invoking native speak
      if (currentToken != _sessionToken) {
        return false;
      }

      // 4. Speak visible text
      final result = await _engine.speak(cleanText);
      final success = result == 1 || result == true;
      if (!success && currentToken == _sessionToken) {
        _state = CivicAssistantTtsState.idle;
        _currentSpeakingMessageId = null;
        _currentSpeakingText = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('[CivicAssistantTTS] speakText failed: $e');
      _state = CivicAssistantTtsState.error;
      _lastError = e.toString();
      _currentSpeakingMessageId = null;
      _currentSpeakingText = null;
      notifyListeners();
      return false;
    }
  }

  /// Stops any currently active speech.
  Future<void> stop() async {
    _sessionToken++;
    try {
      await _engine.stop();
    } catch (e) {
      debugPrint('[CivicAssistantTTS] stop failed: $e');
    } finally {
      _state = CivicAssistantTtsState.stopped;
      _currentSpeakingMessageId = null;
      _currentSpeakingText = null;
      notifyListeners();
    }
  }

  /// Pauses current speech playback if supported.
  Future<void> pause() async {
    try {
      await _engine.pause();
      _state = CivicAssistantTtsState.paused;
      notifyListeners();
    } catch (e) {
      debugPrint('[CivicAssistantTTS] pause failed: $e');
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
