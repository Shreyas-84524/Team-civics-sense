import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/ai/models/ai_analysis_status.dart';
import 'package:civic_app/core/localization/app_localizations.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/repositories/user_repository.dart';
import 'package:civic_app/User%20UI/screens/assistant_screen.dart';
import 'package:civic_app/User%20UI/services/assistant_service.dart';

class FakeUserRepository implements UserRepository {
  UserModel _user = const UserModel(
    id: 'usr_test_1',
    fullName: 'Aditya Patil',
    email: 'aditya@example.com',
    phone: '+919876543210',
    languageCode: 'en',
  );

  @override
  Future<UserModel> getCurrentUser() async => _user;

  @override
  Future<UserModel> updateUserProfile({
    String? fullName,
    String? email,
    String? phone,
    String? wardNumber,
    String? languageCode,
    String? avatarUrl,
  }) async {
    _user = _user.copyWith(
      fullName: fullName,
      email: email,
      phone: phone,
      wardNumber: wardNumber,
      languageCode: languageCode,
      avatarUrl: avatarUrl,
    );
    return _user;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 7 — Production Translation Service (RemoteTranslationService)', () {
    test('Translates faithfully across all 6 language directions', () async {
      int remoteCallCount = 0;
      final service = RemoteTranslationService(
        remoteCaller: (payload) async {
          remoteCallCount++;
          final text = payload['text'] as String;
          final target = payload['targetLanguage'] as String;
          final src = payload['sourceLanguage'] as String;

          if (text.contains('water leakage') && target == 'mr') {
            return {'translatedText': 'शाळेजवळ पाण्याची गळती आहे.', 'provider': 'gemini'};
          }
          if (text.contains('water leakage') && target == 'hi') {
            return {'translatedText': 'स्कूल के पास पानी का रिसाव है।', 'provider': 'gemini'};
          }
          if (text.contains('पाण्याची गळती') && target == 'en') {
            return {'translatedText': 'There is water leakage near the school.', 'provider': 'gemini'};
          }
          if (text.contains('पाण्याची गळती') && target == 'hi') {
            return {'translatedText': 'स्कूल के पास पानी का रिसाव है।', 'provider': 'gemini'};
          }
          if (text.contains('पानी का रिसाव') && target == 'en') {
            return {'translatedText': 'There is water leakage near the school.', 'provider': 'gemini'};
          }
          if (text.contains('पानी का रिसाव') && target == 'mr') {
            return {'translatedText': 'शाळेजवळ पाण्याची गळती आहे.', 'provider': 'gemini'};
          }

          return {'translatedText': '[$src->$target] $text', 'provider': 'gemini'};
        },
      );

      // 1. en -> mr
      final res1 = await service.translate(const TranslationRequest(
        originalText: 'There is water leakage near the school.',
        sourceLanguage: 'en',
        targetLanguage: 'mr',
      ));
      expect(res1.translatedText, 'शाळेजवळ पाण्याची गळती आहे.');
      expect(res1.targetLanguage, 'mr');

      // 2. en -> hi
      final res2 = await service.translate(const TranslationRequest(
        originalText: 'There is water leakage near the school.',
        sourceLanguage: 'en',
        targetLanguage: 'hi',
      ));
      expect(res2.translatedText, 'स्कूल के पास पानी का रिसाव है।');
      expect(res2.targetLanguage, 'hi');

      // 3. mr -> en
      final res3 = await service.translate(const TranslationRequest(
        originalText: 'शाळेजवळ पाण्याची गळती आहे.',
        sourceLanguage: 'mr',
        targetLanguage: 'en',
      ));
      expect(res3.translatedText, 'There is water leakage near the school.');

      // 4. mr -> hi
      final res4 = await service.translate(const TranslationRequest(
        originalText: 'शाळेजवळ पाण्याची गळती आहे.',
        sourceLanguage: 'mr',
        targetLanguage: 'hi',
      ));
      expect(res4.translatedText, 'स्कूल के पास पानी का रिसाव है।');

      // 5. hi -> en
      final res5 = await service.translate(const TranslationRequest(
        originalText: 'स्कूल के पास पानी का रिसाव है।',
        sourceLanguage: 'hi',
        targetLanguage: 'en',
      ));
      expect(res5.translatedText, 'There is water leakage near the school.');

      // 6. hi -> mr
      final res6 = await service.translate(const TranslationRequest(
        originalText: 'स्कूल के पास पानी का रिसाव है।',
        sourceLanguage: 'hi',
        targetLanguage: 'mr',
      ));
      expect(res6.translatedText, 'शाळेजवळ पाण्याची गळती आहे.');

      expect(remoteCallCount, 6);
    });

    test('Same-language identity bypass makes zero remote calls', () async {
      int remoteCalls = 0;
      final service = RemoteTranslationService(
        remoteCaller: (_) async {
          remoteCalls++;
          return {'translatedText': 'fail'};
        },
      );

      final res = await service.translate(const TranslationRequest(
        originalText: 'Pothole on Main Road',
        sourceLanguage: 'en',
        targetLanguage: 'en',
      ));

      expect(res.translatedText, 'Pothole on Main Road');
      expect(res.provider, 'identity');
      expect(remoteCalls, 0);
    });

    test('Rejects unsupported languages and empty text safely without crashing', () async {
      final service = const RemoteTranslationService();

      final res1 = await service.translate(const TranslationRequest(
        originalText: 'Civic issue',
        sourceLanguage: 'en',
        targetLanguage: 'fr', // Unsupported
      ));
      expect(res1.translatedText, 'Civic issue');
      expect(res1.provider, 'unsupported_language_fallback');

      final res2 = await service.translate(const TranslationRequest(
        originalText: '   ',
        sourceLanguage: 'en',
        targetLanguage: 'mr',
      ));
      expect(res2.translatedText, '   ');
      expect(res2.provider, 'identity');
    });

    test('Handles remote timeouts and network failures with fallback to original text', () async {
      final timeoutService = RemoteTranslationService(
        timeout: const Duration(milliseconds: 50),
        remoteCaller: (_) async {
          await Future.delayed(const Duration(milliseconds: 150));
          return {'translatedText': 'delayed'};
        },
      );

      final resTimeout = await timeoutService.translate(const TranslationRequest(
        originalText: 'Open garbage dump',
        sourceLanguage: 'en',
        targetLanguage: 'mr',
      ));
      expect(resTimeout.translatedText, 'Open garbage dump');
      expect(resTimeout.provider, 'timeout_fallback');

      final errorService = RemoteTranslationService(
        remoteCaller: (_) async => throw Exception('503 Service Unavailable'),
      );

      final resError = await errorService.translate(const TranslationRequest(
        originalText: 'Open garbage dump',
        sourceLanguage: 'en',
        targetLanguage: 'hi',
      ));
      expect(resError.translatedText, 'Open garbage dump');
      expect(resError.provider, 'error_fallback');
    });
  });

  group('Phase 7 — Two-Level Persistent Translation Cache', () {
    test('L1 hit returns cached result immediately without L2 or remote call', () async {
      final l1 = MemoryTranslationCache();
      final l2 = PersistentTranslationCache();
      final twoLevel = TwoLevelTranslationCache(l1Cache: l1, l2Cache: l2);

      await l1.put(TranslationResult(
        originalText: 'Water pipeline burst',
        originalLanguage: 'en',
        targetLanguage: 'mr',
        translatedText: 'जलवाहिनी फुटली',
        provider: 'gemini',
        translatedAt: DateTime(2026, 10, 8),
      ));

      final result = await twoLevel.get('Water pipeline burst', 'mr');
      expect(result, isNotNull);
      expect(result!.translatedText, 'जलवाहिनी फुटली');
      expect(result.isCached, isTrue);
    });

    test('L2 hit backfills L1 cache and returns persistent entry', () async {
      final l1 = MemoryTranslationCache();
      final l2 = PersistentTranslationCache();
      final twoLevel = TwoLevelTranslationCache(l1Cache: l1, l2Cache: l2);

      // Seed L2 persistent store
      await l2.put(TranslationResult(
        originalText: 'Dangerous tree branch',
        originalLanguage: 'en',
        targetLanguage: 'hi',
        translatedText: 'पेड़ की खतरनाक शाखा',
        provider: 'persistent_store',
        translatedAt: DateTime(2026, 10, 8),
      ));

      // Query through TwoLevelTranslationCache
      final result = await twoLevel.get('Dangerous tree branch', 'hi');
      expect(result, isNotNull);
      expect(result!.translatedText, 'पेड़ की खतरनाक शाखा');

      // Verify L1 was backfilled
      final l1Result = await l1.get('Dangerous tree branch', 'hi');
      expect(l1Result, isNotNull);
      expect(l1Result!.translatedText, 'पेड़ की खतरनाक शाखा');
    });

    test('Writing to TwoLevelTranslationCache populates both L1 and L2', () async {
      final l1 = MemoryTranslationCache();
      final l2 = PersistentTranslationCache();
      final twoLevel = TwoLevelTranslationCache(l1Cache: l1, l2Cache: l2);

      final entry = TranslationResult(
        originalText: 'Sewage overflow near market',
        originalLanguage: 'en',
        targetLanguage: 'mr',
        translatedText: 'बाजाराजवळ सांडपाणी साचले',
        provider: 'gemini',
        translatedAt: DateTime(2026, 10, 8),
      );

      await twoLevel.put(entry);

      expect((await l1.get('Sewage overflow near market', 'mr'))?.translatedText, 'बाजाराजवळ सांडपाणी साचले');
      expect((await l2.get('Sewage overflow near market', 'mr'))?.translatedText, 'बाजाराजवळ सांडपाणी साचले');
    });

    test('Source-hash invalidation bypasses cache when original text changes', () async {
      final l2 = PersistentTranslationCache();

      await l2.put(TranslationResult(
        originalText: 'Broken street light at corner',
        originalLanguage: 'en',
        targetLanguage: 'mr',
        translatedText: 'कोपऱ्यावरील पथदिवा बंद आहे',
        provider: 'gemini',
        translatedAt: DateTime(2026, 10, 8),
      ));

      // Exact text matches
      final hit = await l2.get('Broken street light at corner', 'mr');
      expect(hit, isNotNull);

      // Modified text has a different hash -> Cache miss
      final miss = await l2.get('Broken street light at corner - updated location', 'mr');
      expect(miss, isNull);
    });

    test('Separates target languages and translation versions strictly', () async {
      final l2 = PersistentTranslationCache(translationVersion: 1);

      await l2.put(TranslationResult(
        originalText: 'Pothole issue',
        originalLanguage: 'en',
        targetLanguage: 'mr',
        translatedText: 'खड्ड्याची समस्या',
        provider: 'gemini',
        translatedAt: DateTime(2026, 10, 8),
      ));

      expect(await l2.get('Pothole issue', 'mr'), isNotNull);
      expect(await l2.get('Pothole issue', 'hi'), isNull); // Different target language

      // Upgraded translation version
      final l2Version2 = PersistentTranslationCache(
        initialStorage: l2.snapshot,
        translationVersion: 2,
      );
      expect(await l2Version2.get('Pothole issue', 'mr'), isNull); // Different version -> miss
    });
  });

  group('Phase 7 — Request Deduplication & In-Flight Coalescing', () {
    test('Multiple concurrent requests trigger exactly 1 remote provider invocation', () async {
      int remoteCallCount = 0;
      final completer = Completer<Map<String, dynamic>>();

      final service = RemoteTranslationService(
        remoteCaller: (_) async {
          remoteCallCount++;
          return await completer.future;
        },
      );

      final repo = DefaultTranslationRepository(
        service: service,
        cache: MemoryTranslationCache(),
      );

      const request = TranslationRequest(
        originalText: 'Road crater near station',
        sourceLanguage: 'en',
        targetLanguage: 'mr',
        contentId: 'CIV-2026-99',
        fieldName: 'description',
      );

      // Launch 4 concurrent translation calls
      final future1 = repo.translate(request);
      final future2 = repo.translate(request);
      final future3 = repo.translate(request);
      final future4 = repo.translate(request);

      completer.complete({
        'translatedText': 'स्थानकाजवळ रस्त्यावर मोठा खड्डा',
        'provider': 'gemini',
      });

      final results = await Future.wait([future1, future2, future3, future4]);

      expect(remoteCallCount, 1);
      for (final r in results) {
        expect(r.translatedText, 'स्थानकाजवळ रस्त्यावर मोठा खड्डा');
      }
    });
  });

  group('Phase 7 — Chatbot Locale & AI Assistant Language Integration', () {
    test('CivicAssistantService generates strict language prompts for en, hi, mr', () {
      final mrPrompt = CivicAssistantService.generateLanguageSystemPrompt('mr');
      expect(mrPrompt.contains('Marathi (मराठी)'), isTrue);
      expect(mrPrompt.contains('तक्रार'), isTrue);

      final hiPrompt = CivicAssistantService.generateLanguageSystemPrompt('hi');
      expect(hiPrompt.contains('Hindi (हिन्दी)'), isTrue);
      expect(hiPrompt.contains('शिकायत'), isTrue);

      final enPrompt = CivicAssistantService.generateLanguageSystemPrompt('en');
      expect(enPrompt.contains('English'), isTrue);
      expect(enPrompt.contains('Complaint'), isTrue);
    });

    test('CivicAssistantService processQuery returns response in requested locale', () async {
      final service = CivicAssistantService();

      final enReply = await service.processQuery(query: 'How to report issue?', languageCode: 'en');
      expect(enReply.text.contains("Report an Issue"), isTrue);

      final hiReply = await service.processQuery(query: 'How to report issue?', languageCode: 'hi');
      expect(hiReply.text.contains("समस्या दर्ज करें"), isTrue);

      final mrReply = await service.processQuery(query: 'How to report issue?', languageCode: 'mr');
      expect(mrReply.text.contains("तक्रार नोंदवा"), isTrue);
    });

    test('Cross-language queries are answered in the active UI locale', () async {
      final service = CivicAssistantService();

      // User types English in Marathi UI
      final mrResponse = await service.processQuery(
        query: 'how to track complaint',
        languageCode: 'mr',
      );
      expect(mrResponse.text.contains('माझ्या तक्रारी'), isTrue);

      // User types English in Hindi UI
      final hiResponse = await service.processQuery(
        query: 'how to track complaint',
        languageCode: 'hi',
      );
      expect(hiResponse.text.contains('मेरी शिकायतें'), isTrue);
    });

    testWidgets('AssistantScreen dynamically respects active app locale and maintains history', (tester) async {
      final fakeUserRepo = FakeUserRepository();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('mr'),
          home: AssistantScreen(
            userRepository: fakeUserRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial greeting in Marathi
      expect(find.textContaining('मी तुमचा CivicFix सहाय्यक आहे'), findsOneWidget);
      expect(find.text('तक्रार कशी नोंदवायची?'), findsWidgets);

      // Enter a query
      final inputFinder = find.byType(TextField);
      await tester.enterText(inputFinder, 'track complaint');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Expect user message and assistant reply in Marathi
      expect(find.text('track complaint'), findsOneWidget);
      expect(find.textContaining('माझ्या तक्रारी'), findsOneWidget);
    });
  });

  group('Phase 7 — Authoritative Original Content Immutability Proof', () {
    test('Translation, caching, and repository calls never mutate ComplaintModel properties', () async {
      const originalTitle = 'Severe waterlogging at Dadar TT circle';
      const originalDesc = 'Knee-deep water accumulating after heavy rainfall.';
      const originalNotes = 'Assigned to stormwater crew for pump deployment.';

      final complaint = ComplaintModel(
        id: 'CIV-TEST-777',
        ticketNumber: 'CF-2026-000777',
        citizenId: 'cit_123',
        title: originalTitle,
        description: originalDesc,
        category: CivicCategory.defaultCategories.first,
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.high,
        officerNotes: originalNotes,
        location: const CivicLocation(latitude: 19.0178, longitude: 72.8478, address: 'Dadar TT'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrls: const [],
        timeline: const [],
        upvotes: 0,
        isHazard: false,
        syncStatus: SyncStatus.synced,
        aiAnalysisStatus: AiAnalysisStatus.completed,
        evidenceVerificationStatus: 'passed',
        departmentVerificationStatus: 'passed',
        verificationStage: 'verification_completed',
        aiVerificationAttempts: 1,
      );

      final repo = DefaultTranslationRepository.instance;

      // Translate title
      final titleResult = await repo.translate(TranslationRequest(
        originalText: complaint.title,
        sourceLanguage: 'en',
        targetLanguage: 'mr',
        contentId: complaint.id,
        fieldName: 'title',
      ));

      // Translate description
      final descResult = await repo.translate(TranslationRequest(
        originalText: complaint.description,
        sourceLanguage: 'en',
        targetLanguage: 'hi',
        contentId: complaint.id,
        fieldName: 'description',
      ));

      expect(titleResult.translatedText, isNotEmpty);
      expect(descResult.translatedText, isNotEmpty);

      // Verify the authoritative complaint record is verbatim unchanged
      expect(complaint.title, originalTitle);
      expect(complaint.description, originalDesc);
      expect(complaint.officerNotes, originalNotes);
    });
  });

  group('Phase 7 — Notification Language Templates & TTS Language Configuration', () {
    test('NotificationLanguageTemplates formats all canonical types in en, hi, mr', () {
      final types = [
        'complaintReported',
        'complaintUnderVerification',
        'complaintVerified',
        'complaintAssigned',
        'complaintStatusChanged',
        'complaintResolved',
        'complaintClosed',
        'reworkRequested',
        'slaWarning',
      ];

      for (final type in types) {
        final en = NotificationLanguageTemplates.format(
          notificationType: type,
          languageCode: 'en',
          ticketNumber: 'CF-2026-001',
          complaintTitle: 'Pothole on Linking Road',
        );
        expect(en.title, isNotEmpty);
        expect(en.body, isNotEmpty);

        final hi = NotificationLanguageTemplates.format(
          notificationType: type,
          languageCode: 'hi',
          ticketNumber: 'CF-2026-001',
          complaintTitle: 'सड़क पर गड्ढा',
        );
        expect(hi.title, isNotEmpty);
        expect(hi.body, isNotEmpty);

        final mr = NotificationLanguageTemplates.format(
          notificationType: type,
          languageCode: 'mr',
          ticketNumber: 'CF-2026-001',
          complaintTitle: 'रस्त्यावर खड्डा',
        );
        expect(mr.title, isNotEmpty);
        expect(mr.body, isNotEmpty);
      }
    });

    test('TtsLanguageConfig maps voices and adheres to visible text reading rule', () {
      expect(TtsLanguageConfig.resolveTtsLocale('en'), 'en-IN');
      expect(TtsLanguageConfig.resolveTtsLocale('hi'), 'hi-IN');
      expect(TtsLanguageConfig.resolveTtsLocale('mr'), 'mr-IN');

      // Rule: When viewing translated text -> reads translated text with target voice
      final speech1 = TtsLanguageConfig.resolveSpeechPayload(
        originalText: 'Water leak',
        sourceLanguage: 'en',
        targetLanguage: 'mr',
        translatedText: 'पाण्याची गळती',
        isViewingOriginal: false,
      );
      expect(speech1.textToSpeak, 'पाण्याची गळती');
      expect(speech1.speechLocale, 'mr-IN');

      // Rule: When toggled to View Original -> reads original text with source voice
      final speech2 = TtsLanguageConfig.resolveSpeechPayload(
        originalText: 'Water leak',
        sourceLanguage: 'en',
        targetLanguage: 'mr',
        translatedText: 'पाण्याची गळती',
        isViewingOriginal: true,
      );
      expect(speech2.textToSpeak, 'Water leak');
      expect(speech2.speechLocale, 'en-IN');
    });
  });
}
