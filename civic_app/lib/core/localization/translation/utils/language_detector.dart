/// Utility for deterministic, lightweight script and language detection.
/// Supports English ('en'), Hindi ('hi'), Marathi ('mr'), and 'unknown'.
class ResolvedLanguage {
  final String code;
  final double confidence;
  final bool isDevanagari;

  const ResolvedLanguage({
    required this.code,
    required this.confidence,
    this.isDevanagari = false,
  });

  factory ResolvedLanguage.unknown() => const ResolvedLanguage(
        code: 'unknown',
        confidence: 0.0,
        isDevanagari: false,
      );

  bool get isKnown => code != 'unknown';
  bool get isEnglish => code == 'en';
  bool get isHindi => code == 'hi';
  bool get isMarathi => code == 'mr';

  @override
  String toString() => 'ResolvedLanguage(code: $code, confidence: $confidence)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedLanguage &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          confidence == other.confidence;

  @override
  int get hashCode => Object.hash(code, confidence);
}

/// Lightweight, deterministic language detection engine.
class LanguageDetector {
  static const Set<String> _marathiKeywords = {
    'आहे', 'आहेत', 'नाही', 'नाहीत', 'झाले', 'झाली', 'झाला', 'आणि', 'केले', 'केली',
    'करा', 'करावे', 'होते', 'होता', 'होती', 'मध्ये', 'रस्त्यावर', 'पाण्याची', 'गळती',
    'तक्रार', 'कचरा', 'काम', 'प्रभाग', 'पाहणी', 'दिले', 'केल्यास', 'पाहिजे', 'येथे',
    'अडचण', 'दुरूस्ती', 'दुरुस्ती', 'रस्ता', 'खड्डा', 'खड्डे', 'पाणी', 'दिवे', 'उद्यान',
    'कचऱ्याचे', 'झाडाची', 'फांदी', 'अतिक्रमण', 'नाले', 'गटार', 'सांडपाणी',
    'पथदिवा', 'असून', 'अंधार', 'असतो', 'साचले', 'पसरली',
  };

  static const Set<String> _hindiKeywords = {
    'है', 'हैं', 'नहीं', 'हुआ', 'हुई', 'हुए', 'और', 'किया', 'किए', 'करें', 'करना',
    'था', 'थी', 'थे', 'में', 'सड़क', 'पानी', 'लीकेज', 'गड्ढा', 'गड्ढे', 'शिकायत',
    'सफाई', 'नाला', 'नाली', 'बिजली', 'चाहिए', 'यहां', 'दिक्कत', 'मरम्मत', 'कूड़ा',
    'पेड़', 'गिरा', 'कचरा', 'स्ट्रीट', 'लाइट', 'बंद', 'विभाग',
  };

  /// Resolves the source language of [text].
  ///
  /// Priority:
  /// 1. If [explicitLanguage] is provided and valid ('en', 'hi', 'mr'), uses it.
  /// 2. If text is empty or purely symbolic, returns [ResolvedLanguage.unknown].
  /// 3. Analyzes character script distribution (Latin vs Devanagari).
  /// 4. For Devanagari, analyzes distinctive lexical tokens and Marathi-specific characters (e.g. ळ).
  static ResolvedLanguage detect(String text, {String? explicitLanguage}) {
    if (explicitLanguage != null && explicitLanguage.trim().isNotEmpty) {
      final normalized = explicitLanguage.trim().toLowerCase();
      if (normalized == 'en' || normalized == 'hi' || normalized == 'mr') {
        return ResolvedLanguage(
          code: normalized,
          confidence: 1.0,
          isDevanagari: normalized == 'hi' || normalized == 'mr',
        );
      }
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return ResolvedLanguage.unknown();
    }

    int latinCount = 0;
    int devanagariCount = 0;
    int marathiExclusiveCharCount = 0; // e.g. ळ (\u0933), ऱ (\u0931)

    for (final rune in trimmed.runes) {
      if ((rune >= 0x0041 && rune <= 0x005A) || (rune >= 0x0061 && rune <= 0x007A)) {
        latinCount++;
      } else if (rune >= 0x0900 && rune <= 0x097F) {
        devanagariCount++;
        if (rune == 0x0933 || rune == 0x0931) {
          marathiExclusiveCharCount++;
        }
      }
    }

    final totalLetters = latinCount + devanagariCount;
    if (totalLetters == 0) {
      return ResolvedLanguage.unknown();
    }

    // Latin Script Dominant (English)
    if (latinCount > devanagariCount) {
      final confidence = latinCount / totalLetters;
      return ResolvedLanguage(
        code: 'en',
        confidence: confidence.clamp(0.5, 1.0),
        isDevanagari: false,
      );
    }

    // Devanagari Script Dominant (Marathi or Hindi)
    if (devanagariCount > 0) {
      if (marathiExclusiveCharCount > 0) {
        return const ResolvedLanguage(
          code: 'mr',
          confidence: 0.95,
          isDevanagari: true,
        );
      }

      // Tokenize words
      final words = trimmed
          .split(RegExp(r'[\s,\.!?;:()\[\]"“”‘’\-—/\\]+'))
          .map((w) => w.trim())
          .where((w) => w.isNotEmpty)
          .toList();

      int marathiWordMatches = 0;
      int hindiWordMatches = 0;

      for (final word in words) {
        if (_marathiKeywords.contains(word)) {
          marathiWordMatches++;
        }
        if (_hindiKeywords.contains(word)) {
          hindiWordMatches++;
        }
      }

      if (marathiWordMatches > hindiWordMatches) {
        return ResolvedLanguage(
          code: 'mr',
          confidence: 0.9,
          isDevanagari: true,
        );
      } else if (hindiWordMatches > marathiWordMatches) {
        return ResolvedLanguage(
          code: 'hi',
          confidence: 0.9,
          isDevanagari: true,
        );
      }

      // Default Devanagari heuristic: Marathi in Maharashtra municipal domain
      return const ResolvedLanguage(
        code: 'mr',
        confidence: 0.7,
        isDevanagari: true,
      );
    }

    return ResolvedLanguage.unknown();
  }
}
