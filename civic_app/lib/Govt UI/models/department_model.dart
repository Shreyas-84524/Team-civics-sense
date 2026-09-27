import 'package:flutter/material.dart';

/// Municipal Department Model.
class GovtDepartmentModel {
  final String id;
  final String name;
  final String code;
  final IconData icon;
  final String description;
  final int activeComplaintsCount;
  final int assignedPersonnelCount;

  const GovtDepartmentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.icon,
    required this.description,
    this.activeComplaintsCount = 0,
    this.assignedPersonnelCount = 0,
  });

  static const List<GovtDepartmentModel> defaultDepartments = [
    GovtDepartmentModel(
      id: 'dept_roads',
      name: 'Roads Department',
      code: 'PWD-RD',
      icon: Icons.edit_road_rounded,
      description: 'Pothole repairs, asphalt resurfacing, and pavement maintenance.',
      activeComplaintsCount: 8,
      assignedPersonnelCount: 14,
    ),
    GovtDepartmentModel(
      id: 'dept_water',
      name: 'Water Department',
      code: 'MWS-WTR',
      icon: Icons.water_drop_rounded,
      description: 'Potable water pipelines, valve leakages, and water tankers.',
      activeComplaintsCount: 5,
      assignedPersonnelCount: 10,
    ),
    GovtDepartmentModel(
      id: 'dept_sanitation',
      name: 'Sanitation Department',
      code: 'SWM-SAN',
      icon: Icons.cleaning_services_rounded,
      description: 'Public health sanitation, disinfection, and street sweeping.',
      activeComplaintsCount: 6,
      assignedPersonnelCount: 18,
    ),
    GovtDepartmentModel(
      id: 'dept_waste',
      name: 'Waste Management',
      code: 'SWM-WST',
      icon: Icons.delete_outline_rounded,
      description: 'Garbage compactor routes, dump yard management, and recycling.',
      activeComplaintsCount: 4,
      assignedPersonnelCount: 12,
    ),
    GovtDepartmentModel(
      id: 'dept_electrical',
      name: 'Electrical / Public Works',
      code: 'ENG-ELEC',
      icon: Icons.lightbulb_outline_rounded,
      description: 'Street light repair, feeder maintenance, and high mast installations.',
      activeComplaintsCount: 4,
      assignedPersonnelCount: 8,
    ),
    GovtDepartmentModel(
      id: 'dept_drainage',
      name: 'Drainage Department',
      code: 'SWD-DRN',
      icon: Icons.waves_rounded,
      description: 'Desilting culverts, stormwater drains, and flood management.',
      activeComplaintsCount: 7,
      assignedPersonnelCount: 12,
    ),
    GovtDepartmentModel(
      id: 'dept_public_works',
      name: 'Public Works',
      code: 'PWD-GEN',
      icon: Icons.architecture_rounded,
      description: 'Public structures, civic infrastructure, and building maintenance.',
      activeComplaintsCount: 3,
      assignedPersonnelCount: 9,
    ),
    GovtDepartmentModel(
      id: 'dept_traffic',
      name: 'Traffic / Road Safety',
      code: 'TRF-SFT',
      icon: Icons.traffic_rounded,
      description: 'Traffic signals, speed breakers, road signage, and zebra crossings.',
      activeComplaintsCount: 5,
      assignedPersonnelCount: 11,
    ),
    GovtDepartmentModel(
      id: 'dept_manual_review',
      name: 'Manual Review',
      code: 'REV-MTR',
      icon: Icons.rate_review_outlined,
      description: 'Special triage committee for multi-department and complex grievances.',
      activeComplaintsCount: 2,
      assignedPersonnelCount: 6,
    ),
  ];
}

/// Assigned Field Officer / Maintenance Crew Model.
///
/// NOTE: Legacy hardcoded mock officer records (off_101..off_109) have been removed
/// in Phase 1 cleanup. In Phase 2, dynamic municipal personnel will be loaded from
/// the new hierarchical BMC backend.
class GovtOfficerModel {
  final String id;
  final String name;
  final String departmentId;
  final String designation;
  final String phone;
  final String assignedZone;
  final bool isAvailable;

  const GovtOfficerModel({
    required this.id,
    required this.name,
    required this.departmentId,
    required this.designation,
    required this.phone,
    required this.assignedZone,
    this.isAvailable = true,
  });

  /// Deprecated: legacy mock records removed in Phase 1 cleanup.
  static const List<GovtOfficerModel> defaultOfficers = [];
}
