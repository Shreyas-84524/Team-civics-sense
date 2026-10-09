import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../translation/models/translation_request.dart';
import '../translation/repositories/translation_repository.dart';
import '../translation/utils/language_detector.dart';

/// Translation display status for [CivicFixTranslatedText].
enum TranslationStatus {
  /// Source and target languages are identical, or text is empty/unknown.
  sameLanguage,

  /// Translation is in flight; original text is displayed with a subtle indicator.
  loading,

  /// Translation is available and displayed.
  translated,

  /// User explicitly toggled to view the original text.
  viewingOriginal,

  /// Translation request failed or was unavailable; original text is displayed.
  failed,

  /// Translation unavailable due to offline state with no cache; original text is displayed.
  offline,
}

/// A standardized, reusable widget that renders user-generated content with dynamic
/// presentation translation and an interactive "View original" / "View translation" toggle.
///
/// HARD INVARIANTS:
/// 1. Original user text is 100% immutable and authoritative.
/// 2. Translation exists purely in transient cache and presentation layers.
/// 3. Database records (Firestore/Hive) are never modified.
class CivicFixTranslatedText extends StatefulWidget {
  /// The immutable raw user-entered or officer-authored text.
  final String originalText;

  /// Optional content ID (e.g. complaint ID 'CIV-1234') for deterministic caching.
  final String? contentId;

  /// Optional field name (e.g. 'title', 'description', 'reworkReason') for deterministic caching.
  final String? fieldName;

  /// Explicit source language code ('en', 'hi', 'mr') if known.
  /// If omitted, [LanguageDetector] automatically determines the source language.
  final String? originalLanguage;

  /// Target language code. If null, dynamically resolves from the ambient [AppLocalizations].
  final String? targetLanguage;

  /// Injected translation repository. Defaults to [DefaultTranslationRepository.instance].
  final TranslationRepository? repository;

  /// Text style for the main content body.
  final TextStyle? style;

  /// Text style for the translation metadata footer.
  final TextStyle? labelStyle;

  /// Maximum lines to display before ellipsis.
  final int? maxLines;

  /// Text overflow behavior.
  final TextOverflow? overflow;

  /// Alignment of the text.
  final TextAlign? textAlign;

  /// Whether to show the translation metadata footer ("Translated from English / View original").
  /// Defaults to `true`.
  final bool showToggleAction;

  /// Whether to render in dense/compact mode (for cards and lists). Defaults to `false`.
  final bool dense;

  /// Semantic content category to guide contextual translation.
  final String? contentCategory;

  /// Optional callback invoked when a translation is requested.
  final VoidCallback? onRequestTranslation;

  /// Whether to allow text selection (defaults to false for performance in lists).
  final bool selectable;

  const CivicFixTranslatedText({
    super.key,
    required this.originalText,
    this.contentId,
    this.fieldName,
    this.originalLanguage,
    this.targetLanguage,
    this.repository,
    this.style,
    this.labelStyle,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.showToggleAction = true,
    this.dense = false,
    this.contentCategory,
    this.onRequestTranslation,
    this.selectable = false,
  });

  @override
  State<CivicFixTranslatedText> createState() => CivicFixTranslatedTextState();
}

class CivicFixTranslatedTextState extends State<CivicFixTranslatedText> {
  late TranslationRepository _repository;
  TranslationStatus _status = TranslationStatus.sameLanguage;
  String? _translatedText;
  String? _resolvedSourceLanguage;
  bool _userToggledToOriginal = false;
  String? _lastRequestedKey;

  TranslationStatus get status => _status;
  String? get translatedText => _translatedText;
  String? get resolvedSourceLanguage => _resolvedSourceLanguage;
  bool get isViewingOriginal => _userToggledToOriginal;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DefaultTranslationRepository.instance;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveAndTranslate();
  }

  @override
  void didUpdateWidget(CivicFixTranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.repository != null && widget.repository != oldWidget.repository) {
      _repository = widget.repository!;
    }
    if (oldWidget.originalText != widget.originalText ||
        oldWidget.targetLanguage != widget.targetLanguage ||
        oldWidget.originalLanguage != widget.originalLanguage) {
      _userToggledToOriginal = false;
      _resolveAndTranslate();
    }
  }

  String _resolveTargetLanguage(BuildContext context) {
    if (widget.targetLanguage != null && widget.targetLanguage!.trim().isNotEmpty) {
      return widget.targetLanguage!.trim().toLowerCase();
    }
    final locale = Localizations.maybeLocaleOf(context);
    return locale?.languageCode.toLowerCase() ?? 'en';
  }

  Future<void> _resolveAndTranslate() async {
    final rawText = widget.originalText.trim();
    if (rawText.isEmpty) {
      if (mounted) {
        setState(() {
          _status = TranslationStatus.sameLanguage;
          _translatedText = widget.originalText;
        });
      }
      return;
    }

    final targetLang = _resolveTargetLanguage(context);

    // 1. Resolve source language
    final resolvedLang = LanguageDetector.detect(
      rawText,
      explicitLanguage: widget.originalLanguage,
    );
    _resolvedSourceLanguage = resolvedLang.code;

    // 2. If source matches target or source is unknown, show original text directly
    if (_resolvedSourceLanguage == targetLang || !resolvedLang.isKnown) {
      if (mounted) {
        setState(() {
          _status = TranslationStatus.sameLanguage;
          _translatedText = widget.originalText;
        });
      }
      return;
    }

    // 3. Build request
    final request = TranslationRequest(
      originalText: widget.originalText,
      targetLanguage: targetLang,
      sourceLanguage: _resolvedSourceLanguage,
      contentId: widget.contentId,
      fieldName: widget.fieldName,
      contentCategory: widget.contentCategory,
    );

    final requestKey = '${request.originalText}_${request.targetLanguage}_${request.sourceLanguage}';
    if (_lastRequestedKey == requestKey && _translatedText != null) {
      return;
    }
    _lastRequestedKey = requestKey;

    // 4. Check cache synchronously / fast path
    final cached = await _repository.cache.get(
      request.originalText,
      request.targetLanguage,
      contentId: request.contentId,
      fieldName: request.fieldName,
      sourceLanguage: request.sourceLanguage,
    );

    if (cached != null) {
      if (mounted) {
        setState(() {
          _translatedText = cached.translatedText;
          _status = _userToggledToOriginal
              ? TranslationStatus.viewingOriginal
              : TranslationStatus.translated;
        });
      }
      return;
    }

    // 5. In-flight loading
    if (mounted) {
      setState(() {
        _status = TranslationStatus.loading;
      });
    }

    widget.onRequestTranslation?.call();

    try {
      final result = await _repository.translate(request);
      if (!mounted) return;

      if (result.translatedText.trim().isNotEmpty &&
          result.translatedText != widget.originalText) {
        setState(() {
          _translatedText = result.translatedText;
          _status = _userToggledToOriginal
              ? TranslationStatus.viewingOriginal
              : TranslationStatus.translated;
        });
      } else {
        setState(() {
          _status = TranslationStatus.sameLanguage;
          _translatedText = widget.originalText;
        });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('[CivicFixTranslatedText] Translation error: $e');
      setState(() {
        _status = TranslationStatus.failed;
      });
    }
  }

  void toggleViewOriginal() {
    setState(() {
      _userToggledToOriginal = !_userToggledToOriginal;
      if (_status == TranslationStatus.translated) {
        _status = TranslationStatus.viewingOriginal;
      } else if (_status == TranslationStatus.viewingOriginal) {
        _status = TranslationStatus.translated;
      }
    });
  }

  void retryTranslation() {
    _lastRequestedKey = null;
    _resolveAndTranslate();
  }

  String _getSourceLanguageName(AppLocalizations? l10n, String code) {
    switch (code) {
      case 'hi':
        return l10n?.languageHindi ?? 'हिन्दी';
      case 'mr':
        return l10n?.languageMarathi ?? 'मराठी';
      case 'en':
      default:
        return l10n?.languageEnglish ?? 'English';
    }
  }

  String _getTranslatedFromLabel(AppLocalizations? l10n, String code) {
    switch (code) {
      case 'en':
        return l10n?.translatedFromEnglish ?? 'Translated from English';
      case 'hi':
        return l10n?.translatedFromHindi ?? 'Translated from Hindi';
      case 'mr':
        return l10n?.translatedFromMarathi ?? 'Translated from Marathi';
      default:
        final name = _getSourceLanguageName(l10n, code);
        return l10n?.translatedFromLanguage(name) ?? 'Translated from $name';
    }
  }

  String _getOriginalLabel(AppLocalizations? l10n, String code) {
    switch (code) {
      case 'en':
        return l10n?.originalEnglish ?? 'Original — English';
      case 'hi':
        return l10n?.originalHindi ?? 'Original — Hindi';
      case 'mr':
        return l10n?.originalMarathi ?? 'Original — Marathi';
      default:
        final name = _getSourceLanguageName(l10n, code);
        return l10n?.originalLanguage(name) ?? 'Original — $name';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isShowingTranslated = _status == TranslationStatus.translated &&
        !_userToggledToOriginal &&
        _translatedText != null &&
        _translatedText!.isNotEmpty;

    final displayText = isShowingTranslated ? _translatedText! : widget.originalText;

    final defaultStyle = CivicFixTypography.bodyMedium.copyWith(
      color: CivicFixColors.primaryText,
      height: 1.45,
    );
    final effectiveStyle = widget.style != null ? defaultStyle.merge(widget.style) : defaultStyle;

    final sourceCode = _resolvedSourceLanguage ?? 'en';
    final metadataLabel = _status == TranslationStatus.viewingOriginal
        ? _getOriginalLabel(l10n, sourceCode)
        : _getTranslatedFromLabel(l10n, sourceCode);

    final toggleButtonLabel = _status == TranslationStatus.viewingOriginal
        ? (l10n?.viewTranslation ?? 'View translation')
        : (l10n?.viewOriginal ?? 'View original');

    return Semantics(
      label: _buildAccessibilityLabel(displayText, l10n),
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Text Content
          widget.selectable
              ? SelectableText(
                  displayText,
                  style: effectiveStyle,
                  maxLines: widget.maxLines,
                  textAlign: widget.textAlign,
                )
              : Text(
                  displayText,
                  style: effectiveStyle,
                  maxLines: widget.maxLines,
                  overflow: widget.overflow,
                  textAlign: widget.textAlign,
                ),

          // 2. Translation Metadata Footer (Subtle & Non-Intrusive)
          if (widget.showToggleAction && _status != TranslationStatus.sameLanguage) ...[
            SizedBox(height: widget.dense ? 2 : 4),
            _buildMetadataFooter(
              context: context,
              l10n: l10n,
              metadataLabel: metadataLabel,
              toggleButtonLabel: toggleButtonLabel,
            ),
          ],
        ],
      ),
    );
  }

  String _buildAccessibilityLabel(String text, AppLocalizations? l10n) {
    if (_status == TranslationStatus.translated && !_userToggledToOriginal) {
      final src = _getTranslatedFromLabel(l10n, _resolvedSourceLanguage ?? 'en');
      return '$text. $src.';
    } else if (_status == TranslationStatus.viewingOriginal) {
      final orig = _getOriginalLabel(l10n, _resolvedSourceLanguage ?? 'en');
      return '$text. $orig.';
    }
    return text;
  }

  Widget _buildMetadataFooter({
    required BuildContext context,
    required AppLocalizations? l10n,
    required String metadataLabel,
    required String toggleButtonLabel,
  }) {
    final metaStyle = widget.labelStyle ??
        CivicFixTypography.caption.copyWith(
          color: CivicFixColors.secondaryText,
          fontSize: widget.dense ? 11 : 12,
        );

    final actionColor = CivicFixColors.primary;

    if (_status == TranslationStatus.loading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(CivicFixColors.secondaryText),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            l10n?.translating ?? 'Translating...',
            style: metaStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      );
    }

    if (_status == TranslationStatus.failed || _status == TranslationStatus.offline) {
      final isOffline = _status == TranslationStatus.offline;
      final errorText = isOffline
          ? (l10n?.translationUnavailableOffline ?? 'Translation unavailable offline')
          : (l10n?.translationUnavailable ?? 'Translation unavailable');

      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 2,
        children: [
          Text(
            errorText,
            style: metaStyle.copyWith(color: CivicFixColors.disabledText),
          ),
          InkWell(
            onTap: retryTranslation,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                l10n?.retryTranslation ?? 'Retry',
                style: metaStyle.copyWith(
                  color: actionColor,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 2,
      children: [
        Text(
          metadataLabel,
          style: metaStyle,
        ),
        InkWell(
          onTap: toggleViewOriginal,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              toggleButtonLabel,
              style: metaStyle.copyWith(
                color: actionColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
