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
import '../../User UI/screens/registration_screen.dart';
import '../../User UI/screens/report_issue_screen.dart';
import '../../User UI/screens/rewards_screen.dart';
import '../../User UI/screens/select_location_screen.dart';
import '../../User UI/screens/settings_screen.dart';
import '../../User UI/screens/splash_screen.dart';
import '../../User UI/widgets/settings/language_selector_sheet.dart';
import '../../Govt UI/screens/auth/govt_forgot_password_screen.dart';
import '../../Govt UI/screens/auth/govt_login_screen.dart';
import '../../Govt UI/screens/complaints/govt_complaint_assignment_screen.dart';
import '../../Govt UI/screens/complaints/govt_complaint_details_screen.dart';
import '../../Govt UI/screens/complaints/govt_status_update_screen.dart';
import '../../Govt UI/screens/govt_shell_screen.dart';
import '../../Govt UI/services/govt_auth_service.dart';
import '../location/location_model.dart';
import '../models/complaint_model.dart';
import 'app_routes.dart';

/// Centralized route generator for CivicFix application.
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.registration:
        return MaterialPageRoute(builder: (_) => const RegistrationScreen());

      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 0));

      case AppRoutes.mainNavigation:
        final initialIndex = settings.arguments is int ? settings.arguments as int : 0;
        return MaterialPageRoute(builder: (_) => MainNavigationScreen(initialIndex: initialIndex));

      case AppRoutes.reportIssue:
        return MaterialPageRoute(builder: (_) => const ReportIssueScreen());

      case AppRoutes.selectLocation:
        final initialLoc = settings.arguments is CivicLocation ? settings.arguments as CivicLocation : null;
        return MaterialPageRoute(builder: (_) => SelectLocationScreen(initialLocation: initialLoc));

      case AppRoutes.complaintSubmitted:
        final complaint = settings.arguments is ComplaintModel ? settings.arguments as ComplaintModel : null;
        return MaterialPageRoute(builder: (_) => ComplaintSubmittedScreen(complaint: complaint));

      case AppRoutes.myComplaints:
        return MaterialPageRoute(builder: (_) => const MyComplaintsScreen());

      case AppRoutes.complaintDetails:
        if (settings.arguments is ComplaintModel) {
          return MaterialPageRoute(
            builder: (_) => ComplaintDetailsScreen(
              complaint: settings.arguments as ComplaintModel,
            ),
          );
        } else if (settings.arguments is String) {
          return MaterialPageRoute(
            builder: (_) => ComplaintDetailsScreen(
              complaintId: settings.arguments as String,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const ComplaintDetailsScreen(),
        );

      case AppRoutes.complaintTracker:
        if (settings.arguments is ComplaintModel) {
          return MaterialPageRoute(
            builder: (_) => ComplaintTrackerScreen(
              complaint: settings.arguments as ComplaintModel,
            ),
          );
        }
        return _errorRoute(settings.name);

      case AppRoutes.hazardMap:
        return MaterialPageRoute(builder: (_) => const HazardMapScreen());

      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case AppRoutes.rewards:
        return MaterialPageRoute(builder: (_) => const RewardsScreen());

      case AppRoutes.assistant:
        return MaterialPageRoute(builder: (_) => const AssistantScreen());

      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case AppRoutes.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case AppRoutes.notificationSettings:
        return MaterialPageRoute(builder: (_) => const NotificationSettingsScreen());

      case AppRoutes.privacySettings:
        return MaterialPageRoute(builder: (_) => const PrivacySettingsScreen());

      case AppRoutes.about:
        return MaterialPageRoute(builder: (_) => const AboutScreen());

      case AppRoutes.languageSelect:
        final currentCode = settings.arguments is String ? settings.arguments as String : 'en';
        return MaterialPageRoute(
          builder: (ctx) => Scaffold(
            appBar: AppBar(title: const Text('Select Language')),
            body: LanguageSelectorSheet(currentLanguageCode: currentCode),
          ),
        );

      // Government Routes
      case AppRoutes.govtLogin:
        return MaterialPageRoute(builder: (_) => const GovtLoginScreen());

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

      default:
        return _errorRoute(settings.name);
    }
  }

  /// Helper to enforce Government authentication on protected routes.
  static Route<dynamic> _protectedGovtRoute(Widget authenticatedScreen) {
    final isAuth = MockGovtAuthService().isAuthenticated;
    if (!isAuth) {
      return MaterialPageRoute(builder: (_) => const GovtLoginScreen());
    }
    return MaterialPageRoute(builder: (_) => authenticatedScreen);
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
