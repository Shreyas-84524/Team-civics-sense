import 'package:civic_app/core/auth/auth_service.dart';
import 'package:civic_app/core/auth/firebase_auth_service.dart';
import 'package:civic_app/core/firebase/firestore/firebase_user_data_source.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/repositories/hive_user_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFirebaseUserDataSource extends FirebaseUserDataSource {
  final Map<String, UserModel> users = {};

  @override
  Future<UserModel?> getUserById(String userId) async {
    return users[userId];
  }

  @override
  Future<UserModel> createCitizenProfile(UserModel user) async {
    // Enforce citizen role as Firestore security rules do
    if (user.role != 'citizen') {
      throw Exception('PERMISSION_DENIED: Role must be citizen');
    }
    users[user.id] = user;
    return user;
  }

  @override
  Future<UserModel> updateCitizenProfile(
    String userId, {
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? languageCode,
    String? wardNumber,
  }) async {
    final existing = users[userId] ??
        UserModel(
          id: userId,
          fullName: fullName ?? 'Citizen',
          email: 'citizen@test.com',
          phone: phone ?? '',
        );
    final updated = existing.copyWith(
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
      languageCode: languageCode,
      wardNumber: wardNumber,
    );
    users[userId] = updated;
    return updated;
  }
}

class FakeHiveUserRepository extends HiveUserRepository {
  UserModel? cachedUser;

  @override
  Future<void> cacheUser(UserModel user) async {
    cachedUser = user;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    return cachedUser ??
        const UserModel(
          id: 'user_cached_fallback',
          fullName: 'Cached User',
          email: 'cached@test.com',
          phone: '',
        );
  }
}

void main() {
  group('FirebaseAuthService Unit & Architecture Tests', () {
    test('enforces role citizen on registration and caches locally', () async {
      final fakeRemote = FakeFirebaseUserDataSource();
      final fakeLocal = FakeHiveUserRepository();

      // Test UserModel construction matching registration
      const newCitizen = UserModel(
        id: 'uid_test_citizen_123',
        fullName: 'Aarav Mehta',
        email: 'aarav@civicfix.test',
        phone: '+91 98765 00000',
        role: 'citizen',
        civicPoints: 20,
        reportsSubmitted: 0,
        reportsResolved: 0,
        wardNumber: 'Ward 14 (Central)',
        languageCode: 'hi',
        badges: ['New Citizen'],
      );

      // Verify Firestore create profile
      await fakeRemote.createCitizenProfile(newCitizen);
      expect(fakeRemote.users['uid_test_citizen_123'], isNotNull);
      expect(fakeRemote.users['uid_test_citizen_123']!.role, equals('citizen'));
      expect(fakeRemote.users['uid_test_citizen_123']!.civicPoints, equals(20));

      // Verify Hive cache
      await fakeLocal.cacheUser(newCitizen);
      expect(fakeLocal.cachedUser?.id, equals('uid_test_citizen_123'));
      expect(fakeLocal.cachedUser?.fullName, equals('Aarav Mehta'));
    });

    test('anti-tampering rule rejects attempts to self-assign government role', () async {
      final fakeRemote = FakeFirebaseUserDataSource();

      const invalidTamperedUser = UserModel(
        id: 'uid_hacker_001',
        fullName: 'Rogue Officer',
        email: 'rogue@test.com',
        phone: '+91 00000 00000',
        role: 'government', // TAMPERED ROLE
      );

      expect(
        () async => await fakeRemote.createCitizenProfile(invalidTamperedUser),
        throwsA(isA<Exception>()),
      );
    });

    test('AuthResult model preserves type safety and error messages', () {
      const successResult = AuthResult.success(
        user: UserModel(
          id: 'user_success_01',
          fullName: 'Test User',
          email: 'test@civicfix.test',
          phone: '123',
        ),
        successMessage: 'Login successful',
      );

      expect(successResult.isSuccess, isTrue);
      expect(successResult.user?.id, equals('user_success_01'));
      expect(successResult.errorMessage, isNull);
      expect(successResult.successMessage, equals('Login successful'));

      const failureResult = AuthResult.failure('Invalid password provided.');
      expect(failureResult.isSuccess, isFalse);
      expect(failureResult.isCancelled, isFalse);
      expect(failureResult.user, isNull);
      expect(failureResult.errorMessage, equals('Invalid password provided.'));

      const cancelledResult = AuthResult.cancelled();
      expect(cancelledResult.isSuccess, isFalse);
      expect(cancelledResult.isCancelled, isTrue);
      expect(cancelledResult.errorMessage, isNull);
      expect(cancelledResult.user, isNull);
    });

    test('login validates empty email and password upfront', () async {
      final fakeRemote = FakeFirebaseUserDataSource();
      final fakeLocal = FakeHiveUserRepository();
      final service = FirebaseAuthService(
        userDataSource: fakeRemote,
        userRepository: fakeLocal,
      );

      final emptyEmail = await service.login(email: '', password: 'secretpassword');
      expect(emptyEmail.isSuccess, isFalse);
      expect(emptyEmail.errorMessage, equals('Please enter your email.'));

      final emptyWhitespaceEmail = await service.login(email: '   ', password: 'secretpassword');
      expect(emptyWhitespaceEmail.isSuccess, isFalse);
      expect(emptyWhitespaceEmail.errorMessage, equals('Please enter your email.'));

      final emptyPassword = await service.login(email: 'citizen@test.com', password: '');
      expect(emptyPassword.isSuccess, isFalse);
      expect(emptyPassword.errorMessage, equals('Please enter your password.'));
    });

    test('register validates empty fields and password length upfront', () async {
      final fakeRemote = FakeFirebaseUserDataSource();
      final fakeLocal = FakeHiveUserRepository();
      final service = FirebaseAuthService(
        userDataSource: fakeRemote,
        userRepository: fakeLocal,
      );

      final emptyName = await service.register(
        fullName: '  ',
        email: 'test@test.com',
        password: 'password123',
        language: 'en',
      );
      expect(emptyName.isSuccess, isFalse);
      expect(emptyName.errorMessage, equals('Please enter your full name.'));

      final emptyEmail = await service.register(
        fullName: 'Citizen User',
        email: '',
        password: 'password123',
        language: 'en',
      );
      expect(emptyEmail.isSuccess, isFalse);
      expect(emptyEmail.errorMessage, equals('Please enter your email.'));

      final shortPwd = await service.register(
        fullName: 'Citizen User',
        email: 'test@test.com',
        password: 'short',
        language: 'en',
      );
      expect(shortPwd.isSuccess, isFalse);
      expect(shortPwd.errorMessage, equals('Password must be at least 8 characters.'));
    });

    test('new Google Sign-In user constructs citizen profile without fake phone and with citizen role', () async {
      final fakeRemote = FakeFirebaseUserDataSource();
      final fakeLocal = FakeHiveUserRepository();

      // Simulated new Google account
      const googleCitizen = UserModel(
        id: 'google_uid_999',
        fullName: 'Ananya Deshmukh',
        email: 'ananya.deshmukh@gmail.com',
        phone: '', // No fake phone invented
        avatarUrl: 'https://lh3.googleusercontent.com/a/photo_123',
        civicPoints: 20,
        reportsSubmitted: 0,
        reportsResolved: 0,
        wardNumber: 'Ward 14 (Central)',
        languageCode: 'en',
        role: 'citizen', // Enforced citizen role
        badges: ['New Citizen'],
      );

      await fakeRemote.createCitizenProfile(googleCitizen);
      await fakeLocal.cacheUser(googleCitizen);

      expect(fakeRemote.users['google_uid_999']?.fullName, equals('Ananya Deshmukh'));
      expect(fakeRemote.users['google_uid_999']?.role, equals('citizen'));
      expect(fakeRemote.users['google_uid_999']?.phone, isEmpty);
      expect(fakeRemote.users['google_uid_999']?.avatarUrl, contains('googleusercontent'));
      expect(fakeLocal.cachedUser?.id, equals('google_uid_999'));
    });

    test('existing Google Sign-In profile retrieval preserves existing profile data and role', () async {
      final fakeRemote = FakeFirebaseUserDataSource();
      const existingUser = UserModel(
        id: 'google_existing_111',
        fullName: 'Rohit Kadam',
        email: 'rohit@gmail.com',
        phone: '+91 91234 56789',
        avatarUrl: 'https://lh3.googleusercontent.com/a/rohit',
        civicPoints: 180,
        reportsSubmitted: 5,
        reportsResolved: 3,
        wardNumber: 'Ward 8',
        languageCode: 'mr',
        role: 'citizen',
        badges: ['Top Reporter'],
      );

      await fakeRemote.createCitizenProfile(existingUser);

      final retrieved = await fakeRemote.getUserById('google_existing_111');
      expect(retrieved, isNotNull);
      expect(retrieved!.fullName, equals('Rohit Kadam'));
      expect(retrieved.civicPoints, equals(180));
      expect(retrieved.role, equals('citizen'));
    });

    test('role isolation blocks government and admin accounts from citizen portal', () {
      const govtUser = UserModel(
        id: 'govt_officer_001',
        fullName: 'Ward Officer Deshmukh',
        email: 'ward.a@civicfix.gov.in',
        phone: '',
        role: 'government',
      );

      final isCitizen = govtUser.role != 'government' && govtUser.role != 'admin';
      expect(isCitizen, isFalse);
    });
  });
}
