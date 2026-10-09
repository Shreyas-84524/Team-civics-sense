import '../models/assistant_app_context.dart';
import '../models/assistant_conversation_history.dart';
import '../models/assistant_language.dart';

/// Resolves the target response language for the CivicFix Assistant.
///
/// Implements the canonical resolution priority:
/// 1. Explicit request in the current message ("Explain in Hindi", "मराठीत सांगा").
/// 2. Script and lexical language detection from current user query (Devanagari analysis).
/// 3. Conversational session history continuity (retaining language across multi-turn exchanges).
/// 4. Active CivicFix application locale (`AssistantAppContext.selectedLanguage`).
/// 5. English default fallback.
class AssistantLanguageResolver {
  /// Regular expressions for explicit language switching commands.
  static final RegExp _explicitEnglishPattern = RegExp(
    r'\b(in\s+english|explain\s+in\s+english|speak\s+in\s+english|english\s+please|इंग्रजीत\s+सांगा|अंग्रेजी\s+में\s+बताइए)\b',
    caseSensitive: false,
  );

  static final RegExp _explicitHindiPattern = RegExp(
    r'\b(in\s+hindi|explain\s+in\s+hindi|speak\s+in\s+hindi|hindi\s+mein\s+batao|हिंदी\s+में\s+समझा|हिंदी\s+में\s+बता|हिंदी\s+में|हिंदीत\s+सांगा)\b',
    caseSensitive: false,
  );

  static final RegExp _explicitMarathiPattern = RegExp(
    r'\b(in\s+marathi|explain\s+in\s+marathi|speak\s+in\s+marathi|marathi\s+madhe\s+sanga|मराठीत\s+सांगा|मराठी\s+मध्ये\s+समझा|मराठी\s+में\s+बता|मराठीत)\b',
    caseSensitive: false,
  );

  /// Devanagari Unicode character range: \u0900 to \u097F
  static final RegExp _devanagariRegex = RegExp(r'[\u0900-\u097F]');

  /// Characteristic Marathi functional words and grammar markers.
  static final Set<String> _marathiKeywords = {
    'नमस्कार',
    'आहे',
    'आहेत',
    'नाही',
    'काय',
    'कसे',
    'कशी',
    'कसा',
    'झाले',
    'झाली',
    'झाला',
    'माझी',
    'माझे',
    'माझ्या',
    'तक्रार',
    'तक्रारी',
    'तक्रारीचे',
    'तक्रारीची',
    'पडताळणी',
    'पडताळणीमध्ये',
    'पडताळणीत',
    'नकाशा',
    'सांगा',
    'पुन्हा',
    'होईल',
    'करा',
    'अडथळा',
    'म्हणजे',
    'कोण',
    'कुठे',
    'कधी',
    'वेळ',
    'मुदत',
    'दुरुस्ती',
    'काम',
    'बघा',
    'पाहू',
    'मिळेल',
    'करावे',
    'करावी',
    'येईल',
    'झालेला',
    'झालेली',
    'असेल',
    'असावे',
    'तुम्ही',
    'आम्ही',
    'कशा',
    'कशासाठी',
  };

  /// Characteristic Hindi functional words and grammar markers.
  static final Set<String> _hindiKeywords = {
    'नमस्ते',
    'प्रणाम',
    'है',
    'हैं',
    'नहीं',
    'क्या',
    'कैसे',
    'कैसी',
    'कैसा',
    'हुआ',
    'हुई',
    'मेरी',
    'मेरा',
    'मेरे',
    'शिकायत',
    'शिकायतें',
    'सत्यापन',
    'सत्यापनाधीन',
    'मैप',
    'बताइए',
    'बताओ',
    'दोबारा',
    'होगा',
    'होगी',
    'देखिए',
    'बाधा',
    'अर्थ',
    'मतलब',
    'कौन',
    'कहाँ',
    'कहा',
    'कब',
    'समय',
    'करूं',
    'करें',
    'कीजिए',
    'सकते',
    'सकता',
    'सकती',
    'होती',
    'होता',
    'आप',
    'हम',
    'किस',
    'किसलिए',
  };

  /// Transliterated Romanized markers for Hinglish and Marathlish.
  static final Set<String> _marathlishMarkers = {
    'aahe',
    'nahit',
    'kay',
    'kasa',
    'kashi',
    'kase',
    'zala',
    'zali',
    'zale',
    'mazi',
    'maze',
    'mazya',
    'pudhe',
    'sanga',
    'hoil',
    'kuthe',
    'kadhi',
    'madhe',
    'kela',
    'keli',
    'karaychi',
    'karaycha',
    'karave',
  };

  static final Set<String> _hinglishMarkers = {
    'hai',
    'hain',
    'nahi',
    'kya',
    'kaise',
    'kaisa',
    'kaisey',
    'hua',
    'hui',
    'mera',
    'meri',
    'mere',
    'aage',
    'batao',
    'bataiye',
    'hoga',
    'hogi',
    'kaha',
    'kahan',
    'mein',
    'kiya',
    'kare',
    'hone',
    'kitna',
    'kitne',
    'kitni',
    'lagega',
    'lagegi',
    'karu',
  };

  /// Resolves the optimal [AssistantLanguage] for the given query and environment.
  static AssistantLanguage resolve({
    required String query,
    AssistantAppContext? appContext,
    AssistantConversationHistory? history,
    String? requestedLanguage,
  }) {
    final clean = query.trim();
    if (clean.isEmpty) {
      return _resolveFromContextOrApp(appContext, history, requestedLanguage);
    }

    // 1. Explicit language request in current message
    final explicitLang = _checkExplicitLanguageRequest(clean);
    if (explicitLang != null) {
      return explicitLang;
    }

    // 2. Query Script & Lexical Analysis
    final detectedQueryLang = detectQueryLanguage(clean);
    if (detectedQueryLang != null) {
      return detectedQueryLang;
    }

    // 3. Conversation History Continuity (Multi-turn consistency)
    if (history != null && history.isNotEmpty) {
      final lastQuery = history.lastUserQuery;
      if (lastQuery != null && lastQuery.trim().isNotEmpty) {
        final historyLang = detectQueryLanguage(lastQuery);
        if (historyLang != null) {
          return historyLang;
        }
      }
    }

    // 4. If caller explicitly passed a non-English requestedLanguage, use it
    if (requestedLanguage != null && requestedLanguage.trim().isNotEmpty && requestedLanguage != 'en') {
      return AssistantLanguage.fromCode(requestedLanguage);
    }

    // 5. Pure English ASCII text
    if (RegExp(r'^[a-zA-Z0-9\s.,?!-/\\]+$').hasMatch(clean)) {
      return AssistantLanguage.english;
    }

    // 6. Requested / App Language / Context Language fallback
    return _resolveFromContextOrApp(appContext, history, requestedLanguage);
  }

  /// Detects language from query text via Devanagari vocabulary analysis and Romanized markers.
  static AssistantLanguage? detectQueryLanguage(String text) {
    final lower = text.toLowerCase();

    // Check for explicit language switch requests inside text
    final explicit = _checkExplicitLanguageRequest(lower);
    if (explicit != null) return explicit;

    // A. Devanagari Script Analysis
    if (_devanagariRegex.hasMatch(text)) {
      final words = text
          .replaceAll(RegExp(r'[^\u0900-\u097F\s]'), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();

      int marathiScore = 0;
      int hindiScore = 0;

      for (final word in words) {
        if (_marathiKeywords.contains(word)) marathiScore += 2;
        if (_hindiKeywords.contains(word)) hindiScore += 2;
      }

      // Check common Marathi verb/grammatical endings (e.g. 'मध्ये', 'ने', 'ला', 'चे', 'च्या', 'होईल')
      for (final word in words) {
        if (word.endsWith('मध्ये') ||
            word.endsWith('तील') ||
            word.endsWith('हून') ||
            word.endsWith('तात') ||
            word.endsWith('तात')) {
          marathiScore++;
        }
        if (word.endsWith('एगा') ||
            word.endsWith('एगी') ||
            word.endsWith('एंगे') ||
            word.endsWith('वाले') ||
            word.endsWith('वाली')) {
          hindiScore++;
        }
      }

      if (marathiScore > hindiScore) {
        return AssistantLanguage.marathi;
      } else if (hindiScore > marathiScore) {
        return AssistantLanguage.hindi;
      }

      // Default Devanagari tie-breaker: if query contains distinctive letters like ळ (U+0933) -> Marathi
      if (text.contains('ळ')) {
        return AssistantLanguage.marathi;
      }

      // Fallback for general Devanagari without distinctive keywords: Marathi if in Maharashtra context or Hindi
      return AssistantLanguage.hindi;
    }

    // B. Romanized (Hinglish vs Marathlish) Analysis
    final tokens = lower.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    int marathlishScore = 0;
    int hinglishScore = 0;

    for (final token in tokens) {
      if (_marathlishMarkers.contains(token)) marathlishScore++;
      if (_hinglishMarkers.contains(token)) hinglishScore++;
    }

    if (marathlishScore > 0 && marathlishScore >= hinglishScore) {
      return AssistantLanguage.marathi;
    }
    if (hinglishScore > 0 && hinglishScore > marathlishScore) {
      return AssistantLanguage.hindi;
    }

    return null;
  }

  static AssistantLanguage? _checkExplicitLanguageRequest(String text) {
    if (_explicitEnglishPattern.hasMatch(text)) {
      return AssistantLanguage.english;
    }
    if (_explicitHindiPattern.hasMatch(text)) {
      return AssistantLanguage.hindi;
    }
    if (_explicitMarathiPattern.hasMatch(text)) {
      return AssistantLanguage.marathi;
    }
    return null;
  }

  static AssistantLanguage _resolveFromContextOrApp(
    AssistantAppContext? appContext,
    AssistantConversationHistory? history, [
    String? requestedLanguage,
  ]) {
    if (requestedLanguage != null && requestedLanguage.trim().isNotEmpty) {
      return AssistantLanguage.fromCode(requestedLanguage);
    }
    if (appContext != null && appContext.selectedLanguage.isNotEmpty) {
      return AssistantLanguage.fromCode(appContext.selectedLanguage);
    }
    return AssistantLanguage.english;
  }
}
