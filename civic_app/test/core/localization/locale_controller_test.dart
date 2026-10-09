import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/local/local_storage_service.dart';
import 'package:civic_app/core/local/hive/hive_boxes.dart';
import 'package:civic_app/core/local/models/settings_local_model.dart';
import 'package:civic_app/core/localization/locale_controller.dart';

class InMemoryLocalStorageService implements LocalStorageService {
  final Map<String, Map<dynamic, dynamic>> _storage = {};
  bool _initialized = true;

  @override
  bool get isInitialized => _initialized;

  void setInitialized(bool value) => _initialized = value;

  @override
  Future<void> init({String? subDir, bool isTest = false}) async {
    _initialized = true;
  }

  @override
  Future<void> put<T>(String boxName, dynamic key, T value) async {
    _storage.putIfAbsent(boxName, () => {})[key] = value;
  }

  @override
  Future<T?> get<T>(String boxName, dynamic key, {T? defaultValue}) async {
    final box = _storage[boxName];
    if (box == null || !box.containsKey(key)) return defaultValue;
    return box[key] as T?;
  }

  @override
  Future<void> delete(String boxName, dynamic key) async {
    _storage[boxName]?.remove(key);
  }

  @override
  Future<void> clear(String boxName) async {
    _storage[boxName]?.clear();
  }

  @override
  Future<void> closeAll() async {}

  @override
  Future<void> closeBox(String boxName) async {}

  @override
  Future<bool> containsKey(String boxName, dynamic key) async {
    return _storage[boxName]?.containsKey(key) ?? false;
  }

  @override
  Future<int> count(String boxName) async => _storage[boxName]?.length ?? 0;

  @override
  Future<void> deleteBoxFromDisk(String boxName) async {
    _storage.remove(boxName);
  }

  @override
  Future<List<T>> getAll<T>(String boxName) async {
    return _storage[boxName]?.values.whereType<T>().toList() ?? <T>[];
  }

  @override
  Future<Map<dynamic, T>> getAllEntries<T>(String boxName) async {
    final box = _storage[boxName];
    if (box == null) return <dynamic, T>{};
    return box.map((k, v) => MapEntry(k, v as T));
  }

  @override
  bool isBoxOpen(String boxName) => true;

  @override
  Future<void> openBox<T>(String boxName) async {
    _storage.putIfAbsent(boxName, () => {});
  }

  @override
  Future<void> putAll<T>(String boxName, Map<dynamic, T> entries) async {
    _storage.putIfAbsent(boxName, () => {}).addAll(entries);
  }

  @override
  Future<void> deleteAll(String boxName, Iterable keys) async {
    for (final k in keys) {
      _storage[boxName]?.remove(k);
    }
  }

  @override
  Future<void> resetAllBoxes() async {
    _storage.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryLocalStorageService storage;
  late LocaleController controller;

  setUp(() {
    storage = InMemoryLocalStorageService();
    controller = LocaleController(storage: storage);
  });

  tearDown(() {
    LocaleController.resetInstance();
  });

  group('LocaleController Fallback Chain & Initialization', () {
    test('Defaults to English (en) when storage is empty and device locale is unsupported', () async {
      final locale = await controller.determineInitialLocale(deviceLocale: const Locale('fr'));
      expect(locale, const Locale('en'));
    });

    test('Falls back to supported device locale if no stored preference exists', () async {
      final hindiLocale = await controller.determineInitialLocale(deviceLocale: const Locale('hi'));
      expect(hindiLocale, const Locale('hi'));

      final marathiLocale = await controller.determineInitialLocale(deviceLocale: const Locale('mr'));
      expect(marathiLocale, const Locale('mr'));
    });

    test('Stored preference takes precedence over supported device locale', () async {
      await storage.put<String>(
        HiveBoxes.settings,
        LocaleController.selectedLocaleStorageKey,
        'mr',
      );

      final resolved = await controller.determineInitialLocale(deviceLocale: const Locale('hi'));
      expect(resolved, const Locale('mr'));
    });

    test('Fallback to SettingsLocalModel languageCode if raw key is not present', () async {
      await storage.put<SettingsLocalModel>(
        HiveBoxes.settings,
        HiveBoxes.appSettingsKey,
        const SettingsLocalModel(languageCode: 'hi'),
      );

      final resolved = await controller.determineInitialLocale(deviceLocale: const Locale('en'));
      expect(resolved, const Locale('hi'));
    });

    test('Gracefully ignores corrupted or unsupported stored preference and falls back', () async {
      await storage.put<String>(
        HiveBoxes.settings,
        LocaleController.selectedLocaleStorageKey,
        'unsupported_lang',
      );

      final resolved = await controller.determineInitialLocale(deviceLocale: const Locale('mr'));
      expect(resolved, const Locale('mr'));
    });
  });

  group('LocaleController Runtime Switching & State', () {
    test('Switches locale dynamically and notifies listeners', () async {
      int notifyCount = 0;
      controller.addListener(() {
        notifyCount++;
      });

      expect(controller.currentLocale, const Locale('en'));
      expect(controller.value, const Locale('en'));

      await controller.setLocale(const Locale('hi'));

      expect(controller.currentLocale, const Locale('hi'));
      expect(controller.value, const Locale('hi'));
      expect(controller.currentLanguageCode, 'hi');
      expect(notifyCount, 1);

      // Verify stored in storage
      final stored = await storage.get<String>(
        HiveBoxes.settings,
        LocaleController.selectedLocaleStorageKey,
      );
      expect(stored, 'hi');
    });

    test('Switches language by language code', () async {
      await controller.setLanguageCode('mr');

      expect(controller.currentLocale, const Locale('mr'));
      expect(controller.currentLanguageCode, 'mr');

      final stored = await storage.get<String>(
        HiveBoxes.settings,
        LocaleController.selectedLocaleStorageKey,
      );
      expect(stored, 'mr');
    });

    test('Unsupported locale falls back to default English', () async {
      await controller.setLocale(const Locale('es'));

      expect(controller.currentLocale, const Locale('en'));
      expect(controller.currentLanguageCode, 'en');
    });

    test('resolveLocale respects explicit user selection over device locale', () async {
      await controller.setLocale(const Locale('mr'));

      final resolved = controller.resolveLocale(
        const Locale('hi'),
        LocaleController.supportedLocales,
      );

      expect(resolved, const Locale('mr'));
    });
  });

  group('LocaleController Static Helpers', () {
    test('isSupported validates correct languages', () {
      expect(LocaleController.isSupported('en'), isTrue);
      expect(LocaleController.isSupported('hi'), isTrue);
      expect(LocaleController.isSupported('mr'), isTrue);
      expect(LocaleController.isSupported('EN'), isTrue);
      expect(LocaleController.isSupported('fr'), isFalse);
      expect(LocaleController.isSupported(const Locale('hi')), isTrue);
      expect(LocaleController.isSupported(null), isFalse);
    });

    test('Singleton accessor is accessible and rebindable', () {
      final custom = LocaleController(storage: storage);
      LocaleController.instance = custom;
      expect(LocaleController.instance, custom);
    });
  });
}
