import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:civic_app/core/local/hive/hive_boxes.dart';
import 'package:civic_app/core/local/hive/hive_initializer.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_init_test_');
  });

  tearDown(() async {
    await HiveInitializer.resetForTesting();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveInitializer Unit Tests', () {
    test('Initializes safely with custom test directory', () async {
      final success = await HiveInitializer.initialize(
        customPath: tempDir.path,
        isTest: true,
      );

      expect(success, isTrue);
      expect(HiveInitializer.isInitialized, isTrue);
    });

    test('registerAdapters is idempotent and can be invoked repeatedly without error', () async {
      await HiveInitializer.initialize(
        customPath: tempDir.path,
        isTest: true,
      );

      // Multiple successive invocations should not throw "Adapter already registered"
      expect(() => HiveInitializer.registerAdapters(), returnsNormally);
      expect(() => HiveInitializer.registerAdapters(), returnsNormally);
      expect(() => HiveInitializer.registerAdapters(), returnsNormally);
    });

    test('openEssentialBoxes opens all canonical boxes', () async {
      await HiveInitializer.initialize(
        customPath: tempDir.path,
        isTest: true,
      );

      final results = await HiveInitializer.openEssentialBoxes();

      expect(results.length, HiveBoxes.allBoxes.length);
      for (final boxName in HiveBoxes.allBoxes) {
        expect(results[boxName], isTrue);
        expect(Hive.isBoxOpen(boxName), isTrue);
      }
    });

    test('recoverCorruptedBox recovers and re-creates box cleanly', () async {
      await HiveInitializer.initialize(
        customPath: tempDir.path,
        isTest: true,
      );

      final box = await Hive.openBox('corrupt_candidate');
      await box.put('sample_key', 'sample_value');
      expect(box.isOpen, isTrue);

      final recovered = await HiveInitializer.recoverCorruptedBox('corrupt_candidate');
      expect(recovered, isTrue);
      expect(Hive.isBoxOpen('corrupt_candidate'), isTrue);

      // Re-opened clean box is empty
      final cleanBox = Hive.box('corrupt_candidate');
      expect(cleanBox.isEmpty, isTrue);
    });
  });
}
