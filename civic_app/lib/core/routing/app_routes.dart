/// Named Route Constants for CivicFix.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String registration = '/register';
  static const String verifyPhone = '/verify-phone';
  static const String forgotPassword = '/forgot-password';
  static const String mainNavigation = '/main';
  static const String home = '/home';
  static const String reportIssue = '/report-issue';
  static const String selectLocation = '/select-location';
  static const String complaintSubmitted = '/complaint-submitted';
  static const String myComplaints = '/my-complaints';
  static const String complaintDetails = '/complaint-details';
  static const String complaintTracker = '/complaint-tracker';
  static const String hazardMap = '/hazard-map';
  static const String notifications = '/notifications';
  static const String rewards = '/rewards';
  static const String assistant = '/assistant';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String notificationSettings = '/notification-settings';
  static const String privacySettings = '/privacy-settings';
  static const String about = '/about';
  static const String languageSelect = '/language-select';

  // Government Routes
  static const String govtLogin = '/govt/login';
  static const String govtForgotPassword = '/govt/forgot-password';
  static const String govtDashboard = '/govt/dashboard';
  static const String govtComplaints = '/govt/complaints';
  static const String govtComplaintDetails = '/govt/complaint-details';
  static const String govtComplaintAssignment = '/govt/complaint-assignment';
  static const String govtStatusUpdate = '/govt/status-update';
  static const String govtHazardMap = '/govt/hazard-map';
  static const String govtAnalytics = '/govt/analytics';
  static const String govtProfile = '/govt/profile';

  // Phase 1 & 2 Canonical Government Routes
  static const String government = '/government';
  static const String governmentLogin = '/government/login';
  static const String governmentDashboard = '/government/dashboard';
  static const String governmentZone = '/government/zone';
  static const String governmentDepartment = '/government/department';
  static const String governmentWard = '/government/ward';
  static const String governmentDepartmentOperations = '/government/department-operations';
  static const String governmentWork = '/government/work';
  static const String governmentAccessDenied = '/government/access-denied';
  static const String governmentComplaints = '/government/complaints';
  static const String governmentOperations = '/government/operations';
  static const String governmentAnalytics = '/government/analytics';
  static const String governmentEscalations = '/government/escalations';
  static const String governmentStaff = '/government/staff';
  static const String governmentAudit = '/government/audit';
  static const String governmentSettings = '/government/settings';

  // Development & Verification Showcase Route
  static const String govtShowcase = '/govt/showcase';
}
