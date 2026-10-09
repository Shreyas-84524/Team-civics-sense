import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/localization/app_localizations.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/civic_department_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/government_role.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pillar 1: Static UI Localization & Required Test Strings', () {
    test('English ARB contains required Phase 1 test strings', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.appName, 'CivicFix');
      expect(l10n.languageEnglish, 'English');
      expect(l10n.languageHindi, 'Hindi');
      expect(l10n.languageMarathi, 'Marathi');
      expect(l10n.commonRetry, 'Retry');
      expect(l10n.commonCancel, 'Cancel');
    });

    test('Hindi ARB contains required Phase 1 test strings', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('hi'));
      expect(l10n.appName, 'CivicFix');
      expect(l10n.languageEnglish, 'अंग्रेज़ी');
      expect(l10n.languageHindi, 'हिन्दी');
      expect(l10n.languageMarathi, 'मराठी');
      expect(l10n.commonRetry, 'पुनः प्रयास करें');
      expect(l10n.commonCancel, 'रद्द करें');
    });

    test('Marathi ARB contains required Phase 1 test strings', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('mr'));
      expect(l10n.appName, 'CivicFix');
      expect(l10n.languageEnglish, 'इंग्रजी');
      expect(l10n.languageHindi, 'हिंदी');
      expect(l10n.languageMarathi, 'मराठी');
      expect(l10n.commonRetry, 'पुन्हा प्रयत्न करा');
      expect(l10n.commonCancel, 'रद्द करा');
    });
  });

  group('AppLocale Model & Fallback Behavior', () {
    test('AppLocale defines en, hi, mr with correct metadata', () {
      expect(AppLocale.values.length, 3);
      expect(AppLocale.english.languageCode, 'en');
      expect(AppLocale.hindi.languageCode, 'hi');
      expect(AppLocale.marathi.languageCode, 'mr');
      expect(AppLocale.english.nativeName, 'English');
      expect(AppLocale.hindi.nativeName, 'हिन्दी');
      expect(AppLocale.marathi.nativeName, 'मराठी');
    });

    test('AppLocale resolution handles standard, regional, and unsupported codes', () {
      expect(AppLocale.fromLanguageCode('en'), AppLocale.english);
      expect(AppLocale.fromLanguageCode('en_US'), AppLocale.english);
      expect(AppLocale.fromLanguageCode('en-GB'), AppLocale.english);
      expect(AppLocale.fromLanguageCode('hi'), AppLocale.hindi);
      expect(AppLocale.fromLanguageCode('hi_IN'), AppLocale.hindi);
      expect(AppLocale.fromLanguageCode('mr'), AppLocale.marathi);
      expect(AppLocale.fromLanguageCode('mr_IN'), AppLocale.marathi);

      // Safe fallback to English
      expect(AppLocale.fromLanguageCode('fr'), AppLocale.english);
      expect(AppLocale.fromLanguageCode('es'), AppLocale.english);
      expect(AppLocale.fromLanguageCode(''), AppLocale.english);
      expect(AppLocale.fromLanguageCode(null), AppLocale.english);
    });

    test('AppLocale isSupported correctly validates codes', () {
      expect(AppLocale.isSupported('en'), isTrue);
      expect(AppLocale.isSupported('hi'), isTrue);
      expect(AppLocale.isSupported('mr'), isTrue);
      expect(AppLocale.isSupported('de'), isFalse);
      expect(AppLocale.isSupported(null), isFalse);
    });
  });

  group('Pillar 2: Canonical Backend Values & Display Mappers', () {
    test('Preserves canonical backend status tokens without mutation', () {
      // Backend canonical enum names remain stable and unmutated
      expect(ComplaintStatus.underVerification.name, 'underVerification');
      expect(ComplaintStatus.inProgress.name, 'inProgress');
      expect(ComplaintStatus.resolved.name, 'resolved');
    });

    test('Preserves canonical backend role identifiers', () {
      expect(GovernmentRole.superAdminId, 'government_super_admin');
      expect(GovernmentRole.zonalDmcId, 'zonal_dmc');
      expect(GovernmentRole.centralDepartmentHodId, 'central_department_hod');
      expect(GovernmentRole.wardOfficerId, 'ward_officer');
      expect(GovernmentRole.wardDepartmentLeadId, 'ward_department_lead');
      expect(GovernmentRole.departmentCrewId, 'department_crew');
    });

    test('localizedComplaintStatus maps enums with and without l10n context', () async {
      // Without l10n context -> falls back to default label
      expect(localizedComplaintStatus(ComplaintStatus.inProgress), 'Work In Progress');
      expect(localizedComplaintStatus(ComplaintStatus.reported), 'Reported');

      // With English l10n
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(localizedComplaintStatus(ComplaintStatus.inProgress, l10n: en), 'In Progress');
      expect(localizedComplaintStatus(ComplaintStatus.reported, l10n: en), 'Reported');

      // With Hindi l10n
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      expect(localizedComplaintStatus(ComplaintStatus.inProgress, l10n: hi), 'प्रगति पर');
      expect(localizedComplaintStatus(ComplaintStatus.reported, l10n: hi), 'दर्ज की गई');

      // With Marathi l10n
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));
      expect(localizedComplaintStatus(ComplaintStatus.inProgress, l10n: mr), 'प्रगतीपथावर');
      expect(localizedComplaintStatus(ComplaintStatus.reported, l10n: mr), 'नोंदवली');
    });

    test('localizedGovernmentRole maps roles cleanly', () {
      expect(
        localizedGovernmentRole(GovernmentRole.departmentCrew),
        'Department Ground Crew',
      );
      expect(
        localizedGovernmentRole(GovernmentRole.wardDepartmentLead),
        'Ward Department Lead',
      );
    });

    test('localizedDepartment maps string IDs and CivicDepartment models safely', () {
      const dept = CivicDepartment(
        departmentId: 'water_supply',
        departmentCode: 'WAT',
        displayName: 'Hydraulic Engineer (Water Supply)',
        description: 'Potable water supply network',
        defaultLeadDesignation: 'Executive Engineer (Water)',
      );
      expect(localizedDepartment(dept), 'Hydraulic Engineer (Water Supply)');
      expect(localizedDepartment('Roads & Traffic'), 'Roads & Traffic');
      expect(localizedDepartment(null), 'General Municipal Desk');
    });

    test('localizedCategory maps category models and IDs safely', () {
      expect(localizedCategory(CivicCategory.defaultCategories.first), 'Roads');
      expect(localizedCategory('Pothole Hazard'), 'Pothole Hazard');
      expect(localizedCategory(null), 'General Issue');
    });

    test('localizedVerificationState maps AI/human review states safely', () {
      expect(localizedVerificationState('pending'), 'Verification Pending');
      expect(localizedVerificationState('processing'), 'Analyzing & Verifying...');
      expect(localizedVerificationState('passed'), 'Verification Passed');
      expect(localizedVerificationState('failed'), 'Verification Failed');
      expect(localizedVerificationState('humanDepartmentReview'), 'Department Officer Review');
      expect(localizedVerificationState(null), 'Verification Pending');
    });
  });

  group('Pillar 3: User Content Immutability & Translation Domain Models', () {
    test('TranslationRequest model holds parameters correctly', () {
      const request = TranslationRequest(
        originalText: 'Pothole on Linking Road near Bandra station',
        targetLanguage: 'hi',
        sourceLanguage: 'en',
        contentCategory: 'complaint_title',
      );

      expect(request.isValid, isTrue);
      expect(request.isSameLanguage, isFalse);
      expect(request.originalText, 'Pothole on Linking Road near Bandra station');
      expect(request.targetLanguage, 'hi');
      expect(request.contentCategory, 'complaint_title');

      final json = request.toJson();
      final fromJson = TranslationRequest.fromJson(json);
      expect(fromJson, request);
    });

    test('TranslationResult encapsulates original text, translation, provider, and timestamp', () {
      final now = DateTime.now();
      final result = TranslationResult(
        originalText: 'Water pipe leakage causing flooding',
        originalLanguage: 'en',
        targetLanguage: 'mr',
        translatedText: 'पाण्याच्या पाईपमधून गळती होऊन पाणी साचले आहे',
        provider: 'mock_provider',
        translatedAt: now,
        confidence: 0.98,
        isCached: false,
      );

      expect(result.originalText, 'Water pipe leakage causing flooding');
      expect(result.translatedText, 'पाण्याच्या पाईपमधून गळती होऊन पाणी साचले आहे');
      expect(result.provider, 'mock_provider');
      expect(result.targetLanguage, 'mr');

      final json = result.toJson();
      final fromJson = TranslationResult.fromJson(json);
      expect(fromJson.originalText, result.originalText);
      expect(fromJson.translatedText, result.translatedText);
      expect(fromJson.provider, result.provider);
    });

    test('TranslatableContent guarantees original user text remains authoritative and immutable', () {
      const originalDescription =
          'Severe road cave-in observed in front of BMC Ward Office Gate 2.';

      final content = TranslatableContent.fromOriginal(
        originalDescription,
        detectedLanguage: 'en',
      );

      // Verify initial fallback is the immutable original
      expect(content.rawOriginalText, originalDescription);
      expect(content.textFor('en'), originalDescription);
      expect(content.textFor('hi'), originalDescription);
      expect(content.hasTranslationFor('hi'), isFalse);

      // Add Hindi translation to presentation layer
      final withHindi = content.withTranslation(
        targetLanguageCode: 'hi',
        translatedText: 'बीएमसी वार्ड कार्यालय गेट 2 के सामने सड़क धंस गई है।',
      );

      // 1. Authoritative original text must remain completely unchanged
      expect(withHindi.rawOriginalText, originalDescription);
      expect(content.rawOriginalText, originalDescription);

      // 2. Hindi presentation text returns translated text
      expect(withHindi.textFor('hi'), 'बीएमसी वार्ड कार्यालय गेट 2 के सामने सड़क धंस गई है।');

      // 3. Marathi presentation text safely falls back to authoritative original text
      expect(withHindi.textFor('mr'), originalDescription);

      // 4. English presentation text returns original text
      expect(withHindi.textFor('en'), originalDescription);
    });

    test('NoOpTranslationService handles translation requests safely without external network calls', () async {
      const service = NoOpTranslationService();
      expect(service.providerName, 'no_op_phase1');
      expect(await service.isLanguageSupported('hi'), isTrue);
      expect(await service.isLanguageSupported('mr'), isTrue);
      expect(await service.isLanguageSupported('en'), isTrue);
      expect(await service.isLanguageSupported('fr'), isFalse);

      const request = TranslationRequest(
        originalText: 'Streetlight pole tilted and sparking',
        targetLanguage: 'mr',
      );

      final result = await service.translate(request);
      expect(result.originalText, 'Streetlight pole tilted and sparking');
      expect(result.translatedText, 'Streetlight pole tilted and sparking');
      expect(result.provider, 'no_op_phase1');
    });

    test('MemoryTranslationCache stores and invalidates translations separately from database', () async {
      final cache = MemoryTranslationCache();
      expect(await cache.size, 0);

      final result = TranslationResult(
        originalText: 'Garbage dump overflowing',
        originalLanguage: 'en',
        targetLanguage: 'hi',
        translatedText: 'कचरा डिपो भर गया है',
        provider: 'test',
        translatedAt: DateTime.now(),
      );

      await cache.put(result);
      expect(await cache.size, 1);

      final retrieved = await cache.get('Garbage dump overflowing', 'hi');
      expect(retrieved, isNotNull);
      expect(retrieved!.translatedText, 'कचरा डिपो भर गया है');
      expect(retrieved.isCached, isTrue);

      final missing = await cache.get('Garbage dump overflowing', 'mr');
      expect(missing, isNull);

      await cache.invalidate('Garbage dump overflowing');
      expect(await cache.size, 0);
    });

    test('DefaultTranslationRepository coordinates cache and service smoothly', () async {
      final cache = MemoryTranslationCache();
      const service = NoOpTranslationService();
      final repository = DefaultTranslationRepository(service: service, cache: cache);

      const request = TranslationRequest(
        originalText: 'Drainage choked near fish market',
        targetLanguage: 'mr',
      );

      final firstCall = await repository.translate(request);
      expect(firstCall.originalText, 'Drainage choked near fish market');
      expect(await cache.size, 1);

      final secondCall = await repository.translate(request);
      expect(secondCall.isCached, isTrue);

      // Test translateContent
      final content = TranslatableContent.fromOriginal('Broken water valve');
      final translatedContent = await repository.translateContent(content, 'hi');
      expect(translatedContent.rawOriginalText, 'Broken water valve');
      expect(translatedContent.hasTranslationFor('hi'), isTrue);
    });
  });
}
