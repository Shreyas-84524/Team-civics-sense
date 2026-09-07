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

  static const List<GovtOfficerModel> defaultOfficers = [
    GovtOfficerModel(
      id: 'off_101',
      name: 'Officer A (Ramesh Patel)',
      departmentId: 'dept_roads',
      designation: 'Assistant Executive Engineer',
      phone: '+91 98201 11223',
      assignedZone: 'Ward 14 (Central)',
      isAvailable: true,
    ),
    GovtOfficerModel(
      id: 'off_102',
      name: 'Officer B (Suresh More)',
      departmentId: 'dept_drainage',
      designation: 'Junior Engineer',
      phone: '+91 98202 33445',
      assignedZone: 'Ward 14 (Central)',
      isAvailable: true,
    ),
    GovtOfficerModel(
      id: 'off_103',
      name: 'Officer C (Pooja Kulkarni)',
      departmentId: 'dept_sanitation',
      designation: 'Sanitary Inspector',
      phone: '+91 98203 55667',
      assignedZone: 'Ward 14 (Central)',
      isAvailable: true,
    ),
    GovtOfficerModel(
      id: 'off_104',
      name: 'Officer D (Vijay Rane)',
      departmentId: 'dept_water',
      designation: 'Sub-Divisional Officer',
      phone: '+91 98204 77889',
      assignedZone: 'Ward 14 (Central)',
      isAvailable: true,
    ),
    GovtOfficerModel(
      id: 'off_105',
      name: 'Officer E (Anil Jadhav)',
      departmentId: 'dept_electrical',
      designation: 'Field Technician Lead',
      phone: '+91 98205 99001',
      assignedZone: 'Ward 14 (Central)',
      isAvailable: true,
    ),
    GovtOfficerModel(
      id: 'off_106',
      name: 'Officer F (Meera Joshi)',
      departmentId: 'dept_waste',
      designation: 'Waste Logistics Supervisor',
      phone: '+91 98206 12345',
      assignedZone: 'Ward 14 (Central)',
      isAvailable: true,
    ),
    GovtOfficerModel(
      id: 'off_107',
      name: 'Officer G (Karan Verma)',
      departmentId: 'dept_public_works',
      designation: 'Civil Superintendent',
      phone: '+91 98207 23456',
      assignedZone: 'Ward 14 (Central)',
      isAvailable: true,
    ),
    GovtOfficerModel(
      id: 'off_108',
      name: 'Officer H (Sunil Shinde)',
      departmentId: 'dept_traffic',
      designation: 'Traffic Safety Officer',
      phone: '+91 98208 34567',
      assignedZone: 'Ward 14 (Central)',
      isAvailable: true,
    ),
    GovtOfficerModel(
      id: 'off_109',
      name: 'Officer I (Dr. N. Deshmukh)',
      departmentId: 'dept_manual_review',
      designation: 'Senior Triage Officer',
      phone: '+91 98209 45678',
      assignedZone: 'Central Headquarters',
      isAvailable: true,
    ),
  ];
}
