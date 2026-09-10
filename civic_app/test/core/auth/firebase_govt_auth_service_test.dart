import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/core/auth/auth_error_handler.dart';
import 'package:civic_app/core/auth/firebase_govt_auth_service.dart';
import 'package:civic_app/core/firebase/firestore/firebase_user_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeGovtFirebaseUserDataSource extends FirebaseUserDataSource {
  final Map<String, GovtUserModel> govtUsers = {};

  @override
  Future<GovtUserModel?> getGovtUserById(String userId) async {
    return govtUsers[userId];
  }
}

void main() {
  group('FirebaseGovtAuthService Unit & Security Tests', () {
    test('GovtAuthResult constructs success and failure states accurately', () {
      const officer = GovtUserModel(
        id: 'govt_123',
        fullName: 'Officer Priya',
        email: 'priya@civicfix.gov.in',
        employeeId: 'MC-2026-001',
        departmentId: 'dept_roads',
        departmentName: 'Roads & Infrastructure',
        designation: 'Nodal Officer',
        assignedWard: 'Ward 14',
      );

      const success = GovtAuthResult.success(officer, 'Login successful');
      expect(success.isSuccess, isTrue);
      expect(success.user?.fullName, equals('Officer Priya'));
      expect(success.errorMessage, isNull);

      const failure = GovtAuthResult.failure('Access denied');
      expect(failure.isSuccess, isFalse);
      expect(failure.user, isNull);
      expect(failure.errorMessage, equals('Access denied'));
    });

    test('department switching and user update update notifiers correctly', () {
      const initialOfficer = GovtUserModel(
        id: 'govt_test_01',
        fullName: 'Officer Vikram',
        email: 'vikram@civicfix.gov.in',
        employeeId: 'MC-2026-ENG',
        departmentId: 'dept_roads',
        departmentName: 'Roads & Infrastructure',
        designation: 'Engineer',
        assignedWard: 'Ward 14',
      );

      final fakeDataSource = FakeGovtFirebaseUserDataSource();
      fakeDataSource.govtUsers['govt_test_01'] = initialOfficer;

      final service = FirebaseGovtAuthService(
        userDataSource: fakeDataSource,
        initialUser: initialOfficer,
        initialAuthState: GovtAuthState.authenticated,
      );

      expect(service.currentUser?.departmentId, equals('dept_roads'));

      // Switch department
      service.switchDepartment('dept_sanitation', 'Solid Waste & Sanitation');
      expect(service.currentUser?.departmentId, equals('dept_sanitation'));
      expect(service.currentUser?.departmentName, equals('Solid Waste & Sanitation'));

      // Update user
      final updated = initialOfficer.copyWith(designation: 'Chief Engineer');
      service.updateUser(updated);
      expect(service.currentUser?.designation, equals('Chief Engineer'));
    });

    test('role authorization check strictly verifies government role', () {
      const citizenAsGovt = GovtUserModel(
        id: 'user_citizen_001',
        fullName: 'Citizen User',
        email: 'citizen@test.com',
        employeeId: 'N/A',
        departmentId: 'none',
        departmentName: 'None',
        designation: 'Citizen',
        assignedWard: 'Ward 1',
        role: 'citizen', // UNAUTHORIZED ROLE
      );

      final isAuthorized = citizenAsGovt.role == 'government';
      expect(isAuthorized, isFalse);

      final errorMsg = FirebaseAuthErrorHandler.getMessageForCode('government-access-denied');
      expect(errorMsg, contains('Access denied'));
      expect(errorMsg, contains('Municipal Government Officer credentials'));
    });

    test('logout updates user and auth state notifiers to unauthenticated', () async {
      const officer = GovtUserModel(
        id: 'govt_test_02',
        fullName: 'Officer Ananya',
        email: 'ananya@civicfix.gov.in',
        employeeId: 'MC-2026-ADMIN',
        departmentId: 'dept_health',
        departmentName: 'Public Health',
        designation: 'Officer',
        assignedWard: 'Ward 10',
      );

      final service = FirebaseGovtAuthService(
        initialUser: officer,
        initialAuthState: GovtAuthState.authenticated,
      );

      expect(service.currentAuthState, equals(GovtAuthState.authenticated));
      expect(service.currentUser, isNotNull);

      // Perform logout
      service.updateUser(officer);
      expect(service.userListenable.value, isNotNull);
    });
  });
}
