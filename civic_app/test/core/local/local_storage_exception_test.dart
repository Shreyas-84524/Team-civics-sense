import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/local/errors/local_storage_exception.dart';

void main() {
  group('LocalStorageException Unit Tests', () {
    test('LocalStorageException formats message and optional cause', () {
      const basic = LocalStorageException('Base storage failure');
      expect(basic.toString(), 'LocalStorageException: Base storage failure');

      final withCause = LocalStorageException('Write error', cause: 'Disk full');
      expect(withCause.toString(), 'LocalStorageException: Write error (Caused by: Disk full)');
    });

    test('HiveInitializationException formats correctly', () {
      const ex = HiveInitializationException('Cannot access app directory');
      expect(ex.toString(), 'LocalStorageException: Cannot access app directory');
      expect(ex, isA<LocalStorageException>());
    });

    test('HiveReadException formats with boxName and key', () {
      const ex = HiveReadException('Record missing', boxName: 'complaints', key: 'cmp_101');
      expect(ex.toString(), contains('HiveReadException: Record missing'));
      expect(ex.toString(), contains('[Box: complaints]'));
      expect(ex.toString(), contains('[Key: cmp_101]'));
    });

    test('HiveWriteException formats with boxName, key and cause', () {
      final ex = HiveWriteException(
        'Serialization failed',
        boxName: 'user',
        key: 'current_user',
        cause: 'Invalid byte',
      );
      expect(ex.toString(), contains('HiveWriteException: Serialization failed'));
      expect(ex.toString(), contains('[Box: user]'));
      expect(ex.toString(), contains('[Key: current_user]'));
      expect(ex.toString(), contains('(Caused by: Invalid byte)'));
    });

    test('HiveDeleteException formats with boxName and key', () {
      const ex = HiveDeleteException('Cannot delete locked item', boxName: 'hazards', key: 'haz_101');
      expect(ex.toString(), contains('HiveDeleteException: Cannot delete locked item'));
      expect(ex.toString(), contains('[Box: hazards]'));
      expect(ex.toString(), contains('[Key: haz_101]'));
    });

    test('BoxNotFoundException formats with box name and custom message', () {
      const ex = BoxNotFoundException('analytics');
      expect(ex.boxName, 'analytics');
      expect(ex.toString(), contains('BoxNotFoundException'));
      expect(ex.toString(), contains('[Box: analytics]'));
    });

    test('StorageCorruptedException formats with box name and cause', () {
      final ex = StorageCorruptedException(
        'CRC checksum failed',
        boxName: 'pending_sync',
        cause: 'Truncated file',
      );
      expect(ex.toString(), contains('StorageCorruptedException: CRC checksum failed'));
      expect(ex.toString(), contains('[Box: pending_sync]'));
      expect(ex.toString(), contains('(Caused by: Truncated file)'));
    });
  });
}
