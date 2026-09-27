import 'package:flutter/foundation.dart';
import '../models/govt_user_model.dart';
import 'government_account_validator.dart';

/// Distinct authentication lifecycle states for the Government Portal.
enum GovtAuthState {
  unauthenticated,
  authenticating,
  authenticated,
  authenticationError,
}

/// Result wrapper for government authentication actions.
class GovtAuthResult {
  final bool isSuccess;
  final GovtUserModel? user;
  final String? errorMessage;
  final String? successMessage;

  const GovtAuthResult.success([this.user, this.successMessage])
      : isSuccess = true,
        errorMessage = null;

  const GovtAuthResult.failure(this.errorMessage)
      : isSuccess = false,
        user = null,
        successMessage = null;
}

/// Abstract contract for Government Authentication.
abstract class GovtAuthService {
  Future<GovtUserModel?> getCurrentUser();
  GovtUserModel? get currentUser;
  bool get isAuthenticated;
  GovtAuthState get currentAuthState;
  ValueListenable<GovtUserModel?> get userListenable;
  ValueListenable<GovtAuthState> get authStateListenable;

  Future<GovtAuthResult> loginWithGovernmentId({
    required String governmentId,
    required String password,
  });

  Future<GovtAuthResult> login({
    required String emailOrEmployeeId,
    required String password,
    String? departmentId,
    bool rememberMe = false,
  });

  Future<GovtAuthResult> requestPasswordReset({required String email});

  Future<void> logout();
  Future<bool> checkAuthState();
  void switchDepartment(String departmentId, String departmentName);
  void updateUser(GovtUserModel updatedUser);
}

/// Test-isolated mock implementation of Government Authentication.
///
/// NOTE: In production runtime, [FirebaseGovtAuthService] is strictly used.
class MockGovtAuthService implements GovtAuthService {
  static final MockGovtAuthService _instance = MockGovtAuthService._internal();
  factory MockGovtAuthService() => _instance;

  MockGovtAuthService._internal() {
    _userNotifier = ValueNotifier<GovtUserModel?>(_defaultOfficer);
    _authStateNotifier = ValueNotifier<GovtAuthState>(GovtAuthState.authenticated);
  }

  // Canonical Mock Government Officer for testing (Government Officer with admin override permission)
  static const GovtUserModel _defaultOfficer = GovtUserModel(
    id: 'govt_off_001',
    fullName: 'Shreyas S. (Executive Officer)',
    email: 'officer@civicfix.gov.in',
    employeeId: 'MC-2026-ENG-842',
    phone: '+91 98765 43210',
    organization: 'Municipal Civic Administration',
    departmentId: 'dept_roads',
    departmentName: 'Roads & Infrastructure',
    designation: 'Senior Municipal Nodal Officer',
    role: 'government',
    assignedWard: 'Ward 14 (Central Zone)',
    permissions: [
      'admin_override',
      'view_complaints',
      'update_status',
      'assign_officer',
      'view_analytics',
      'view_hazard_map',
    ],
  );

  // Standard Test Fixtures across BMC Role Matrix
  static const GovtUserModel mockSuperAdmin = GovtUserModel(
    id: 'GOV-SA-001',
    fullName: 'Bhushan Gagrani, IAS',
    email: 'commissioner@mcgm.gov.in',
    employeeId: 'MUMHQ00001',
    role: 'government_super_admin',
    displayDesignation: 'Municipal Commissioner & Apex Super Admin',
    organization: 'Brihanmumbai Municipal Corporation',
    permissions: [
      'all',
      'view_complaints',
      'update_status',
      'assign_officer',
      'view_analytics',
    ],
  );

  static const GovtUserModel mockZonalDmc = GovtUserModel(
    id: 'GOV-DMC-Z04',
    fullName: 'Dr. Sudhir Patil',
    email: 'dmc.zone4@mcgm.gov.in',
    employeeId: 'GOV-DMC-Z04',
    role: 'zonal_dmc',
    zoneId: 'zone_04',
    displayDesignation: 'Deputy Municipal Commissioner (Zone 4)',
    organization: 'Brihanmumbai Municipal Corporation',
  );

  static const GovtUserModel mockCentralHod = GovtUserModel(
    id: 'GOV-HOD-SWM',
    fullName: 'Priya Shah',
    email: 'hod.swm@mcgm.gov.in',
    employeeId: 'GOV-HOD-SWM',
    role: 'central_department_hod',
    departmentId: 'dept_swm',
    departmentName: 'Solid Waste Management',
    displayDesignation: 'Chief Engineer (SWM)',
    organization: 'Brihanmumbai Municipal Corporation',
  );

  static const GovtUserModel mockWardOfficer = GovtUserModel(
    id: 'GOV-WO-W14',
    fullName: 'Amit Deshmukh',
    email: 'ac.ward14@mcgm.gov.in',
    employeeId: 'GOV-WO-W14',
    role: 'ward_officer',
    wardId: 'N',
    zoneId: 'zone_04',
    displayDesignation: 'Assistant Commissioner (N Ward)',
    organization: 'Brihanmumbai Municipal Corporation',
  );

  static const GovtUserModel mockWardLead = GovtUserModel(
    id: 'GOV-WDL-W14-RDS',
    fullName: 'Rajesh Kulkarni',
    email: 'lead.roads.ward14@mcgm.gov.in',
    employeeId: 'GOV-WDL-W14-RDS',
    role: 'ward_department_lead',
    wardId: 'N',
    zoneId: 'zone_04',
    departmentId: 'dept_roads',
    departmentName: 'Roads & Infrastructure',
    displayDesignation: 'Executive Engineer (Roads)',
    organization: 'Brihanmumbai Municipal Corporation',
  );

  static const GovtUserModel mockDepartmentCrew = GovtUserModel(
    id: 'GOV-CRW-W14-RDS-01',
    fullName: 'Rahul Patil',
    email: 'crew.roads.ward14@mcgm.gov.in',
    employeeId: 'GOV-CRW-W14-RDS-01',
    role: 'department_crew',
    wardId: 'N',
    zoneId: 'zone_04',
    departmentId: 'dept_roads',
    departmentName: 'Roads & Infrastructure',
    displayDesignation: 'Sub-Engineer & Ground Crew Lead',
    administrativeSupervisorId: 'GOV-WDL-W14-RDS',
    organization: 'Brihanmumbai Municipal Corporation',
  );

  static const GovtUserModel mockInactiveOfficer = GovtUserModel(
    id: 'GOV-INACTIVE-01',
    fullName: 'Inactive Officer',
    email: 'inactive@civicfix.gov.in',
    employeeId: 'GOV-INACTIVE',
    role: 'ward_officer',
    wardId: 'ward_14',
    active: false,
  );

  static const GovtUserModel mockMissingWardOfficer = GovtUserModel(
    id: 'GOV-BAD-WO-01',
    fullName: 'Incomplete Ward Officer',
    email: 'bad_wo@civicfix.gov.in',
    employeeId: 'GOV-BAD-WO',
    role: 'ward_officer',
    wardId: null,
  );

  static const GovtUserModel mockMissingDepartmentHod = GovtUserModel(
    id: 'GOV-BAD-HOD-01',
    fullName: 'Incomplete Central HOD',
    email: 'bad_hod@civicfix.gov.in',
    employeeId: 'GOV-BAD-HOD',
    role: 'central_department_hod',
    departmentId: null,
  );

  static const GovtUserModel mockMissingSupervisorCrew = GovtUserModel(
    id: 'GOV-BAD-CRW-01',
    fullName: 'Orphaned Crew',
    email: 'orphan_crew@civicfix.gov.in',
    employeeId: 'GOV-BAD-CRW',
    role: 'department_crew',
    wardId: 'ward_14',
    departmentId: 'dept_roads',
    administrativeSupervisorId: null,
    technicalSupervisorId: null,
  );

  late final ValueNotifier<GovtUserModel?> _userNotifier;
  late final ValueNotifier<GovtAuthState> _authStateNotifier;

  @override
  ValueListenable<GovtUserModel?> get userListenable => _userNotifier;

  @override
  ValueListenable<GovtAuthState> get authStateListenable => _authStateNotifier;

  @override
  GovtUserModel? get currentUser => _userNotifier.value;

  @override
  bool get isAuthenticated => _userNotifier.value != null;

  @override
  GovtAuthState get currentAuthState => _authStateNotifier.value;

  @override
  Future<GovtUserModel?> getCurrentUser() async {
    return _userNotifier.value;
  }

  @override
  Future<bool> checkAuthState() async {
    return _userNotifier.value != null;
  }

  @override
  Future<GovtAuthResult> loginWithGovernmentId({
    required String governmentId,
    required String password,
  }) async {
    return login(
      emailOrEmployeeId: governmentId,
      password: password,
    );
  }

  @override
  Future<GovtAuthResult> login({
    required String emailOrEmployeeId,
    required String password,
    String? departmentId,
    bool rememberMe = false,
  }) async {
    _authStateNotifier.value = GovtAuthState.authenticating;

    final rawInput = emailOrEmployeeId.trim();

    if (rawInput.isEmpty || password.isEmpty) {
      _authStateNotifier.value = GovtAuthState.authenticationError;
      return const GovtAuthResult.failure('Please enter your Government ID and password.');
    }

    final rawUpper = rawInput.toUpperCase();
    final trimmedInput = rawInput.toLowerCase();

    if (password == 'WrongPassword' ||
        password == 'wrongpassword' ||
        trimmedInput.contains('invalid') ||
        trimmedInput.contains('bad_officer')) {
      _authStateNotifier.value = GovtAuthState.authenticationError;
      return const GovtAuthResult.failure(
        'Invalid Government ID or password. Please verify your municipal credentials.',
      );
    }

    if (trimmedInput.contains('citizen')) {
      _authStateNotifier.value = GovtAuthState.authenticationError;
      return const GovtAuthResult.failure(
        'Access denied. This account does not possess authorized Municipal Government Officer credentials.',
      );
    }

    if (trimmedInput.contains('not_found') || trimmedInput.contains('missing_user')) {
      _authStateNotifier.value = GovtAuthState.authenticationError;
      return const GovtAuthResult.failure('Government profile could not be found.');
    }

    GovtUserModel candidate;
    if (rawUpper == 'MUMHQ00001' ||
        rawUpper == 'GOV-SA-001' ||
        trimmedInput.contains('super_admin')) {
      candidate = mockSuperAdmin;
    } else if (rawUpper == 'GOV-DMC-Z04' ||
        rawUpper == 'GOV-DMC-Z01' ||
        trimmedInput.contains('dmc')) {
      candidate = mockZonalDmc;
    } else if (rawUpper == 'GOV-HOD-SWM' ||
        rawUpper == 'GOV-HOD-RDS' ||
        trimmedInput.contains('hod')) {
      candidate = mockCentralHod;
    } else if (rawUpper == 'GOV-WO-W14' ||
        rawUpper == 'GOV-WO-W01' ||
        trimmedInput.contains('ward_officer') ||
        rawUpper.contains('GOV-WO')) {
      candidate = mockWardOfficer;
    } else if (rawUpper == 'GOV-WDL-W14-RDS' ||
        rawUpper == 'GOV-WDL-W01-RDS' ||
        trimmedInput.contains('wdl') ||
        trimmedInput.contains('lead')) {
      candidate = mockWardLead;
    } else if (rawUpper == 'GOV-CRW-W14-RDS-01' ||
        rawUpper == 'GOV-CRW-W01-RDS' ||
        trimmedInput.contains('crew')) {
      candidate = mockDepartmentCrew;
    } else if (rawUpper == 'GOV-INACTIVE' || trimmedInput.contains('inactive')) {
      candidate = mockInactiveOfficer;
    } else if (rawUpper == 'GOV-BAD-WO' || trimmedInput.contains('missing_ward')) {
      candidate = mockMissingWardOfficer;
    } else if (rawUpper == 'GOV-BAD-HOD' || trimmedInput.contains('missing_dept')) {
      candidate = mockMissingDepartmentHod;
    } else if (rawUpper == 'GOV-BAD-CRW' || trimmedInput.contains('missing_supervisor')) {
      candidate = mockMissingSupervisorCrew;
    } else {
      candidate = _defaultOfficer.copyWith(
        employeeId: rawUpper,
        email: trimmedInput.contains('@') ? trimmedInput : '$trimmedInput@civicfix.gov.in',
        departmentId: departmentId ?? _defaultOfficer.departmentId,
      );
    }

    // Account validation
    final validation = GovernmentAccountValidator.validate(candidate);
    if (!validation.isValid) {
      _authStateNotifier.value = GovtAuthState.authenticationError;
      return GovtAuthResult.failure(
        validation.message ?? 'Government account validation failed.',
      );
    }

    _userNotifier.value = candidate;
    _authStateNotifier.value = GovtAuthState.authenticated;
    return GovtAuthResult.success(candidate);
  }

  @override
  Future<GovtAuthResult> requestPasswordReset({required String email}) async {
    final trimmedEmail = email.trim().toLowerCase();

    if (trimmedEmail.isEmpty) {
      return const GovtAuthResult.failure('Please enter your official government email address.');
    }

    // Basic email format check
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      return const GovtAuthResult.failure('Please enter a valid government email address (e.g. officer@civicfix.gov.in).');
    }

    return GovtAuthResult.success(
      null,
      'A secure password reset link and authorization token have been sent to $trimmedEmail.',
    );
  }

  @override
  Future<void> logout() async {
    _authStateNotifier.value = GovtAuthState.authenticating;
    _userNotifier.value = null;
    _authStateNotifier.value = GovtAuthState.unauthenticated;
  }

  @override
  void switchDepartment(String departmentId, String departmentName) {
    if (_userNotifier.value != null) {
      _userNotifier.value = _userNotifier.value!.copyWith(
        departmentId: departmentId,
        departmentName: departmentName,
      );
    }
  }

  @override
  void updateUser(GovtUserModel updatedUser) {
    _userNotifier.value = updatedUser;
  }

  void resetForTesting({bool authenticated = true}) {
    _userNotifier.value = authenticated ? _defaultOfficer : null;
    _authStateNotifier.value = authenticated ? GovtAuthState.authenticated : GovtAuthState.unauthenticated;
  }

  void setCurrentUser(GovtUserModel? user) {
    _userNotifier.value = user;
    _authStateNotifier.value = user != null ? GovtAuthState.authenticated : GovtAuthState.unauthenticated;
  }
}
