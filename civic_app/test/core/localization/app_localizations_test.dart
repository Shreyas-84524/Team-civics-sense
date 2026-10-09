import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/localization/app_localizations.dart';
import 'package:civic_app/core/localization/locale_controller.dart';
import 'package:civic_app/core/local/local_storage_service.dart';

class MockStorageForL10nTest implements LocalStorageService {
  final Map<String, dynamic> data = {};

  @override
  bool get isInitialized => true;

  @override
  Future<void> init({String? subDir, bool isTest = false}) async {}

  @override
  Future<void> put<T>(String boxName, dynamic key, T value) async {
    data['$boxName:$key'] = value;
  }

  @override
  Future<T?> get<T>(String boxName, dynamic key, {T? defaultValue}) async {
    return (data['$boxName:$key'] as T?) ?? defaultValue;
  }

  @override
  Future<void> clear(String boxName) async => data.clear();

  @override
  Future<void> closeAll() async {}

  @override
  Future<void> closeBox(String boxName) async {}

  @override
  Future<bool> containsKey(String boxName, dynamic key) async => data.containsKey('$boxName:$key');

  @override
  Future<int> count(String boxName) async => data.length;

  @override
  Future<void> delete(String boxName, dynamic key) async => data.remove('$boxName:$key');

  @override
  Future<void> deleteAll(String boxName, Iterable keys) async {
    for (final k in keys) {
      data.remove('$boxName:$k');
    }
  }

  @override
  Future<void> deleteBoxFromDisk(String boxName) async => data.clear();

  @override
  Future<List<T>> getAll<T>(String boxName) async => data.values.whereType<T>().toList();

  @override
  Future<Map<dynamic, T>> getAllEntries<T>(String boxName) async => {};

  @override
  bool isBoxOpen(String boxName) => true;

  @override
  Future<void> openBox<T>(String boxName) async {}

  @override
  Future<void> putAll<T>(String boxName, Map<dynamic, T> entries) async {}

  @override
  Future<void> resetAllBoxes() async => data.clear();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLocalizations Configuration & Delegation', () {
    test('Supported locales include en, hi, mr', () {
      final supportedCodes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();
      expect(supportedCodes, containsAll(['en', 'hi', 'mr']));
    });

    test('Localizations delegates are non-empty and include primary delegate', () {
      expect(AppLocalizations.localizationsDelegates, isNotEmpty);
      expect(AppLocalizations.delegate, isNotNull);
    });

    test('Loads English translations and verifies baseline keys and municipal terms', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(en.appTitle, 'CivicFix');
      expect(en.complaint, 'Complaint');
      expect(en.juniorEngineer, 'Junior Engineer');
      expect(en.fieldOfficer, 'Field Officer');
      expect(en.ward, 'Ward');
      expect(en.department, 'Department');
      expect(en.statusReported, 'Reported');
      expect(en.statusAssigned, 'Assigned');
      expect(en.statusInProgress, 'In Progress');
      expect(en.statusResolved, 'Resolved');
      expect(en.statusClosed, 'Closed');
      expect(en.statusReopened, 'Reopened');
      expect(en.welcomeUser('Rahul'), 'Welcome, Rahul');
      expect(en.complaintCount(0), 'No complaints');
      expect(en.complaintCount(1), '1 complaint');
      expect(en.complaintCount(5), '5 complaints');
    });

    test('Loads Hindi translations and verifies standardized municipal terms', () async {
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      expect(hi.appTitle, 'CivicFix');
      expect(hi.complaint, 'शिकायत');
      expect(hi.juniorEngineer, 'कनिष्ठ अभियंता');
      expect(hi.fieldOfficer, 'क्षेत्र अधिकारी');
      expect(hi.ward, 'वार्ड');
      expect(hi.department, 'विभाग');
      expect(hi.statusReported, 'दर्ज की गई');
      expect(hi.statusAssigned, 'आवंटित');
      expect(hi.statusInProgress, 'प्रगति पर');
      expect(hi.statusResolved, 'समाधान हुआ');
      expect(hi.statusClosed, 'बंद');
      expect(hi.statusReopened, 'पुनः खोली गई');
      expect(hi.welcomeUser('राहुल'), 'स्वागत है, राहुल');
      expect(hi.complaintCount(0), 'कोई शिकायत नहीं');
      expect(hi.complaintCount(1), '1 शिकायत');
      expect(hi.complaintCount(3), '3 शिकायतें');
    });

    test('Loads Marathi translations and verifies standardized municipal terms', () async {
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));
      expect(mr.appTitle, 'CivicFix');
      expect(mr.complaint, 'तक्रार');
      expect(mr.juniorEngineer, 'कनिष्ठ अभियंता');
      expect(mr.fieldOfficer, 'क्षेत्र अधिकारी');
      expect(mr.ward, 'प्रभाग');
      expect(mr.department, 'विभाग');
      expect(mr.statusReported, 'नोंदवली');
      expect(mr.statusAssigned, 'नियुक्त');
      expect(mr.statusInProgress, 'प्रगतीपथावर');
      expect(mr.statusResolved, 'निवारण झाले');
      expect(mr.statusClosed, 'बंद');
      expect(mr.statusReopened, 'पुन्हा उघडली');
      expect(mr.welcomeUser('रोहन'), 'स्वागत आहे, रोहन');
      expect(mr.complaintCount(0), 'कोणतीही तक्रार नाही');
      expect(mr.complaintCount(1), '1 तक्रार');
      expect(mr.complaintCount(4), '४ तक्रारी');
    });
  });

  group('Widget Localization & Runtime Switching', () {
    testWidgets('Renders localized text and switches locale at runtime without app restart', (tester) async {
      final storage = MockStorageForL10nTest();
      final controller = LocaleController(storage: storage, initialLocale: const Locale('en'));

      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: controller,
          builder: (context, activeLocale, _) {
            return MaterialApp(
              locale: activeLocale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Builder(
                builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx)!;
                  return Scaffold(
                    body: Column(
                      children: [
                        Text('TITLE: ${l10n.appTitle}'),
                        Text('COMPLAINT: ${l10n.complaint}'),
                        Text('WARD: ${l10n.ward}'),
                        Text('WELCOME: ${l10n.welcomeUser("Siddharth")}'),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Initial state: English
      expect(find.text('TITLE: CivicFix'), findsOneWidget);
      expect(find.text('COMPLAINT: Complaint'), findsOneWidget);
      expect(find.text('WARD: Ward'), findsOneWidget);
      expect(find.text('WELCOME: Welcome, Siddharth'), findsOneWidget);

      // Switch to Hindi at runtime
      await controller.setLanguageCode('hi');
      await tester.pumpAndSettle();

      expect(find.text('TITLE: CivicFix'), findsOneWidget);
      expect(find.text('COMPLAINT: शिकायत'), findsOneWidget);
      expect(find.text('WARD: वार्ड'), findsOneWidget);
      expect(find.text('WELCOME: स्वागत है, Siddharth'), findsOneWidget);

      // Switch to Marathi at runtime
      await controller.setLanguageCode('mr');
      await tester.pumpAndSettle();

      expect(find.text('TITLE: CivicFix'), findsOneWidget);
      expect(find.text('COMPLAINT: तक्रार'), findsOneWidget);
      expect(find.text('WARD: प्रभाग'), findsOneWidget);
      expect(find.text('WELCOME: स्वागत आहे, Siddharth'), findsOneWidget);
    });
  });
}
