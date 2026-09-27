import 'package:flutter/material.dart';
import '../../models/govt_user_model.dart';
import '../dashboard/city_command_center_screen.dart';
import '../dashboard/crew_field_operations_screen.dart';
import '../dashboard/department_command_center_screen.dart';
import '../dashboard/department_operations_screen.dart';
import '../dashboard/ward_command_center_screen.dart';
import '../dashboard/zone_command_center_screen.dart';

/// 1. Municipal Commissioner & Super Admin Landing: /government/dashboard
class CityCommandCenterLanding extends StatelessWidget {
  final GovtUserModel? user;

  const CityCommandCenterLanding({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return CityCommandCenterScreen(user: user);
  }
}

/// 2. Zonal Deputy Municipal Commissioner Landing: /government/zone
class ZoneCommandCenterLanding extends StatelessWidget {
  final GovtUserModel? user;

  const ZoneCommandCenterLanding({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return ZoneCommandCenterScreen(user: user);
  }
}

/// 3. Central Head of Department Landing: /government/department
class DepartmentCommandCenterLanding extends StatelessWidget {
  final GovtUserModel? user;

  const DepartmentCommandCenterLanding({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return DepartmentCommandCenterScreen(user: user);
  }
}

/// 4. Assistant Commissioner / Ward Officer Landing: /government/ward
class WardCommandCenterLanding extends StatelessWidget {
  final GovtUserModel? user;

  const WardCommandCenterLanding({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return WardCommandCenterScreen(user: user);
  }
}

/// 5. Ward Department Lead Landing: /government/department-operations
class DepartmentOperationsLanding extends StatelessWidget {
  final GovtUserModel? user;

  const DepartmentOperationsLanding({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return DepartmentOperationsScreen(user: user);
  }
}

/// 6. Department Crew Landing: /government/work
class CrewWorkdeskLanding extends StatelessWidget {
  final GovtUserModel? user;

  const CrewWorkdeskLanding({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return CrewFieldOperationsScreen(user: user);
  }
}
