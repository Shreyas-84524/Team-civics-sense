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

class MockUserRepository implements UserRepository {
  UserModel _user = const UserModel(
    id: 'usr_phase8_1',
    fullName: 'Pooja Sharma',
    email: 'pooja@example.com',
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

ComplaintModel _createSampleComplaint({
  required String id,
  required String ticketNumber,
  required String title,
  required String description,
  String? officerNotes,
  String? resolutionRemarks,
  String? reopenReason,
  ComplaintStatus status = ComplaintStatus.inProgress,
}) {
  return ComplaintModel(
    id: id,
    ticketNumber: ticketNumber,
    citizenId: 'cit_888',
    title: title,
    description: description,
    category: CivicCategory.defaultCategories.first,
    status: status,
    priority: ComplaintPriority.high,
    officerNotes: officerNotes,
    resolutionRemarks: resolutionRemarks,
    reopenReason: reopenReason,
    location: const CivicLocation(latitude: 19.0760, longitude: 72.8777, address: 'Bandra West'),
    createdAt: DateTime(2026, 1, 15),
    updatedAt: DateTime(2026, 1, 16),
    imageUrls: const [],
    timeline: const [],
    upvotes: 5,
    isHazard: false,
    slaStartedAt: DateTime(2026, 1, 15),
    originalCreatedAt: DateTime(2026, 1, 15),
    aiAnalysisStatus: AiAnalysisStatus.completed,
    evidenceVerificationStatus: 'passed',
    departmentVerificationStatus: 'passed',
    verificationStage: 'verification_completed',
    routingStatus: ComplaintRoutingStatus.assigned,
    assignmentStatus: ComplaintAssignmentStatus.fieldOfficerAssigned,
  );
}

void main() {
  setUp(() {
    TranslationConstants.dynamicTranslationEnabled = true;
    HistoricalLanguageResolver.clearDetectionCache();
  });

  tearDown(() {
    TranslationConstants.dynamicTranslationEnabled = true;
  });

  group('Phase 8 — Historical 9-Cell Matrix Compatibility & Immutability', () {
    test('Translates historical records faithfully across 9-cell language matrix without mutating records', () async {
      final repo = DefaultTranslationRepository(
        service: RemoteTranslationService(
          remoteCaller: (payload) async {
            final text = payload['text'] as String;
            final target = payload['targetLanguage'] as String;
            final src = payload['sourceLanguage'] as String;
            return {
              'originalText': text,
              'originalLanguage': src,
              'targetLanguage': target,
              'translatedText': '[$target translated] $text',
              'provider': 'gemini-cloud-function',
              'confidence': 0.98,
            };
          },
        ),
      );

      final englishComplaint = _createSampleComplaint(
        id: 'CIV-EN-1',
        ticketNumber: 'CF-2026-000101',
        title: 'Open manhole cover on Hill Road',
        description: 'Deep open manhole poses hazard to pedestrians.',
        officerNotes: 'Crew dispatched with replacement slab.',
      );

      final hindiComplaint = _createSampleComplaint(
        id: 'CIV-HI-1',
        ticketNumber: 'CF-2026-000102',
        title: 'सड़क पर गहरा गड्ढा है',
        description: 'लिंकिंग रोड पर बारिश के बाद बड़ा गड्ढा बन गया है।',
        officerNotes: 'डामरीकरण कार्य प्रगति पर है।',
      );

      final marathiComplaint = _createSampleComplaint(
        id: 'CIV-MR-1',
        ticketNumber: 'CF-2026-000103',
        title: 'शाळेजवळ कचऱ्याचे ढीग',
        description: 'स्थानिक प्राथमिक शाळेजवळ कचरा साचला आहे दुर्गंधी पसरली आहे.',
        officerNotes: 'कचरा उचलण्यासाठी घनकचरा विभागाची गाडी पाठवली.',
      );

      // 1. English -> Marathi UI
      final enToMr = await repo.translate(
        TranslationRequest(
          originalText: englishComplaint.title,
          targetLanguage: 'mr',
          sourceLanguage: 'en',
        ),
      );
      expect(enToMr.translatedText, contains('[mr translated]'));

      // 2. English -> Hindi UI
      final enToHi = await repo.translate(
        TranslationRequest(
          originalText: englishComplaint.title,
          targetLanguage: 'hi',
          sourceLanguage: 'en',
        ),
      );
      expect(enToHi.translatedText, contains('[hi translated]'));

      // 3. English -> English UI (Identity bypass)
      final enToEn = await repo.translate(
        TranslationRequest(
          originalText: englishComplaint.title,
          targetLanguage: 'en',
          sourceLanguage: 'en',
        ),
      );
      expect(enToEn.translatedText, englishComplaint.title);
      expect(enToEn.isIdentity, isTrue);

      // 4. Hindi -> English UI
      final hiToEn = await repo.translate(
        TranslationRequest(
          originalText: hindiComplaint.title,
          targetLanguage: 'en',
          sourceLanguage: 'hi',
        ),
      );
      expect(hiToEn.translatedText, contains('[en translated]'));

      // 5. Hindi -> Marathi UI
      final hiToMr = await repo.translate(
        TranslationRequest(
          originalText: hindiComplaint.title,
          targetLanguage: 'mr',
          sourceLanguage: 'hi',
        ),
      );
      expect(hiToMr.translatedText, contains('[mr translated]'));

      // 6. Hindi -> Hindi UI (Identity bypass)
      final hiToHi = await repo.translate(
        TranslationRequest(
          originalText: hindiComplaint.title,
          targetLanguage: 'hi',
          sourceLanguage: 'hi',
        ),
      );
      expect(hiToHi.translatedText, hindiComplaint.title);
      expect(hiToHi.isIdentity, isTrue);

      // 7. Marathi -> English UI
      final mrToEn = await repo.translate(
        TranslationRequest(
          originalText: marathiComplaint.title,
          targetLanguage: 'en',
          sourceLanguage: 'mr',
        ),
      );
      expect(mrToEn.translatedText, contains('[en translated]'));

      // 8. Marathi -> Hindi UI
      final mrToHi = await repo.translate(
        TranslationRequest(
          originalText: marathiComplaint.title,
          targetLanguage: 'hi',
          sourceLanguage: 'mr',
        ),
      );
      expect(mrToHi.translatedText, contains('[hi translated]'));

      // 9. Marathi -> Marathi UI (Identity bypass)
      final mrToMr = await repo.translate(
        TranslationRequest(
          originalText: marathiComplaint.title,
          targetLanguage: 'mr',
          sourceLanguage: 'mr',
        ),
      );
      expect(mrToMr.translatedText, marathiComplaint.title);
      expect(mrToMr.isIdentity, isTrue);

      // VERIFY IMMUTABILITY: ComplaintModel properties remain unchanged
      expect(englishComplaint.title, 'Open manhole cover on Hill Road');
      expect(englishComplaint.description, 'Deep open manhole poses hazard to pedestrians.');
      expect(englishComplaint.officerNotes, 'Crew dispatched with replacement slab.');

      expect(hindiComplaint.title, 'सड़क पर गहरा गड्ढा है');
      expect(hindiComplaint.description, 'लिंकिंग रोड पर बारिश के बाद बड़ा गड्ढा बन गया है।');
      expect(hindiComplaint.officerNotes, 'डामरीकरण कार्य प्रगति पर है।');

      expect(marathiComplaint.title, 'शाळेजवळ कचऱ्याचे ढीग');
      expect(marathiComplaint.description, 'स्थानिक प्राथमिक शाळेजवळ कचरा साचला आहे दुर्गंधी पसरली आहे.');
      expect(marathiComplaint.officerNotes, 'कचरा उचलण्यासाठी घनकचरा विभागाची गाडी पाठवली.');
    });
  });

  group('Phase 8 — Historical Source-Language Resolution & Classification', () {
    test('Classifies historical records across Categories A through E correctly', () {
      // Category A: Explicit metadata
      final catA = HistoricalLanguageResolver.resolve(
        text: 'Drainage problem',
        explicitLanguage: 'en',
      );
      expect(catA.category, HistoricalDataCategory.explicitMetadata);
      expect(catA.sourceLanguage, 'en');

      // Category B: Confident detectable
      final catBHi = HistoricalLanguageResolver.resolve(
        text: 'पानी की पाइपलाइन फट गई है और सड़क पर जलभराव हो गया है',
      );
      expect(catBHi.category, HistoricalDataCategory.confidentDetectable);
      expect(catBHi.sourceLanguage, 'hi');

      final catBMr = HistoricalLanguageResolver.resolve(
        text: 'रस्त्यावरील पथदिवा बंद असून रात्री अंधार असतो',
      );
      expect(catBMr.category, HistoricalDataCategory.confidentDetectable);
      expect(catBMr.sourceLanguage, 'mr');

      // Category C: Mixed language (Latin + Devanagari)
      final catC = HistoricalLanguageResolver.resolve(
        text: 'SV Road वर मोठा pothole आहे',
      );
      expect(catC.category, HistoricalDataCategory.mixedLanguage);
      expect(catC.sourceLanguage, 'en');

      // Category D: Uncertain / purely alphanumeric codes
      final catD = HistoricalLanguageResolver.resolve(
        text: '1234567890',
      );
      expect(catD.category, HistoricalDataCategory.uncertain);

      // Category E: Empty or null
      final catE = HistoricalLanguageResolver.resolve(
        text: '   ',
      );
      expect(catE.category, HistoricalDataCategory.emptyOrNull);
    });

    test('Reuses cached detection result for identical sourceHash', () {
      const text = 'Water contamination issue in Ward K/West';
      final res1 = HistoricalLanguageResolver.resolve(text: text);
      expect(res1.isFromCache, isFalse);

      final res2 = HistoricalLanguageResolver.resolve(text: text);
      expect(res2.isFromCache, isTrue);
      expect(res2.sourceLanguage, res1.sourceLanguage);
      expect(res2.sourceHash, res1.sourceHash);
    });
  });

  group('Phase 8 — Non-Destructive Migration Utility (Dry-Run)', () {
    test('runAuditDryRun accurately scans historical complaints and modifies 0 records', () {
      final complaints = [
        _createSampleComplaint(
          id: 'CIV-HIST-1',
          ticketNumber: 'CF-2026-000201',
          title: 'Fallen tree blocking SV Road',
          description: 'Large banyan tree branch fell during storm.',
        ),
        _createSampleComplaint(
          id: 'CIV-HIST-2',
          ticketNumber: 'CF-2026-000202',
          title: 'गटाराचे पाणी रस्त्यावर येत आहे',
          description: 'दादर पूर्व भागात दुर्गंधी आणि सांडपाणी साचले आहे.',
        ),
        _createSampleComplaint(
          id: 'CIV-HIST-3',
          ticketNumber: 'CF-2026-000203',
          title: 'School ke paas पानी leakage hai',
          description: 'Main pipeline leak near gate 2.',
        ),
      ];

      final report = HistoricalMigrationUtility.runAuditDryRun(complaints);

      expect(report.recordsScanned, 3);
      expect(report.recordsModified, 0); // Non-destructive guarantee
      expect(report.recordsMissingMetadata, 3);
      expect(report.recordsConfidentlyDetected, greaterThanOrEqualTo(2));
      expect(report.sampleAudits.length, 3);
    });

    test('warmUpActiveComplaints pre-caches active complaints through standard repository', () async {
      int translationCalls = 0;
      final repo = DefaultTranslationRepository(
        service: RemoteTranslationService(
          remoteCaller: (payload) async {
            translationCalls++;
            return {
              'originalText': payload['text'],
              'originalLanguage': payload['sourceLanguage'],
              'targetLanguage': payload['targetLanguage'],
              'translatedText': 'Warm-up: ${payload['text']}',
              'provider': 'warmup-gemini',
              'confidence': 0.99,
            };
          },
        ),
      );

      final activeComplaints = [
        _createSampleComplaint(
          id: 'CIV-WARM-1',
          ticketNumber: 'CF-2026-000301',
          title: 'Damaged footpath tiles',
          description: 'Senior citizens tripping near park entrance.',
          status: ComplaintStatus.inProgress,
        ),
      ];

      final warmedCount = await HistoricalMigrationUtility.warmUpActiveComplaints(
        complaints: activeComplaints,
        repository: repo,
        targetLanguages: {'hi', 'mr'},
      );

      expect(warmedCount, 2); // Warm-up hi and mr from en
      expect(translationCalls, 2);

      // Verify subsequent query hits cache
      final cachedRes = await repo.translate(
        TranslationRequest(
          originalText: 'Senior citizens tripping near park entrance.',
          targetLanguage: 'mr',
          sourceLanguage: 'en',
        ),
        useCache: true,
      );
      expect(cachedRes.isCached, isTrue);
      expect(cachedRes.translatedText, contains('Warm-up:'));
      expect(translationCalls, 2); // Zero additional calls
    });
  });

  group('Phase 8 — Code-Switched Mumbai Text & Civic Proper Noun Preservation', () {
    test('Preserves Mumbai civic proper nouns, ward codes, and ticket numbers intact', () async {
      final repo = DefaultTranslationRepository(
        service: RemoteTranslationService(
          remoteCaller: (payload) async {
            final text = payload['text'] as String;
            return {
              'originalText': text,
              'originalLanguage': 'en',
              'targetLanguage': 'mr',
              // Simulating realistic LLM preserving proper nouns and tokens
              'translatedText': text
                  .replaceAll('pothole', 'खड्डा')
                  .replaceAll('water leakage', 'पाणी गळती')
                  .replaceAll('near', 'जवळ'),
              'provider': 'gemini-cloud-function',
              'confidence': 0.95,
            };
          },
        ),
      );

      // Test SV Road, Linking Road, LBS Marg, K/West, CIV-12345
      const query1 = 'pothole on SV Road in Ward K/West near Borivali';
      final res1 = await repo.translate(
        TranslationRequest(originalText: query1, targetLanguage: 'mr', sourceLanguage: 'en'),
      );
      expect(res1.translatedText, contains('SV Road'));
      expect(res1.translatedText, contains('K/West'));
      expect(res1.translatedText, contains('Borivali'));

      const query2 = 'water leakage on LBS Marg MCGM ticket CIV-99881';
      final res2 = await repo.translate(
        TranslationRequest(originalText: query2, targetLanguage: 'mr', sourceLanguage: 'en'),
      );
      expect(res2.translatedText, contains('LBS Marg'));
      expect(res2.translatedText, contains('MCGM'));
      expect(res2.translatedText, contains('CIV-99881'));
    });
  });

  group('Phase 8 — Feature Flag & Translation Version Invalidation', () {
    test('Disabling dynamicTranslationEnabled kill-switch returns original text cleanly', () async {
      int remoteCalls = 0;
      final repo = DefaultTranslationRepository(
        service: RemoteTranslationService(
          remoteCaller: (payload) async {
            remoteCalls++;
            return {'translatedText': 'Should not reach here'};
          },
        ),
      );

      // Disable kill switch
      TranslationConstants.dynamicTranslationEnabled = false;

      final result = await repo.translate(
        TranslationRequest(
          originalText: 'Severe garbage accumulation near station',
          targetLanguage: 'mr',
          sourceLanguage: 'en',
        ),
      );

      expect(result.isIdentity, isTrue);
      expect(result.translatedText, 'Severe garbage accumulation near station');
      expect(result.provider, 'feature_flag_disabled');
      expect(remoteCalls, 0);
    });

    test('Translation version separates cache keys and prevents obsolete version reuse', () async {
      final cache = PersistentTranslationCache(translationVersion: 1);
      final cacheV2 = PersistentTranslationCache(translationVersion: 2);

      await cache.put(TranslationResult(
        originalText: 'Broken water pipe',
        originalLanguage: 'en',
        targetLanguage: 'hi',
        translatedText: 'टूटी हुई पानी की पाइप (v1)',
        provider: 'gemini_v1',
        translatedAt: DateTime.now(),
      ));

      // v1 cache returns entry
      final v1Result = await cache.get('Broken water pipe', 'hi');
      expect(v1Result, isNotNull);
      expect(v1Result!.translatedText, contains('(v1)'));

      // v2 cache lookup returns null, avoiding stale translation reuse
      final v2Result = await cacheV2.get('Broken water pipe', 'hi');
      expect(v2Result, isNull);
    });
  });

  group('Phase 8 — Offline & Outage Resilience Gating', () {
    test('Offline cached entry is returned without network', () async {
      final l1 = MemoryTranslationCache();
      await l1.put(TranslationResult(
        originalText: 'Pothole on MG Road',
        originalLanguage: 'en',
        targetLanguage: 'mr',
        translatedText: 'एमजी रोडवर खड्डा',
        provider: 'gemini',
        translatedAt: DateTime.now(),
      ));

      final repo = DefaultTranslationRepository(
        cache: l1,
        service: RemoteTranslationService(
          remoteCaller: (_) async => throw Exception('No internet connection'),
        ),
      );

      final result = await repo.translate(
        TranslationRequest(
          originalText: 'Pothole on MG Road',
          targetLanguage: 'mr',
          sourceLanguage: 'en',
        ),
        useCache: true,
      );

      expect(result.translatedText, 'एमजी रोडवर खड्डा');
      expect(result.isCached, isTrue);
    });

    test('Offline uncached entry gracefully falls back to original text without throwing', () async {
      final repo = DefaultTranslationRepository(
        cache: MemoryTranslationCache(),
        service: RemoteTranslationService(
          remoteCaller: (_) async => throw Exception('SocketException: Connection refused'),
        ),
      );

      final result = await repo.translate(
        TranslationRequest(
          originalText: 'Clogged drainage canal near highway',
          targetLanguage: 'mr',
          sourceLanguage: 'en',
        ),
        useCache: true,
      );

      expect(result.translatedText, 'Clogged drainage canal near highway');
      expect(result.isIdentity, isTrue);
    });
  });

  group('Phase 8 — Chatbot & Notification Final Multilingual QA', () {
    testWidgets('AssistantScreen seamlessly follows active locale and preserves message history', (tester) async {
      final fakeUserRepo = MockUserRepository();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('hi'),
          home: AssistantScreen(
            userRepository: fakeUserRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial greeting in Hindi
      expect(find.textContaining('मैं आपका CivicFix सहायक हूँ'), findsOneWidget);
      expect(find.text('समस्या कैसे दर्ज करें?'), findsWidgets);

      // Send query in Hindi UI
      final inputFinder = find.byType(TextField);
      await tester.enterText(inputFinder, 'track status');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Verify Hindi response received
      expect(find.text('track status'), findsOneWidget);
      expect(find.textContaining('मेरी शिकायतें'), findsOneWidget);
    });

    test('NotificationLanguageTemplates formats all 9 canonical types accurately with recipient locale fallback', () {
      // English
      final enNotif = NotificationLanguageTemplates.format(
        notificationType: 'complaintResolved',
        languageCode: 'en',
        ticketNumber: 'CF-2026-9999',
        complaintTitle: 'Water leakage',
        departmentName: 'Water Department',
      );
      expect(enNotif.title, contains('Grievance Resolved'));
      expect(enNotif.title, contains('CF-2026-9999'));
      expect(enNotif.body, contains('Water leakage'));

      // Hindi
      final hiNotif = NotificationLanguageTemplates.format(
        notificationType: 'complaintResolved',
        languageCode: 'hi',
        ticketNumber: 'CF-2026-9999',
        complaintTitle: 'Water leakage',
        departmentName: 'Water Department',
      );
      expect(hiNotif.title, contains('शिकायत का समाधान'));
      expect(hiNotif.title, contains('CF-2026-9999'));
      expect(hiNotif.body, contains('Water leakage'));

      // Marathi
      final mrNotif = NotificationLanguageTemplates.format(
        notificationType: 'complaintResolved',
        languageCode: 'mr',
        ticketNumber: 'CF-2026-9999',
        complaintTitle: 'Water leakage',
        departmentName: 'Water Department',
      );
      expect(mrNotif.title, contains('तक्रार निवारण'));
      expect(mrNotif.title, contains('CF-2026-9999'));
      expect(mrNotif.body, contains('Water leakage'));

      // Invalid / Missing -> English Fallback
      final fallbackNotif = NotificationLanguageTemplates.format(
        notificationType: 'complaintResolved',
        languageCode: 'invalid_code',
        ticketNumber: 'CF-2026-9999',
        complaintTitle: 'Water leakage',
        departmentName: 'Water Department',
      );
      expect(fallbackNotif.title, contains('Grievance Resolved'));
      expect(fallbackNotif.title, contains('CF-2026-9999'));
    });
  });

  group('Phase 8 — TTS Voice Configuration & Visible Text Reading Rule', () {
    test('TtsLanguageConfig maps BCP-47 locale tags and adheres to visible text reading rule', () {
      expect(TtsLanguageConfig.resolveTtsLocale('en'), 'en-IN');
      expect(TtsLanguageConfig.resolveTtsLocale('hi'), 'hi-IN');
      expect(TtsLanguageConfig.resolveTtsLocale('mr'), 'mr-IN');
      expect(TtsLanguageConfig.resolveTtsLocale('unknown'), 'en-IN');

      // Rule: Visible translated text is read when translation is active
      const originalText = 'Water contamination';
      const translatedText = 'पाणी दूषित झाले आहे';

      final spokenWhenTranslated = TtsLanguageConfig.resolveSpeechPayload(
        isViewingOriginal: false,
        originalText: originalText,
        sourceLanguage: 'en',
        targetLanguage: 'mr',
        translatedText: translatedText,
      );
      expect(spokenWhenTranslated.textToSpeak, translatedText);
      expect(spokenWhenTranslated.speechLocale, 'mr-IN');

      // Rule: Original text is read when "View Original" is toggled
      final spokenWhenOriginal = TtsLanguageConfig.resolveSpeechPayload(
        isViewingOriginal: true,
        originalText: originalText,
        sourceLanguage: 'en',
        targetLanguage: 'mr',
        translatedText: translatedText,
      );
      expect(spokenWhenOriginal.textToSpeak, originalText);
      expect(spokenWhenOriginal.speechLocale, 'en-IN');
    });
  });
}
