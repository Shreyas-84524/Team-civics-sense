import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../map/basemap_mode.dart';
import '../../models/category_model.dart';
import '../../models/civic_department_model.dart';
import '../../models/complaint_model.dart';
import '../../models/complaint_routing_ticket_model.dart';
import '../../models/government_role.dart';
import '../../models/notification_model.dart';
import '../../models/reward_model.dart';

/// Architecture Pillar 2: Canonical Backend Values to Localized Display Mappers.
///
/// HARD ARCHITECTURAL INVARIANTS:
/// 1. Canonical backend values (e.g. 'inProgress', 'department_crew', 'ward_department_lead',
///    'waterLeakage', 'underVerification') MUST REMAIN language-independent ASCII/canonical tokens.
/// 2. Firestore document fields, database columns, and backend schemas MUST NEVER store
///    localized or translated strings (e.g. never write Hindi or Marathi display labels to Firestore).
/// 3. User-generated text (complaint titles, descriptions, officer remarks, instructions) is
///    authoritative and immutable and MUST NOT be translated by these mappers.
/// 4. These mapper functions convert canonical backend entities/enums/IDs into display presentation
///    strings at the UI boundary.
/// 5. All 17 canonical domains support English ('en'), Hindi ('hi'), and Marathi ('mr') via [AppLocalizations].
/// 6. Unknown tokens safely fallback to clean Title Case formatting with debug telemetry in [kDebugMode],
///    guaranteeing zero runtime exceptions.

/// Internal safe title formatting and telemetry logger for unmapped canonical tokens.
String _safeFallback(String rawToken, String domain, [String? defaultLabel]) {
  final token = rawToken.trim();
  if (token.isEmpty) {
    return defaultLabel ?? domain;
  }

  if (kDebugMode) {
    debugPrint('[CanonicalMapper] Unmapped canonical token in domain "$domain": "$token"');
  }

  // Convert camelCase, snake_case, and kebab-case into Title Case
  final withSpaces = token
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ')
      .replaceAll('-', ' ');

  final words = withSpaces.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isNotEmpty) {
    return words.map((w) {
      if (w.length <= 1) return w.toUpperCase();
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).join(' ');
  }

  return defaultLabel ?? domain;
}

String _normalizeCanonicalToken(String raw) {
  return raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

// ============================================================================
// 1. COMPLAINT STATUS MAPPER
// ============================================================================

/// Maps a canonical [ComplaintStatus] or status string to its localized display string.
String localizedComplaintStatus(
  dynamic statusOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  String raw = '';
  if (statusOrId is ComplaintStatus) {
    raw = statusOrId.name;
  } else if (statusOrId is String) {
    raw = statusOrId.trim();
  } else if (statusOrId != null) {
    raw = statusOrId.toString();
  }

  final normalized = _normalizeCanonicalToken(raw);

  if (localizations == null) {
    switch (normalized) {
      case 'underverification':
      case 'under_verification':
        return 'Under Verification';
      case 'reported':
      case 'submitted':
        return 'Reported';
      case 'verified':
      case 'underreview':
      case 'under_review':
        return 'Verified';
      case 'assigned':
        return 'Assigned';
      case 'inprogress':
      case 'in_progress':
      case 'work_in_progress':
        return 'Work In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      case 'rejected':
        return 'Rejected';
      case 'reopened':
      case 'rework':
        return 'Rework / In Progress';
      default:
        return _safeFallback(raw, 'ComplaintStatus', 'Under Verification');
    }
  }

  switch (normalized) {
    case 'underverification':
    case 'under_verification':
      return localizations.statusUnderVerification;
    case 'reported':
    case 'submitted':
      return localizations.statusReported;
    case 'verified':
    case 'underreview':
    case 'under_review':
      return localizations.statusVerified;
    case 'assigned':
      return localizations.statusAssigned;
    case 'inprogress':
    case 'in_progress':
    case 'work_in_progress':
      return localizations.statusInProgress;
    case 'resolved':
      return localizations.statusResolved;
    case 'closed':
      return localizations.statusClosed;
    case 'rejected':
      return localizations.statusRejected;
    case 'reopened':
    case 'rework':
      return localizations.statusReopened;
    default:
      return _safeFallback(raw, 'ComplaintStatus', localizations.statusUnderVerification);
  }
}

// ============================================================================
// 2. COMPLAINT PRIORITY MAPPER
// ============================================================================

/// Maps a canonical [ComplaintPriority] or priority string to its localized display label.
String localizedComplaintPriority(
  dynamic priorityOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  String raw = '';
  if (priorityOrId is ComplaintPriority) {
    raw = priorityOrId.name;
  } else if (priorityOrId is String) {
    raw = priorityOrId.trim();
  } else if (priorityOrId != null) {
    raw = priorityOrId.toString();
  }

  final normalized = _normalizeCanonicalToken(raw);

  if (localizations == null) {
    switch (normalized) {
      case 'low':
        return 'Low';
      case 'medium':
      case 'normal':
        return 'Medium';
      case 'high':
        return 'High';
      case 'emergency':
      case 'critical':
      case 'urgent':
        return 'Critical';
      default:
        return _safeFallback(raw, 'ComplaintPriority', 'Medium');
    }
  }

  switch (normalized) {
    case 'low':
      return localizations.priorityLow;
    case 'medium':
    case 'normal':
      return localizations.priorityMedium;
    case 'high':
      return localizations.priorityHigh;
    case 'emergency':
    case 'critical':
    case 'urgent':
      return localizations.priorityEmergency;
    default:
      return _safeFallback(raw, 'ComplaintPriority', localizations.priorityMedium);
  }
}

// ============================================================================
// 3. COMPLAINT CATEGORY MAPPER
// ============================================================================

/// Maps a canonical civic category identifier or [CivicCategory] to its display name.
String localizedCategory(
  dynamic categoryOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  String id = '';
  String fallback = '';

  if (categoryOrId is CivicCategory) {
    id = categoryOrId.id;
    fallback = categoryOrId.name;
  } else if (categoryOrId is String) {
    id = categoryOrId.trim();
    fallback = id;
  } else if (categoryOrId != null) {
    id = categoryOrId.toString();
    fallback = id;
  }

  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  final normalized = _normalizeCanonicalToken(id);

  if (localizations == null) {
    if (categoryOrId is CivicCategory && categoryOrId.name.isNotEmpty) {
      return categoryOrId.name;
    }
    if (fallback.isNotEmpty && fallback != id) {
      return fallback;
    }
    switch (normalized) {
      case 'roads':
      case 'road':
        return 'Roads';
      case 'potholes':
      case 'pothole':
        return 'Potholes';
      case 'water':
      case 'watersupply':
      case 'water_supply':
        return 'Water Supply';
      case 'waterleakage':
      case 'water_leakage':
        return 'Water Leakage';
      case 'damagedwater':
      case 'damaged_water':
        return 'Damaged Pipeline';
      case 'waterlogging':
      case 'water_logging':
        return 'Waterlogging';
      case 'sanitation':
        return 'Sanitation';
      case 'waste':
      case 'garbage':
      case 'wastemanagement':
      case 'waste_management':
        return 'Waste Management';
      case 'garbageoverflow':
      case 'garbage_overflow':
      case 'garbagedumping':
      case 'garbage_dumping':
        return 'Garbage Overflow';
      case 'streetlights':
      case 'streetlight':
      case 'street_lights':
        return 'Streetlights';
      case 'drainage':
        return 'Drainage';
      case 'sewageoverflow':
      case 'sewage_overflow':
        return 'Sewage Overflow';
      case 'manholes':
      case 'manhole':
        return 'Manholes';
      case 'infrastructure':
      case 'publicinfrastructure':
      case 'public_infrastructure':
        return 'Infrastructure';
      case 'footpaths':
      case 'footpath':
        return 'Footpaths';
      case 'traffic':
      case 'traffic_road_safety':
      case 'roadsafety':
      case 'road_safety':
        return 'Traffic & Roads';
      case 'trees':
      case 'tree':
        return 'Trees';
      case 'other':
      case 'general':
        return 'Other';
      default:
        return _safeFallback(id, 'CivicCategory', fallback.isNotEmpty ? fallback : 'General Issue');
    }
  }

  switch (normalized) {
    case 'roads':
    case 'road':
      return localizations.categoryRoads;
    case 'potholes':
    case 'pothole':
      return localizations.categoryPotholes;
    case 'water':
    case 'watersupply':
    case 'water_supply':
      return localizations.categoryWater;
    case 'waterleakage':
    case 'water_leakage':
      return localizations.categoryWaterLeakage;
    case 'damagedwater':
    case 'damaged_water':
      return localizations.categoryDamagedWater;
    case 'waterlogging':
    case 'water_logging':
      return localizations.categoryWaterlogging;
    case 'sanitation':
      return localizations.categorySanitation;
    case 'waste':
    case 'garbage':
    case 'wastemanagement':
    case 'waste_management':
      return localizations.categoryWaste;
    case 'garbageoverflow':
    case 'garbage_overflow':
      return localizations.categoryGarbageOverflow;
    case 'garbagedumping':
    case 'garbage_dumping':
      return localizations.categoryGarbageOverflow;
    case 'streetlights':
    case 'streetlight':
    case 'street_lights':
      return localizations.categoryStreetlights;
    case 'drainage':
      return localizations.categoryDrainage;
    case 'sewageoverflow':
    case 'sewage_overflow':
      return localizations.categorySewageOverflow;
    case 'manholes':
    case 'manhole':
      return localizations.categoryManholes;
    case 'infrastructure':
    case 'publicinfrastructure':
    case 'public_infrastructure':
      return localizations.categoryInfrastructure;
    case 'footpaths':
    case 'footpath':
      return localizations.categoryFootpaths;
    case 'traffic':
    case 'traffic_road_safety':
    case 'roadsafety':
    case 'road_safety':
      return localizations.categoryTraffic;
    case 'trees':
    case 'tree':
      return localizations.categoryTrees;
    case 'other':
    case 'general':
      return localizations.categoryOther;
    default:
      return _safeFallback(id, 'CivicCategory', fallback.isNotEmpty ? fallback : localizations.categoryOther);
  }
}

/// Semantic alias for [localizedCategory].
String localizedComplaintCategory(
  dynamic categoryOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) => localizedCategory(categoryOrId, context: context, l10n: l10n);

/// Maps a canonical category identifier or [CivicCategory] to its localized description.
String localizedCategoryDescription(
  dynamic categoryOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  String id = '';
  String fallback = '';

  if (categoryOrId is CivicCategory) {
    id = categoryOrId.id;
    fallback = categoryOrId.description;
  } else if (categoryOrId is String) {
    id = categoryOrId.trim();
  }

  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  if (localizations == null) {
    return fallback;
  }

  final normalized = _normalizeCanonicalToken(id);

  switch (normalized) {
    case 'roads':
      return localizations.categoryRoadsDesc;
    case 'water':
      return localizations.categoryWaterDesc;
    case 'sanitation':
      return localizations.categorySanitationDesc;
    case 'waste':
      return localizations.categoryWasteDesc;
    case 'streetlights':
      return localizations.categoryStreetlightsDesc;
    case 'drainage':
      return localizations.categoryDrainageDesc;
    case 'infrastructure':
      return localizations.categoryInfrastructureDesc;
    case 'traffic':
      return localizations.categoryTrafficDesc;
    case 'other':
      return localizations.categoryOtherDesc;
    default:
      return fallback;
  }
}

// ============================================================================
// 4. CIVIC DEPARTMENT MAPPER (18 BMC Technical Departments)
// ============================================================================

/// Maps a canonical department identifier or [CivicDepartment] to its localized display name.
String localizedDepartment(
  dynamic departmentOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  String id = '';
  String fallback = 'General Municipal Desk';

  if (departmentOrId is CivicDepartment) {
    id = departmentOrId.departmentId.isNotEmpty ? departmentOrId.departmentId : departmentOrId.departmentCode;
    fallback = departmentOrId.displayName;
  } else if (departmentOrId is String) {
    id = departmentOrId.trim();
    fallback = id;
  } else if (departmentOrId != null) {
    id = departmentOrId.toString();
    fallback = id;
  }

  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  final normalized = _normalizeCanonicalToken(id);

  if (localizations == null) {
    if (departmentOrId is CivicDepartment && departmentOrId.displayName.isNotEmpty) {
      return departmentOrId.displayName;
    }
    if (fallback.isNotEmpty && fallback != id) {
      return fallback;
    }
    switch (normalized) {
      case 'roads_maintenance':
      case 'maintenance_roads':
      case 'rds':
      case 'roads':
      case 'roads_department':
      case 'roads_infrastructure':
        return 'Maintenance & Roads Department';
      case 'roads_traffic':
      case 'traffic':
        return 'Roads & Traffic';
      case 'water_works':
      case 'ww':
        return 'Water Works Department';
      case 'water_supply':
      case 'water_sewerage':
      case 'water':
      case 'water_department':
        return 'Water Supply & Sewerage';
      case 'solid_waste_management':
      case 'swm':
      case 'solid_waste':
      case 'waste':
      case 'sanitation_waste_department':
        return 'Solid Waste Management';
      case 'building_factory':
      case 'bf':
        return 'Building & Factory Department';
      case 'garden_trees':
      case 'gdn':
      case 'gardens_trees':
      case 'trees':
        return 'Garden & Tree Authority';
      case 'public_health':
      case 'ph':
      case 'health':
        return 'Public Health Department';
      case 'pest_control_insecticide':
      case 'pest_control':
      case 'pci':
        return 'Pest Control & Insecticide';
      case 'encroachment':
      case 'encroachment_removal':
      case 'enc':
        return 'Encroachment Removal';
      case 'licence':
      case 'licence_department':
      case 'lic':
        return 'Licence Department';
      case 'shops_establishments':
      case 'se':
        return 'Shops & Establishments';
      case 'assessment_collection':
      case 'ac':
        return 'Assessment & Collection';
      case 'estate':
      case 'estate_department':
      case 'est':
        return 'Estate Department';
      case 'colony_slum':
      case 'colony_slum_improvement':
      case 'csi':
        return 'Slum Improvement';
      case 'education_schools':
      case 'edu':
        return 'Education & Schools';
      case 'security':
      case 'security_force':
      case 'sec':
        return 'Security Department';
      case 'legal':
      case 'legal_department':
      case 'leg':
        return 'Legal Department';
      case 'administration_establishment':
      case 'adm':
        return 'Administration & Establishment';
      case 'town_planning':
      case 'town_planning_development_plan':
      case 'tp':
        return 'Town Planning & DP';
      case 'electrical_streetlights':
      case 'streetlights':
      case 'electrical_public_works':
        return 'Electrical & Streetlights';
      case 'storm_drainage':
      case 'drainage':
      case 'drainage_department':
        return 'Storm Water Drainage';
      case 'building_infrastructure':
      case 'infrastructure':
        return 'Building & Infrastructure';
      case 'general_municipal_desk':
      case 'general':
      case '':
        return 'General Municipal Desk';
      default:
        if (normalized.contains('road') || normalized.contains('traffic') || normalized.contains('pothole')) {
          return 'Maintenance & Roads Department';
        } else if (normalized.contains('waste') || normalized.contains('garbage')) {
          return 'Solid Waste Management';
        } else if (normalized.contains('water') || normalized.contains('sewerage') || normalized.contains('drain')) {
          return 'Water Supply & Sewerage';
        } else if (normalized.contains('electric') || normalized.contains('light') || normalized.contains('power')) {
          return 'Electrical & Streetlights';
        } else if (normalized.contains('health') || normalized.contains('sanitation') || normalized.contains('medical')) {
          return 'Public Health Department';
        } else if (normalized.contains('garden') || normalized.contains('tree') || normalized.contains('park')) {
          return 'Garden & Tree Authority';
        } else if (normalized.contains('building') || normalized.contains('infra') || normalized.contains('factory')) {
          return 'Building & Infrastructure';
        } else if (normalized.contains('general') || normalized.isEmpty) {
          return 'General Municipal Desk';
        }
        return _safeFallback(id, 'CivicDepartment', fallback.isNotEmpty ? fallback : 'General Municipal Desk');
    }
  }

  // Exact & canonical 18 BMC Technical Departments
  if (normalized == 'roads_maintenance' || normalized == 'maintenance_roads' || normalized == 'rds' || normalized == 'roads' || normalized == 'roads_department' || normalized == 'roads_infrastructure') {
    return localizations.deptMaintenanceRoads;
  } else if (normalized == 'roads_traffic' || normalized == 'traffic') {
    return localizations.deptRoadsTraffic;
  } else if (normalized == 'water_works' || normalized == 'ww') {
    return localizations.deptWaterWorks;
  } else if (normalized == 'water_supply' || normalized == 'water_sewerage' || normalized == 'water' || normalized == 'water_department') {
    return localizations.deptWaterSewerage;
  } else if (normalized == 'solid_waste_management' || normalized == 'swm' || normalized == 'waste' || normalized == 'sanitation_waste_department') {
    return localizations.deptSolidWasteManagement;
  } else if (normalized == 'solid_waste') {
    return localizations.deptSolidWaste;
  } else if (normalized == 'building_factory' || normalized == 'bf') {
    return localizations.deptBuildingFactory;
  } else if (normalized == 'garden_trees' || normalized == 'gdn' || normalized == 'gardens_trees' || normalized == 'trees') {
    return localizations.deptGardenTrees;
  } else if (normalized == 'public_health' || normalized == 'ph' || normalized == 'health') {
    return localizations.deptPublicHealth;
  } else if (normalized == 'pest_control_insecticide' || normalized == 'pest_control' || normalized == 'pci') {
    return localizations.deptPestControlInsecticide;
  } else if (normalized == 'encroachment' || normalized == 'encroachment_removal' || normalized == 'enc') {
    return localizations.deptEncroachment;
  } else if (normalized == 'licence' || normalized == 'licence_department' || normalized == 'lic') {
    return localizations.deptLicence;
  } else if (normalized == 'shops_establishments' || normalized == 'se') {
    return localizations.deptShopsEstablishments;
  } else if (normalized == 'assessment_collection' || normalized == 'ac') {
    return localizations.deptAssessmentCollection;
  } else if (normalized == 'estate' || normalized == 'estate_department' || normalized == 'est') {
    return localizations.deptEstate;
  } else if (normalized == 'colony_slum' || normalized == 'colony_slum_improvement' || normalized == 'csi') {
    return localizations.deptColonySlum;
  } else if (normalized == 'education_schools' || normalized == 'edu') {
    return localizations.deptEducationSchools;
  } else if (normalized == 'security' || normalized == 'security_force' || normalized == 'sec') {
    return localizations.deptSecurity;
  } else if (normalized == 'legal' || normalized == 'legal_department' || normalized == 'leg') {
    return localizations.deptLegal;
  } else if (normalized == 'administration_establishment' || normalized == 'adm') {
    return localizations.deptAdministrationEstablishment;
  } else if (normalized == 'town_planning' || normalized == 'town_planning_development_plan' || normalized == 'tp') {
    return localizations.deptTownPlanning;
  } else if (normalized == 'electrical_streetlights' || normalized == 'streetlights' || normalized == 'electrical_public_works') {
    return localizations.deptElectricalStreetlights;
  } else if (normalized == 'storm_drainage' || normalized == 'drainage' || normalized == 'drainage_department') {
    return localizations.deptStormDrainage;
  } else if (normalized == 'building_infrastructure' || normalized == 'infrastructure') {
    return localizations.deptBuildingInfrastructure;
  } else if (normalized == 'general_municipal_desk' || normalized == 'general') {
    return localizations.deptGeneral;
  }

  // Broad keyword fallbacks for compatibility
  if (normalized.contains('road') || normalized.contains('traffic') || normalized.contains('pothole')) {
    return localizations.deptRoadsTraffic;
  } else if (normalized.contains('waste') || normalized.contains('garbage')) {
    return localizations.deptSolidWaste;
  } else if (normalized.contains('water') || normalized.contains('sewerage') || normalized.contains('drain') || normalized.contains('he')) {
    return localizations.deptWaterSewerage;
  } else if (normalized.contains('electric') || normalized.contains('light') || normalized.contains('power')) {
    return localizations.deptElectricalStreetlights;
  } else if (normalized.contains('storm') || normalized.contains('flood')) {
    return localizations.deptStormDrainage;
  } else if (normalized.contains('health') || normalized.contains('sanitation') || normalized.contains('medical')) {
    return localizations.deptPublicHealth;
  } else if (normalized.contains('garden') || normalized.contains('tree') || normalized.contains('park')) {
    return localizations.deptGardenTrees;
  } else if (normalized.contains('building') || normalized.contains('infra') || normalized.contains('factory')) {
    return localizations.deptBuildingInfrastructure;
  } else if (normalized.contains('general') || normalized.isEmpty) {
    return localizations.deptGeneral;
  }

  return _safeFallback(id, 'CivicDepartment', fallback);
}

// ============================================================================
// 5. GOVERNMENT ROLE MAPPER
// ============================================================================

/// Maps a canonical [GovernmentRole] or role ID string to its localized display designation.
String localizedGovernmentRole(
  dynamic roleOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  GovernmentRole? role;
  String rawId = '';

  if (roleOrId is GovernmentRole) {
    role = roleOrId;
    rawId = role.id;
  } else if (roleOrId is String) {
    rawId = roleOrId.trim();
    final normalized = rawId.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    final stripped = normalized.replaceAll('_', '');
    for (final r in GovernmentRole.values) {
      if (r.id == normalized || r.name.toLowerCase() == stripped || r.id.replaceAll('_', '') == stripped) {
        role = r;
        break;
      }
    }
    if (role == null) {
      if (normalized == 'super_admin' || normalized == 'government_super_admin') {
        role = GovernmentRole.governmentSuperAdmin;
      } else if (normalized == 'government' || normalized == 'officer') {
        role = GovernmentRole.wardDepartmentLead;
      }
    }
  } else if (roleOrId != null) {
    rawId = roleOrId.toString();
  }

  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  final normalized = rawId.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  // Check specific designation titles first
  if (normalized == 'assistant_engineer' || normalized == 'ae') {
    return localizations?.govRoleAssistantEngineer ?? 'Assistant Engineer';
  } else if (normalized == 'executive_engineer' || normalized == 'ee') {
    return localizations?.govRoleExecutiveEngineer ?? 'Executive Engineer';
  } else if (normalized == 'sub_engineer' || normalized == 'se_eng') {
    return localizations?.govRoleSubEngineer ?? 'Sub-Engineer';
  } else if (normalized == 'medical_officer' || normalized == 'moh') {
    return localizations?.govRoleMedicalOfficer ?? 'Medical Officer of Health';
  } else if (normalized == 'superintendent' || normalized == 'asst_superintendent') {
    return localizations?.govRoleSuperintendent ?? 'Assistant Superintendent';
  }

  if (localizations == null) {
    return role?.displayName ?? _safeFallback(rawId, 'GovernmentRole', 'Ward Department Lead');
  }

  if (role != null) {
    switch (role) {
      case GovernmentRole.governmentSuperAdmin:
        return localizations.govRoleSuperAdmin;
      case GovernmentRole.zonalDmc:
        return localizations.govRoleZonalDmc;
      case GovernmentRole.centralDepartmentHod:
        return localizations.govRoleCentralHod;
      case GovernmentRole.wardOfficer:
        return localizations.govRoleWardOfficer;
      case GovernmentRole.wardDepartmentLead:
        return localizations.govRoleWardLead;
      case GovernmentRole.departmentCrew:
        return localizations.govRoleDepartmentCrew;
    }
  }

  return _safeFallback(rawId, 'GovernmentRole', localizations.govRoleWardLead);
}

// ============================================================================
// 6. VERIFICATION STATE MAPPER
// ============================================================================

/// Maps canonical AI / human verification state identifiers to display descriptions.
String localizedVerificationState(
  dynamic stateOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  final raw = (stateOrId?.toString() ?? 'pending').trim();
  final normalized = raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    switch (normalized) {
      case 'pending':
        return 'Verification Pending';
      case 'processing':
        return 'Analyzing & Verifying...';
      case 'passed':
      case 'verified':
      case 'evidence_verified':
        return 'Verification Passed';
      case 'failed':
      case 'evidence_failed':
      case 'department_failed':
        return 'Verification Failed';
      case 'temporarily_unavailable':
      case 'delayed':
        return 'Automated Verification Delayed';
      case 'humandepartmentreview':
      case 'human_department_review':
      case 'manual_review':
      case 'needsmanualreview':
        return 'Department Officer Review';
      case 'verification_completed':
        return 'Verification Completed';
      case 'low_confidence':
        return 'Low Verification Confidence';
      case 'manual_override':
        return 'Manual Verification Override';
      default:
        return _safeFallback(raw, 'VerificationState', 'Under Verification');
    }
  }

  switch (normalized) {
    case 'pending':
      return localizations.verificationPending;
    case 'processing':
      return localizations.verificationProcessing;
    case 'passed':
    case 'verified':
    case 'evidence_verified':
      return localizations.verificationPassed;
    case 'failed':
    case 'evidence_failed':
    case 'department_failed':
      return localizations.verificationFailed;
    case 'temporarily_unavailable':
    case 'delayed':
      return localizations.verificationDelayed;
    case 'humandepartmentreview':
    case 'human_department_review':
    case 'manual_review':
    case 'needsmanualreview':
      return localizations.verificationOfficerReview;
    case 'verification_completed':
      return localizations.verificationCompleted;
    default:
      return _safeFallback(raw, 'VerificationState', localizations.statusUnderVerification);
  }
}

// ============================================================================
// 7. ROUTING STATE & ROUTING TICKET MAPPER
// ============================================================================

/// Maps a canonical [ComplaintRoutingStatus] or routing string to its display routing label.
String localizedRoutingStatus(
  dynamic statusOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  String raw = '';
  if (statusOrId is ComplaintRoutingStatus) {
    raw = statusOrId.name;
  } else if (statusOrId is String) {
    raw = statusOrId.trim();
  } else if (statusOrId != null) {
    raw = statusOrId.toString();
  }

  final normalized = raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    switch (normalized) {
      case 'unassigned':
        return 'Unassigned';
      case 'assigned':
        return 'Assigned';
      case 'reassignmentrequested':
      case 'reassignment_requested':
        return 'Reassignment Requested';
      case 'transferred':
        return 'Transferred';
      case 'inprogress':
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return _safeFallback(raw, 'ComplaintRoutingStatus', 'Assigned');
    }
  }

  switch (normalized) {
    case 'unassigned':
      return localizations.routingUnassigned;
    case 'assigned':
      return localizations.routingAssigned;
    case 'reassignmentrequested':
    case 'reassignment_requested':
      return localizations.routingReassignmentRequested;
    case 'transferred':
      return localizations.routingTransferred;
    case 'inprogress':
    case 'in_progress':
      return localizations.routingInProgress;
    case 'resolved':
      return localizations.routingResolved;
    default:
      return _safeFallback(raw, 'ComplaintRoutingStatus', localizations.routingAssigned);
  }
}

/// Semantic alias for [localizedRoutingStatus].
String localizedRoutingState(
  dynamic statusOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) => localizedRoutingStatus(statusOrId, context: context, l10n: l10n);

/// Maps a [RoutingTicketStatus] or routing ticket string to its localized display label.
String localizedRoutingTicketStatus(
  dynamic statusOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  String raw = '';
  if (statusOrId is RoutingTicketStatus) {
    raw = statusOrId.name;
  } else if (statusOrId is String) {
    raw = statusOrId.trim();
  } else if (statusOrId != null) {
    raw = statusOrId.toString();
  }

  final normalized = raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    switch (normalized) {
      case 'pending':
        return 'Pending Ward Officer Review';
      case 'approved':
        return 'Reassignment Approved';
      case 'rejected':
        return 'Reassignment Rejected';
      case 'cancelled':
      case 'canceled':
        return 'Ticket Cancelled';
      default:
        return _safeFallback(raw, 'RoutingTicketStatus', 'Pending Ward Officer Review');
    }
  }

  switch (normalized) {
    case 'pending':
      return localizations.routingTicketPending;
    case 'approved':
      return localizations.routingTicketApproved;
    case 'rejected':
      return localizations.routingTicketRejected;
    case 'cancelled':
    case 'canceled':
      return localizations.routingTicketCancelled;
    default:
      return _safeFallback(raw, 'RoutingTicketStatus', localizations.routingTicketPending);
  }
}

// ============================================================================
// 8. ASSIGNMENT STATE MAPPER
// ============================================================================

/// Maps a canonical [ComplaintAssignmentStatus] or assignment string to its display label.
String localizedAssignmentStatus(
  dynamic statusOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  String raw = '';
  if (statusOrId is ComplaintAssignmentStatus) {
    raw = statusOrId.name;
  } else if (statusOrId is String) {
    raw = statusOrId.trim();
  } else if (statusOrId != null) {
    raw = statusOrId.toString();
  }

  final normalized = raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    switch (normalized) {
      case 'unassigned':
        return 'Unassigned';
      case 'leadassigned':
      case 'lead_assigned':
        return 'Assigned to Ward Lead';
      case 'crewassigned':
      case 'crew_assigned':
        return 'Assigned to Ground Crew';
      case 'fieldofficerassigned':
      case 'field_officer_assigned':
        return 'Assigned to Field Officer';
      default:
        return _safeFallback(raw, 'ComplaintAssignmentStatus', 'Unassigned');
    }
  }

  switch (normalized) {
    case 'unassigned':
      return localizations.assignmentUnassigned;
    case 'leadassigned':
    case 'lead_assigned':
      return localizations.assignmentLeadAssigned;
    case 'crewassigned':
    case 'crew_assigned':
      return localizations.assignmentCrewAssigned;
    case 'fieldofficerassigned':
    case 'field_officer_assigned':
      return localizations.assignmentFieldOfficerAssigned;
    default:
      return _safeFallback(raw, 'ComplaintAssignmentStatus', localizations.assignmentUnassigned);
  }
}

/// Semantic alias for [localizedAssignmentStatus].
String localizedAssignmentState(
  dynamic statusOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) => localizedAssignmentStatus(statusOrId, context: context, l10n: l10n);

// ============================================================================
// 9. EXECUTION STATE MAPPER
// ============================================================================

/// Maps field execution states to localized display labels.
String localizedExecutionState(
  dynamic stateOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  final raw = (stateOrId?.toString() ?? 'readyToStart').trim();
  final normalized = raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    switch (normalized) {
      case 'notstarted':
      case 'not_started':
      case 'readytostart':
      case 'ready_to_start':
        return 'Ready to Start';
      case 'inprogress':
      case 'in_progress':
      case 'commenced':
      case 'workstarted':
      case 'work_started':
        return 'Execution In Progress';
      case 'blocked':
      case 'onhold':
      case 'on_hold':
        return 'Execution Blocked';
      case 'awaitingevidence':
      case 'awaiting_evidence':
        return 'Awaiting Ground Evidence';
      case 'completed':
      case 'submitted':
      case 'workcompleted':
      case 'work_completed':
        return 'Work Completed';
      default:
        return _safeFallback(raw, 'ExecutionState', 'Ready to Start');
    }
  }

  switch (normalized) {
    case 'notstarted':
    case 'not_started':
    case 'readytostart':
    case 'ready_to_start':
      return localizations.executionNotStarted;
    case 'inprogress':
    case 'in_progress':
    case 'commenced':
    case 'workstarted':
    case 'work_started':
      return localizations.executionInProgress;
    case 'blocked':
    case 'onhold':
    case 'on_hold':
      return localizations.executionBlocked;
    case 'awaitingevidence':
    case 'awaiting_evidence':
      return localizations.executionAwaitingEvidence;
    case 'completed':
    case 'submitted':
    case 'workcompleted':
    case 'work_completed':
      return localizations.executionCompleted;
    default:
      return _safeFallback(raw, 'ExecutionState', localizations.executionNotStarted);
  }
}

// ============================================================================
// 10. RESOLUTION STATE MAPPER
// ============================================================================

/// Maps resolution lifecycle states to localized display labels.
String localizedResolutionState(
  dynamic stateOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  final raw = (stateOrId?.toString() ?? 'pending').trim();
  final normalized = raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    switch (normalized) {
      case 'pending':
      case 'resolution_pending':
      case 'unresolved':
        return 'Resolution Pending';
      case 'submitted':
      case 'resolution_submitted':
      case 'awaiting_review':
        return 'Resolution Submitted';
      case 'approved':
      case 'resolved':
      case 'verified':
        return 'Resolution Approved';
      case 'rejected':
      case 'rework_needed':
        return 'Resolution Rejected';
      case 'closed':
        return 'Resolution Closed';
      default:
        return _safeFallback(raw, 'ResolutionState', 'Resolution Pending');
    }
  }

  switch (normalized) {
    case 'pending':
    case 'resolution_pending':
    case 'unresolved':
      return localizations.resolutionPending;
    case 'submitted':
    case 'resolution_submitted':
    case 'awaiting_review':
      return localizations.resolutionSubmitted;
    case 'approved':
    case 'resolved':
    case 'verified':
      return localizations.resolutionApproved;
    case 'rejected':
    case 'rework_needed':
      return localizations.resolutionRejected;
    case 'closed':
      return localizations.resolutionClosed;
    default:
      return _safeFallback(raw, 'ResolutionState', localizations.resolutionPending);
  }
}

// ============================================================================
// 11. REWORK STATE MAPPER
// ============================================================================

/// Maps supervisory quality rework states to localized display labels.
String localizedReworkState(
  dynamic stateOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  final raw = (stateOrId?.toString() ?? 'none').trim();
  final normalized = raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    switch (normalized) {
      case 'none':
      case 'not_required':
      case 'reworknotrequired':
      case 'rework_not_required':
        return 'No Rework Required';
      case 'required':
      case 'reworkrequired':
      case 'rework_required':
      case 'reopened':
        return 'Rework Required';
      case 'inprogress':
      case 'reworkinprogress':
      case 'rework_in_progress':
        return 'Rework In Progress';
      case 'submitted':
      case 'reworksubmitted':
      case 'rework_submitted':
        return 'Rework Submitted';
      case 'approved':
      case 'reworkapproved':
      case 'rework_approved':
        return 'Rework Approved';
      default:
        return _safeFallback(raw, 'ReworkState', 'No Rework Required');
    }
  }

  switch (normalized) {
    case 'none':
    case 'not_required':
    case 'reworknotrequired':
    case 'rework_not_required':
      return localizations.reworkNotRequired;
    case 'required':
    case 'reworkrequired':
    case 'rework_required':
    case 'reopened':
      return localizations.reworkRequiredState;
    case 'inprogress':
    case 'reworkinprogress':
    case 'rework_in_progress':
      return localizations.reworkInProgress;
    case 'submitted':
    case 'reworksubmitted':
    case 'rework_submitted':
      return localizations.reworkSubmitted;
    case 'approved':
    case 'reworkapproved':
    case 'rework_approved':
      return localizations.reworkApproved;
    default:
      return _safeFallback(raw, 'ReworkState', localizations.reworkNotRequired);
  }
}

// ============================================================================
// 12. SYNC STATE MAPPER
// ============================================================================

/// Maps a canonical [SyncStatus] or sync string to its display synchronization label.
String localizedSyncStatus(
  dynamic statusOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  String raw = '';
  if (statusOrId is SyncStatus) {
    raw = statusOrId.name;
  } else if (statusOrId is String) {
    raw = statusOrId.trim();
  } else if (statusOrId != null) {
    raw = statusOrId.toString();
  }

  final normalized = raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    switch (normalized) {
      case 'synced':
        return 'Synced';
      case 'pending':
        return 'Pending Sync';
      case 'syncing':
        return 'Syncing...';
      case 'failed':
        return 'Sync Failed';
      case 'offline':
        return 'Offline Queue';
      case 'retrying':
        return 'Retrying Sync...';
      default:
        return _safeFallback(raw, 'SyncStatus', 'Synced');
    }
  }

  switch (normalized) {
    case 'synced':
      return localizations.syncSynced;
    case 'pending':
      return localizations.syncPending;
    case 'syncing':
      return localizations.syncSyncing;
    case 'failed':
      return localizations.syncFailed;
    case 'offline':
      return localizations.syncOffline;
    case 'retrying':
      return localizations.syncRetrying;
    default:
      return _safeFallback(raw, 'SyncStatus', localizations.syncSynced);
  }
}

/// Semantic alias for [localizedSyncStatus].
String localizedSyncState(
  dynamic statusOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) => localizedSyncStatus(statusOrId, context: context, l10n: l10n);

// ============================================================================
// 13. NOTIFICATION TYPE MAPPER
// ============================================================================

/// Maps a canonical [NotificationType], [NotificationModel], or notification string to its localized title.
String localizedNotificationType(
  dynamic typeOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  String raw = '';
  if (typeOrId is NotificationType) {
    raw = typeOrId.name;
  } else if (typeOrId is NotificationModel) {
    raw = typeOrId.type.name;
  } else if (typeOrId is String) {
    raw = typeOrId.trim();
  } else if (typeOrId != null) {
    raw = typeOrId.toString();
  }

  final normalized = raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    switch (normalized) {
      case 'complaintsubmitted':
      case 'complaint_submitted':
      case 'submitted':
        return 'Complaint Submitted';
      case 'complaintverified':
      case 'complaint_verified':
      case 'verified':
        return 'Complaint Verified';
      case 'complaintassigned':
      case 'complaint_assigned':
      case 'assigned':
        return 'Complaint Assigned';
      case 'complaintstatuschanged':
      case 'complaint_status_changed':
      case 'statusupdate':
      case 'status_update':
        return 'Status Updated';
      case 'complaintresolved':
      case 'complaint_resolved':
      case 'resolved':
        return 'Complaint Resolved';
      case 'generalcivic':
      case 'general_civic':
      case 'civicbroadcast':
      case 'civic_broadcast':
        return 'Civic Announcement';
      case 'hazardalert':
      case 'hazard_alert':
        return 'Hazard Warning';
      case 'rewardearned':
      case 'reward_earned':
        return 'Reward Earned';
      case 'slawarning':
      case 'sla_warning':
        return 'SLA Deadline Warning';
      case 'reworkrequested':
      case 'rework_requested':
        return 'Rework Requested';
      default:
        return _safeFallback(raw, 'NotificationType', 'Civic Announcement');
    }
  }

  switch (normalized) {
    case 'complaintsubmitted':
    case 'complaint_submitted':
    case 'submitted':
      return localizations.notifComplaintSubmitted;
    case 'complaintverified':
    case 'complaint_verified':
    case 'verified':
      return localizations.notifComplaintVerified;
    case 'complaintassigned':
    case 'complaint_assigned':
    case 'assigned':
      return localizations.notifComplaintAssigned;
    case 'complaintstatuschanged':
    case 'complaint_status_changed':
    case 'statusupdate':
    case 'status_update':
      return localizations.notifComplaintStatusChanged;
    case 'complaintresolved':
    case 'complaint_resolved':
    case 'resolved':
      return localizations.notifComplaintResolved;
    case 'generalcivic':
    case 'general_civic':
    case 'civicbroadcast':
    case 'civic_broadcast':
      return localizations.notifGeneralCivic;
    case 'hazardalert':
    case 'hazard_alert':
      return localizations.notifHazardAlert;
    case 'rewardearned':
    case 'reward_earned':
      return localizations.notifRewardEarned;
    case 'slawarning':
    case 'sla_warning':
      return localizations.notifSlaWarning;
    case 'reworkrequested':
    case 'rework_requested':
      return localizations.notifReworkRequested;
    default:
      return _safeFallback(raw, 'NotificationType', localizations.notifGeneralCivic);
  }
}

// ============================================================================
// 14. REWARD / ACHIEVEMENT / LEVEL MAPPER
// ============================================================================

/// Maps a canonical achievement/badge identifier to its localized title.
String localizedAchievementTitle(
  dynamic achievementOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
  String? fallback,
}) {
  String id = '';
  String titleFallback = fallback ?? '';

  if (achievementOrId is CivicAchievement) {
    id = achievementOrId.id;
    if (titleFallback.isEmpty) titleFallback = achievementOrId.title;
  } else if (achievementOrId is String) {
    id = achievementOrId.trim();
    if (titleFallback.isEmpty) titleFallback = id;
  } else if (achievementOrId != null) {
    id = achievementOrId.toString();
  }

  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  final normalized = id.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    switch (normalized) {
      case 'first_report':
      case 'ach_1':
        return 'First Report';
      case 'active_citizen':
      case 'ach_4':
        return 'Active Citizen';
      case 'neighborhood_hero':
      case 'community_guardian':
      case 'ach_2':
        return 'Neighborhood Hero';
      case 'sharp_eye':
      case 'safety_watcher':
        return 'Sharp Eye';
      case 'evidence_expert':
        return 'Evidence Expert';
      case 'community_pillar':
      case 'civic_champion':
      case 'ach_3':
        return 'Community Pillar';
      case 'community_helper':
        return 'Community Helper';
      case 'ground_reporter':
        return 'Ground Reporter';
      case 'community_voice':
        return 'Community Voice';
      case 'resolution_champion':
        return 'Resolution Champion';
      default:
        return _safeFallback(id, 'CivicAchievement', titleFallback.isNotEmpty ? titleFallback : 'Civic Milestone');
    }
  }

  switch (normalized) {
    case 'first_report':
    case 'ach_1':
      return localizations.badgeFirstReport;
    case 'active_citizen':
    case 'ach_4':
      return localizations.badgeActiveCitizen;
    case 'neighborhood_hero':
    case 'community_guardian':
    case 'ach_2':
      return localizations.badgeNeighborhoodHero;
    case 'sharp_eye':
    case 'safety_watcher':
      return localizations.badgeSharpEye;
    case 'evidence_expert':
      return 'Evidence Expert';
    case 'community_pillar':
    case 'civic_champion':
    case 'ach_3':
      return localizations.badgeCommunityPillar;
    case 'community_helper':
      return 'Community Helper';
    case 'ground_reporter':
      return localizations.badgeGroundReporter;
    case 'community_voice':
      return localizations.badgeCommunityVoice;
    case 'resolution_champion':
      return localizations.badgeResolutionChampion;
    default:
      return _safeFallback(id, 'CivicAchievement', titleFallback.isNotEmpty ? titleFallback : localizations.badgeCommunityPillar);
  }
}

/// Maps a canonical achievement/badge identifier to its localized description.
String localizedAchievementDescription(
  dynamic achievementOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
  String? fallback,
}) {
  String id = '';
  String descFallback = fallback ?? '';

  if (achievementOrId is CivicAchievement) {
    id = achievementOrId.id;
    if (descFallback.isEmpty) descFallback = achievementOrId.description;
  } else if (achievementOrId is String) {
    id = achievementOrId.trim();
    if (descFallback.isEmpty) descFallback = id;
  } else if (achievementOrId != null) {
    id = achievementOrId.toString();
  }

  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  final normalized = id.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    switch (normalized) {
      case 'first_report':
      case 'ach_1':
        return 'Submitted your first civic grievance';
      case 'active_citizen':
      case 'ach_4':
        return 'Reported 5 or more civic issues';
      case 'neighborhood_hero':
      case 'community_guardian':
      case 'ach_2':
        return 'Had 10 issues resolved in your community';
      case 'sharp_eye':
      case 'safety_watcher':
        return 'Reported an immediate safety hazard';
      case 'evidence_expert':
        return 'Useful evidence helps officers act.';
      case 'community_pillar':
      case 'civic_champion':
      case 'ach_3':
        return 'Achieved 500+ Civic Points';
      case 'community_helper':
        return 'Support responsible community reports.';
      case 'ground_reporter':
        return 'Help officers find the right location.';
      case 'community_voice':
        return 'Make shared civic concerns visible.';
      case 'resolution_champion':
        return 'Follow reports through to resolution.';
      default:
        return descFallback;
    }
  }

  switch (normalized) {
    case 'first_report':
    case 'ach_1':
      return localizations.badgeFirstReportDesc;
    case 'active_citizen':
    case 'ach_4':
      return localizations.badgeActiveCitizenDesc;
    case 'neighborhood_hero':
    case 'community_guardian':
    case 'ach_2':
      return localizations.badgeNeighborhoodHeroDesc;
    case 'sharp_eye':
    case 'safety_watcher':
      return localizations.badgeSharpEyeDesc;
    case 'evidence_expert':
      return descFallback.isNotEmpty ? descFallback : 'Useful evidence helps officers act.';
    case 'community_pillar':
    case 'civic_champion':
    case 'ach_3':
      return localizations.badgeCommunityPillarDesc;
    case 'community_helper':
      return descFallback.isNotEmpty ? descFallback : 'Support responsible community reports.';
    case 'ground_reporter':
      return localizations.badgeGroundReporterDesc;
    case 'community_voice':
      return localizations.badgeCommunityVoiceDesc;
    case 'resolution_champion':
      return descFallback.isNotEmpty ? descFallback : localizations.badgeResolutionChampionDesc;
    default:
      return descFallback;
  }
}

/// Semantic alias for [localizedAchievementTitle].
String localizedRewardType(
  dynamic rewardOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) => localizedAchievementTitle(rewardOrId, context: context, l10n: l10n);

/// Maps a civic level number, title, or [CivicLevel] to its localized display title.
String localizedCivicLevelTitle(
  dynamic levelOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  int levelNumber = 1;
  String raw = '';

  if (levelOrId is CivicLevel) {
    levelNumber = levelOrId.number;
    raw = levelOrId.title;
  } else if (levelOrId is int) {
    levelNumber = levelOrId;
    raw = 'level_$levelNumber';
  } else if (levelOrId is String) {
    raw = levelOrId.trim();
    if (raw.contains('1') || raw.contains('starter')) {
      levelNumber = 1;
    } else if (raw.contains('2') || raw.contains('contributor')) {
      levelNumber = 2;
    } else if (raw.contains('3') || raw.contains('champion')) {
      levelNumber = 3;
    } else if (raw.contains('4') || raw.contains('leader')) {
      levelNumber = 4;
    } else if (raw.contains('5') || raw.contains('hero')) {
      levelNumber = 5;
    }
  }

  if (localizations == null) {
    switch (levelNumber) {
      case 1:
        return 'Civic Starter';
      case 2:
        return 'Civic Contributor';
      case 3:
        return 'Civic Champion';
      case 4:
        return 'Civic Leader';
      case 5:
        return 'Civic Hero';
      default:
        return _safeFallback(raw, 'CivicLevel', 'Civic Starter');
    }
  }

  switch (levelNumber) {
    case 1:
      return localizations.civicLevelStarter;
    case 2:
      return localizations.civicLevelContributor;
    case 3:
      return localizations.civicLevelChampion;
    case 4:
      return localizations.civicLevelLeader;
    case 5:
      return localizations.civicLevelHero;
    default:
      return _safeFallback(raw, 'CivicLevel', localizations.civicLevelStarter);
  }
}

// ============================================================================
// 15. BASEMAP MODE MAPPER
// ============================================================================

/// Maps a canonical [BasemapMode] or basemap string to its display label.
String localizedBasemapMode(
  dynamic modeOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  String raw = '';
  if (modeOrId is BasemapMode) {
    raw = modeOrId.name;
  } else if (modeOrId is String) {
    raw = modeOrId.trim();
  } else if (modeOrId != null) {
    raw = modeOrId.toString();
  }

  final normalized = raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    switch (normalized) {
      case 'streets':
      case 'street':
        return 'Streets';
      case 'satellite':
        return 'Satellite';
      case 'hybrid':
        return 'Hybrid';
      default:
        return _safeFallback(raw, 'BasemapMode', 'Streets');
    }
  }

  switch (normalized) {
    case 'streets':
    case 'street':
      return localizations.basemapStreets;
    case 'satellite':
      return localizations.basemapSatellite;
    case 'hybrid':
      return localizations.basemapHybrid;
    default:
      return _safeFallback(raw, 'BasemapMode', localizations.basemapStreets);
  }
}

/// Maps a canonical [BasemapMode] or basemap string to its localized description.
String localizedBasemapModeDescription(
  dynamic modeOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  String raw = '';
  if (modeOrId is BasemapMode) {
    raw = modeOrId.name;
  } else if (modeOrId is String) {
    raw = modeOrId.trim();
  } else if (modeOrId != null) {
    raw = modeOrId.toString();
  }

  final normalized = raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    switch (normalized) {
      case 'streets':
      case 'street':
        return 'Detailed vector road networks, wards, and civic infrastructure';
      case 'satellite':
        return 'High-resolution aerial and satellite photographic imagery';
      case 'hybrid':
        return 'Satellite imagery overlaid with street names, borders, and locality labels';
      default:
        return '';
    }
  }

  switch (normalized) {
    case 'streets':
    case 'street':
      return localizations.basemapStreetsDesc;
    case 'satellite':
      return localizations.basemapSatelliteDesc;
    case 'hybrid':
      return localizations.basemapHybridDesc;
    default:
      return '';
  }
}

// ============================================================================
// 16. JURISDICTION TYPE & SCOPE MAPPER
// ============================================================================

/// Maps a jurisdiction type enum or string to its localized label.
String localizedJurisdictionType(
  dynamic typeOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  final raw = (typeOrId?.toString() ?? 'ward').trim();
  final normalized = raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    switch (normalized) {
      case 'zone':
      case 'govjurisdictiontype.zone':
        return 'Zone Jurisdiction';
      case 'ward':
      case 'govjurisdictiontype.ward':
        return 'Ward Jurisdiction';
      case 'department':
      case 'govjurisdictiontype.department':
        return 'Department Jurisdiction';
      case 'role':
      case 'govjurisdictiontype.role':
        return 'Role Scope';
      case 'citywide':
        return 'Citywide';
      default:
        return _safeFallback(raw, 'JurisdictionType', 'Ward Jurisdiction');
    }
  }

  switch (normalized) {
    case 'zone':
    case 'govjurisdictiontype.zone':
      return localizations.jurisdictionZone;
    case 'ward':
    case 'govjurisdictiontype.ward':
      return localizations.jurisdictionWard;
    case 'department':
    case 'govjurisdictiontype.department':
      return localizations.jurisdictionDepartment;
    case 'role':
    case 'govjurisdictiontype.role':
      return localizations.jurisdictionRole;
    case 'citywide':
      return localizations.govCitywide;
    default:
      return _safeFallback(raw, 'JurisdictionType', localizations.jurisdictionWard);
  }
}

/// Maps jurisdiction scope (citywide, ward, zone) to localized display string.
String localizedJurisdictionScope({
  String? ward,
  String? zone,
  bool isCitywide = false,
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  if (localizations == null) {
    if (isCitywide) return 'Citywide';
    if (ward != null && ward.isNotEmpty) return 'Ward $ward';
    if (zone != null && zone.isNotEmpty) return 'Zone $zone';
    return 'Municipal Jurisdiction';
  }

  if (isCitywide || (ward == null && zone == null)) {
    return localizations.govCitywide;
  }
  if (ward != null && ward.isNotEmpty) {
    return localizations.govWardJurisdiction(ward);
  }
  if (zone != null && zone.isNotEmpty) {
    return localizations.govZoneJurisdiction(zone);
  }

  return localizations.govCitywide;
}

// ============================================================================
// 17. SLA STATE MAPPER
// ============================================================================

/// Maps an SLA status string or state to its localized display label.
String localizedSlaStatus(
  dynamic slaStatusOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  final raw = (slaStatusOrId?.toString() ?? 'healthy').trim();
  final normalized = raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (localizations == null) {
    if (normalized.contains('breach') || normalized.contains('overdue')) {
      return 'SLA Breached';
    } else if (normalized.contains('approach') || normalized.contains('warn') || normalized.contains('urgent')) {
      return 'Approaching SLA Deadline';
    } else if (normalized.contains('within') || normalized.contains('ok') || normalized.contains('safe') || normalized.contains('healthy')) {
      return 'Within SLA';
    }
    return _safeFallback(raw, 'GovtSlaStatus', 'SLA Compliance');
  }

  if (normalized.contains('breach') || normalized.contains('overdue')) {
    return localizations.govSlaBreached;
  } else if (normalized.contains('approach') || normalized.contains('warn') || normalized.contains('urgent')) {
    return localizations.govApproachingSlaDeadline;
  } else if (normalized.contains('within') || normalized.contains('ok') || normalized.contains('safe') || normalized.contains('healthy')) {
    return localizations.govWithinSla;
  }

  return _safeFallback(raw, 'GovtSlaStatus', localizations.govSlaStatus);
}

/// Semantic alias for [localizedSlaStatus].
String localizedSlaState(
  dynamic slaStatusOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) => localizedSlaStatus(slaStatusOrId, context: context, l10n: l10n);

/// Semantic alias for [localizedSlaStatus].
String localizedSlaBreachState(
  dynamic slaStatusOrId, {
  BuildContext? context,
  AppLocalizations? l10n,
}) => localizedSlaStatus(slaStatusOrId, context: context, l10n: l10n);

// ============================================================================
// NAVIGATION & HEADER HELPERS
// ============================================================================

/// Maps a Government navigation route or canonical title to its localized display label.
String localizedGovtNavTitle(
  String routeOrTitle, {
  BuildContext? context,
  AppLocalizations? l10n,
}) {
  final localizations = l10n ?? (context != null ? AppLocalizations.of(context) : null);
  if (localizations == null) {
    return routeOrTitle;
  }

  final key = routeOrTitle.toLowerCase().replaceAll('/', '').replaceAll('-', '_').replaceAll(' ', '_');

  if (key.contains('dashboard')) {
    return localizations.govNavDashboard;
  } else if (key.contains('complaint')) {
    return localizations.govNavComplaints;
  } else if (key.contains('hazard') || key.contains('map')) {
    return localizations.govNavHazardMap;
  } else if (key.contains('analytics')) {
    return localizations.govNavAnalytics;
  } else if (key.contains('profile')) {
    return localizations.govNavProfile;
  } else if (key.contains('my_work') || key.contains('mywork')) {
    return localizations.govNavMyWork;
  } else if (key.contains('operation')) {
    return localizations.govNavOperations;
  } else if (key.contains('sla')) {
    return localizations.govNavSla;
  } else if (key.contains('history') || key.contains('audit')) {
    return localizations.govNavHistory;
  } else if (key.contains('verification')) {
    return localizations.govNavVerification;
  } else if (key.contains('assignment')) {
    return localizations.govNavAssignments;
  }

  return routeOrTitle;
}
