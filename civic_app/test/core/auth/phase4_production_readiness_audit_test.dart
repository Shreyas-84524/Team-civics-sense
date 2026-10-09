import 'package:flutter_test/flutter_test.dart';
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

class MockAuditHierarchyRepository implements GovernmentHierarchyRepository {
  final Map<String, GovtUserModel> usersByUid = {};
  final Map<String, GovtUserModel> usersByEmployeeId = {};
  final Map<String, GovtUserModel> usersByEmail = {};

  void seedUser(GovtUserModel user) {
    usersByUid[user.id] = user;
    if (user.employeeId.isNotEmpty) {
      usersByEmployeeId[user.employeeId] = user;
    }
    usersByEmail[user.email.toLowerCase()] = user;
  }

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
  Future<GovtUserModel?> getUserById(String id) async =>
      usersByUid[id] ?? usersByEmployeeId[id] ?? usersByEmail[id.toLowerCase()];

  @override
  Future<GovtUserModel?> getUserByEmployeeId(String employeeId) async => usersByEmployeeId[employeeId];

  @override
  Future<GovtUserModel?> getUserByEmail(String email) async => usersByEmail[email.toLowerCase()];

  @override
  Future<List<GovtUserModel>> getUsers({String? role, String? wardId, String? departmentId, String? zoneId}) async =>
      usersByUid.values.toList();

  @override
  Future<GovtUserModel?> getAdministrativeSupervisor(GovtUserModel user) async => null;

  @override
  Future<GovtUserModel?> getTechnicalSupervisor(GovtUserModel user) async => null;

  @override
  Future<List<GovtUserModel>> getAdministrativeSubordinates(GovtUserModel user) async => const [];

  @override
  Future<List<GovtUserModel>> getTechnicalSubordinates(GovtUserModel user) async => const [];
}

class MockAuditFirebaseUserDataSource extends FirebaseUserDataSource {
  final Map<String, GovtUserModel> firestoreUsers = {};

  @override
  Future<GovtUserModel?> getGovtUserById(String userId) async {
    return firestoreUsers[userId];
  }
}

void main() {
  group('Phase 4: Government Authentication, Authorization & Production Readiness Audit', () {
    late MockAuditHierarchyRepository hierarchyRepo;
    late MockAuditFirebaseUserDataSource userDataSource;

    setUp(() {
      hierarchyRepo = MockAuditHierarchyRepository();
      userDataSource = MockAuditFirebaseUserDataSource();
    });

    // -------------------------------------------------------------------------
    // Audit Section 1: Canonical Roles & Account Validation Matrix
    // -------------------------------------------------------------------------
    group('Audit Section 1: Canonical Roles & Account Validation Matrix', () {
      test('1.1 Super Admin passes strict validation with citywide scope', () {
        const superAdmin = GovtUserModel(
          id: '0MbBnluLmuVnUVsG73JIgbOwSPB3',
          employeeId: 'GOV-SA-001',
          fullName: 'Dr. Bhushan Gagrani, IAS',
          email: 'commissioner@civicfix.dev',
          role: 'government_super_admin',
          displayDesignation: 'Municipal Commissioner & Administrator',
          active: true,
        );
        hierarchyRepo.seedUser(superAdmin);

        final val = GovernmentAccountValidator.validate(superAdmin);
        expect(val.isValid, isTrue);
        expect(superAdmin.role, equals(GovernmentRole.superAdminId));
        expect(superAdmin.isSuperAdmin, isTrue);
      });

      test('1.2 Zonal DMC requires zone assignment and passes validation', () {
        const zonalDmc = GovtUserModel(
          id: '5uHBytBB8HaFpqDgusDalIiUUE62',
          employeeId: 'GOV-DMC-Z01',
          fullName: 'DMC Arun Deshmukh',
          email: 'dmc.zone1@civicfix.dev',
          role: 'zonal_dmc',
          zoneId: 'ZONE_1',
          active: true,
        );
        hierarchyRepo.seedUser(zonalDmc);

        final val = GovernmentAccountValidator.validate(zonalDmc);
        expect(val.isValid, isTrue);
        expect(zonalDmc.isZonalDmc, isTrue);

        // Negative check: DMC missing zone
        final invalidDmc = zonalDmc.copyWith(zoneId: '');
        final invalidVal = GovernmentAccountValidator.validate(invalidDmc);
        expect(invalidVal.isValid, isFalse);
        expect(invalidVal.error, equals(GovernmentValidationError.missingZone));
      });

      test('1.3 Central HOD requires department assignment and passes validation', () {
        const centralHod = GovtUserModel(
          id: 'vp29AlnYPKXYZHimHiiZLaK1YK33',
          employeeId: 'GOV-HOD-MAINTENANCE_ROADS',
          fullName: 'Chief Eng. Karan Deshmukh',
          email: 'hod.rds@civicfix.dev',
          role: 'central_department_hod',
          departmentId: 'maintenance_roads',
          active: true,
        );
        hierarchyRepo.seedUser(centralHod);

        final val = GovernmentAccountValidator.validate(centralHod);
        expect(val.isValid, isTrue);
        expect(centralHod.isCentralHod, isTrue);

        // Negative check: HOD missing department
        final invalidHod = centralHod.copyWith(departmentId: '');
        final invalidVal = GovernmentAccountValidator.validate(invalidHod);
        expect(invalidVal.isValid, isFalse);
        expect(invalidVal.error, equals(GovernmentValidationError.missingDepartment));
      });

      test('1.4 Ward Officer requires ward assignment and passes validation', () {
        const wardOfficer = GovtUserModel(
          id: 'AF0SbsVQSGcT0lxUcgNwng792tV2',
          employeeId: 'GOV-WO-A',
          fullName: 'AMC Ajay Deshmukh',
          email: 'ward.a@civicfix.dev',
          role: 'ward_officer',
          wardId: 'A',
          active: true,
        );
        hierarchyRepo.seedUser(wardOfficer);

        final val = GovernmentAccountValidator.validate(wardOfficer);
        expect(val.isValid, isTrue);
        expect(wardOfficer.isWardOfficer, isTrue);

        // Negative check: Ward Officer missing ward
        final invalidWo = wardOfficer.copyWith(wardId: '');
        final invalidVal = GovernmentAccountValidator.validate(invalidWo);
        expect(invalidVal.isValid, isFalse);
        expect(invalidVal.error, equals(GovernmentValidationError.missingWard));
      });

      test('1.5 Ward Department Lead requires both ward and department assignments', () {
        const wardLead = GovtUserModel(
          id: '9S91EYhamcPFrsZ086e0AdhH4Wp2',
          employeeId: 'GOV-WDL-A-MAINTENANCE_ROADS',
          fullName: 'Nitin Patel',
          email: 'lead.a.rds@civicfix.dev',
          role: 'ward_department_lead',
          wardId: 'A',
          departmentId: 'maintenance_roads',
          active: true,
        );
        hierarchyRepo.seedUser(wardLead);

        final val = GovernmentAccountValidator.validate(wardLead);
        expect(val.isValid, isTrue);
        expect(wardLead.isWardLead, isTrue);

        // Missing ward
        final missingWard = wardLead.copyWith(wardId: '');
        expect(GovernmentAccountValidator.validate(missingWard).isValid, isFalse);

        // Missing dept
        final missingDept = wardLead.copyWith(departmentId: '');
        expect(GovernmentAccountValidator.validate(missingDept).isValid, isFalse);
      });

      test('1.6 Department Crew requires ward, department, and supervisor assignments', () {
        const crew = GovtUserModel(
          id: '8bEQGn8u92evkzMCOp6RK1oBiYt2',
          employeeId: 'GOV-CREW-A-MAINTENANCE_ROADS-01',
          fullName: 'Deepak Patel',
          email: 'crew.a.rds.01@civicfix.dev',
          role: 'department_crew',
          wardId: 'A',
          departmentId: 'maintenance_roads',
          administrativeSupervisorId: 'GOV-WDL-A-MAINTENANCE_ROADS',
          active: true,
        );
        hierarchyRepo.seedUser(crew);

        final val = GovernmentAccountValidator.validate(crew);
        expect(val.isValid, isTrue);
        expect(crew.isCrew, isTrue);

        // Missing supervisor
        final missingSupervisor = crew.copyWith(administrativeSupervisorId: '', technicalSupervisorId: '');
        expect(GovernmentAccountValidator.validate(missingSupervisor).isValid, isFalse);
        expect(GovernmentAccountValidator.validate(missingSupervisor).error, equals(GovernmentValidationError.missingSupervisor));
      });
    });

    // -------------------------------------------------------------------------
    // Audit Section 2: Multi-Key Indexing & Repository Lookups
    // -------------------------------------------------------------------------
    group('Audit Section 2: Multi-Key Indexing & Fast Retrieval', () {
      test('2.1 Repository retrieves officer accurately across UID, employeeId, email', () async {
        const officer = GovtUserModel(
          id: 'uid_test_alpha',
          employeeId: 'GOV-WO-M_EAST',
          fullName: 'Assistant Commissioner ME',
          email: 'ac.me@civicfix.dev',
          role: 'ward_officer',
          wardId: 'M_EAST',
          active: true,
        );
        hierarchyRepo.seedUser(officer);

        // By UID
        final byUid = await hierarchyRepo.getUserById('uid_test_alpha');
        expect(byUid?.fullName, equals('Assistant Commissioner ME'));

        // By EmployeeId
        final byEmp = await hierarchyRepo.getUserByEmployeeId('GOV-WO-M_EAST');
        expect(byEmp?.email, equals('ac.me@civicfix.dev'));

        // By Normalized Email
        final byEmail = await hierarchyRepo.getUserByEmail('AC.ME@CIVICFIX.DEV');
        expect(byEmail?.id, equals('uid_test_alpha'));
      });
    });

    // -------------------------------------------------------------------------
    // Audit Section 3: Fail-Closed Security & Negative Edge Cases
    // -------------------------------------------------------------------------
    group('Audit Section 3: Fail-Closed Security & Negative Edge Cases', () {
      test('3.1 Inactive account is rejected by validator with accountInactive error', () {
        const inactiveOfficer = GovtUserModel(
          id: 'uid_inactive_01',
          fullName: 'Suspended Officer',
          email: 'suspended@civicfix.dev',
          employeeId: 'GOV-WO-Z',
          role: 'ward_officer',
          wardId: 'A',
          active: false,
        );
        final val = GovernmentAccountValidator.validate(inactiveOfficer);
        expect(val.isValid, isFalse);
        expect(val.error, equals(GovernmentValidationError.accountInactive));
      });

      test('3.2 Non-canonical role check identifies unauthorized user', () {
        final isAuthorized = GovernmentRole.allRoleIds.contains('citizen');
        expect(isAuthorized, isFalse);
      });

      test('3.3 Empty email or password fails immediately before network/auth call', () async {
        final service = FirebaseGovtAuthService(
          hierarchyRepository: hierarchyRepo,
          userDataSource: userDataSource,
        );

        final resEmpty = await service.login(emailOrEmployeeId: '', password: '');
        expect(resEmpty.isSuccess, isFalse);
        expect(resEmpty.errorMessage, equals('Please enter your government email and password.'));
        expect(service.currentAuthState, equals(GovtAuthState.authenticationError));
      });
    });

    // -------------------------------------------------------------------------
    // Audit Section 4: Session Lifecycle & State Notifications
    // -------------------------------------------------------------------------
    group('Audit Section 4: Session Lifecycle & State Notifications', () {
      test('4.1 Department switching updates currentUser and preserves auth state', () {
        const officer = GovtUserModel(
          id: 'uid_lead_01',
          fullName: 'Lead Engineer',
          email: 'lead.roads@civicfix.dev',
          employeeId: 'GOV-WDL-A-MAINTENANCE_ROADS',
          role: 'ward_department_lead',
          wardId: 'A',
          departmentId: 'maintenance_roads',
          departmentName: 'Roads & Infrastructure',
          active: true,
        );

        final service = FirebaseGovtAuthService(
          hierarchyRepository: hierarchyRepo,
          userDataSource: userDataSource,
          initialUser: officer,
          initialAuthState: GovtAuthState.authenticated,
        );

        expect(service.isAuthenticated, isTrue);
        expect(service.currentUser?.departmentId, equals('maintenance_roads'));

        service.switchDepartment('solid_waste', 'Solid Waste Management');
        expect(service.currentUser?.departmentId, equals('solid_waste'));
        expect(service.currentUser?.departmentName, equals('Solid Waste Management'));
        expect(service.isAuthenticated, isTrue);
      });

      test('4.2 User update updates userNotifier value correctly', () {
        const officer = GovtUserModel(
          id: 'uid_crew_01',
          fullName: 'Field Worker',
          email: 'worker@civicfix.dev',
          employeeId: 'GOV-CREW-A-MAINTENANCE_ROADS-01',
          role: 'department_crew',
          wardId: 'A',
          departmentId: 'maintenance_roads',
          active: true,
        );

        final service = FirebaseGovtAuthService(
          initialUser: officer,
          initialAuthState: GovtAuthState.authenticated,
        );

        final updated = officer.copyWith(displayDesignation: 'Senior Technician');
        service.updateUser(updated);
        expect(service.currentUser?.displayDesignation, equals('Senior Technician'));
      });

      test('4.3 Logout resets user state and notifies unauthenticated', () async {
        const officer = GovtUserModel(
          id: 'uid_logout_01',
          fullName: 'Logging Out Officer',
          email: 'officer.logout@civicfix.dev',
          employeeId: 'GOV-WO-A',
          role: 'ward_officer',
          wardId: 'A',
          active: true,
        );

        final service = FirebaseGovtAuthService(
          initialUser: officer,
          initialAuthState: GovtAuthState.authenticated,
        );

        expect(service.isAuthenticated, isTrue);
        await service.logout();
        expect(service.currentUser, isNull);
        expect(service.currentAuthState, equals(GovtAuthState.unauthenticated));
      });
    });

    // -------------------------------------------------------------------------
    // Audit Section 5: Citizen vs Government Isolation & Quality Gates
    // -------------------------------------------------------------------------
    group('Audit Section 5: Citizen vs Government Isolation', () {
      test('5.1 Government auth error handler maps security codes cleanly', () {
        final accessDeniedMsg = FirebaseAuthErrorHandler.getMessageForCode('government-access-denied');
        expect(accessDeniedMsg, contains('Municipal Government Officer credentials'));

        final wrongPasswordMsg = FirebaseAuthErrorHandler.getMessageForCode('wrong-password');
        expect(wrongPasswordMsg, contains('Incorrect email or password'));

        final userNotFoundMsg = FirebaseAuthErrorHandler.getMessageForCode('user-not-found');
        expect(userNotFoundMsg, contains('Incorrect email or password'));
      });
    });
  });
}
