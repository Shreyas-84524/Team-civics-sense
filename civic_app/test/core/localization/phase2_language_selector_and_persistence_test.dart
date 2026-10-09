import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/local/hive/hive_boxes.dart';
import 'package:civic_app/core/local/local_storage_service.dart';
import 'package:civic_app/core/local/models/settings_local_model.dart';
import 'package:civic_app/core/localization/app_localizations.dart';
import 'package:civic_app/core/localization/locale_controller.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/government_role.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/repositories/hive_user_repository.dart';

class MockStorageForPhase2Test implements LocalStorageService {
  final Map<String, dynamic> _data = {};
  bool _initialized = true;

  @override
  bool get isInitialized => _initialized;

  set isInitialized(bool val) => _initialized = val;

  @override
  Future<void> init({String? subDir, bool isTest = false}) async {
    _initialized = true;
  }

  @override
  Future<void> put<T>(String boxName, dynamic key, T value) async {
    _data['$boxName:$key'] = value;
  }

  @override
  Future<T?> get<T>(String boxName, dynamic key, {T? defaultValue}) async {
    return (_data['$boxName:$key'] as T?) ?? defaultValue;
  }

  @override
  Future<void> clear(String boxName) async => _data.clear();

  @override
  Future<void> closeAll() async {}

  @override
  Future<void> closeBox(String boxName) async {}

  @override
  Future<bool> containsKey(String boxName, dynamic key) async => _data.containsKey('$boxName:$key');

  @override
  Future<int> count(String boxName) async => _data.length;

  @override
  Future<void> delete(String boxName, dynamic key) async => _data.remove('$boxName:$key');

  @override
  Future<void> deleteAll(String boxName, Iterable keys) async {
    for (final k in keys) {
      _data.remove('$boxName:$k');
    }
  }

  @override
  Future<void> deleteBoxFromDisk(String boxName) async => _data.clear();

  @override
  Future<List<T>> getAll<T>(String boxName) async => _data.values.whereType<T>().toList();

  @override
  Future<Map<dynamic, T>> getAllEntries<T>(String boxName) async => {};

  @override
  bool isBoxOpen(String boxName) => true;

  @override
  Future<void> openBox<T>(String boxName) async {}

  @override
  Future<void> putAll<T>(String boxName, Map<dynamic, T> entries) async {}

  @override
  Future<void> resetAllBoxes() async => _data.clear();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2: Bidirectional Runtime Locale Switching', () {
    late MockStorageForPhase2Test storage;
    late LocaleController controller;

    setUp(() {
      storage = MockStorageForPhase2Test();
      controller = LocaleController(storage: storage, initialLocale: const Locale('en'));
    });

    test('English -> Hindi runtime switching updates active locale and storage', () async {
      expect(controller.currentLocale, const Locale('en'));
      expect(controller.currentLanguageCode, 'en');

      await controller.setAppLocale(AppLocale.hindi);
      expect(controller.currentLocale, const Locale('hi'));
      expect(controller.currentLanguageCode, 'hi');
      expect(controller.currentAppLocale, AppLocale.hindi);

      // Verify persisted in storage
      final stored = await storage.get<String>(HiveBoxes.settings, LocaleController.selectedLocaleStorageKey);
      expect(stored, 'hi');
    });

    test('English -> Marathi runtime switching updates active locale and storage', () async {
      await controller.setAppLocale(AppLocale.marathi);
      expect(controller.currentLocale, const Locale('mr'));
      expect(controller.currentLanguageCode, 'mr');
      expect(controller.currentAppLocale, AppLocale.marathi);

      final stored = await storage.get<String>(HiveBoxes.settings, LocaleController.selectedLocaleStorageKey);
      expect(stored, 'mr');
    });

    test('Hindi -> English runtime switching updates active locale and storage', () async {
      await controller.setAppLocale(AppLocale.hindi);
      expect(controller.currentLanguageCode, 'hi');

      await controller.setAppLocale(AppLocale.english);
      expect(controller.currentLocale, const Locale('en'));
      expect(controller.currentLanguageCode, 'en');
      expect(controller.currentAppLocale, AppLocale.english);

      final stored = await storage.get<String>(HiveBoxes.settings, LocaleController.selectedLocaleStorageKey);
      expect(stored, 'en');
    });

    test('Marathi -> Hindi runtime switching updates active locale and storage', () async {
      await controller.setAppLocale(AppLocale.marathi);
      expect(controller.currentLanguageCode, 'mr');

      await controller.setAppLocale(AppLocale.hindi);
      expect(controller.currentLocale, const Locale('hi'));
      expect(controller.currentLanguageCode, 'hi');
      expect(controller.currentAppLocale, AppLocale.hindi);

      final stored = await storage.get<String>(HiveBoxes.settings, LocaleController.selectedLocaleStorageKey);
      expect(stored, 'hi');
    });
  });

  group('Phase 2: Saved Locale Restoration & Startup Resolution', () {
    test('Restores saved Marathi preference before UI rendering', () async {
      final storage = MockStorageForPhase2Test();
      await storage.put<String>(HiveBoxes.settings, LocaleController.selectedLocaleStorageKey, 'mr');

      final controller = LocaleController(storage: storage);
      final initialLocale = await controller.initialize();

      expect(initialLocale, const Locale('mr'));
      expect(controller.currentLocale, const Locale('mr'));
      expect(controller.hasExplicitSelection, isTrue);
    });

    test('Restores saved Hindi preference from SettingsLocalModel', () async {
      final storage = MockStorageForPhase2Test();
      await storage.put<SettingsLocalModel>(
        HiveBoxes.settings,
        HiveBoxes.appSettingsKey,
        const SettingsLocalModel(languageCode: 'hi'),
      );

      final controller = LocaleController(storage: storage);
      final initialLocale = await controller.initialize();

      expect(initialLocale, const Locale('hi'));
      expect(controller.currentLocale, const Locale('hi'));
      expect(controller.hasExplicitSelection, isTrue);
    });

    test('Device locale fallback to Hindi when no saved preference exists', () async {
      final storage = MockStorageForPhase2Test();
      final controller = LocaleController(storage: storage);
      final initialLocale = await controller.initialize(customDeviceLocale: const Locale('hi'));

      expect(initialLocale, const Locale('hi'));
      expect(controller.currentLocale, const Locale('hi'));
    });

    test('Device locale fallback to Marathi when no saved preference exists', () async {
      final storage = MockStorageForPhase2Test();
      final controller = LocaleController(storage: storage);
      final initialLocale = await controller.initialize(customDeviceLocale: const Locale('mr'));

      expect(initialLocale, const Locale('mr'));
      expect(controller.currentLocale, const Locale('mr'));
    });

    test('Unsupported device locale (Gujarati) safely falls back to English', () async {
      final storage = MockStorageForPhase2Test();
      final controller = LocaleController(storage: storage);
      final initialLocale = await controller.initialize(customDeviceLocale: const Locale('gu'));

      expect(initialLocale, const Locale('en'));
      expect(controller.currentLocale, const Locale('en'));
    });

    test('Saved Marathi preference takes precedence over English device locale', () async {
      final storage = MockStorageForPhase2Test();
      await storage.put<String>(HiveBoxes.settings, LocaleController.selectedLocaleStorageKey, 'mr');

      final controller = LocaleController(storage: storage);
      final initialLocale = await controller.initialize(customDeviceLocale: const Locale('en'));

      expect(initialLocale, const Locale('mr'));
      expect(controller.currentLocale, const Locale('mr'));
    });

    test('Corrupted or invalid stored locale safely falls back to English', () async {
      final storage = MockStorageForPhase2Test();
      await storage.put<String>(HiveBoxes.settings, LocaleController.selectedLocaleStorageKey, 'corrupted_code_123');

      final controller = LocaleController(storage: storage);
      final initialLocale = await controller.initialize(customDeviceLocale: const Locale('fr'));

      expect(initialLocale, const Locale('en'));
      expect(controller.currentLocale, const Locale('en'));
    });
  });

  group('Phase 2: User Profile Synchronization & UserModel Parsing', () {
    test('UserModel parses preferred languageCode and provides localized display name', () {
      const enUser = UserModel(id: 'u1', fullName: 'Aarav Shah', email: 'a@c.com', phone: '123', languageCode: 'en');
      expect(enUser.languageName, 'English');

      const hiUser = UserModel(id: 'u2', fullName: 'राहुल वर्मा', email: 'r@c.com', phone: '456', languageCode: 'hi');
      expect(hiUser.languageName, 'हिन्दी (Hindi)');

      const mrUser = UserModel(id: 'u3', fullName: 'रोहन जोशी', email: 'ro@c.com', phone: '789', languageCode: 'mr');
      expect(mrUser.languageName, 'मराठी (Marathi)');
    });

    test('HiveUserRepository caches and updates languageCode cleanly', () async {
      final storage = MockStorageForPhase2Test();
      final userRepo = HiveUserRepository(storage: storage);

      final user = await userRepo.updateUserProfile(
        fullName: 'Aditya Patil',
        languageCode: 'mr',
      );

      expect(user.languageCode, 'mr');
      expect(user.languageName, 'मराठी (Marathi)');

      final fetched = await userRepo.getCurrentUser();
      expect(fetched.languageCode, 'mr');
    });
  });

  group('Phase 2: Language Selector UI & Selected State', () {
    testWidgets('LanguageSelectorWidget renders all 3 native languages and highlights selected state', (tester) async {
      final storage = MockStorageForPhase2Test();
      final controller = LocaleController(storage: storage, initialLocale: const Locale('mr'));

      AppLocale? selectedCallback;

      await tester.pumpWidget(
        MaterialApp(
          locale: controller.currentLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: LanguageSelectorWidget(
              localeController: controller,
              currentLanguageCode: 'mr',
              onLanguageSelected: (locale) {
                selectedCallback = locale;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify native names are present
      expect(find.text('English'), findsWidgets);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('मराठी'), findsOneWidget);

      // Verify check icon is shown for selected Marathi
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);

      // Tap Hindi option
      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();

      expect(selectedCallback, AppLocale.hindi);
      expect(controller.currentLanguageCode, 'hi');
    });

    testWidgets('Locale switch preserves navigation stack and does not reset routes', (tester) async {
      final storage = MockStorageForPhase2Test();
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
                builder: (ctx) => Scaffold(
                  appBar: AppBar(title: const Text('Root Screen')),
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (subCtx) {
                            final l10n = subCtx.l10n;
                            return Scaffold(
                              appBar: AppBar(title: Text('Subscreen: ${l10n.appName}')),
                              body: ElevatedButton(
                                onPressed: () async {
                                  await controller.setAppLocale(AppLocale.hindi);
                                },
                                child: Text('Switch to Hindi: ${l10n.commonRetry}'),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: const Text('Navigate to Subscreen'),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Root Screen'), findsOneWidget);

      // Navigate to subscreen
      await tester.tap(find.text('Navigate to Subscreen'));
      await tester.pumpAndSettle();

      expect(find.text('Subscreen: CivicFix'), findsOneWidget);
      expect(find.text('Switch to Hindi: Retry'), findsOneWidget);

      // Switch language to Hindi from inside subscreen
      await tester.tap(find.text('Switch to Hindi: Retry'));
      await tester.pumpAndSettle();

      // Navigation stack is preserved! Subscreen is still on top with Hindi text
      expect(find.text('Subscreen: CivicFix'), findsOneWidget);
      expect(find.text('Switch to Hindi: पुनः प्रयास करें'), findsOneWidget);

      // Pop back to root screen safely
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.text('Root Screen'), findsOneWidget);
    });
  });

  group('Phase 2: Canonical Backend Values Invariance', () {
    test('Switching to Hindi and Marathi does not alter backend canonical values or enums', () async {
      final storage = MockStorageForPhase2Test();
      final controller = LocaleController(storage: storage);

      // 1. In English
      await controller.setAppLocale(AppLocale.english);
      expect(ComplaintStatus.inProgress.name, 'inProgress');
      expect(ComplaintStatus.underVerification.name, 'underVerification');
      expect(GovernmentRole.departmentCrew.id, 'department_crew');

      // 2. In Hindi
      await controller.setAppLocale(AppLocale.hindi);
      expect(ComplaintStatus.inProgress.name, 'inProgress');
      expect(ComplaintStatus.underVerification.name, 'underVerification');
      expect(GovernmentRole.departmentCrew.id, 'department_crew');

      // 3. In Marathi
      await controller.setAppLocale(AppLocale.marathi);
      expect(ComplaintStatus.inProgress.name, 'inProgress');
      expect(ComplaintStatus.underVerification.name, 'underVerification');
      expect(GovernmentRole.departmentCrew.id, 'department_crew');
    });
  });
}
