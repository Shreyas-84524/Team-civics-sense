/// Supported languages for the CivicFix Citizen Assistant.
enum AssistantLanguage {
  english(
    code: 'en',
    displayName: 'English',
    nativeName: 'English',
  ),
  hindi(
    code: 'hi',
    displayName: 'Hindi',
    nativeName: 'हिन्दी',
  ),
  marathi(
    code: 'mr',
    displayName: 'Marathi',
    nativeName: 'मराठी',
  );

  final String code;
  final String displayName;
  final String nativeName;

  const AssistantLanguage({
    required this.code,
    required this.displayName,
    required this.nativeName,
  });

  /// Resolves an [AssistantLanguage] from a language/locale code string ('en', 'hi', 'mr').
  static AssistantLanguage fromCode(String? code) {
    if (code == null) return AssistantLanguage.english;
    final clean = code.trim().toLowerCase();
    if (clean.startsWith('hi')) return AssistantLanguage.hindi;
    if (clean.startsWith('mr')) return AssistantLanguage.marathi;
    return AssistantLanguage.english;
  }

  /// Whether this language uses the Devanagari script.
  bool get isDevanagari => this == AssistantLanguage.hindi || this == AssistantLanguage.marathi;

  /// Returns the standard BCP-47 locale tag.
  String get localeTag {
    switch (this) {
      case AssistantLanguage.hindi:
        return 'hi-IN';
      case AssistantLanguage.marathi:
        return 'mr-IN';
      case AssistantLanguage.english:
        return 'en-IN';
    }
  }
}
