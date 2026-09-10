import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/firebase/firebase_constants.dart';
import 'package:civic_app/core/firebase/firebase_initializer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseConstants Tests', () {
    test('Firestore collection names are properly defined and consistent', () {
      expect(FirestoreCollections.complaints, equals('complaints'));
      expect(FirestoreCollections.complaintUpdates, equals('complaint_updates'));
      expect(FirestoreCollections.users, equals('users'));
      expect(FirestoreCollections.govtUsers, equals('govt_users'));
      expect(FirestoreCollections.hazards, equals('hazards'));
      expect(FirestoreCollections.notifications, equals('notifications'));
      expect(FirestoreCollections.rewards, equals('rewards'));
      expect(FirestoreCollections.departments, equals('departments'));
      expect(FirestoreCollections.officers, equals('officers'));
    });

    test('FirebaseStoragePaths helper methods format storage paths correctly', () {
      expect(FirebaseStoragePaths.complaintEvidence, equals('complaint_evidence'));
      expect(FirebaseStoragePaths.userAvatars, equals('user_avatars'));
      expect(FirebaseStoragePaths.govtAvatars, equals('govt_avatars'));

      final evidencePath = FirebaseStoragePaths.complaintEvidencePath('cmp_123', 'photo_1.jpg');
      expect(evidencePath, equals('complaint_evidence/cmp_123/photo_1.jpg'));

      final avatarPath = FirebaseStoragePaths.userAvatarPath('usr_456', 'avatar.png');
      expect(avatarPath, equals('user_avatars/usr_456/avatar.png'));
    });
  });

  group('FirebaseInitializer Unit Tests', () {
    setUp(() {
      FirebaseInitializer.resetForTesting(initialized: false);
    });

    tearDown(() {
      FirebaseInitializer.resetForTesting(initialized: false);
    });

    test('isInitialized returns false initially before initialization', () {
      expect(FirebaseInitializer.isInitialized, isFalse);
      expect(FirebaseInitializer.app, isNull);
    });

    test('resetForTesting updates initialized and app state cleanly', () {
      FirebaseInitializer.resetForTesting(initialized: true);
      expect(FirebaseInitializer.isInitialized, isTrue);

      FirebaseInitializer.resetForTesting(initialized: false);
      expect(FirebaseInitializer.isInitialized, isFalse);
    });

    test('initialize catches platform exceptions gracefully in non-Firebase test runner', () async {
      final result = await FirebaseInitializer.initialize();
      expect(result, isA<bool>());
    });
  });
}
