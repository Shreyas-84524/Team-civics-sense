/// Technology-agnostic contract for key-value and object local storage in CivicFix.
abstract class LocalStorageService {
  /// Initializes the local storage engine.
  /// [subDir] optionally specifies a custom storage directory path (e.g. for testing).
  Future<void> init({String? subDir, bool isTest = false});

  /// Whether the storage service has been initialized.
  bool get isInitialized;

  /// Opens a box/collection by name with type [T].
  Future<void> openBox<T>(String boxName);

  /// Stores a single [value] associated with [key] in [boxName].
  Future<void> put<T>(String boxName, dynamic key, T value);

  /// Stores multiple [entries] at once in [boxName].
  Future<void> putAll<T>(String boxName, Map<dynamic, T> entries);

  /// Retrieves a value for [key] in [boxName], or returns [defaultValue] if not found.
  Future<T?> get<T>(String boxName, dynamic key, {T? defaultValue});

  /// Retrieves all values stored in [boxName].
  Future<List<T>> getAll<T>(String boxName);

  /// Retrieves all key-value entries stored in [boxName].
  Future<Map<dynamic, T>> getAllEntries<T>(String boxName);

  /// Deletes the entry for [key] from [boxName].
  Future<void> delete(String boxName, dynamic key);

  /// Deletes multiple [keys] from [boxName].
  Future<void> deleteAll(String boxName, Iterable<dynamic> keys);

  /// Clears all entries from [boxName] without deleting the box structure.
  Future<void> clear(String boxName);

  /// Returns whether [boxName] contains an entry for [key].
  Future<bool> containsKey(String boxName, dynamic key);

  /// Returns the total number of entries in [boxName].
  Future<int> count(String boxName);

  /// Checks if [boxName] is currently open.
  bool isBoxOpen(String boxName);

  /// Closes [boxName] if currently open.
  Future<void> closeBox(String boxName);

  /// Closes all open boxes in local storage.
  Future<void> closeAll();

  /// Deletes [boxName] and its associated storage files from disk.
  Future<void> deleteBoxFromDisk(String boxName);

  /// Resets / clears all managed boxes in the local storage layer.
  Future<void> resetAllBoxes();
}
