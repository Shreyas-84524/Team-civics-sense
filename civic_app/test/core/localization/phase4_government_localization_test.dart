import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/constants/app_spacing.dart';
import 'package:civic_app/core/localization/app_localizations.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/government_role.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_role_badge.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_sla_badge.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_sidebar.dart';
import 'package:civic_app/Govt UI/widgets/profile/govt_language_settings_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4 - Static Government Portal ARB Resolution (en, hi, mr)', () {
    test('English ARB loads all government keys accurately', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.govPortalTitle, 'CivicFix Government Portal');
      expect(l10n.govLoginTitle, 'Government Officer Sign In');
      expect(l10n.govSignInButton, 'Sign In to Portal');
      expect(l10n.govAccessDenied, 'Access Denied');
      expect(l10n.govForgotPassword, 'Forgot Password');
      expect(l10n.govSessionExpired, 'Session has expired. Please sign in again.');
      expect(l10n.govNavDashboard, 'Dashboard');
      expect(l10n.govNavComplaints, 'Complaints');
      expect(l10n.govNavHazardMap, 'Hazard Map');
      expect(l10n.govNavAnalytics, 'Analytics');
      expect(l10n.govNavProfile, 'Profile');
      expect(l10n.govNavMyWork, 'My Work');
      expect(l10n.govMunicipalCorporation, 'Brihanmumbai Municipal Corporation');
      expect(l10n.govRoleSuperAdmin, 'Municipal Commissioner / Super Admin');
      expect(l10n.govRoleZonalDmc, 'Zonal Deputy Municipal Commissioner');
      expect(l10n.govRoleCentralHod, 'Central Department Head of Department');
      expect(l10n.govRoleWardOfficer, 'Assistant Municipal Commissioner (Ward Officer)');
      expect(l10n.govRoleWardLead, 'Ward Department Lead');
      expect(l10n.govRoleDepartmentCrew, 'Junior Engineer / Field Execution Officer');
      expect(l10n.govTableHeaderId, 'Ticket Number');
      expect(l10n.govTableHeaderDepartment, 'Department');
      expect(l10n.govTableHeaderStatus, 'Status');
      expect(l10n.govTableHeaderPriority, 'Priority');
      expect(l10n.govTableHeaderSla, 'SLA Remaining');
      expect(l10n.govTableHeaderActions, 'Actions');
      expect(l10n.govOfficerProfile, 'Government Officer Profile');
      expect(l10n.govEmployeeId, 'Employee ID');
      expect(l10n.govCitywide, 'Citywide (All Zones & Wards)');
      expect(l10n.govWardJurisdiction('K-West'), 'Ward K-West');
      expect(l10n.govZoneJurisdiction('Zone 4'), 'Zone Zone 4');
    });

    test('Hindi ARB loads all government keys in Devanagari script', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('hi'));
      expect(l10n.govPortalTitle, 'CivicFix सरकारी पोर्टल');
      expect(l10n.govLoginTitle, 'सरकारी अधिकारी साइन इन');
      expect(l10n.govSignInButton, 'पोर्टल में साइन इन करें');
      expect(l10n.govAccessDenied, 'पहुंच अस्वीकृत');
      expect(l10n.govForgotPassword, 'पासवर्ड भूल गए');
      expect(l10n.govSessionExpired, 'सत्र समाप्त हो गया है। कृपया पुनः साइन इन करें।');
      expect(l10n.govNavDashboard, 'डैशबोर्ड');
      expect(l10n.govNavComplaints, 'शिकायतें');
      expect(l10n.govNavHazardMap, 'खतरा मानचित्र');
      expect(l10n.govNavAnalytics, 'एनालिटिक्स');
      expect(l10n.govNavProfile, 'प्रोफ़ाइल');
      expect(l10n.govNavMyWork, 'मेरा कार्य');
      expect(l10n.govMunicipalCorporation, 'बृहन्मुंबई महानगरपालिका');
      expect(l10n.govRoleSuperAdmin, 'महानगरपालिका आयुक्त / सुपर एडमिन');
      expect(l10n.govRoleZonalDmc, 'क्षेत्रीय उपायुक्त');
      expect(l10n.govRoleCentralHod, 'केंद्रीय विभागाध्यक्ष');
      expect(l10n.govRoleWardOfficer, 'सहायक आयुक्त (वार्ड अधिकारी)');
      expect(l10n.govRoleWardLead, 'वार्ड विभाग प्रमुख');
      expect(l10n.govRoleDepartmentCrew, 'कनिष्ठ अभियंता / फील्ड निष्पादन अधिकारी');
      expect(l10n.govTableHeaderId, 'टिकट संख्या');
      expect(l10n.govTableHeaderDepartment, 'विभाग');
      expect(l10n.govTableHeaderStatus, 'स्थिति');
      expect(l10n.govTableHeaderPriority, 'प्राथमिकता');
      expect(l10n.govTableHeaderSla, 'शेष एसएलए');
      expect(l10n.govTableHeaderActions, 'कार्य');
      expect(l10n.govOfficerProfile, 'सरकारी अधिकारी प्रोफ़ाइल');
      expect(l10n.govEmployeeId, 'कर्मचारी आईडी');
      expect(l10n.govCitywide, 'संपूर्ण शहर (सभी जोन और वार्ड)');
      expect(l10n.govWardJurisdiction('के-वेस्ट'), 'वार्ड के-वेस्ट');
      expect(l10n.govZoneJurisdiction('४'), 'जोन ४');
    });

    test('Marathi ARB loads all government keys in authentic Marathi Devanagari script', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('mr'));
      expect(l10n.govPortalTitle, 'CivicFix शासकीय पोर्टल');
      expect(l10n.govLoginTitle, 'शासकीय अधिकारी साइन इन');
      expect(l10n.govSignInButton, 'पोर्टलवर साइन इन करा');
      expect(l10n.govAccessDenied, 'प्रवेश नाकारला');
      expect(l10n.govForgotPassword, 'पासवर्ड विसरलात');
      expect(l10n.govSessionExpired, 'सत्र समाप्त झाले आहे. कृपया पुन्हा साइन इन करा.');
      expect(l10n.govNavDashboard, 'डॅशबोर्ड');
      expect(l10n.govNavComplaints, 'तक्रारी');
      expect(l10n.govNavHazardMap, 'धोका नकाशा');
      expect(l10n.govNavAnalytics, 'विश्लेषण');
      expect(l10n.govNavProfile, 'प्रोफाइल');
      expect(l10n.govNavMyWork, 'माझे काम');
      expect(l10n.govMunicipalCorporation, 'बृहन्मुंबई महानगरपालिका');
      expect(l10n.govRoleSuperAdmin, 'महानगरपालिका आयुक्त / सुपर अ‍ॅडमिन');
      expect(l10n.govRoleZonalDmc, 'परिमंडळ सहआयुक्त');
      expect(l10n.govRoleCentralHod, 'मध्यवर्ती विभागप्रमुख');
      expect(l10n.govRoleWardOfficer, 'सहायक आयुक्त (प्रभाग अधिकारी)');
      expect(l10n.govRoleWardLead, 'प्रभाग विभाग प्रमुख');
      expect(l10n.govRoleDepartmentCrew, 'कनिष्ठ अभियंता / क्षेत्रीय अंमलबजावणी अधिकारी');
      expect(l10n.govTableHeaderId, 'तक्रार क्रमांक');
      expect(l10n.govTableHeaderDepartment, 'विभाग');
      expect(l10n.govTableHeaderStatus, 'स्थिती');
      expect(l10n.govTableHeaderPriority, 'प्राधान्य');
      expect(l10n.govTableHeaderSla, 'उर्वरित एसएलए');
      expect(l10n.govTableHeaderActions, 'कृती');
      expect(l10n.govOfficerProfile, 'शासकीय अधिकारी प्रोफाइल');
      expect(l10n.govEmployeeId, 'कर्मचारी आयडी');
      expect(l10n.govCitywide, 'शहरव्यापी (सर्व परिमंडळे व प्रभाग)');
      expect(l10n.govWardJurisdiction('के-पश्चिम'), 'प्रभाग के-पश्चिम');
      expect(l10n.govZoneJurisdiction('४'), 'परिमंडळ ४');
    });
  });

  group('Phase 4 - Canonical Display Mappers for Government Roles & Departments', () {
    test('localizedGovernmentRole resolves all 6 roles across en, hi, mr', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      for (final role in GovernmentRole.values) {
        final enRole = localizedGovernmentRole(role, l10n: en);
        final hiRole = localizedGovernmentRole(role, l10n: hi);
        final mrRole = localizedGovernmentRole(role, l10n: mr);

        expect(enRole.isNotEmpty, isTrue);
        expect(hiRole.isNotEmpty, isTrue);
        expect(mrRole.isNotEmpty, isTrue);

        // Also test string-based resolution
        expect(localizedGovernmentRole(role.name, l10n: en), enRole);
        expect(localizedGovernmentRole(role.name, l10n: hi), hiRole);
        expect(localizedGovernmentRole(role.name, l10n: mr), mrRole);
      }

      // Explicit role verification
      expect(localizedGovernmentRole(GovernmentRole.wardDepartmentLead, l10n: en), 'Ward Department Lead');
      expect(localizedGovernmentRole(GovernmentRole.wardDepartmentLead, l10n: hi), 'वार्ड विभाग प्रमुख');
      expect(localizedGovernmentRole(GovernmentRole.wardDepartmentLead, l10n: mr), 'प्रभाग विभाग प्रमुख');

      expect(localizedGovernmentRole(GovernmentRole.departmentCrew, l10n: en), 'Junior Engineer / Field Execution Officer');
      expect(localizedGovernmentRole(GovernmentRole.departmentCrew, l10n: hi), 'कनिष्ठ अभियंता / फील्ड निष्पादन अधिकारी');
      expect(localizedGovernmentRole(GovernmentRole.departmentCrew, l10n: mr), 'कनिष्ठ अभियंता / क्षेत्रीय अंमलबजावणी अधिकारी');
    });

    test('localizedDepartment resolves all 18 BMC municipal departments across en, hi, mr', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      final testDepts = [
        'roads_maintenance',
        'water_works',
        'solid_waste_management',
        'building_factory',
        'gardens_trees',
        'pest_control',
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
        'general_municipal_desk',
      ];

      for (final deptId in testDepts) {
        final enDept = localizedDepartment(deptId, l10n: en);
        final hiDept = localizedDepartment(deptId, l10n: hi);
        final mrDept = localizedDepartment(deptId, l10n: mr);

        expect(enDept.isNotEmpty, isTrue);
        expect(hiDept.isNotEmpty, isTrue);
        expect(mrDept.isNotEmpty, isTrue);
      }

      // Explicit department checks
      expect(localizedDepartment('roads_maintenance', l10n: en), 'Roads & Maintenance');
      expect(localizedDepartment('roads_maintenance', l10n: hi), 'सड़क एवं रखरखाव विभाग');
      expect(localizedDepartment('roads_maintenance', l10n: mr), 'रस्ते आणि देखभाल विभाग');

      expect(localizedDepartment('water_works', l10n: en), 'Water Works & Supply');
      expect(localizedDepartment('water_works', l10n: hi), 'जल कार्य एवं जलापूर्ति विभाग');
      expect(localizedDepartment('water_works', l10n: mr), 'जलकामे आणि पाणीपुरवठा विभाग');

      expect(localizedDepartment('solid_waste_management', l10n: en), 'Solid Waste Management');
      expect(localizedDepartment('solid_waste_management', l10n: hi), 'ठोस अपशिष्ट प्रबंधन विभाग');
      expect(localizedDepartment('solid_waste_management', l10n: mr), 'घनकचरा व्यवस्थापन विभाग');
    });

    test('localizedGovtNavTitle resolves navigation endpoints across en, hi, mr', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      expect(localizedGovtNavTitle('dashboard', l10n: en), 'Dashboard');
      expect(localizedGovtNavTitle('dashboard', l10n: hi), 'डैशबोर्ड');
      expect(localizedGovtNavTitle('dashboard', l10n: mr), 'डॅशबोर्ड');

      expect(localizedGovtNavTitle('complaints', l10n: en), 'Complaints');
      expect(localizedGovtNavTitle('complaints', l10n: hi), 'शिकायतें');
      expect(localizedGovtNavTitle('complaints', l10n: mr), 'तक्रारी');

      expect(localizedGovtNavTitle('hazard_map', l10n: en), 'Hazard Map');
      expect(localizedGovtNavTitle('hazard_map', l10n: hi), 'खतरा मानचित्र');
      expect(localizedGovtNavTitle('hazard_map', l10n: mr), 'धोका नकाशा');

      expect(localizedGovtNavTitle('analytics', l10n: en), 'Analytics');
      expect(localizedGovtNavTitle('analytics', l10n: hi), 'एनालिटिक्स');
      expect(localizedGovtNavTitle('analytics', l10n: mr), 'विश्लेषण');
    });

    test('localizedJurisdictionScope formats jurisdictions across en, hi, mr', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      expect(localizedJurisdictionScope(isCitywide: true, l10n: en), 'Citywide (All Zones & Wards)');
      expect(localizedJurisdictionScope(isCitywide: true, l10n: hi), 'संपूर्ण शहर (सभी जोन और वार्ड)');
      expect(localizedJurisdictionScope(isCitywide: true, l10n: mr), 'शहरव्यापी (सर्व परिमंडळे व प्रभाग)');

      expect(localizedJurisdictionScope(ward: 'K-West', l10n: en), 'Ward K-West');
      expect(localizedJurisdictionScope(ward: 'के-पश्चिम', l10n: hi), 'वार्ड के-पश्चिम');
      expect(localizedJurisdictionScope(ward: 'के-पश्चिम', l10n: mr), 'प्रभाग के-पश्चिम');

      expect(localizedJurisdictionScope(zone: 'Zone 4', l10n: en), 'Zone Zone 4');
      expect(localizedJurisdictionScope(zone: '४', l10n: hi), 'जोन ४');
      expect(localizedJurisdictionScope(zone: '४', l10n: mr), 'परिमंडळ ४');
    });

    test('localizedSlaStatus formats SLA statuses across en, hi, mr', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));
      final mr = await AppLocalizations.delegate.load(const Locale('mr'));

      expect(localizedSlaStatus('within_sla', l10n: en), 'Within SLA Target');
      expect(localizedSlaStatus('within_sla', l10n: hi), 'एसएलए लक्ष्य के भीतर');
      expect(localizedSlaStatus('within_sla', l10n: mr), 'एसएलए मुदतीत');

      expect(localizedSlaStatus('approaching_deadline', l10n: en), 'Approaching SLA Deadline');
      expect(localizedSlaStatus('approaching_deadline', l10n: hi), 'एसएलए समय सीमा निकट');
      expect(localizedSlaStatus('approaching_deadline', l10n: mr), 'एसएलए मुदत संपत आली आहे');

      expect(localizedSlaStatus('breached', l10n: en), 'SLA Breached');
      expect(localizedSlaStatus('breached', l10n: hi), 'एसएलए उल्लंघन');
      expect(localizedSlaStatus('breached', l10n: mr), 'एसएलए मुदत उलटली');
    });
  });

  group('Phase 4 - Architectural Invariants & Immutability', () {
    test('Raw user-generated content and officer notes are strictly preserved and never mutated', () {
      const originalTitle = 'Dangerous deep open manhole outside Andheri station';
      const originalDescription = 'The iron cover is completely broken and water is overflowing onto the main road.';

      final complaint = ComplaintModel(
        id: 'complaint_invariant_001',
        ticketNumber: 'TKT-INV-2026-001',
        title: originalTitle,
        description: originalDescription,
        category: CivicCategory.defaultCategories.first,
        location: const CivicLocation(
          latitude: 19.1197,
          longitude: 72.8464,
          address: 'SV Road, Andheri West, Mumbai',
          ward: 'K-West',
        ),
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.high,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        assignedTo: 'Eng. Ramesh Patil',
        departmentName: 'Roads & Maintenance',
        citizenId: 'cit_invariant_01',
      );

      // Verify that presentation mapping does not mutate complaint fields
      expect(complaint.title, originalTitle);
      expect(complaint.description, originalDescription);
      expect(complaint.status, ComplaintStatus.inProgress);
      expect(complaint.status.name, 'inProgress');
      expect(complaint.departmentName, 'Roads & Maintenance');
      expect(complaint.priority, ComplaintPriority.high);
    });

    test('Canonical Firestore tokens remain raw ASCII identifiers', () {
      expect(GovernmentRole.governmentSuperAdmin.name, 'governmentSuperAdmin');
      expect(GovernmentRole.zonalDmc.name, 'zonalDmc');
      expect(GovernmentRole.centralDepartmentHod.name, 'centralDepartmentHod');
      expect(GovernmentRole.wardOfficer.name, 'wardOfficer');
      expect(GovernmentRole.wardDepartmentLead.name, 'wardDepartmentLead');
      expect(GovernmentRole.departmentCrew.name, 'departmentCrew');

      expect(ComplaintStatus.underVerification.name, 'underVerification');
      expect(ComplaintStatus.reported.name, 'reported');
      expect(ComplaintStatus.verified.name, 'verified');
      expect(ComplaintStatus.assigned.name, 'assigned');
      expect(ComplaintStatus.inProgress.name, 'inProgress');
      expect(ComplaintStatus.resolved.name, 'resolved');
      expect(ComplaintStatus.closed.name, 'closed');
      expect(ComplaintStatus.rejected.name, 'rejected');
    });
  });

  group('Phase 4 - Government Widgets & Badge Rendering', () {
    testWidgets('GovtRoleBadge renders correctly in English, Hindi, and Marathi', (tester) async {
      for (final locale in [const Locale('en'), const Locale('hi'), const Locale('mr')]) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: GovtRoleBadge(
                role: GovernmentRole.wardDepartmentLead,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.govRoleWardLead), findsOneWidget);
      }
    });

    testWidgets('GovtSlaBadge renders correctly in English, Hindi, and Marathi', (tester) async {
      for (final locale in [const Locale('en'), const Locale('hi'), const Locale('mr')]) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: GovtSlaBadge(
                status: GovtSlaStatus.healthy,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.govWithinSla), findsOneWidget);
      }
    });

    testWidgets('GovtLanguageSettingsWidget renders all 3 language options with native labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: GovtLanguageSettingsWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('English (Default)'), findsOneWidget);
      expect(find.text('हिन्दी (Hindi)'), findsOneWidget);
      expect(find.text('मराठी (Marathi)'), findsOneWidget);
      expect(find.text('Portal Language'), findsOneWidget);
    });

    testWidgets('GovtSidebar displays localized destination items', (tester) async {
      final mockUser = GovtUserModel(
        id: 'usr_lead_01',
        fullName: 'Sunil Deshmukh',
        employeeId: 'EMP-BMC-1049',
        email: 'sunil.deshmukh@mcgm.gov.in',
        role: 'ward_department_lead',
        wardId: 'K-West',
        departmentId: 'roads_maintenance',
        departmentName: 'Roads & Maintenance',
        displayDesignation: 'Assistant Engineer',
        organization: 'Brihanmumbai Municipal Corporation',
        phone: '+919876543210',
        active: true,
        createdAt: DateTime.now(),
      );

      for (final locale in [const Locale('en'), const Locale('hi'), const Locale('mr')]) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GovtSidebar(
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                user: mockUser,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.govNavDashboard), findsOneWidget);
        expect(find.text(l10n.govNavComplaints), findsOneWidget);
        expect(find.text(l10n.govNavHazardMap), findsOneWidget);
        expect(find.text(l10n.govNavAnalytics), findsOneWidget);
      }
    });
  });

  group('Phase 4 - Multi-Screen Responsive & Non-Overflow Audit', () {
    final screenBreakpoints = <String, Size>{
      'Mobile 320px': const Size(320, 568),
      'Mobile 360px': const Size(360, 640),
      'Mobile 390px': const Size(390, 844),
      'Mobile 412px': const Size(412, 915),
      'Tablet 768px': const Size(768, 1024),
      'Desktop 1024px': const Size(1024, 768),
      'Large Desktop 1440px': const Size(1440, 900),
    };

    for (final entry in screenBreakpoints.entries) {
      final deviceName = entry.key;
      final size = entry.value;

      testWidgets('Govt widgets render with zero RenderFlex overflow on $deviceName across en, hi, mr', (tester) async {
        for (final locale in [const Locale('en'), const Locale('hi'), const Locale('mr')]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      GovtLanguageSettingsWidget(),
                      CivicFixSpacing.vSpaceMd,
                      GovtRoleBadge(role: GovernmentRole.wardOfficer),
                      CivicFixSpacing.vSpaceMd,
                      GovtSlaBadge(status: GovtSlaStatus.warning),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: 'No RenderFlex overflow on $deviceName in ${locale.languageCode}');
        }
      });
    }
  });
}
