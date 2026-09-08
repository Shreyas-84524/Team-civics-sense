import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_adapters/achievement_hive_adapter.dart';
import 'hive_adapters/complaint_hive_adapter.dart';
import 'hive_adapters/hazard_hive_adapter.dart';
import 'hive_adapters/location_hive_adapter.dart';
import 'hive_adapters/notification_hive_adapter.dart';
import 'hive_adapters/pending_sync_hive_adapter.dart';
import 'hive_adapters/reward_item_hive_adapter.dart';
import 'hive_adapters/settings_hive_adapter.dart';
import 'hive_adapters/timeline_event_hive_adapter.dart';
import 'hive_adapters/user_hive_adapter.dart';
import 'hive_boxes.dart';

/// Centralized bootstrap & initialization orchestrator for Hive persistence.
class HiveInitializer {
  HiveInitializer._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Initializes Hive storage and registers all type adapters safely.
  ///
  /// In Flutter runtime, it uses [Hive.initFlutter].
  /// In unit tests, pass [customPath] (e.g. Directory.systemTemp) or set [isTest] to true.
  static Future<bool> initialize({
    String? customPath,
    bool isTest = false,
  }) async {
    try {
      if (isTest || customPath != null) {
        final path = customPath ?? Directory.systemTemp.path;
        Hive.init(path);
      } else {
        await Hive.initFlutter();
      }

      registerAdapters();
      _initialized = true;
      debugPrint('[CivicFix LocalStorage] Hive initialized successfully.');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[CivicFix LocalStorage] Warning: Failed to initialize Hive: $e\n$stackTrace');
      _initialized = false;
      return false;
    }
  }

  /// Registers all CivicFix Hive adapters idempotently.
  static void registerAdapters() {
    _safeRegisterAdapter(ComplaintHiveAdapter()); // typeId: 0
    _safeRegisterAdapter(LocationHiveAdapter()); // typeId: 1
    _safeRegisterAdapter(TimelineEventHiveAdapter()); // typeId: 2
    _safeRegisterAdapter(HazardHiveAdapter()); // typeId: 3
    _safeRegisterAdapter(NotificationHiveAdapter()); // typeId: 4
    _safeRegisterAdapter(UserHiveAdapter()); // typeId: 5
    _safeRegisterAdapter(AchievementHiveAdapter()); // typeId: 6
    _safeRegisterAdapter(RewardItemHiveAdapter()); // typeId: 7
    _safeRegisterAdapter(PendingSyncHiveAdapter()); // typeId: 8
    _safeRegisterAdapter(SettingsHiveAdapter()); // typeId: 9
  }

  static void _safeRegisterAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
  }

  /// Attempts to safely open all primary boxes, automatically recovering from corrupted boxes.
  static Future<Map<String, bool>> openEssentialBoxes() async {
    final Map<String, bool> results = {};

    for (final boxName in HiveBoxes.allBoxes) {
      try {
        if (!Hive.isBoxOpen(boxName)) {
          await Hive.openBox(boxName);
        }
        results[boxName] = true;
      } catch (e) {
        debugPrint('[CivicFix LocalStorage] Warning: Failed to open box "$boxName", attempting recovery: $e');
        final recovered = await recoverCorruptedBox(boxName);
        results[boxName] = recovered;
      }
    }

    return results;
  }

  /// Recovers from a corrupted box by closing it, deleting corrupted files from disk, and re-creating it.
  static Future<bool> recoverCorruptedBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.openBox(boxName);
      debugPrint('[CivicFix LocalStorage] Successfully recovered corrupted box "$boxName".');
      return true;
    } catch (e) {
      debugPrint('[CivicFix LocalStorage] Error: Failed to recover box "$boxName": $e');
      return false;
    }
  }

  /// Closes and resets Hive for testing or teardown.
  @visibleForTesting
  static Future<void> resetForTesting() async {
    await Hive.close();
    _initialized = false;
  }
}
