import 'package:flutter/material.dart';
import '../../User UI/screens/about_screen.dart';
import '../../User UI/screens/assistant_screen.dart';
import '../../User UI/screens/complaint_details_screen.dart';
import '../../User UI/screens/complaint_submitted_screen.dart';
import '../../User UI/screens/complaint_tracker_screen.dart';
import '../../User UI/screens/edit_profile_screen.dart';
import '../../User UI/screens/forgot_password_screen.dart';
import '../../User UI/screens/hazard_map_screen.dart';
import '../../User UI/screens/login_screen.dart';
import '../../User UI/screens/main_navigation_screen.dart';
import '../../User UI/screens/my_complaints_screen.dart';
import '../../User UI/screens/notification_settings_screen.dart';
import '../../User UI/screens/notifications_screen.dart';
import '../../User UI/screens/privacy_settings_screen.dart';
import '../../User UI/screens/profile_screen.dart';
import '../../User UI/screens/phone_verification_screen.dart';
import '../../User UI/screens/registration_screen.dart';
import '../../User UI/screens/report_issue_screen.dart';
import '../../User UI/screens/rewards_screen.dart';
import '../../User UI/screens/select_location_screen.dart';
import '../../User UI/screens/settings_screen.dart';
import '../../User UI/screens/splash_screen.dart';
import '../../User UI/widgets/settings/language_selector_sheet.dart';
import '../../Govt UI/screens/auth/govt_forgot_password_screen.dart';
import '../../Govt UI/screens/auth/govt_login_screen.dart';
import '../../Govt UI/screens/common/govt_placeholder_screen.dart';
import '../../Govt UI/screens/complaints/govt_complaint_assignment_screen.dart';
import '../../Govt UI/screens/complaints/govt_complaint_details_screen.dart';
import '../../Govt UI/screens/complaints/govt_status_update_screen.dart';
import '../../Govt UI/screens/govt_shell_screen.dart';
import '../../Govt UI/screens/showcase/government_ui_showcase_screen.dart';
import '../../Govt UI/models/government_session.dart';
import '../../Govt UI/screens/auth/government_access_denied_screen.dart';
import '../../Govt UI/screens/landing/government_role_landing_screens.dart';
import '../../Govt UI/services/government_account_validator.dart';
import '../auth/auth_service_locator.dart';
import '../location/location_model.dart';
import '../models/complaint_model.dart';
import '../models/government_role.dart';
import 'app_routes.dart';

/// Centralized route generator for CivicFix application.
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // Dynamic Deep Link for Government Complaint Details: /government/complaints/:id
    if (routeName.startsWith('/government/complaints/') ||
        routeName.startsWith('/govt/complaints/')) {
      final segments = routeName.split('/');
      if (segments.length >= 4 && segments[3].isNotEmpty) {
        final complaintId = segments[3];
        return _protectedGovtRoute(
          GovtComplaintDetailsScreen(complaintId: complaintId),
          settings: settings,
        );
      }
    }

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.registration:
        return MaterialPageRoute(builder: (_) => const RegistrationScreen());

      case AppRoutes.verifyPhone:
        final initialPhone = settings.arguments is String ? settings.arguments as String : null;
        return _protectedVerifyPhoneRoute(
          PhoneVerificationScreen(initialPhone: initialPhone),
        );

      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case AppRoutes.home:
        return _protectedCitizenRoute(const MainNavigationScreen(initialIndex: 0));

      case AppRoutes.mainNavigation:
        final initialIndex = settings.arguments is int ? settings.arguments as int : 0;
        return _protectedCitizenRoute(MainNavigationScreen(initialIndex: initialIndex));

      case AppRoutes.reportIssue:
        return _protectedCitizenRoute(const ReportIssueScreen());

      case AppRoutes.selectLocation:
        final initialLoc = settings.arguments is CivicLocation ? settings.arguments as CivicLocation : null;
        return _protectedCitizenRoute(SelectLocationScreen(initialLocation: initialLoc));

      case AppRoutes.complaintSubmitted:
        final complaint = settings.arguments is ComplaintModel ? settings.arguments as ComplaintModel : null;
        return _protectedCitizenRoute(ComplaintSubmittedScreen(complaint: complaint));

      case AppRoutes.myComplaints:
        return _protectedCitizenRoute(const MyComplaintsScreen());

      case AppRoutes.complaintDetails:
        if (settings.arguments is ComplaintModel) {
          return _protectedCitizenRoute(
            ComplaintDetailsScreen(
              complaint: settings.arguments as ComplaintModel,
            ),
          );
        } else if (settings.arguments is String) {
          return _protectedCitizenRoute(
            ComplaintDetailsScreen(
              complaintId: settings.arguments as String,
            ),
          );
        }
        return _protectedCitizenRoute(const ComplaintDetailsScreen());

      case AppRoutes.complaintTracker:
        if (settings.arguments is ComplaintModel) {
          return _protectedCitizenRoute(
            ComplaintTrackerScreen(
              complaint: settings.arguments as ComplaintModel,
            ),
          );
        }
        return _errorRoute(settings.name);

      case AppRoutes.hazardMap:
        return _protectedCitizenRoute(const HazardMapScreen());

      case AppRoutes.notifications:
        return _protectedCitizenRoute(const NotificationsScreen());

      case AppRoutes.rewards:
        return _protectedCitizenRoute(const RewardsScreen());

      case AppRoutes.assistant:
        return _protectedCitizenRoute(const AssistantScreen());

      case AppRoutes.profile:
        return _protectedCitizenRoute(const ProfileScreen());

      case AppRoutes.editProfile:
        return _protectedCitizenRoute(const EditProfileScreen());

      case AppRoutes.settings:
        return _protectedCitizenRoute(const SettingsScreen());

      case AppRoutes.notificationSettings:
        return _protectedCitizenRoute(const NotificationSettingsScreen());

      case AppRoutes.privacySettings:
        return _protectedCitizenRoute(const PrivacySettingsScreen());

      case AppRoutes.about:
        return _protectedCitizenRoute(const AboutScreen());

      case AppRoutes.languageSelect:
        final currentCode = settings.arguments is String ? settings.arguments as String : 'en';
        return _protectedCitizenRoute(
          Scaffold(
            appBar: AppBar(title: const Text('Select Language')),
            body: LanguageSelectorSheet(currentLanguageCode: currentCode),
          ),
        );

      // Government Routes
      case AppRoutes.govtLogin:
      case AppRoutes.governmentLogin:
        final govtAuth = AuthServiceLocator.govtAuth;
        if (govtAuth.isAuthenticated && govtAuth.currentUser != null) {
          final user = govtAuth.currentUser!;
          final validation = GovernmentAccountValidator.validate(user);
          if (validation.isValid) {
            final session = GovernmentSession.fromUser(user);
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => _resolveLandingScreen(session.landingRoute),
            );
          }
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const GovtLoginScreen(),
        );

      case AppRoutes.govtForgotPassword:
        return MaterialPageRoute(builder: (_) => const GovtForgotPasswordScreen());

      case AppRoutes.govtDashboard:
        return _protectedGovtRoute(const GovtShellScreen(initialIndex: 0));

      case AppRoutes.govtComplaints:
        return _protectedGovtRoute(const GovtShellScreen(initialIndex: 1));

      case AppRoutes.govtHazardMap:
        return _protectedGovtRoute(const GovtShellScreen(initialIndex: 2));

      case AppRoutes.govtAnalytics:
        return _protectedGovtRoute(const GovtShellScreen(initialIndex: 3));

      case AppRoutes.govtProfile:
        return _protectedGovtRoute(const GovtShellScreen(initialIndex: 4));

      case AppRoutes.govtComplaintDetails:
        if (settings.arguments is ComplaintModel) {
          return _protectedGovtRoute(
            GovtComplaintDetailsScreen(
              complaint: settings.arguments as ComplaintModel,
            ),
          );
        } else if (settings.arguments is String) {
          return _protectedGovtRoute(
            GovtComplaintDetailsScreen(
              complaintId: settings.arguments as String,
            ),
          );
        }
        return _protectedGovtRoute(const GovtComplaintDetailsScreen());

      case AppRoutes.govtComplaintAssignment:
        final complaint = settings.arguments is ComplaintModel ? settings.arguments as ComplaintModel : null;
        return _protectedGovtRoute(
          GovtComplaintAssignmentScreen(complaint: complaint),
        );

      case AppRoutes.govtStatusUpdate:
        final complaint = settings.arguments is ComplaintModel ? settings.arguments as ComplaintModel : null;
        return _protectedGovtRoute(
          GovtStatusUpdateScreen(complaint: complaint),
        );

      // Phase 1 & 2 Canonical Government Routes
      case AppRoutes.government:
      case AppRoutes.governmentDashboard:
        return _protectedGovtRoute(
          const CityCommandCenterLanding(),
          settings: settings,
        );

      case AppRoutes.governmentZone:
        return _protectedGovtRoute(
          const ZoneCommandCenterLanding(),
          settings: settings,
        );

      case AppRoutes.governmentDepartment:
        return _protectedGovtRoute(
          const DepartmentCommandCenterLanding(),
          settings: settings,
        );

      case AppRoutes.governmentWard:
        return _protectedGovtRoute(
          const WardCommandCenterLanding(),
          settings: settings,
        );

      case AppRoutes.governmentDepartmentOperations:
        return _protectedGovtRoute(
          const DepartmentOperationsLanding(),
          settings: settings,
        );

      case AppRoutes.governmentWork:
        return _protectedGovtRoute(
          const CrewWorkdeskLanding(),
          settings: settings,
        );

      case AppRoutes.governmentAccessDenied:
        return MaterialPageRoute(
          builder: (_) => const GovernmentAccessDeniedScreen(),
          settings: settings,
        );

      case AppRoutes.governmentComplaints:
        return _protectedGovtRoute(
          const GovtShellScreen(initialIndex: 1),
          settings: settings,
        );

      case AppRoutes.governmentOperations:
        return _protectedGovtRoute(
          const GovtPlaceholderScreen(
            title: 'Municipal Operations & Field Crew',
            subtitle: 'Dispatch and workload tracking for departmental crew members',
            icon: Icons.engineering_rounded,
            moduleName: 'Operations',
            navIndex: 5,
          ),
          settings: settings,
        );

      case AppRoutes.governmentAnalytics:
        return _protectedGovtRoute(
          const GovtShellScreen(initialIndex: 3),
          settings: settings,
        );

      case AppRoutes.governmentEscalations:
        return _protectedGovtRoute(
          const GovtPlaceholderScreen(
            title: 'Statutory SLA Escalations',
            subtitle: 'Supervisory review queue for grievances exceeding statutory deadlines',
            icon: Icons.priority_high_rounded,
            moduleName: 'Escalations',
            navIndex: 6,
          ),
          settings: settings,
        );

      case AppRoutes.governmentStaff:
        return _protectedGovtRoute(
          const GovtPlaceholderScreen(
            title: 'Municipal Officers & Field Roster',
            subtitle: 'Departmental staff, designations, and supervisory hierarchies',
            icon: Icons.people_rounded,
            moduleName: 'Staff',
            navIndex: 7,
          ),
          settings: settings,
        );

      case AppRoutes.governmentAudit:
        return _protectedGovtRoute(
          const GovtPlaceholderScreen(
            title: 'Administrative Audit & Security Logs',
            subtitle: 'Immutable record of municipal actions, reassignments, and state transitions',
            icon: Icons.receipt_long_rounded,
            moduleName: 'Audit Logs',
            navIndex: 8,
          ),
          settings: settings,
        );

      case AppRoutes.governmentSettings:
        return _protectedGovtRoute(
          const GovtShellScreen(initialIndex: 4),
          settings: settings,
        );

      case AppRoutes.govtShowcase:
        return MaterialPageRoute(
          builder: (_) => const GovernmentUiShowcaseScreen(),
          settings: settings,
        );

      default:
        return _errorRoute(settings.name);
    }
  }

  /// Helper to enforce Citizen authentication and phone verification on protected citizen routes.
  static Route<dynamic> _protectedCitizenRoute(Widget authenticatedScreen) {
    final citizenAuth = AuthServiceLocator.citizenAuth;
    final isAuth = citizenAuth.isAuthenticated;
    final user = citizenAuth.currentUser;

    if (!isAuth || user == null) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }

    if (!user.phoneVerified) {
      return MaterialPageRoute(
        builder: (_) => PhoneVerificationScreen(initialPhone: user.phone),
      );
    }

    return MaterialPageRoute(builder: (_) => authenticatedScreen);
  }

  /// Helper to guard Phone Verification screen against unauthenticated or already-verified access.
  static Route<dynamic> _protectedVerifyPhoneRoute(Widget verificationScreen) {
    final citizenAuth = AuthServiceLocator.citizenAuth;
    final isAuth = citizenAuth.isAuthenticated;
    final user = citizenAuth.currentUser;

    if (!isAuth || user == null) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }

    if (user.phoneVerified) {
      return MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 0));
    }

    return MaterialPageRoute(builder: (_) => verificationScreen);
  }

  /// Helper to enforce Government authentication, account validity, and role route permissions.
  static Route<dynamic> _protectedGovtRoute(
    Widget authenticatedScreen, {
    RouteSettings? settings,
    List<GovernmentRole>? allowedRoles,
  }) {
    final govtAuth = AuthServiceLocator.govtAuth;
    final isAuth = govtAuth.isAuthenticated;
    final user = govtAuth.currentUser;

    if (!isAuth || user == null) {
      return MaterialPageRoute(
        builder: (_) => const GovtLoginScreen(),
        settings: settings,
      );
    }

    // Security invariant: strictly reject non-government / citizen accounts
    if (user.role == 'citizen') {
      return MaterialPageRoute(
        builder: (_) => const GovtLoginScreen(),
        settings: settings,
      );
    }

    // Account validation (active status, role validity, jurisdiction, supervisor)
    final validation = GovernmentAccountValidator.validate(user);
    if (!validation.isValid) {
      return MaterialPageRoute(
        builder: (_) => const GovtLoginScreen(),
        settings: settings,
      );
    }

    // Route-level permission & role jurisdiction checks
    final routeName = settings?.name;
    if (routeName != null) {
      final session = GovernmentSession.fromUser(user);
      if (!session.isAuthorizedForRoute(routeName)) {
        return MaterialPageRoute(
          builder: (_) => GovernmentAccessDeniedScreen(user: user),
          settings: settings,
        );
      }
    } else if (allowedRoles != null && !allowedRoles.contains(user.govtRole)) {
      if (!user.isSuperAdmin) {
        return MaterialPageRoute(
          builder: (_) => GovernmentAccessDeniedScreen(user: user),
          settings: settings,
        );
      }
    }

    return MaterialPageRoute(builder: (_) => authenticatedScreen, settings: settings);
  }

  static Widget _resolveLandingScreen(String landingRoute) {
    switch (landingRoute) {
      case AppRoutes.governmentDashboard:
        return const CityCommandCenterLanding();
      case AppRoutes.governmentZone:
        return const ZoneCommandCenterLanding();
      case AppRoutes.governmentDepartment:
        return const DepartmentCommandCenterLanding();
      case AppRoutes.governmentWard:
        return const WardCommandCenterLanding();
      case AppRoutes.governmentDepartmentOperations:
        return const DepartmentOperationsLanding();
      case AppRoutes.governmentWork:
        return const CrewWorkdeskLanding();
      default:
        return const CityCommandCenterLanding();
    }
  }

  static Route<dynamic> _errorRoute(String? routeName) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Navigation Error')),
        body: Center(
          child: Text('Route "$routeName" not found or missing required arguments.'),
        ),
      ),
    );
  }
}
