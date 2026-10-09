import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/localization/app_localizations.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';

/// Test translation service simulating dynamic translations with call counters and error controls.
class MockDynamicTranslationService implements TranslationService {
  int callCount = 0;
  bool shouldFail = false;
  bool isOffline = false;
  Duration simulatedDelay = Duration.zero;

  final Map<String, Map<String, String>> _translations = {
    'There is water leakage near the school.': {
      'mr': 'शाळेजवळ पाण्याची गळती आहे.',
      'hi': 'स्कूल के पास पानी का लीकेज है।',
    },
    'Pothole on Main Road': {
      'mr': 'मुख्य रस्त्यावर खड्डा',
      'hi': 'मुख्य सड़क पर गड्ढा',
    },
    'कामासाठी रस्ता बंद करावा लागेल.': {
      'en': 'The road will need to be closed for the work.',
      'hi': 'काम के लिए सड़क बंद करनी होगी।',
    },
    'कचरा नियमित उचलला जात नाही.': {
      'en': 'Garbage is not being collected regularly.',
      'hi': 'कचरा नियमित रूप से नहीं उठाया जा रहा है।',
    },
    'स्कूल के पास बड़ा गड्ढा है।': {
      'en': 'There is a large pothole near the school.',
      'mr': 'शाळेजवळ मोठा खड्डा आहे.',
    },
  };

  @override
  String get providerName => 'mock_test_provider';

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    callCount++;
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }
    if (isOffline) {
      throw Exception('Network unreachable (offline)');
    }
    if (shouldFail) {
      throw Exception('Translation provider service failure');
    }

    final targetMap = _translations[request.originalText];
    final translated = targetMap?[request.targetLanguage] ??
        '${request.targetLanguage.toUpperCase()}: ${request.originalText}';

    return TranslationResult(
      originalText: request.originalText,
      originalLanguage: request.sourceLanguage ?? 'en',
      targetLanguage: request.targetLanguage,
      translatedText: translated,
      provider: providerName,
      translatedAt: DateTime.now(),
      confidence: 0.95,
      isCached: false,
    );
  }

  @override
  Future<List<TranslationResult>> translateBatch(List<TranslationRequest> requests) {
    return Future.wait(requests.map(translate));
  }

  @override
  Future<bool> isLanguageSupported(String languageCode) async {
    final code = languageCode.trim().toLowerCase();
    return code == 'en' || code == 'hi' || code == 'mr';
  }

  @override
  Future<String> detectLanguage(String text) async {
    return LanguageDetector.detect(text).code;
  }
}

void main() {
  late AppLocalizations l10nEn;
  late AppLocalizations l10nHi;
  late AppLocalizations l10nMr;

  setUpAll(() async {
    l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
    l10nHi = await AppLocalizations.delegate.load(const Locale('hi'));
    l10nMr = await AppLocalizations.delegate.load(const Locale('mr'));
  });

  Widget buildTestableWidget({
    required Widget child,
    Locale locale = const Locale('mr'),
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('Phase 6 — Language Detection & Resolution Engine', () {
    test('detects Latin script as English with high confidence', () {
      final res = LanguageDetector.detect('There is water leakage near the primary school.');
      expect(res.code, 'en');
      expect(res.isEnglish, isTrue);
      expect(res.confidence, greaterThanOrEqualTo(0.9));
      expect(res.isDevanagari, isFalse);
    });

    test('detects Marathi exclusive characters (ळ, ऱ) as Marathi', () {
      final res = LanguageDetector.detect('रस्त्यावरील खड्डे त्वरित बुझवावेत आणि डांबर घालावे.');
      expect(res.code, 'mr');
      expect(res.isMarathi, isTrue);
      expect(res.isDevanagari, isTrue);
    });

    test('detects Marathi keywords and morphology', () {
      final res = LanguageDetector.detect('शाळेजवळ पाण्याची गळती आहे आणि कचरा साचला आहे.');
      expect(res.code, 'mr');
      expect(res.isMarathi, isTrue);
    });

    test('detects Hindi keywords and morphology', () {
      final res = LanguageDetector.detect('स्कूल के पास सड़क पर बड़ा गड्ढा है और पानी भरा हुआ है।');
      expect(res.code, 'hi');
      expect(res.isHindi, isTrue);
    });

    test('honors explicit original language metadata when provided', () {
      final res = LanguageDetector.detect('Some ambiguous text', explicitLanguage: 'hi');
      expect(res.code, 'hi');
      expect(res.confidence, 1.0);
    });

    test('returns unknown for empty or non-alphabetical strings', () {
      expect(LanguageDetector.detect('').code, 'unknown');
      expect(LanguageDetector.detect('   ').code, 'unknown');
      expect(LanguageDetector.detect('1234567890').code, 'unknown');
      expect(LanguageDetector.detect('!@#\$%^&*()').code, 'unknown');
    });
  });

  group('Phase 6 — Translation Cache & In-Flight Request Deduplication', () {
    test('deterministic cache key includes contentId, field, hash, and language pair', () {
      final key1 = MemoryTranslationCache.buildCacheKey(
        text: 'Water leakage',
        targetLanguage: 'mr',
        sourceLanguage: 'en',
        contentId: 'CIV-101',
        fieldName: 'description',
      );
      final key2 = MemoryTranslationCache.buildCacheKey(
        text: 'Water leakage',
        targetLanguage: 'hi',
        sourceLanguage: 'en',
        contentId: 'CIV-101',
        fieldName: 'description',
      );
      final key3 = MemoryTranslationCache.buildCacheKey(
        text: 'Road damaged',
        targetLanguage: 'mr',
        sourceLanguage: 'en',
        contentId: 'CIV-101',
        fieldName: 'description',
      );

      expect(key1, isNot(equals(key2)), reason: 'Target language must separate cache keys');
      expect(key1, isNot(equals(key3)), reason: 'Text hash must separate cache keys');
    });

    test('coalesces duplicate in-flight translation requests to a single service call', () async {
      final mockService = MockDynamicTranslationService()
        ..simulatedDelay = const Duration(milliseconds: 50);
      final cache = MemoryTranslationCache();
      final repo = DefaultTranslationRepository(service: mockService, cache: cache);

      final req = const TranslationRequest(
        originalText: 'There is water leakage near the school.',
        targetLanguage: 'mr',
        sourceLanguage: 'en',
        contentId: 'CIV-101',
        fieldName: 'description',
      );

      // Launch 5 concurrent calls
      final futures = List.generate(5, (_) => repo.translate(req));
      final results = await Future.wait(futures);

      expect(results.length, 5);
      for (final res in results) {
        expect(res.translatedText, 'शाळेजवळ पाण्याची गळती आहे.');
      }
      expect(mockService.callCount, 1, reason: 'In-flight deduplication must coalesce to 1 call');

      // Subsequent call reuses cache
      final cachedResult = await repo.translate(req);
      expect(cachedResult.isCached, isTrue);
      expect(mockService.callCount, 1, reason: 'Cache hit must not invoke service');
    });

    test('invalidates cache properly when text changes', () async {
      final mockService = MockDynamicTranslationService();
      final cache = MemoryTranslationCache();
      final repo = DefaultTranslationRepository(service: mockService, cache: cache);

      const textA = 'There is water leakage near the school.';
      const textB = 'Pothole on Main Road';

      await repo.translate(const TranslationRequest(originalText: textA, targetLanguage: 'mr'));
      await repo.translate(const TranslationRequest(originalText: textB, targetLanguage: 'mr'));
      expect(await cache.size, 2);

      await cache.invalidate(textA);
      final queryA = await cache.get(textA, 'mr');
      final queryB = await cache.get(textB, 'mr');

      expect(queryA, isNull);
      expect(queryB, isNotNull);
    });
  });

  group('Phase 6 — CivicFixTranslatedText Widget UX States & Toggling', () {
    testWidgets('Same language: shows original text directly with NO translation footer', (tester) async {
      final mockService = MockDynamicTranslationService();
      final repo = DefaultTranslationRepository(service: mockService, cache: MemoryTranslationCache());

      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('mr'),
          child: CivicFixTranslatedText(
            originalText: 'शाळेजवळ पाण्याची गळती आहे.',
            originalLanguage: 'mr',
            targetLanguage: 'mr',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('शाळेजवळ पाण्याची गळती आहे.'), findsOneWidget);
      expect(find.text('View original'), findsNothing);
      expect(find.text('View translation'), findsNothing);
      expect(find.text('Translated from Marathi'), findsNothing);
      expect(mockService.callCount, 0, reason: 'Same language must not invoke translation');
    });

    testWidgets('Translation available: shows translated text by default with "View original" action', (tester) async {
      final mockService = MockDynamicTranslationService();
      final repo = DefaultTranslationRepository(service: mockService, cache: MemoryTranslationCache());

      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('mr'),
          child: CivicFixTranslatedText(
            originalText: 'There is water leakage near the school.',
            originalLanguage: 'en',
            targetLanguage: 'mr',
            contentId: 'CIV-201',
            fieldName: 'description',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Translated text is shown
      expect(find.text('शाळेजवळ पाण्याची गळती आहे.'), findsOneWidget);
      // Marathi ARB label: इंग्रजीतून भाषांतरित / मूळ पहा
      expect(find.text(l10nMr.translatedFromEnglish), findsOneWidget);
      expect(find.text(l10nMr.viewOriginal), findsOneWidget);

      // Tap "View original"
      await tester.tap(find.text(l10nMr.viewOriginal));
      await tester.pumpAndSettle();

      // Original English text is now displayed
      expect(find.text('There is water leakage near the school.'), findsOneWidget);
      expect(find.text(l10nMr.originalEnglish), findsOneWidget);
      expect(find.text(l10nMr.viewTranslation), findsOneWidget);

      // Tap "View translation" to switch back
      await tester.tap(find.text(l10nMr.viewTranslation));
      await tester.pumpAndSettle();

      expect(find.text('शाळेजवळ पाण्याची गळती आहे.'), findsOneWidget);
      expect(find.text(l10nMr.viewOriginal), findsOneWidget);
    });

    testWidgets('Translation loading: shows original text immediately during in-flight fetch', (tester) async {
      final mockService = MockDynamicTranslationService()
        ..simulatedDelay = const Duration(milliseconds: 200);
      final repo = DefaultTranslationRepository(service: mockService, cache: MemoryTranslationCache());

      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('mr'),
          child: CivicFixTranslatedText(
            originalText: 'There is water leakage near the school.',
            originalLanguage: 'en',
            targetLanguage: 'mr',
            repository: repo,
          ),
        ),
      );

      // Initial frame: original text is shown immediately without blanking
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('There is water leakage near the school.'), findsOneWidget);
      expect(find.text(l10nMr.translating), findsOneWidget);

      // Settle loading
      await tester.pumpAndSettle();
      expect(find.text('शाळेजवळ पाण्याची गळती आहे.'), findsOneWidget);
      expect(find.text(l10nMr.translating), findsNothing);
    });

    testWidgets('Translation unavailable / Failure: shows original text and Retry button', (tester) async {
      final mockService = MockDynamicTranslationService()..shouldFail = true;
      final repo = DefaultTranslationRepository(service: mockService, cache: MemoryTranslationCache());

      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('mr'),
          child: CivicFixTranslatedText(
            originalText: 'There is water leakage near the school.',
            originalLanguage: 'en',
            targetLanguage: 'mr',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Original text is NEVER hidden on failure
      expect(find.text('There is water leakage near the school.'), findsOneWidget);
      expect(find.text(l10nMr.translationUnavailable), findsOneWidget);
      expect(find.text(l10nMr.retryTranslation), findsOneWidget);

      // Fix failure and tap Retry
      mockService.shouldFail = false;
      await tester.tap(find.text(l10nMr.retryTranslation));
      await tester.pumpAndSettle();

      expect(find.text('शाळेजवळ पाण्याची गळती आहे.'), findsOneWidget);
      expect(find.text(l10nMr.viewOriginal), findsOneWidget);
    });

    testWidgets('Offline: uses cached translation when available, otherwise shows safe offline message', (tester) async {
      final mockService = MockDynamicTranslationService();
      final cache = MemoryTranslationCache();
      final repo = DefaultTranslationRepository(service: mockService, cache: cache);

      const original = 'There is water leakage near the school.';

      // Pre-populate cache for 'mr'
      await cache.put(
        TranslationResult(
          originalText: original,
          originalLanguage: 'en',
          targetLanguage: 'mr',
          translatedText: 'शाळेजवळ पाण्याची गळती आहे.',
          provider: 'pre_cache',
          translatedAt: DateTime.fromMillisecondsSinceEpoch(0),
          isCached: true,
        ),
      );

      // Set service to offline
      mockService.isOffline = true;

      // 1. Cached text in 'mr' -> renders translated text offline
      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('mr'),
          child: CivicFixTranslatedText(
            originalText: original,
            originalLanguage: 'en',
            targetLanguage: 'mr',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('शाळेजवळ पाण्याची गळती आहे.'), findsOneWidget);
      expect(find.text(l10nMr.viewOriginal), findsOneWidget);

      // 2. Uncached request for 'hi' while offline -> renders original text with safe message
      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('hi'),
          child: CivicFixTranslatedText(
            originalText: original,
            originalLanguage: 'en',
            targetLanguage: 'hi',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('There is water leakage near the school.'), findsOneWidget);
      expect(find.text(l10nHi.translationUnavailable), findsOneWidget);
    });
  });

  group('Phase 6 — Dynamic Locale Switching & Cache Reuse', () {
    testWidgets('Switches translation presentation smoothly when app locale changes', (tester) async {
      final mockService = MockDynamicTranslationService();
      final cache = MemoryTranslationCache();
      final repo = DefaultTranslationRepository(service: mockService, cache: cache);

      const original = 'There is water leakage near the school.';

      // 1. Render in Marathi
      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('mr'),
          child: CivicFixTranslatedText(
            originalText: original,
            originalLanguage: 'en',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('शाळेजवळ पाण्याची गळती आहे.'), findsOneWidget);
      expect(find.text(l10nMr.translatedFromEnglish), findsOneWidget);
      expect(mockService.callCount, 1);

      // 2. Switch app locale to Hindi
      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('hi'),
          child: CivicFixTranslatedText(
            originalText: original,
            originalLanguage: 'en',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('स्कूल के पास पानी का लीकेज है।'), findsOneWidget);
      expect(find.text(l10nHi.translatedFromEnglish), findsOneWidget);
      expect(mockService.callCount, 2);

      // 3. Switch app locale to English (same as source)
      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('en'),
          child: CivicFixTranslatedText(
            originalText: original,
            originalLanguage: 'en',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('There is water leakage near the school.'), findsOneWidget);
      expect(find.text(l10nEn.viewOriginal), findsNothing);
      expect(mockService.callCount, 2, reason: 'English -> English must not invoke service');

      // 4. Switch back to Marathi -> Cache reuse!
      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('mr'),
          child: CivicFixTranslatedText(
            originalText: original,
            originalLanguage: 'en',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('शाळेजवळ पाण्याची गळती आहे.'), findsOneWidget);
      expect(mockService.callCount, 2, reason: 'Marathi translation must be reused from cache');
    });
  });

  group('Phase 6 — Strict Database & Model Immutability Verification', () {
    test('translating user-generated fields has zero side-effects on ComplaintModel fields', () async {
      final mockService = MockDynamicTranslationService();
      final repo = DefaultTranslationRepository(service: mockService);

      final originalComplaint = ComplaintModel(
        id: 'CIV-777',
        ticketNumber: 'TKT-777',
        title: 'Pothole on Main Road',
        description: 'There is water leakage near the school.',
        category: CivicCategory.defaultCategories.first,
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.high,
        location: const CivicLocation(
          latitude: 19.0760,
          longitude: 72.8777,
          address: 'Andheri West, Mumbai',
          ward: 'K/W',
        ),
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 2),
        resolutionRemarks: 'कामासाठी रस्ता बंद करावा लागेल.',
        reopenReason: 'कामाचा दर्जा निकृष्ट आहे.',
      );

      // Request translations for all human-authored fields
      final titleResult = await repo.translate(
        TranslationRequest(
          originalText: originalComplaint.title,
          targetLanguage: 'mr',
          contentId: originalComplaint.id,
          fieldName: 'title',
        ),
      );
      final descResult = await repo.translate(
        TranslationRequest(
          originalText: originalComplaint.description,
          targetLanguage: 'mr',
          contentId: originalComplaint.id,
          fieldName: 'description',
        ),
      );
      final remarkResult = await repo.translate(
        TranslationRequest(
          originalText: originalComplaint.resolutionRemarks!,
          targetLanguage: 'en',
          contentId: originalComplaint.id,
          fieldName: 'resolutionRemarks',
        ),
      );

      // Verify results are translated
      expect(titleResult.translatedText, 'मुख्य रस्त्यावर खड्डा');
      expect(descResult.translatedText, 'शाळेजवळ पाण्याची गळती आहे.');
      expect(remarkResult.translatedText, 'The road will need to be closed for the work.');

      // Strict Immutability Proof: ComplaintModel fields remain untouched and identical
      expect(originalComplaint.title, 'Pothole on Main Road');
      expect(originalComplaint.description, 'There is water leakage near the school.');
      expect(originalComplaint.resolutionRemarks, 'कामासाठी रस्ता बंद करावा लागेल.');
      expect(originalComplaint.reopenReason, 'कामाचा दर्जा निकृष्ट आहे.');
      expect(originalComplaint.status, ComplaintStatus.inProgress);
    });
  });

  group('Phase 6 — Long Devanagari Typography & Non-Overflow Audit', () {
    testWidgets('renders long multi-line Marathi and Hindi text without RenderFlex overflow', (tester) async {
      final mockService = MockDynamicTranslationService();
      final repo = DefaultTranslationRepository(service: mockService);

      const longMarathiText =
          'बृहन्मुंबई महानगरपालिका प्रभाग के/पश्चिम अंतर्गत स्वामी विवेकानंद मार्गावर शाळेजवळ मोठ्या प्रमाणात मलनिस्सारण वाहिनी फुटल्यामुळे संपूर्ण रस्त्यावर सांडपाणी साचले असून दुर्गंधी पसरली आहे आणि वाहतुकीस गंभीर अडथळा निर्माण झाला आहे. कृपया तातडीने दुरुस्ती पथक पाठवून कार्यवाही करावी.';

      final widths = [320.0, 360.0, 390.0, 768.0, 1024.0];

      for (final width in widths) {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('mr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: CivicFixTranslatedText(
                    originalText: longMarathiText,
                    originalLanguage: 'mr',
                    targetLanguage: 'mr',
                    repository: repo,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(longMarathiText), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Zero RenderFlex overflow at ${width}px');
      }
    });
  });
}
