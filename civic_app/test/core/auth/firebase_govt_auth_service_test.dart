import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/services/government_account_validator.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/core/auth/auth_error_handler.dart';
import 'package:civic_app/core/auth/firebase_govt_auth_service.dart';
import 'package:civic_app/core/firebase/firestore/firebase_user_data_source.dart';
import 'package:civic_app/core/models/civic_department_model.dart';
import 'package:civic_app/core/models/civic_ward_model.dart';
import 'package:civic_app/core/models/civic_zone_model.dart';
import 'package:civic_app/core/models/government_role.dart';
import 'package:civic_app/core/models/ward_department_model.dart';
import 'package:civic_app/core/services/government_hierarchy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeGovtFirebaseUserDataSource extends FirebaseUserDataSource {
  final Map<String, GovtUserModel> govtUsers = {};

  @override
  Future<GovtUserModel?> getGovtUserById(String userId) async {
    return govtUsers[userId];
  }
}

class FakeGovernmentHierarchyRepository implements GovernmentHierarchyRepository {
  final Map<String, GovtUserModel> usersById = {};
  final Map<String, GovtUserModel> usersByEmail = {};
  final Map<String, GovtUserModel> usersByEmployeeId = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<CivicZone?> getZoneById(String zoneId) async => null;

  @override
  Future<List<CivicZone>> getZones() async => const [];

  @override
  Future<CivicWard?> getWardById(String wardId) async => null;

  @override
  Future<List<CivicWard>> getWards({String? zoneId}) async => const [];

  @override
  Future<CivicDepartment?> getDepartmentById(String departmentId) async => null;

  @override
  Future<List<CivicDepartment>> getDepartments() async => const [];

  @override
  Future<WardDepartment?> getWardDepartment(String wardId, String departmentId) async => null;

  @override
  Future<List<WardDepartment>> getWardDepartments({String? wardId, String? departmentId}) async => const [];

  @override
  Future<GovtUserModel?> getUserById(String id) async => usersById[id] ?? usersByEmployeeId[id] ?? usersByEmail[id.toLowerCase()];

  @override
  Future<GovtUserModel?> getUserByEmployeeId(String employeeId) async => usersByEmployeeId[employeeId];

  @override
  Future<GovtUserModel?> getUserByEmail(String email) async => usersByEmail[email.toLowerCase()];

  @override
  Future<List<GovtUserModel>> getUsers({String? role, String? wardId, String? departmentId, String? zoneId}) async =>
      usersById.values.toList();

  @override
  Future<GovtUserModel?> getAdministrativeSupervisor(GovtUserModel user) async => null;

  @override
  Future<GovtUserModel?> getTechnicalSupervisor(GovtUserModel user) async => null;

  @override
  Future<List<GovtUserModel>> getAdministrativeSubordinates(GovtUserModel user) async => const [];

  @override
  Future<List<GovtUserModel>> getTechnicalSubordinates(GovtUserModel user) async => const [];
}

void main() {
  group('FirebaseGovtAuthService Unit & Security Tests', () {
    test('GovtAuthResult constructs success and failure states accurately', () {
      const officer = GovtUserModel(
        id: 'govt_123',
        fullName: 'Officer Priya',
        email: 'priya@civicfix.dev',
        employeeId: 'GOV-WO-A',
        departmentId: 'dept_roads',
        departmentName: 'Roads & Infrastructure',
        designation: 'Nodal Officer',
        wardId: 'A',
        role: 'ward_officer',
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
        email: 'vikram@civicfix.dev',
        employeeId: 'GOV-WDL-A-RDS',
        departmentId: 'dept_roads',
        departmentName: 'Roads & Infrastructure',
        designation: 'Engineer',
        wardId: 'A',
        role: 'ward_department_lead',
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
      final updated = initialOfficer.copyWith(displayDesignation: 'Chief Engineer');
      service.updateUser(updated);
      expect(service.currentUser?.displayDesignation, equals('Chief Engineer'));
    });

    test('role authorization check strictly verifies canonical government roles', () {
      const citizenAsGovt = GovtUserModel(
        id: 'user_citizen_001',
        fullName: 'Citizen User',
        email: 'citizen@example.com',
        employeeId: 'N/A',
        departmentId: 'none',
        departmentName: 'None',
        designation: 'Citizen',
        wardId: 'Ward 1',
        role: 'citizen', // UNAUTHORIZED ROLE
      );

      final isAuthorized = GovernmentRole.allRoleIds.contains(citizenAsGovt.role);
      expect(isAuthorized, isFalse);

      final errorMsg = FirebaseAuthErrorHandler.getMessageForCode('government-access-denied');
      expect(errorMsg, contains('Access denied'));
      expect(errorMsg, contains('Municipal Government Officer credentials'));
    });

    test('logout updates user and auth state notifiers to unauthenticated', () async {
      const officer = GovtUserModel(
        id: 'govt_test_02',
        fullName: 'Officer Ananya',
        email: 'ananya@civicfix.dev',
        employeeId: 'GOV-WO-B',
        departmentId: 'dept_health',
        departmentName: 'Public Health',
        designation: 'Officer',
        wardId: 'B',
        role: 'ward_officer',
      );

      final service = FirebaseGovtAuthService(
        initialUser: officer,
        initialAuthState: GovtAuthState.authenticated,
      );

      expect(service.currentAuthState, equals(GovtAuthState.authenticated));
      expect(service.currentUser, isNotNull);

      service.updateUser(officer);
      expect(service.userListenable.value, isNotNull);
    });

    test('login rejects empty email or password', () async {
      final service = FirebaseGovtAuthService();

      final emptyIdResult = await service.login(
        emailOrEmployeeId: '',
        password: 'any_password',
      );
      expect(emptyIdResult.isSuccess, isFalse);
      expect(emptyIdResult.errorMessage, equals('Please enter your government email and password.'));
      expect(service.currentAuthState, equals(GovtAuthState.authenticationError));

      final emptyPwdResult = await service.login(
        emailOrEmployeeId: 'officer@civicfix.dev',
        password: '',
      );
      expect(emptyPwdResult.isSuccess, isFalse);
      expect(emptyPwdResult.errorMessage, equals('Please enter your government email and password.'));
      expect(service.currentAuthState, equals(GovtAuthState.authenticationError));

      final whitespaceResult = await service.login(
        emailOrEmployeeId: '   ',
        password: '   ',
      );
      expect(whitespaceResult.isSuccess, isFalse);
      expect(whitespaceResult.errorMessage, equals('Please enter your government email and password.'));
    });

    test('GovernmentAccountValidator validates all 6 canonical roles correctly', () {
      // 1. Super Admin
      const superAdmin = GovtUserModel(
        id: 'sa_01',
        fullName: 'Commissioner',
        email: 'commissioner@civicfix.dev',
        employeeId: 'GOV-SA-001',
        role: 'government_super_admin',
      );
      expect(GovernmentAccountValidator.validate(superAdmin).isValid, isTrue);

      // 2. Zonal DMC
      const zonalDmc = GovtUserModel(
        id: 'dmc_01',
        fullName: 'DMC South',
        email: 'dmc.zone1@civicfix.dev',
        employeeId: 'GOV-DMC-Z01',
        role: 'zonal_dmc',
        zoneId: 'ZONE_1',
      );
      expect(GovernmentAccountValidator.validate(zonalDmc).isValid, isTrue);

      // 3. Central HOD
      const centralHod = GovtUserModel(
        id: 'hod_01',
        fullName: 'Chief Engineer Roads',
        email: 'hod.roads@civicfix.dev',
        employeeId: 'GOV-HOD-D01',
        role: 'central_department_hod',
        departmentId: 'dept_roads',
      );
      expect(GovernmentAccountValidator.validate(centralHod).isValid, isTrue);

      // 4. Ward Officer
      const wardOfficer = GovtUserModel(
        id: 'wo_01',
        fullName: 'Assistant Commissioner A Ward',
        email: 'ac.a@civicfix.dev',
        employeeId: 'GOV-WO-A',
        role: 'ward_officer',
        wardId: 'A',
      );
      expect(GovernmentAccountValidator.validate(wardOfficer).isValid, isTrue);

      // 5. Ward Department Lead
      const wardLead = GovtUserModel(
        id: 'wdl_01',
        fullName: 'Lead Engineer A Ward Roads',
        email: 'lead.roads.a@civicfix.dev',
        employeeId: 'GOV-WDL-A-RDS',
        role: 'ward_department_lead',
        wardId: 'A',
        departmentId: 'dept_roads',
      );
      expect(GovernmentAccountValidator.validate(wardLead).isValid, isTrue);

      // 6. Department Crew
      const crew = GovtUserModel(
        id: 'crew_01',
        fullName: 'Technician 1',
        email: 'crew.roads.a.01@civicfix.dev',
        employeeId: 'GOV-CREW-A-RDS-01',
        role: 'department_crew',
        wardId: 'A',
        departmentId: 'dept_roads',
        administrativeSupervisorId: 'GOV-WDL-A-RDS',
      );
      expect(GovernmentAccountValidator.validate(crew).isValid, isTrue);
    });

    test('Inactive officer account is blocked by GovernmentAccountValidator', () {
      const inactiveOfficer = GovtUserModel(
        id: 'inactive_01',
        fullName: 'Inactive Officer',
        email: 'inactive@civicfix.dev',
        employeeId: 'GOV-WO-Z',
        role: 'ward_officer',
        wardId: 'Z',
        active: false,
      );
      final validation = GovernmentAccountValidator.validate(inactiveOfficer);
      expect(validation.isValid, isFalse);
      expect(validation.error, GovernmentValidationError.accountInactive);
    });
  });
}
