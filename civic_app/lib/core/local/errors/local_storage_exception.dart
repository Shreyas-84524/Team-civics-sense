/// Base exception for all local storage errors in CivicFix.
class LocalStorageException implements Exception {
  final String message;
  final dynamic cause;
  final StackTrace? stackTrace;

  const LocalStorageException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() {
    if (cause != null) {
      return 'LocalStorageException: $message (Caused by: $cause)';
    }
    return 'LocalStorageException: $message';
  }
}

/// Thrown when local storage initialization fails.
class HiveInitializationException extends LocalStorageException {
  const HiveInitializationException(super.message, {super.cause, super.stackTrace});
}

/// Thrown when reading a key or querying a box fails.
class HiveReadException extends LocalStorageException {
  final String? boxName;
  final dynamic key;

  const HiveReadException(
    super.message, {
    this.boxName,
    this.key,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('HiveReadException: $message');
    if (boxName != null) buffer.write(' [Box: $boxName]');
    if (key != null) buffer.write(' [Key: $key]');
    if (cause != null) buffer.write(' (Caused by: $cause)');
    return buffer.toString();
  }
}

/// Thrown when writing or updating data in a box fails.
class HiveWriteException extends LocalStorageException {
  final String? boxName;
  final dynamic key;

  const HiveWriteException(
    super.message, {
    this.boxName,
    this.key,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('HiveWriteException: $message');
    if (boxName != null) buffer.write(' [Box: $boxName]');
    if (key != null) buffer.write(' [Key: $key]');
    if (cause != null) buffer.write(' (Caused by: $cause)');
    return buffer.toString();
  }
}

/// Thrown when deleting data from a box fails.
class HiveDeleteException extends LocalStorageException {
  final String? boxName;
  final dynamic key;

  const HiveDeleteException(
    super.message, {
    this.boxName,
    this.key,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('HiveDeleteException: $message');
    if (boxName != null) buffer.write(' [Box: $boxName]');
    if (key != null) buffer.write(' [Key: $key]');
    if (cause != null) buffer.write(' (Caused by: $cause)');
    return buffer.toString();
  }
}

/// Thrown when an operation is requested on a box that is not opened or registered.
class BoxNotFoundException extends LocalStorageException {
  final String boxName;

  const BoxNotFoundException(this.boxName, [String? message])
      : super(message ?? 'Box "$boxName" is not open or does not exist.');

  @override
  String toString() => 'BoxNotFoundException: $message [Box: $boxName]';
}

/// Thrown when stored data is corrupted or fails deserialization.
class StorageCorruptedException extends LocalStorageException {
  final String? boxName;

  const StorageCorruptedException(super.message, {this.boxName, super.cause, super.stackTrace});

  @override
  String toString() {
    final buffer = StringBuffer('StorageCorruptedException: $message');
    if (boxName != null) buffer.write(' [Box: $boxName]');
    if (cause != null) buffer.write(' (Caused by: $cause)');
    return buffer.toString();
  }
}
