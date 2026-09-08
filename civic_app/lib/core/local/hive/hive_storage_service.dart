import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../errors/local_storage_exception.dart';
import '../local_storage_service.dart';
import 'hive_boxes.dart';
import 'hive_initializer.dart';

/// Hive-backed production implementation of [LocalStorageService].
class HiveStorageService implements LocalStorageService {
  static final HiveStorageService _instance = HiveStorageService._internal();
  factory HiveStorageService() => _instance;
  static HiveStorageService get instance => _instance;

  HiveStorageService._internal();

  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> init({String? subDir, bool isTest = false}) async {
    try {
      await HiveInitializer.initialize(customPath: subDir, isTest: isTest);
      _isInitialized = true;
    } catch (e, st) {
      _isInitialized = false;
      throw HiveInitializationException(
        'Failed to initialize Hive local storage: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Internal helper to ensure a box is open and accessible.
  Future<Box> _getOrOpenBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    if (!_isInitialized) {
      throw BoxNotFoundException(
        boxName,
        'HiveStorageService is not initialized. Call init() before accessing box "$boxName".',
      );
    }
    try {
      return await Hive.openBox(boxName);
    } catch (e, st) {
      if (e is HiveError && e.message.contains('corrupted')) {
        throw StorageCorruptedException(
          'Box "$boxName" file is corrupted and could not be opened.',
          boxName: boxName,
          cause: e,
          stackTrace: st,
        );
      }
      throw BoxNotFoundException(
        boxName,
        'Failed to open or access box "$boxName": $e',
      );
    }
  }

  @override
  Future<void> openBox<T>(String boxName) async {
    await _getOrOpenBox(boxName);
  }

  @override
  Future<void> put<T>(String boxName, dynamic key, T value) async {
    try {
      final box = await _getOrOpenBox(boxName);
      await box.put(key, value);
    } catch (e, st) {
      if (e is LocalStorageException) rethrow;
      throw HiveWriteException(
        'Failed to write key "$key" into box "$boxName": $e',
        boxName: boxName,
        key: key,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> putAll<T>(String boxName, Map<dynamic, T> entries) async {
    try {
      final box = await _getOrOpenBox(boxName);
      await box.putAll(entries);
    } catch (e, st) {
      if (e is LocalStorageException) rethrow;
      throw HiveWriteException(
        'Failed to write batch entries into box "$boxName": $e',
        boxName: boxName,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<T?> get<T>(String boxName, dynamic key, {T? defaultValue}) async {
    try {
      final box = await _getOrOpenBox(boxName);
      final value = box.get(key, defaultValue: defaultValue);
      if (value == null) return defaultValue;
      if (value is T) return value;
      return value as T?;
    } catch (e, st) {
      if (e is LocalStorageException) rethrow;
      throw HiveReadException(
        'Failed to read key "$key" from box "$boxName": $e',
        boxName: boxName,
        key: key,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<T>> getAll<T>(String boxName) async {
    try {
      final box = await _getOrOpenBox(boxName);
      if (T == dynamic) {
        return List<T>.unmodifiable(box.values.toList());
      }
      return List<T>.unmodifiable(box.values.whereType<T>().toList());
    } catch (e, st) {
      if (e is LocalStorageException) rethrow;
      throw HiveReadException(
        'Failed to read all values from box "$boxName": $e',
        boxName: boxName,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<Map<dynamic, T>> getAllEntries<T>(String boxName) async {
    try {
      final box = await _getOrOpenBox(boxName);
      final Map<dynamic, T> map = {};
      for (final key in box.keys) {
        final val = box.get(key);
        if (val != null) {
          if (val is T) {
            map[key] = val;
          } else if (T == dynamic) {
            map[key] = val as T;
          }
        }
      }
      return Map<dynamic, T>.unmodifiable(map);
    } catch (e, st) {
      if (e is LocalStorageException) rethrow;
      throw HiveReadException(
        'Failed to read all entries from box "$boxName": $e',
        boxName: boxName,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> delete(String boxName, dynamic key) async {
    try {
      final box = await _getOrOpenBox(boxName);
      await box.delete(key);
    } catch (e, st) {
      if (e is LocalStorageException) rethrow;
      throw HiveDeleteException(
        'Failed to delete key "$key" from box "$boxName": $e',
        boxName: boxName,
        key: key,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> deleteAll(String boxName, Iterable<dynamic> keys) async {
    try {
      final box = await _getOrOpenBox(boxName);
      await box.deleteAll(keys);
    } catch (e, st) {
      if (e is LocalStorageException) rethrow;
      throw HiveDeleteException(
        'Failed to delete keys from box "$boxName": $e',
        boxName: boxName,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> clear(String boxName) async {
    try {
      final box = await _getOrOpenBox(boxName);
      await box.clear();
    } catch (e, st) {
      if (e is LocalStorageException) rethrow;
      throw HiveDeleteException(
        'Failed to clear box "$boxName": $e',
        boxName: boxName,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<bool> containsKey(String boxName, dynamic key) async {
    try {
      final box = await _getOrOpenBox(boxName);
      return box.containsKey(key);
    } catch (e, st) {
      if (e is LocalStorageException) rethrow;
      throw HiveReadException(
        'Failed to check key existence "$key" in box "$boxName": $e',
        boxName: boxName,
        key: key,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<int> count(String boxName) async {
    try {
      final box = await _getOrOpenBox(boxName);
      return box.length;
    } catch (e, st) {
      if (e is LocalStorageException) rethrow;
      throw HiveReadException(
        'Failed to count entries in box "$boxName": $e',
        boxName: boxName,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  bool isBoxOpen(String boxName) {
    return Hive.isBoxOpen(boxName);
  }

  @override
  Future<void> closeBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
    } catch (e) {
      debugPrint('Warning: Error closing box "$boxName": $e');
    }
  }

  @override
  Future<void> closeAll() async {
    try {
      await Hive.close();
    } catch (e) {
      debugPrint('Warning: Error closing all Hive boxes: $e');
    }
  }

  @override
  Future<void> deleteBoxFromDisk(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
      await Hive.deleteBoxFromDisk(boxName);
    } catch (e, st) {
      throw HiveDeleteException(
        'Failed to delete box "$boxName" from disk: $e',
        boxName: boxName,
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> resetAllBoxes() async {
    for (final boxName in HiveBoxes.allBoxes) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(boxName).clear();
        } else {
          final box = await Hive.openBox(boxName);
          await box.clear();
        }
      } catch (e) {
        debugPrint('Warning: Failed to clear box "$boxName" during reset: $e');
      }
    }
  }
}
