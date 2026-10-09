import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/civic_department_model.dart';
import '../models/civic_ward_model.dart';
import '../models/civic_zone_model.dart';
import '../models/ward_department_model.dart';
import '../../Govt UI/models/govt_user_model.dart';

/// BMC Government Hierarchy Repository.
///
/// Provides access to the 7 Zones, 24 Wards, 18 Departments, 432 Ward-Department units,
/// and 2,642 Government Personnel with dual-chain (Administrative + Technical) traversal.
abstract class GovernmentHierarchyRepository {
  Future<void> initialize();

  // Primary Entities
  Future<List<CivicZone>> getZones();
  Future<CivicZone?> getZoneById(String zoneId);

  Future<List<CivicWard>> getWards({String? zoneId});
  Future<CivicWard?> getWardById(String wardId);

  Future<List<CivicDepartment>> getDepartments();
  Future<CivicDepartment?> getDepartmentById(String departmentId);

  Future<List<WardDepartment>> getWardDepartments({String? wardId, String? departmentId});
  Future<WardDepartment?> getWardDepartment(String wardId, String departmentId);

  // Personnel Lookups
  Future<List<GovtUserModel>> getUsers({
    String? role,
    String? wardId,
    String? departmentId,
    String? zoneId,
  });
  Future<GovtUserModel?> getUserById(String id);
  Future<GovtUserModel?> getUserByEmployeeId(String employeeId);
  Future<GovtUserModel?> getUserByEmail(String email);

  // Dual-Hierarchy Traversal
  Future<GovtUserModel?> getAdministrativeSupervisor(GovtUserModel user);
  Future<GovtUserModel?> getTechnicalSupervisor(GovtUserModel user);
  Future<List<GovtUserModel>> getAdministrativeSubordinates(GovtUserModel user);
  Future<List<GovtUserModel>> getTechnicalSubordinates(GovtUserModel user);
}

/// In-memory and local asset-backed implementation of [GovernmentHierarchyRepository].
class LocalGovernmentHierarchyRepository implements GovernmentHierarchyRepository {
  static final LocalGovernmentHierarchyRepository _instance =
      LocalGovernmentHierarchyRepository._internal();
  factory LocalGovernmentHierarchyRepository() => _instance;
  LocalGovernmentHierarchyRepository._internal();

  bool _initialized = false;
  final List<CivicZone> _zones = [];
  final List<CivicWard> _wards = [];
  final List<CivicDepartment> _departments = [];
  final List<WardDepartment> _wardDepartments = [];
  final List<GovtUserModel> _users = [];

  final Map<String, CivicZone> _zonesById = {};
  final Map<String, CivicWard> _wardsById = {};
  final Map<String, CivicDepartment> _departmentsById = {};
  final Map<String, WardDepartment> _wardDepartmentsByKey = {}; // "wardId:departmentId"
  final Map<String, GovtUserModel> _usersById = {};
  final Map<String, GovtUserModel> _usersByEmployeeId = {};
  final Map<String, GovtUserModel> _usersByEmail = {};

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Load from disk / assets
    String? zonesJson = await _loadJsonContent('zones.json');
    String? wardsJson = await _loadJsonContent('wards.json');
    String? deptsJson = await _loadJsonContent('departments.json');
    String? wardDeptsJson = await _loadJsonContent('ward_departments.json');
    String? usersJson = await _loadJsonContent('government_users.json');

    if (zonesJson != null) {
      final decoded = jsonDecode(zonesJson) as Map<String, dynamic>;
      final list = decoded['zones'] as List<dynamic>? ?? [];
      for (final item in list) {
        final zone = CivicZone.fromJson(Map<String, dynamic>.from(item as Map));
        _zones.add(zone);
        _zonesById[zone.zoneId] = zone;
      }
    }

    if (wardsJson != null) {
      final decoded = jsonDecode(wardsJson) as Map<String, dynamic>;
      final list = decoded['wards'] as List<dynamic>? ?? [];
      for (final item in list) {
        final ward = CivicWard.fromJson(Map<String, dynamic>.from(item as Map));
        _wards.add(ward);
        _wardsById[ward.wardId] = ward;
      }
    }

    if (deptsJson != null) {
      final decoded = jsonDecode(deptsJson) as Map<String, dynamic>;
      final list = decoded['departments'] as List<dynamic>? ?? [];
      for (final item in list) {
        final dept = CivicDepartment.fromJson(Map<String, dynamic>.from(item as Map));
        _departments.add(dept);
        _departmentsById[dept.departmentId] = dept;
      }
    }

    if (wardDeptsJson != null) {
      final decoded = jsonDecode(wardDeptsJson) as Map<String, dynamic>;
      final list = decoded['wardDepartments'] as List<dynamic>? ?? [];
      for (final item in list) {
        final wd = WardDepartment.fromJson(Map<String, dynamic>.from(item as Map));
        _wardDepartments.add(wd);
        _wardDepartmentsByKey['${wd.wardId}:${wd.departmentId}'] = wd;
      }
    }

    if (usersJson != null) {
      final decoded = jsonDecode(usersJson) as Map<String, dynamic>;
      final list = decoded['governmentUsers'] as List<dynamic>? ?? [];
      for (final item in list) {
        final map = Map<String, dynamic>.from(item as Map);
        final u = GovtUserModel.fromJson(map);
        _users.add(u);
        if (u.id.isNotEmpty) {
          _usersById[u.id] = u;
        }
        final rawUserId = map['userId'] as String?;
        if (rawUserId != null && rawUserId.isNotEmpty) {
          _usersById[rawUserId] = u;
        }
        if (u.employeeId.isNotEmpty) {
          _usersByEmployeeId[u.employeeId] = u;
          _usersByEmployeeId[u.employeeId.toUpperCase()] = u;
          _usersById[u.employeeId] = u;
        }
        if (u.email.isNotEmpty) {
          _usersByEmail[u.email.toLowerCase()] = u;
        }
      }
    }

    _initialized = true;
  }

  /// Manually seeds data (useful in testing environments).
  void seedData({
    List<CivicZone>? zones,
    List<CivicWard>? wards,
    List<CivicDepartment>? departments,
    List<WardDepartment>? wardDepartments,
    List<GovtUserModel>? users,
  }) {
    if (zones != null) {
      _zones.clear();
      _zonesById.clear();
      for (final z in zones) {
        _zones.add(z);
        _zonesById[z.zoneId] = z;
      }
    }
    if (wards != null) {
      _wards.clear();
      _wardsById.clear();
      for (final w in wards) {
        _wards.add(w);
        _wardsById[w.wardId] = w;
      }
    }
    if (departments != null) {
      _departments.clear();
      _departmentsById.clear();
      for (final d in departments) {
        _departments.add(d);
        _departmentsById[d.departmentId] = d;
      }
    }
    if (wardDepartments != null) {
      _wardDepartments.clear();
      _wardDepartmentsByKey.clear();
      for (final wd in wardDepartments) {
        _wardDepartments.add(wd);
        _wardDepartmentsByKey['${wd.wardId}:${wd.departmentId}'] = wd;
      }
    }
    if (users != null) {
      _users.clear();
      _usersById.clear();
      _usersByEmployeeId.clear();
      _usersByEmail.clear();
      for (final u in users) {
        _users.add(u);
        if (u.id.isNotEmpty) _usersById[u.id] = u;
        if (u.employeeId.isNotEmpty) {
          _usersByEmployeeId[u.employeeId] = u;
          _usersById[u.employeeId] = u;
        }
        if (u.email.isNotEmpty) {
          _usersByEmail[u.email.toLowerCase()] = u;
        }
      }
    }
    _initialized = true;
  }

  Future<String?> _loadJsonContent(String fileName) async {
    // 1. Try Flutter AssetBundle first (works across Web, Android, iOS, and Desktop in app runtime)
    try {
      return await rootBundle.loadString('assets/govt_data/$fileName');
    } catch (_) {}

    // 2. Try file system directly (for CLI / headless tests where rootBundle is unavailable)
    if (!kIsWeb) {
      final candidatePaths = [
        'assets/govt_data/$fileName',
        'civic_app/assets/govt_data/$fileName',
        'resources/Govt Data/$fileName',
        '../resources/Govt Data/$fileName',
        '../../resources/Govt Data/$fileName',
      ];

      for (final p in candidatePaths) {
        try {
          final f = File(p);
          if (f.existsSync()) {
            return await f.readAsString();
          }
        } catch (_) {}
      }
    }

    return null;
  }

  @override
  Future<List<CivicZone>> getZones() async {
    await initialize();
    return List.unmodifiable(_zones);
  }

  @override
  Future<CivicZone?> getZoneById(String zoneId) async {
    await initialize();
    return _zonesById[zoneId];
  }

  @override
  Future<List<CivicWard>> getWards({String? zoneId}) async {
    await initialize();
    if (zoneId != null) {
      return _wards.where((w) => w.zoneId == zoneId).toList();
    }
    return List.unmodifiable(_wards);
  }

  @override
  Future<CivicWard?> getWardById(String wardId) async {
    await initialize();
    return _wardsById[wardId];
  }

  @override
  Future<List<CivicDepartment>> getDepartments() async {
    await initialize();
    return List.unmodifiable(_departments);
  }

  @override
  Future<CivicDepartment?> getDepartmentById(String departmentId) async {
    await initialize();
    return _departmentsById[departmentId];
  }

  @override
  Future<List<WardDepartment>> getWardDepartments({String? wardId, String? departmentId}) async {
    await initialize();
    var list = _wardDepartments;
    if (wardId != null) {
      list = list.where((wd) => wd.wardId == wardId).toList();
    }
    if (departmentId != null) {
      list = list.where((wd) => wd.departmentId == departmentId).toList();
    }
    return List.unmodifiable(list);
  }

  @override
  Future<WardDepartment?> getWardDepartment(String wardId, String departmentId) async {
    await initialize();
    return _wardDepartmentsByKey['$wardId:$departmentId'];
  }

  @override
  Future<List<GovtUserModel>> getUsers({
    String? role,
    String? wardId,
    String? departmentId,
    String? zoneId,
  }) async {
    await initialize();
    var list = _users;
    if (role != null) {
      list = list.where((u) => u.role == role).toList();
    }
    if (wardId != null) {
      list = list.where((u) => u.wardId == wardId).toList();
    }
    if (departmentId != null) {
      list = list.where((u) => u.departmentId == departmentId).toList();
    }
    if (zoneId != null) {
      list = list.where((u) => u.zoneId == zoneId).toList();
    }
    return List.unmodifiable(list);
  }

  @override
  Future<GovtUserModel?> getUserById(String id) async {
    await initialize();
    return _usersById[id] ?? _usersByEmployeeId[id] ?? _usersByEmail[id.toLowerCase()];
  }

  @override
  Future<GovtUserModel?> getUserByEmployeeId(String employeeId) async {
    await initialize();
    return _usersByEmployeeId[employeeId] ?? _usersByEmployeeId[employeeId.toUpperCase()];
  }

  @override
  Future<GovtUserModel?> getUserByEmail(String email) async {
    await initialize();
    return _usersByEmail[email.trim().toLowerCase()];
  }

  @override
  Future<GovtUserModel?> getAdministrativeSupervisor(GovtUserModel user) async {
    await initialize();
    final supId = user.administrativeSupervisorId;
    if (supId == null || supId.isEmpty) return null;
    return _usersByEmployeeId[supId] ?? _usersById[supId];
  }

  @override
  Future<GovtUserModel?> getTechnicalSupervisor(GovtUserModel user) async {
    await initialize();
    final supId = user.technicalSupervisorId;
    if (supId == null || supId.isEmpty) return null;
    return _usersByEmployeeId[supId] ?? _usersById[supId];
  }

  @override
  Future<List<GovtUserModel>> getAdministrativeSubordinates(GovtUserModel user) async {
    await initialize();
    return _users.where((u) => u.administrativeSupervisorId == user.employeeId).toList();
  }

  @override
  Future<List<GovtUserModel>> getTechnicalSubordinates(GovtUserModel user) async {
    await initialize();
    return _users.where((u) => u.technicalSupervisorId == user.employeeId).toList();
  }
}
