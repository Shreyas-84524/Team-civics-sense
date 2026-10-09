import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/localization/app_localizations.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/map/basemap_mode.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/civic_department_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/complaint_routing_ticket_model.dart';
import 'package:civic_app/core/models/government_role.dart';
import 'package:civic_app/core/models/notification_model.dart';

void main() {
  late AppLocalizations l10nEn;
  late AppLocalizations l10nHi;
  late AppLocalizations l10nMr;

  setUpAll(() async {
    l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
    l10nHi = await AppLocalizations.delegate.load(const Locale('hi'));
    l10nMr = await AppLocalizations.delegate.load(const Locale('mr'));
  });

  group('Phase 5 — Domain 1: Complaint Status Mapper', () {
    test('localizes all 8 ComplaintStatus enums across en, hi, mr', () {
      // English
      expect(localizedComplaintStatus(ComplaintStatus.underVerification, l10n: l10nEn), 'Under Verification');
      expect(localizedComplaintStatus(ComplaintStatus.reported, l10n: l10nEn), 'Reported');
      expect(localizedComplaintStatus(ComplaintStatus.verified, l10n: l10nEn), 'Verified');
      expect(localizedComplaintStatus(ComplaintStatus.assigned, l10n: l10nEn), 'Assigned');
      expect(localizedComplaintStatus(ComplaintStatus.inProgress, l10n: l10nEn), 'In Progress');
      expect(localizedComplaintStatus(ComplaintStatus.resolved, l10n: l10nEn), 'Resolved');
      expect(localizedComplaintStatus(ComplaintStatus.closed, l10n: l10nEn), 'Closed');
      expect(localizedComplaintStatus(ComplaintStatus.rejected, l10n: l10nEn), 'Rejected');

      // Hindi
      expect(localizedComplaintStatus(ComplaintStatus.underVerification, l10n: l10nHi), 'सत्यापन प्रक्रिया में');
      expect(localizedComplaintStatus(ComplaintStatus.reported, l10n: l10nHi), 'दर्ज की गई');
      expect(localizedComplaintStatus(ComplaintStatus.verified, l10n: l10nHi), 'सत्यापित');
      expect(localizedComplaintStatus(ComplaintStatus.assigned, l10n: l10nHi), 'आवंटित');
      expect(localizedComplaintStatus(ComplaintStatus.inProgress, l10n: l10nHi), 'प्रगति पर');
      expect(localizedComplaintStatus(ComplaintStatus.resolved, l10n: l10nHi), 'समाधान हुआ');
      expect(localizedComplaintStatus(ComplaintStatus.closed, l10n: l10nHi), 'बंद');
      expect(localizedComplaintStatus(ComplaintStatus.rejected, l10n: l10nHi), 'अस्वीकृत');

      // Marathi
      expect(localizedComplaintStatus(ComplaintStatus.underVerification, l10n: l10nMr), 'पडताळणी सुरू आहे');
      expect(localizedComplaintStatus(ComplaintStatus.reported, l10n: l10nMr), 'नोंदवली');
      expect(localizedComplaintStatus(ComplaintStatus.verified, l10n: l10nMr), 'पडताळणी झाली');
      expect(localizedComplaintStatus(ComplaintStatus.assigned, l10n: l10nMr), 'नियुक्त');
      expect(localizedComplaintStatus(ComplaintStatus.inProgress, l10n: l10nMr), 'प्रगतीपथावर');
      expect(localizedComplaintStatus(ComplaintStatus.resolved, l10n: l10nMr), 'निवारण झाले');
      expect(localizedComplaintStatus(ComplaintStatus.closed, l10n: l10nMr), 'बंद');
      expect(localizedComplaintStatus(ComplaintStatus.rejected, l10n: l10nMr), 'नाकारली');
    });

    test('supports raw String canonical tokens and aliases', () {
      expect(localizedComplaintStatus('under_verification', l10n: l10nEn), 'Under Verification');
      expect(localizedComplaintStatus('inProgress', l10n: l10nEn), 'In Progress');
      expect(localizedComplaintStatus('submitted', l10n: l10nEn), 'Reported');
      expect(localizedComplaintStatus('under_review', l10n: l10nEn), 'Verified');
      expect(localizedComplaintStatus('reopened', l10n: l10nEn), 'Reopened');
    });
  });

  group('Phase 5 — Domain 2: Complaint Priority Mapper', () {
    test('localizes all ComplaintPriority enums across en, hi, mr', () {
      expect(localizedComplaintPriority(ComplaintPriority.low, l10n: l10nEn), 'Low');
      expect(localizedComplaintPriority(ComplaintPriority.medium, l10n: l10nEn), 'Medium');
      expect(localizedComplaintPriority(ComplaintPriority.high, l10n: l10nEn), 'High');
      expect(localizedComplaintPriority(ComplaintPriority.emergency, l10n: l10nEn), 'Critical');

      expect(localizedComplaintPriority(ComplaintPriority.low, l10n: l10nHi), 'कम');
      expect(localizedComplaintPriority(ComplaintPriority.emergency, l10n: l10nHi), 'गंभीर');

      expect(localizedComplaintPriority(ComplaintPriority.low, l10n: l10nMr), 'कमी');
      expect(localizedComplaintPriority(ComplaintPriority.emergency, l10n: l10nMr), 'अतिगंभीर');
    });

    test('supports raw priority strings', () {
      expect(localizedComplaintPriority('critical', l10n: l10nEn), 'Critical');
      expect(localizedComplaintPriority('urgent', l10n: l10nEn), 'Critical');
      expect(localizedComplaintPriority('normal', l10n: l10nEn), 'Medium');
    });
  });

  group('Phase 5 — Domain 3: Civic Category Mapper', () {
    test('localizes all categories from models and canonical IDs', () {
      expect(localizedCategory('roads', l10n: l10nEn), 'Roads');
      expect(localizedCategory('potholes', l10n: l10nEn), 'Potholes');
      expect(localizedCategory('water', l10n: l10nEn), 'Water');
      expect(localizedCategory('water_leakage', l10n: l10nEn), 'Water Leakage');
      expect(localizedCategory('sanitation', l10n: l10nEn), 'Sanitation');
      expect(localizedCategory('waste', l10n: l10nEn), 'Waste Management');
      expect(localizedCategory('garbage_overflow', l10n: l10nEn), 'Garbage Overflow');
      expect(localizedCategory('streetlights', l10n: l10nEn), 'Street Lights');
      expect(localizedCategory('drainage', l10n: l10nEn), 'Drainage');
      expect(localizedCategory('infrastructure', l10n: l10nEn), 'Public Infrastructure');
      expect(localizedCategory('traffic', l10n: l10nEn), 'Traffic / Road Safety');
      expect(localizedCategory('trees', l10n: l10nEn), 'Fallen / Dangerous Trees');
      expect(localizedCategory('other', l10n: l10nEn), 'Other');

      // Hindi
      expect(localizedCategory('roads', l10n: l10nHi), 'सड़कें');
      expect(localizedCategory('water', l10n: l10nHi), 'जल आपूर्ति');
      expect(localizedCategory('waste', l10n: l10nHi), 'कचरा प्रबंधन');

      // Marathi
      expect(localizedCategory('roads', l10n: l10nMr), 'रस्ते');
      expect(localizedCategory('water', l10n: l10nMr), 'पाणीपुरवठा');
      expect(localizedCategory('waste', l10n: l10nMr), 'कचरा व्यवस्थापन');
    });

    test('localizes category descriptions', () {
      expect(localizedCategoryDescription('roads', l10n: l10nEn), isNotEmpty);
      expect(localizedCategoryDescription('water', l10n: l10nEn), isNotEmpty);
    });
  });

  group('Phase 5 — Domain 4: Civic Department Mapper (18 BMC Departments)', () {
    test('localizes all 18 BMC Technical Departments across en, hi, mr', () {
      final deptCodes = [
        'roads_maintenance',
        'roads_traffic',
        'water_works',
        'solid_waste_management',
        'building_factory',
        'gardens_trees',
        'public_health',
        'pest_control_insecticide',
        'encroachment_removal',
        'licence_department',
        'shops_establishments',
        'assessment_collection',
        'estate_department',
        'colony_slum_improvement',
        'education_schools',
        'security_force',
        'legal_department',
        'administration_establishment',
        'town_planning',
      ];

      for (final code in deptCodes) {
        final en = localizedDepartment(code, l10n: l10nEn);
        final hi = localizedDepartment(code, l10n: l10nHi);
        final mr = localizedDepartment(code, l10n: l10nMr);

        expect(en, isNotEmpty, reason: 'En dept label for $code');
        expect(hi, isNotEmpty, reason: 'Hi dept label for $code');
        expect(mr, isNotEmpty, reason: 'Mr dept label for $code');
      }
    });

    test('maps CivicDepartment model instances directly', () {
      const dept = CivicDepartment(
        departmentId: 'roads_maintenance',
        departmentCode: 'RDS',
        displayName: 'Roads & Maintenance',
        description: 'Road repair',
        defaultLeadDesignation: 'Executive Engineer',
      );
      expect(localizedDepartment(dept, l10n: l10nEn), 'Roads & Maintenance');
      expect(localizedDepartment(dept, l10n: l10nHi), 'सड़क एवं रखरखाव विभाग');
      expect(localizedDepartment(dept, l10n: l10nMr), 'रस्ते आणि देखभाल विभाग');
    });
  });

  group('Phase 5 — Domain 5: Government Role Mapper', () {
    test('localizes all 6 GovernmentRole enums across en, hi, mr', () {
      expect(localizedGovernmentRole(GovernmentRole.governmentSuperAdmin, l10n: l10nEn), 'Municipal Commissioner / Super Admin');
      expect(localizedGovernmentRole(GovernmentRole.zonalDmc, l10n: l10nEn), 'Zonal Deputy Municipal Commissioner');
      expect(localizedGovernmentRole(GovernmentRole.centralDepartmentHod, l10n: l10nEn), 'Central Department Head of Department');
      expect(localizedGovernmentRole(GovernmentRole.wardOfficer, l10n: l10nEn), 'Assistant Municipal Commissioner (Ward Officer)');
      expect(localizedGovernmentRole(GovernmentRole.wardDepartmentLead, l10n: l10nEn), 'Ward Department Lead');
      expect(localizedGovernmentRole(GovernmentRole.departmentCrew, l10n: l10nEn), 'Junior Engineer / Field Execution Officer');

      expect(localizedGovernmentRole(GovernmentRole.governmentSuperAdmin, l10n: l10nHi), 'महानगरपालिका आयुक्त / सुपर एडमिन');
      expect(localizedGovernmentRole(GovernmentRole.departmentCrew, l10n: l10nHi), 'कनिष्ठ अभियंता / फील्ड निष्पादन अधिकारी');

      expect(localizedGovernmentRole(GovernmentRole.governmentSuperAdmin, l10n: l10nMr), 'महानगरपालिका आयुक्त / सुपर अ‍ॅडमिन');
      expect(localizedGovernmentRole(GovernmentRole.departmentCrew, l10n: l10nMr), 'कनिष्ठ अभियंता / क्षेत्रीय अंमलबजावणी अधिकारी');
    });

    test('supports designation titles (Executive Engineer, Sub-Engineer, Medical Officer)', () {
      expect(localizedGovernmentRole('assistant_engineer', l10n: l10nEn), 'Assistant Engineer');
      expect(localizedGovernmentRole('executive_engineer', l10n: l10nEn), 'Executive Engineer');
      expect(localizedGovernmentRole('sub_engineer', l10n: l10nEn), 'Sub-Engineer');
      expect(localizedGovernmentRole('medical_officer', l10n: l10nEn), 'Medical Officer of Health');
    });
  });

  group('Phase 5 — Domain 6: Verification State Mapper', () {
    test('localizes canonical AI/human verification tokens', () {
      expect(localizedVerificationState('pending', l10n: l10nEn), 'Verification Pending');
      expect(localizedVerificationState('processing', l10n: l10nEn), 'Analyzing & Verifying...');
      expect(localizedVerificationState('passed', l10n: l10nEn), 'Verification Passed');
      expect(localizedVerificationState('failed', l10n: l10nEn), 'Verification Failed');
      expect(localizedVerificationState('temporarily_unavailable', l10n: l10nEn), 'Automated Verification Delayed');
      expect(localizedVerificationState('human_department_review', l10n: l10nEn), 'Department Officer Review');
      expect(localizedVerificationState('verification_completed', l10n: l10nEn), 'Verification Completed');

      // Hindi
      expect(localizedVerificationState('pending', l10n: l10nHi), 'सत्यापन लंबित');
      expect(localizedVerificationState('passed', l10n: l10nHi), 'सत्यापन सफल');

      // Marathi
      expect(localizedVerificationState('pending', l10n: l10nMr), 'पडताळणी प्रलंबित');
      expect(localizedVerificationState('passed', l10n: l10nMr), 'पडताळणी यशस्वी');
    });
  });

  group('Phase 5 — Domain 7: Routing State & Routing Ticket Mapper', () {
    test('localizes ComplaintRoutingStatus enums across en, hi, mr', () {
      expect(localizedRoutingStatus(ComplaintRoutingStatus.unassigned, l10n: l10nEn), 'Unassigned');
      expect(localizedRoutingStatus(ComplaintRoutingStatus.assigned, l10n: l10nEn), 'Assigned');
      expect(localizedRoutingStatus(ComplaintRoutingStatus.reassignmentRequested, l10n: l10nEn), 'Reassignment Requested');
      expect(localizedRoutingStatus(ComplaintRoutingStatus.transferred, l10n: l10nEn), 'Transferred');
      expect(localizedRoutingStatus(ComplaintRoutingStatus.inProgress, l10n: l10nEn), 'In Progress');
      expect(localizedRoutingStatus(ComplaintRoutingStatus.resolved, l10n: l10nEn), 'Resolved');

      expect(localizedRoutingStatus(ComplaintRoutingStatus.reassignmentRequested, l10n: l10nHi), 'पुनः आवंटन का अनुरोध');
      expect(localizedRoutingStatus(ComplaintRoutingStatus.reassignmentRequested, l10n: l10nMr), 'पुनर्नियुक्तीची विनंती');
    });

    test('localizes RoutingTicketStatus enums across en, hi, mr', () {
      expect(localizedRoutingTicketStatus(RoutingTicketStatus.pending, l10n: l10nEn), 'Pending Ward Officer Review');
      expect(localizedRoutingTicketStatus(RoutingTicketStatus.approved, l10n: l10nEn), 'Reassignment Approved');
      expect(localizedRoutingTicketStatus(RoutingTicketStatus.rejected, l10n: l10nEn), 'Reassignment Rejected');
      expect(localizedRoutingTicketStatus(RoutingTicketStatus.cancelled, l10n: l10nEn), 'Ticket Cancelled');

      expect(localizedRoutingTicketStatus(RoutingTicketStatus.approved, l10n: l10nHi), 'पुनर्आवंटन स्वीकृत');
      expect(localizedRoutingTicketStatus(RoutingTicketStatus.approved, l10n: l10nMr), 'पुनर्नियुक्ती मंजूर');
    });
  });

  group('Phase 5 — Domain 8: Assignment State Mapper', () {
    test('localizes ComplaintAssignmentStatus enums across en, hi, mr', () {
      expect(localizedAssignmentStatus(ComplaintAssignmentStatus.unassigned, l10n: l10nEn), 'Unassigned');
      expect(localizedAssignmentStatus(ComplaintAssignmentStatus.leadAssigned, l10n: l10nEn), 'Assigned to Ward Lead');
      expect(localizedAssignmentStatus(ComplaintAssignmentStatus.crewAssigned, l10n: l10nEn), 'Assigned to Ground Crew');
      expect(localizedAssignmentStatus(ComplaintAssignmentStatus.fieldOfficerAssigned, l10n: l10nEn), 'Assigned to Field Officer');

      expect(localizedAssignmentStatus(ComplaintAssignmentStatus.leadAssigned, l10n: l10nHi), 'वार्ड लीड को आवंटित');
      expect(localizedAssignmentStatus(ComplaintAssignmentStatus.leadAssigned, l10n: l10nMr), 'प्रभाग प्रमुखांकडे नियुक्त');
    });
  });

  group('Phase 5 — Domain 9: Field Execution State Mapper', () {
    test('localizes field execution states across en, hi, mr', () {
      expect(localizedExecutionState('notStarted', l10n: l10nEn), 'Ready to Start');
      expect(localizedExecutionState('inProgress', l10n: l10nEn), 'Execution In Progress');
      expect(localizedExecutionState('blocked', l10n: l10nEn), 'Execution Blocked');
      expect(localizedExecutionState('awaitingEvidence', l10n: l10nEn), 'Awaiting Ground Evidence');
      expect(localizedExecutionState('completed', l10n: l10nEn), 'Work Completed');

      expect(localizedExecutionState('inProgress', l10n: l10nHi), 'कार्य प्रगति पर है');
      expect(localizedExecutionState('completed', l10n: l10nHi), 'कार्य पूर्ण हुआ');

      expect(localizedExecutionState('inProgress', l10n: l10nMr), 'काम प्रगतीपथावर आहे');
      expect(localizedExecutionState('completed', l10n: l10nMr), 'काम पूर्ण झाले');
    });
  });

  group('Phase 5 — Domain 10: Resolution State Mapper', () {
    test('localizes resolution lifecycle states across en, hi, mr', () {
      expect(localizedResolutionState('pending', l10n: l10nEn), 'Resolution Pending');
      expect(localizedResolutionState('submitted', l10n: l10nEn), 'Resolution Submitted');
      expect(localizedResolutionState('approved', l10n: l10nEn), 'Resolution Approved');
      expect(localizedResolutionState('rejected', l10n: l10nEn), 'Resolution Rejected');
      expect(localizedResolutionState('closed', l10n: l10nEn), 'Resolution Closed');

      expect(localizedResolutionState('approved', l10n: l10nHi), 'समाधान स्वीकृत');
      expect(localizedResolutionState('approved', l10n: l10nMr), 'निवारण मंजूर');
    });
  });

  group('Phase 5 — Domain 11: Supervisory Rework State Mapper', () {
    test('localizes rework states across en, hi, mr', () {
      expect(localizedReworkState('none', l10n: l10nEn), 'No Rework Required');
      expect(localizedReworkState('required', l10n: l10nEn), 'Rework Required');
      expect(localizedReworkState('inProgress', l10n: l10nEn), 'Rework In Progress');
      expect(localizedReworkState('submitted', l10n: l10nEn), 'Rework Submitted');
      expect(localizedReworkState('approved', l10n: l10nEn), 'Rework Approved');

      expect(localizedReworkState('required', l10n: l10nHi), 'पुनः कार्य आवश्यक');
      expect(localizedReworkState('required', l10n: l10nMr), 'पुन्हा काम आवश्यक');
    });
  });

  group('Phase 5 — Domain 12: Synchronization State Mapper', () {
    test('localizes SyncStatus enums and queue states across en, hi, mr', () {
      expect(localizedSyncStatus(SyncStatus.synced, l10n: l10nEn), 'Synced');
      expect(localizedSyncStatus(SyncStatus.pending, l10n: l10nEn), 'Pending Sync');
      expect(localizedSyncStatus(SyncStatus.syncing, l10n: l10nEn), 'Syncing...');
      expect(localizedSyncStatus(SyncStatus.failed, l10n: l10nEn), 'Sync Failed');
      expect(localizedSyncStatus('offline', l10n: l10nEn), 'Offline Queue');
      expect(localizedSyncStatus('retrying', l10n: l10nEn), 'Retrying Sync...');

      expect(localizedSyncStatus(SyncStatus.synced, l10n: l10nHi), 'सिंक हुआ');
      expect(localizedSyncStatus(SyncStatus.synced, l10n: l10nMr), 'सिंक केले');
    });
  });

  group('Phase 5 — Domain 13: Notification Type Mapper', () {
    test('localizes NotificationType enums and models across en, hi, mr', () {
      expect(localizedNotificationType(NotificationType.complaintSubmitted, l10n: l10nEn), 'Complaint Submitted');
      expect(localizedNotificationType(NotificationType.complaintVerified, l10n: l10nEn), 'Complaint Verified');
      expect(localizedNotificationType(NotificationType.complaintAssigned, l10n: l10nEn), 'Complaint Assigned');
      expect(localizedNotificationType(NotificationType.complaintStatusChanged, l10n: l10nEn), 'Status Updated');
      expect(localizedNotificationType(NotificationType.complaintResolved, l10n: l10nEn), 'Complaint Resolved');
      expect(localizedNotificationType(NotificationType.generalCivic, l10n: l10nEn), 'Civic Announcement');
      expect(localizedNotificationType(NotificationType.hazardAlert, l10n: l10nEn), 'Hazard Warning');
      expect(localizedNotificationType(NotificationType.rewardEarned, l10n: l10nEn), 'Reward Earned');
      expect(localizedNotificationType('slaWarning', l10n: l10nEn), 'SLA Deadline Warning');
      expect(localizedNotificationType('reworkRequested', l10n: l10nEn), 'Rework Requested');

      expect(localizedNotificationType(NotificationType.complaintResolved, l10n: l10nHi), 'शिकायत का समाधान हुआ');
      expect(localizedNotificationType(NotificationType.complaintResolved, l10n: l10nMr), 'तक्रारीचे निवारण झाले');
    });
  });

  group('Phase 5 — Domain 14: Gamification, Achievements & Civic Levels', () {
    test('localizes achievements across en, hi, mr', () {
      expect(localizedAchievementTitle('first_report', l10n: l10nEn), 'First Report');
      expect(localizedAchievementTitle('active_citizen', l10n: l10nEn), 'Active Citizen');
      expect(localizedAchievementTitle('neighborhood_hero', l10n: l10nEn), 'Neighborhood Hero');
      expect(localizedAchievementTitle('sharp_eye', l10n: l10nEn), 'Sharp Eye');
      expect(localizedAchievementTitle('community_pillar', l10n: l10nEn), 'Community Pillar');
      expect(localizedAchievementTitle('ground_reporter', l10n: l10nEn), 'Ground Reporter');
      expect(localizedAchievementTitle('community_voice', l10n: l10nEn), 'Community Voice');
      expect(localizedAchievementTitle('resolution_champion', l10n: l10nEn), 'Resolution Champion');

      expect(localizedAchievementTitle('first_report', l10n: l10nHi), 'पहली शिकायत');
      expect(localizedAchievementTitle('first_report', l10n: l10nMr), 'पहिली तक्रार');
    });

    test('localizes civic levels 1 to 5', () {
      expect(localizedCivicLevelTitle(1, l10n: l10nEn), 'Civic Starter');
      expect(localizedCivicLevelTitle(2, l10n: l10nEn), 'Civic Contributor');
      expect(localizedCivicLevelTitle(3, l10n: l10nEn), 'Civic Champion');
      expect(localizedCivicLevelTitle(4, l10n: l10nEn), 'Civic Leader');
      expect(localizedCivicLevelTitle(5, l10n: l10nEn), 'Civic Hero');

      expect(localizedCivicLevelTitle(1, l10n: l10nHi), 'नागरिक शुरुआत');
      expect(localizedCivicLevelTitle(1, l10n: l10nMr), 'नागरी नवशिक्या');
    });
  });

  group('Phase 5 — Domain 15: Basemap Mode Mapper', () {
    test('localizes BasemapMode enums across en, hi, mr', () {
      expect(localizedBasemapMode(BasemapMode.streets, l10n: l10nEn), 'Streets');
      expect(localizedBasemapMode(BasemapMode.satellite, l10n: l10nEn), 'Satellite');
      expect(localizedBasemapMode(BasemapMode.hybrid, l10n: l10nEn), 'Hybrid');

      expect(localizedBasemapMode(BasemapMode.streets, l10n: l10nHi), 'सड़कें');
      expect(localizedBasemapMode(BasemapMode.streets, l10n: l10nMr), 'रस्ते');
    });

    test('localizes BasemapMode descriptions', () {
      expect(localizedBasemapModeDescription(BasemapMode.streets, l10n: l10nEn), isNotEmpty);
      expect(localizedBasemapModeDescription(BasemapMode.satellite, l10n: l10nEn), isNotEmpty);
      expect(localizedBasemapModeDescription(BasemapMode.hybrid, l10n: l10nEn), isNotEmpty);
    });
  });

  group('Phase 5 — Domain 16: Jurisdiction Type & Scope Mapper', () {
    test('localizes jurisdiction types across en, hi, mr', () {
      expect(localizedJurisdictionType('zone', l10n: l10nEn), 'Zone Jurisdiction');
      expect(localizedJurisdictionType('ward', l10n: l10nEn), 'Ward Jurisdiction');
      expect(localizedJurisdictionType('department', l10n: l10nEn), 'Department Jurisdiction');
      expect(localizedJurisdictionType('role', l10n: l10nEn), 'Role Scope');
      expect(localizedJurisdictionType('citywide', l10n: l10nEn), 'Citywide (All Zones & Wards)');

      expect(localizedJurisdictionType('zone', l10n: l10nHi), 'ज़ोन क्षेत्राधिकार');
      expect(localizedJurisdictionType('zone', l10n: l10nMr), 'परिमंडळ कार्यक्षेत्र');
    });

    test('generates parameterized jurisdiction scope strings', () {
      expect(localizedJurisdictionScope(isCitywide: true, l10n: l10nEn), 'Citywide (All Zones & Wards)');
      expect(localizedJurisdictionScope(ward: 'K-West', l10n: l10nEn), 'Ward K-West');
      expect(localizedJurisdictionScope(zone: 'Zone 3', l10n: l10nEn), 'Zone Zone 3');
    });
  });

  group('Phase 5 — Domain 17: SLA Compliance State Mapper', () {
    test('localizes SLA compliance status across en, hi, mr', () {
      expect(localizedSlaStatus('healthy', l10n: l10nEn), 'Within SLA Target');
      expect(localizedSlaStatus('warning', l10n: l10nEn), 'Approaching SLA Deadline');
      expect(localizedSlaStatus('breached', l10n: l10nEn), 'SLA Breached');

      expect(localizedSlaStatus('healthy', l10n: l10nHi), 'एसएलए लक्ष्य के भीतर');
      expect(localizedSlaStatus('breached', l10n: l10nHi), 'एसएलए उल्लंघन');

      expect(localizedSlaStatus('healthy', l10n: l10nMr), 'एसएलए मुदतीत');
      expect(localizedSlaStatus('breached', l10n: l10nMr), 'एसएलए मुदत उलटली');
    });
  });

  group('Phase 5 — Strict Canonical Invariance & Serialization Tests', () {
    test('ComplaintModel properties maintain raw canonical tokens and immutable user text', () {
      final complaint = ComplaintModel(
        id: 'comp_test_001',
        ticketNumber: 'CF-2026-001',
        title: 'Water pipe leakage on Main St',
        description: 'Large puddle forming near bus station',
        category: const CivicCategory(id: 'water_leakage', name: 'Water Leakage', description: '', icon: Icons.water),
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.high,
        location: const CivicLocation(latitude: 19.0760, longitude: 72.8777, address: 'Andheri East'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        assignedDepartmentId: 'water_works',
        routingStatus: ComplaintRoutingStatus.assigned,
        assignmentStatus: ComplaintAssignmentStatus.crewAssigned,
        syncStatus: SyncStatus.synced,
      );

      // Verify canonical tokens on model instances
      expect(complaint.status.name, 'inProgress');
      expect(complaint.priority.name, 'high');
      expect(complaint.category.id, 'water_leakage');
      expect(complaint.assignedDepartmentId, 'water_works');
      expect(complaint.routingStatus.name, 'assigned');
      expect(complaint.assignmentStatus.name, 'crewAssigned');
      expect(complaint.syncStatus.name, 'synced');

      // Verify that user-entered text remains 100% untouched
      expect(complaint.title, 'Water pipe leakage on Main St');
      expect(complaint.description, 'Large puddle forming near bus station');
    });

    test('ComplaintRoutingTicket serialization preserves canonical status tokens', () {
      final ticket = ComplaintRoutingTicket(
        id: 'rt_001',
        complaintId: 'comp_test_001',
        ticketNumber: 'CF-2026-001',
        wardId: 'K-West',
        sourceDepartmentId: 'roads_maintenance',
        sourceLeadId: 'lead_001',
        suggestedDepartmentId: 'water_works',
        reason: 'Underground pipeline burst, not road surface defect',
        status: RoutingTicketStatus.pending,
        createdAt: DateTime.now(),
      );

      final json = ticket.toJson();
      expect(json['status'], 'pending');
      expect(json['sourceDepartmentId'], 'roads_maintenance');
      expect(json['suggestedDepartmentId'], 'water_works');
      expect(json['reason'], 'Underground pipeline burst, not road surface defect');
    });

    test('CivicDepartment serialization preserves canonical ASCII department codes', () {
      const dept = CivicDepartment(
        departmentId: 'solid_waste_management',
        departmentCode: 'SWM',
        displayName: 'Solid Waste Management',
        description: 'Garbage and waste handling',
        defaultLeadDesignation: 'Executive Engineer',
      );

      final json = dept.toJson();
      expect(json['departmentId'], 'solid_waste_management');
      expect(json['departmentCode'], 'SWM');
      expect(json['displayName'], 'Solid Waste Management');
    });
  });

  group('Phase 5 — Unknown Token Safe Fallback & Telemetry', () {
    test('handles completely unknown or arbitrary canonical tokens safely without exceptions', () {
      // Unknown status
      expect(localizedComplaintStatus('manual_escalation_required', l10n: l10nEn), 'Manual Escalation Required');
      expect(localizedComplaintStatus('customAnomalyStatus', l10n: l10nEn), 'Custom Anomaly Status');

      // Unknown priority
      expect(localizedComplaintPriority('p1_critical_vip', l10n: l10nEn), 'P1 Critical Vip');

      // Unknown category
      expect(localizedCategory('wildlife_hazard', l10n: l10nEn), 'Wildlife Hazard');

      // Unknown department (no generic keyword collision)
      expect(localizedDepartment('autonomous_aerial_patrol', l10n: l10nEn), 'Autonomous Aerial Patrol');

      // Unknown role
      expect(localizedGovernmentRole('drone_survey_pilot', l10n: l10nEn), 'Drone Survey Pilot');

      // Unknown execution state
      expect(localizedExecutionState('special_permit_awaiting', l10n: l10nEn), 'Special Permit Awaiting');
    });
  });

  group('Phase 5 — Extension Helpers on BuildContext & Enums', () {
    testWidgets('enum extensions resolve localized strings in Widget tree', (tester) async {
      late String statusLabel;
      late String priorityLabel;
      late String roleLabel;
      late String syncLabel;
      late String basemapLabel;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('hi'),
          home: Builder(
            builder: (context) {
              statusLabel = LocalizedComplaintStatus(ComplaintStatus.inProgress).localizedLabel(context);
              priorityLabel = LocalizedComplaintPriority(ComplaintPriority.emergency).localizedLabel(context);
              roleLabel = LocalizedGovernmentRole(GovernmentRole.departmentCrew).localizedLabel(context);
              syncLabel = LocalizedSyncStatus(SyncStatus.synced).localizedLabel(context);
              basemapLabel = LocalizedBasemapMode(BasemapMode.streets).localizedLabel(context);
              return Container();
            },
          ),
        ),
      );

      expect(statusLabel, 'प्रगति पर');
      expect(priorityLabel, 'गंभीर');
      expect(roleLabel, 'कनिष्ठ अभियंता / फील्ड निष्पादन अधिकारी');
      expect(syncLabel, 'सिंक हुआ');
      expect(basemapLabel, 'सड़कें');
    });
  });
}
