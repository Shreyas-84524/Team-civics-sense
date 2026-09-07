import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/main.dart';
import 'package:civic_app/core/constants/app_constants.dart';
import 'package:civic_app/core/local/mock_data_source.dart';
import 'package:civic_app/core/location/location_model.dart';
import 'package:civic_app/core/models/category_model.dart';
import 'package:civic_app/core/models/complaint_model.dart';
import 'package:civic_app/core/models/user_model.dart';
import 'package:civic_app/core/routing/app_router.dart';
import 'package:civic_app/core/theme/app_theme.dart';
import 'package:civic_app/core/utils/greeting_helper.dart';
import 'package:civic_app/core/models/evidence_model.dart';
import 'package:civic_app/User UI/models/complaint_draft.dart';
import 'package:civic_app/User UI/models/home_data_model.dart';
import 'package:civic_app/User UI/screens/home_screen.dart';
import 'package:civic_app/User UI/screens/login_screen.dart';
import 'package:civic_app/User UI/screens/main_navigation_screen.dart';
import 'package:civic_app/User UI/screens/registration_screen.dart';
import 'package:civic_app/User UI/screens/report_issue_screen.dart';
import 'package:civic_app/User UI/screens/select_location_screen.dart';
import 'package:civic_app/User UI/screens/forgot_password_screen.dart';
import 'package:civic_app/User UI/services/evidence_service.dart';
import 'package:civic_app/User UI/services/location_service.dart';
import 'package:civic_app/User UI/services/mock_auth_service.dart';
import 'package:civic_app/User UI/services/mock_complaint_service.dart';
import 'package:civic_app/User UI/services/mock_home_service.dart';
import 'package:civic_app/User UI/widgets/report_issue/complaint_review_card.dart';
import 'package:civic_app/User UI/widgets/report_issue/evidence_picker.dart';
import 'package:civic_app/User UI/widgets/report_issue/location_selection_card.dart';
import 'package:civic_app/User UI/widgets/report_issue/report_progress_indicator.dart';
import 'package:civic_app/core/repositories/complaint_repository.dart';
import 'package:civic_app/User UI/widgets/complaint_card.dart';
import 'package:civic_app/User UI/screens/my_complaints_screen.dart';
import 'package:civic_app/User UI/screens/complaint_details_screen.dart';
import 'package:civic_app/User UI/widgets/complaint_details/complaint_tracker.dart';
import 'package:civic_app/User UI/widgets/complaint_details/evidence_gallery.dart';
import 'package:civic_app/User UI/screens/complaint_submitted_screen.dart';
import 'package:civic_app/core/utils/date_formatter.dart';
import 'package:civic_app/core/utils/department_helper.dart';
import 'package:civic_app/core/models/hazard_model.dart';
import 'package:civic_app/core/models/notification_model.dart';
import 'package:civic_app/core/repositories/hazard_repository.dart';
import 'package:civic_app/core/repositories/notification_repository.dart';
import 'package:civic_app/User UI/screens/hazard_map_screen.dart';
import 'package:civic_app/User UI/screens/notifications_screen.dart';
import 'package:civic_app/User UI/widgets/hazard_map/hazard_marker.dart';
import 'package:civic_app/User UI/widgets/hazard_map/hazard_info_card.dart';
import 'package:civic_app/User UI/widgets/notifications/notification_card.dart';
import 'package:civic_app/User UI/screens/profile_screen.dart';
import 'package:civic_app/User UI/screens/edit_profile_screen.dart';
import 'package:civic_app/User UI/screens/rewards_screen.dart';
import 'package:civic_app/User UI/screens/assistant_screen.dart';
import 'package:civic_app/User UI/screens/settings_screen.dart';
import 'package:civic_app/User UI/screens/notification_settings_screen.dart';
import 'package:civic_app/User UI/screens/privacy_settings_screen.dart';
import 'package:civic_app/User UI/screens/about_screen.dart';
import 'package:civic_app/core/repositories/user_repository.dart';
import 'package:civic_app/core/repositories/rewards_repository.dart';
import 'package:civic_app/User UI/services/assistant_service.dart';
import 'package:civic_app/User UI/widgets/assistant/assistant_message_bubble.dart';
import 'package:civic_app/core/models/reward_model.dart';
import 'package:civic_app/User UI/widgets/civic_progress_card.dart';
import 'package:civic_app/User UI/widgets/quick_action_card.dart';
import 'package:civic_app/Govt UI/models/govt_user_model.dart';
import 'package:civic_app/Govt UI/models/department_model.dart';
import 'package:civic_app/Govt UI/services/govt_auth_service.dart';
import 'package:civic_app/Govt UI/services/govt_complaint_repository.dart';
import 'package:civic_app/Govt UI/screens/auth/govt_login_screen.dart';
import 'package:civic_app/Govt UI/screens/auth/govt_forgot_password_screen.dart';
import 'package:civic_app/Govt UI/screens/govt_shell_screen.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_sidebar.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_app_bar.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/stat_card.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/status_distribution_widget.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/category_breakdown_widget.dart';
import 'package:civic_app/Govt UI/widgets/dashboard/attention_required_card.dart';
import 'package:civic_app/Govt UI/screens/dashboard/govt_dashboard_screen.dart';
import 'package:civic_app/Govt UI/screens/complaints/govt_complaint_list_screen.dart';
import 'package:civic_app/Govt UI/screens/complaints/govt_complaint_details_screen.dart';
import 'package:civic_app/Govt UI/widgets/complaints/govt_complaint_card.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_data_table.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_search_field.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_filter_chip.dart';
import 'package:civic_app/Govt UI/screens/complaints/govt_complaint_assignment_screen.dart';
import 'package:civic_app/Govt UI/screens/complaints/govt_status_update_screen.dart';
import 'package:civic_app/Govt UI/widgets/common/govt_confirmation_dialog.dart';
import 'package:civic_app/Govt UI/screens/map/govt_hazard_map_screen.dart';
import 'package:civic_app/Govt UI/widgets/map/govt_hazard_marker.dart';
import 'package:civic_app/Govt UI/widgets/map/govt_hazard_info_card.dart';
import 'package:civic_app/Govt UI/widgets/map/govt_map_legend.dart';
import 'package:civic_app/Govt UI/widgets/map/govt_map_canvas.dart';
import 'package:civic_app/Govt UI/models/analytics_model.dart';
import 'package:civic_app/Govt UI/services/analytics_repository.dart';
import 'package:civic_app/Govt UI/widgets/analytics/govt_analytics_filter_bar.dart';
import 'package:civic_app/Govt UI/widgets/analytics/govt_time_trend_chart.dart';
import 'package:civic_app/Govt UI/widgets/analytics/govt_resolution_performance_widget.dart';
import 'package:civic_app/Govt UI/widgets/analytics/govt_department_analytics_table.dart';
import 'package:civic_app/Govt UI/widgets/analytics/govt_analytics_card.dart';
import 'package:civic_app/Govt UI/screens/analytics/govt_analytics_screen.dart';
import 'package:civic_app/Govt UI/models/govt_settings_model.dart';
import 'package:civic_app/Govt UI/services/govt_user_repository.dart';
import 'package:civic_app/Govt UI/widgets/profile/govt_edit_profile_dialog.dart';
import 'package:civic_app/Govt UI/widgets/profile/govt_notification_settings_widget.dart';
import 'package:civic_app/Govt UI/widgets/profile/govt_language_settings_widget.dart';
import 'package:civic_app/Govt UI/widgets/profile/govt_appearance_settings_widget.dart';
import 'package:civic_app/Govt UI/widgets/profile/govt_privacy_principles_widget.dart';
import 'package:civic_app/Govt UI/widgets/profile/govt_about_widget.dart';
import 'package:civic_app/Govt UI/screens/profile/govt_profile_screen.dart';
import 'package:civic_app/Govt UI/theme/govt_theme_tokens.dart';
import 'package:civic_app/core/widgets/civic_fix_button.dart';
import 'package:civic_app/core/widgets/priority_badge.dart';
import 'package:civic_app/core/routing/app_routes.dart';

Widget _createTestableWidget(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    onGenerateRoute: AppRouter.generateRoute,
    home: child,
  );
}

void main() {
  setUp(() async {
    // Reset mock auth state and mock data sources before each test
    await MockAuthService().logout();
    MockHomeService().resetMockData();
    MockDataSource().resetMockData();
    MockGovtAuthService().resetForTesting();
    MockGovernmentUserRepository().resetForTesting();
  });

  group('Greeting Helper Unit Tests', () {
    test('Calculates correct greeting based on time of day', () {
      final morning = DateTime(2026, 9, 7, 8, 30);
      final afternoon = DateTime(2026, 9, 7, 14, 0);
      final evening = DateTime(2026, 9, 7, 19, 45);
      final night = DateTime(2026, 9, 7, 2, 15);

      expect(GreetingHelper.getGreeting(morning), 'Good morning');
      expect(GreetingHelper.getGreeting(afternoon), 'Good afternoon');
      expect(GreetingHelper.getGreeting(evening), 'Good evening');
      expect(GreetingHelper.getGreeting(night), 'Good evening');

      expect(GreetingHelper.formatUserGreeting('Rahul Sharma', morning), 'Good morning, Rahul');
      expect(GreetingHelper.formatUserGreeting('Priya', afternoon), 'Good afternoon, Priya');
      expect(GreetingHelper.formatUserGreeting('', evening), 'Good evening, Citizen');
      expect(GreetingHelper.formatUserGreeting(null, night), 'Good evening, Citizen');
    });
  });

  group('Civic Progress Summary Model Tests', () {
    test('Calculates tier and progress percentage correctly', () {
      const userNovice = UserModel(
        id: 'u1',
        fullName: 'Test User',
        email: 'test@example.com',
        phone: '+91 9876543210',
        civicPoints: 80,
        reportsSubmitted: 2,
        reportsResolved: 1,
      );
      final summaryNovice = CivicProgressSummary.fromUser(userNovice);
      expect(summaryNovice.levelName, 'Active Citizen');
      expect(summaryNovice.progressPercent, closeTo(0.4, 0.01));

      const userPro = UserModel(
        id: 'u2',
        fullName: 'Test Pro',
        email: 'pro@example.com',
        phone: '+91 9876543210',
        civicPoints: 480,
        reportsSubmitted: 8,
        reportsResolved: 6,
      );
      final summaryPro = CivicProgressSummary.fromUser(userPro);
      expect(summaryPro.levelName, 'Civic Contributor');
      expect(summaryPro.progressPercent, closeTo(0.933, 0.01));
    });
  });

  group('Complaint Draft Model & Service Unit Tests', () {
    test('Validates ComplaintDraft stages accurately', () {
      final emptyDraft = ComplaintDraft.empty();
      expect(emptyDraft.hasChanges, isFalse);
      expect(emptyDraft.isValidStep1, isFalse);
      expect(emptyDraft.isValidLocation, isFalse);
      expect(emptyDraft.isComplete, isFalse);

      final partialDraft = emptyDraft.copyWith(
        title: 'Dangerous Pothole on 4th Main',
        category: CivicCategory.defaultCategories.first,
      );
      expect(partialDraft.hasChanges, isTrue);
      expect(partialDraft.isValidStep1, isFalse); // Missing description

      final validStep1Draft = partialDraft.copyWith(
        description: 'Pothole is 2 feet deep and posing hazard.',
      );
      expect(validStep1Draft.isValidStep1, isTrue);
      expect(validStep1Draft.isValidLocation, isFalse);
      expect(validStep1Draft.departmentName, 'Roads Department');

      const loc = CivicLocation(
        latitude: 12.9716,
        longitude: 77.5946,
        address: '4th Main Road, Ward 14',
      );
      final completeDraft = validStep1Draft.copyWith(location: loc);
      expect(completeDraft.isValidLocation, isTrue);
      expect(completeDraft.isComplete, isTrue);
    });

    test('MockComplaintService creates compliant ticket and updates stats', () async {
      final service = MockComplaintService();
      final draft = ComplaintDraft(
        title: 'Broken Street Light near Park',
        category: CivicCategory.defaultCategories[4], // Street Lights
        description: 'Street light fixture is broken.',
        location: const CivicLocation(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Park Road, Ward 14',
        ),
      );

      final initialPoints = MockDataSource().currentUser.civicPoints;
      final initialReports = MockDataSource().currentUser.reportsSubmitted;

      final complaint = await service.submitComplaint(draft);

      expect(complaint.ticketNumber.startsWith('CF-2026-'), isTrue);
      expect(complaint.status, ComplaintStatus.submitted);
      expect(complaint.title, 'Broken Street Light near Park');
      expect(MockDataSource().currentUser.civicPoints, initialPoints + 20);
      expect(MockDataSource().currentUser.reportsSubmitted, initialReports + 1);
      expect(MockDataSource().complaints.first.id, complaint.id);
    });
  });

  group('Splash Screen Tests', () {
    testWidgets('Displays branding elements on initial launch', (WidgetTester tester) async {
      await tester.pumpWidget(const CivicFixApp());

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text('Making civic action simple.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance through splash delay and route transition
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      // Should land on Login screen when unauthenticated
      expect(find.text('Welcome back'), findsOneWidget);
    });
  });

  group('Login Screen Tests', () {
    testWidgets('Renders all required form controls and action elements', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const LoginScreen()));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Fill Test Credentials'), findsOneWidget);
    });

    testWidgets('Validates empty email and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const LoginScreen()));

      final loginBtn = find.widgetWithText(ElevatedButton, 'Login');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();

      expect(find.text('Please enter your email.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('Validates invalid email format', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const LoginScreen()));

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'invalid-email-format');
      await tester.enterText(textFields.at(1), 'CivicFix123');

      final loginBtn = find.widgetWithText(ElevatedButton, 'Login');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('Test credentials button automatically populates valid mock credentials', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const LoginScreen()));

      final testCredBtn = find.text('Fill Test Credentials');
      await tester.ensureVisible(testCredBtn);
      await tester.tap(testCredBtn);
      await tester.pump();

      expect(find.text('citizen@civicfix.test'), findsOneWidget);
    });

    testWidgets('Shows error banner on invalid credentials', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const LoginScreen()));

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'citizen@civicfix.test');
      await tester.enterText(textFields.at(1), 'WrongPassword123');

      final loginBtn = find.widgetWithText(ElevatedButton, 'Login');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump(); // Starts loading
      await tester.pump(const Duration(milliseconds: 600)); // Finish mock network delay

      expect(find.text('Incorrect email or password.'), findsOneWidget);
    });

    testWidgets('Navigates to Home on successful login', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const LoginScreen()));

      // Populate test credentials
      final testCredBtn = find.text('Fill Test Credentials');
      await tester.ensureVisible(testCredBtn);
      await tester.tap(testCredBtn);
      await tester.pump();

      // Submit
      final loginBtn = find.widgetWithText(ElevatedButton, 'Login');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump(); // Starts loading
      await tester.pump(const Duration(milliseconds: 800)); // Resolves mock auth
      await tester.pumpAndSettle(); // Route animation and Home data fetch

      expect(find.textContaining('Rahul'), findsOneWidget);
      expect(find.text('Help make your community better.'), findsOneWidget);
      expect(find.text('Report an Issue'), findsWidgets);
    });
  });

  group('Registration Screen Tests', () {
    testWidgets('Renders all registration fields and language selector', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const RegistrationScreen()));

      expect(find.text('Create your CivicFix account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone Number (Optional)'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Preferred Language'), findsOneWidget);
    });

    testWidgets('Validates required fields and password rules on submit', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const RegistrationScreen()));

      final createBtn = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pump();

      expect(find.text('Please enter your name.'), findsOneWidget);
      expect(find.text('Please enter your email.'), findsOneWidget);
      expect(find.text('Please enter a password.'), findsOneWidget);
      expect(find.text('Please confirm your password.'), findsOneWidget);
    });

    testWidgets('Validates password mismatch and short password', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const RegistrationScreen()));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Priya Patel');
      await tester.enterText(fields.at(1), 'priya@example.com');
      await tester.enterText(fields.at(2), '+91 9876543210');
      await tester.enterText(fields.at(3), 'short');
      await tester.enterText(fields.at(4), 'short');

      final createBtn = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pump();

      expect(find.text('Password must be at least 8 characters.'), findsOneWidget);

      // Test mismatch
      await tester.enterText(fields.at(3), 'ValidPass123');
      await tester.enterText(fields.at(4), 'DifferentPass123');

      await tester.tap(createBtn);
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('Registers successfully and navigates to Home', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const RegistrationScreen()));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Ananya Verma');
      await tester.enterText(fields.at(1), 'ananya.verma@example.com');
      await tester.enterText(fields.at(2), '+91 9876543210');
      await tester.enterText(fields.at(3), 'SecurePassword123');
      await tester.enterText(fields.at(4), 'SecurePassword123');

      final createBtn = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pump(); // Starts loading
      await tester.pump(const Duration(milliseconds: 800)); // Finish mock registration delay (700ms)

      expect(find.text('Account created successfully.'), findsOneWidget);

      // Finish success banner display delay (700ms) and route transition
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ananya'), findsOneWidget);
    });
  });

  group('Forgot Password Screen Tests', () {
    testWidgets('Validates email field and simulates password reset instructions', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const ForgotPasswordScreen()));

      expect(find.text('Reset your password'), findsOneWidget);

      // Tap Send Reset Link with empty email
      final sendBtn = find.widgetWithText(ElevatedButton, 'Send Reset Link');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pump();

      expect(find.text('Please enter your email.'), findsOneWidget);

      // Enter valid email
      await tester.enterText(find.byType(TextFormField), 'citizen@civicfix.test');
      await tester.tap(sendBtn);
      await tester.pump(); // Loading
      await tester.pump(const Duration(milliseconds: 600)); // Resolve reset

      expect(find.text('Password reset instructions have been sent.'), findsOneWidget);
    });
  });

  group('Citizen Home Screen Dashboard Tests', () {
    testWidgets('Renders all main sections correctly with populated data', (WidgetTester tester) async {
      MockAuthService().setMockUser(const UserModel(
        id: 'user_citizen_001',
        fullName: 'Rahul Sharma',
        email: 'citizen@civicfix.test',
        phone: '+91 98765 43210',
        civicPoints: 480,
        reportsSubmitted: 8,
        reportsResolved: 6,
        wardNumber: 'Ward 14',
      ));

      await tester.pumpWidget(_createTestableWidget(const HomeScreen()));
      // Initial loading state
      expect(find.text('Loading civic dashboard...'), findsOneWidget);

      // Wait for mock data fetch
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // 1. Header greeting & notification badge
      expect(find.textContaining('Rahul'), findsOneWidget);
      expect(find.text('Help make your community better.'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);

      // 2. Primary CTA: Report an Issue
      expect(find.text('Report an Issue'), findsOneWidget);

      // 3. Section Headers
      expect(find.text('Recent Complaints'), findsOneWidget);
      expect(find.text('Nearby Civic Issues'), findsOneWidget);
      expect(find.text('Your Civic Progress'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);

      // 4. Civic Progress Summary
      expect(find.text('480'), findsOneWidget);
      expect(find.text('Total Points'), findsOneWidget);
      expect(find.text('Civic Contributor'), findsOneWidget);

      // 5. Quick Action Cards
      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('Rewards'), findsOneWidget);
    });

    testWidgets('Main Navigation Screen switches between tabs properly', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const MainNavigationScreen()));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Initially on Home tab
      expect(find.text('Recent Complaints'), findsOneWidget);

      // Tap Complaints tab in bottom bar
      await tester.tap(find.text('Complaints'));
      await tester.pumpAndSettle();
      expect(find.text("Track the civic issues you've reported."), findsOneWidget);

      // Tap Map tab
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(HazardMapScreen), findsOneWidget);

      // Tap Notifications tab
      await tester.tap(find.byIcon(Icons.notifications_outlined).last);
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsWidgets);

      // Tap Profile tab
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Citizen Profile'), findsOneWidget);
    });
  });

  group('Citizen Report Issue Flow Tests (Prompt 4)', () {
    testWidgets('Validates required fields in Step 1 (Information)', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const ReportIssueScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Issue Information'), findsWidgets);
      expect(find.byType(ReportProgressIndicator), findsOneWidget);
      expect(find.text('Information'), findsOneWidget);

      // Tap Next without filling required fields
      final nextBtn = find.text('Next: Add Evidence');
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a title for the issue.'), findsOneWidget);
      expect(find.text('Please select an issue category.'), findsOneWidget);
      expect(find.text('Please describe the issue.'), findsOneWidget);
    });

    testWidgets('Executes complete 4-step wizard, submits complaint, and integrates with Home', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const ReportIssueScreen()));
      await tester.pumpAndSettle();

      // ==========================================
      // STEP 1: Enter Information
      // ==========================================
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Deep pothole on 4th cross road');

      // Select 'Roads' category
      final roadsCategory = find.text('Roads');
      await tester.ensureVisible(roadsCategory);
      await tester.tap(roadsCategory);
      await tester.pumpAndSettle();

      // Enter description
      await tester.enterText(textFields.at(1), 'The pothole is roughly 2 feet wide and fills with water during rain.');
      await tester.pumpAndSettle();

      // Advance to Step 2
      final step1Next = find.text('Next: Add Evidence');
      await tester.ensureVisible(step1Next);
      await tester.tap(step1Next);
      await tester.pumpAndSettle();

      // ==========================================
      // STEP 2: Evidence (Add Photos)
      // ==========================================
      expect(find.text('Add Evidence'), findsOneWidget);
      expect(find.textContaining('0/3 photos'), findsOneWidget);

      // Add a photo from Camera
      final takePhotoBtn = find.text('Take Photo');
      await tester.ensureVisible(takePhotoBtn);
      await tester.tap(takePhotoBtn);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.textContaining('1/3 photos'), findsOneWidget);
      expect(find.text('Photo 1'), findsOneWidget);

      // Advance to Step 3
      final step2Next = find.text('Next: Location');
      await tester.ensureVisible(step2Next);
      await tester.tap(step2Next);
      await tester.pumpAndSettle();

      // ==========================================
      // STEP 3: Location Detection
      // ==========================================
      expect(find.text('Where is the issue?'), findsOneWidget);

      // Tap 'Use My Location'
      final useLocationBtn = find.text('Use My Location');
      await tester.ensureVisible(useLocationBtn);
      await tester.tap(useLocationBtn);
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pumpAndSettle();

      expect(find.textContaining('Location Selected'), findsOneWidget);
      expect(find.text('4th Cross, 2nd Main Road'), findsOneWidget);

      // Advance to Step 4
      final step3Next = find.text('Next: Review');
      await tester.ensureVisible(step3Next);
      await tester.tap(step3Next);
      await tester.pumpAndSettle();

      // ==========================================
      // STEP 4: Review & Submit
      // ==========================================
      expect(find.text('Review your issue'), findsOneWidget);
      expect(find.text('Deep pothole on 4th cross road'), findsOneWidget);
      expect(find.text('Photo Evidence (1)'), findsOneWidget);
      expect(find.text('This issue will be routed to Roads Department.'), findsOneWidget);

      // Submit the issue
      final submitBtn = find.text('Submit Issue');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump(); // Starts loading
      await tester.pump(const Duration(milliseconds: 500)); // Finishes mock submission
      await tester.pumpAndSettle();

      // ==========================================
      // SUCCESS SCREEN
      // ==========================================
      expect(find.text('Issue Reported'), findsOneWidget);
      expect(find.text('Your issue has been submitted successfully.'), findsOneWidget);
      expect(find.text('View Complaint'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);

      // Navigate back to Home
      final homeBtn = find.text('Back to Home');
      await tester.ensureVisible(homeBtn);
      await tester.tap(homeBtn);
      await tester.pumpAndSettle();

      // Verify newly submitted complaint is visible at the top of recent complaints
      expect(find.text('Deep pothole on 4th cross road'), findsOneWidget);
    });

    testWidgets('Edit buttons on Review step return to specific steps with data preserved', (WidgetTester tester) async {
      final initialDraft = ComplaintDraft(
        title: 'Broken water pipe leaking',
        category: CivicCategory.defaultCategories[1], // Water
        description: 'Fresh potable water is leaking across the footpath.',
        imageUrls: const ['mock_photo_1.jpg'],
        location: const CivicLocation(
          latitude: 12.9716,
          longitude: 77.5946,
          address: '8th Avenue, Ward 14',
        ),
      );

      await tester.pumpWidget(_createTestableWidget(ReportIssueScreen(initialDraft: initialDraft)));
      await tester.pumpAndSettle();

      // Jump to Step 4 (Review) by advancing
      await tester.tap(find.text('Next: Add Evidence'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next: Location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next: Review'));
      await tester.pumpAndSettle();

      expect(find.text('Review your issue'), findsOneWidget);

      // Tap 'Edit' on Issue Information (first Edit button)
      final editButtons = find.text('Edit');
      expect(editButtons, findsWidgets);
      await tester.tap(editButtons.at(0));
      await tester.pumpAndSettle();

      // Should be back on Step 1 with preserved values
      expect(find.text('Issue Information'), findsWidgets);
      expect(find.text('Broken water pipe leaking'), findsOneWidget);
    });

    testWidgets('Shows discard confirmation dialog on back when draft has entered data', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const ReportIssueScreen()));
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(find.byType(TextFormField).first, 'Some uncommitted text');
      await tester.pumpAndSettle();

      // Tap Back button in AppBar
      final backBtn = find.byIcon(Icons.arrow_back_rounded);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.text('Discard this report?'), findsOneWidget);
      expect(find.text('Your entered information will be lost.'), findsOneWidget);

      // Tap 'Keep Editing'
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();

      expect(find.text('Discard this report?'), findsNothing);
      expect(find.text('Some uncommitted text'), findsOneWidget);
    });

    testWidgets('Exits immediately without dialog when form is completely empty', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const ReportIssueScreen()));
      await tester.pumpAndSettle();

      final backBtn = find.byIcon(Icons.arrow_back_rounded);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.text('Discard this report?'), findsNothing);
    });
  });

  // =========================================================================
  // PROMPT 5 TESTS: ENHANCED EVIDENCE & LOCATION EXPERIENCE
  // =========================================================================

  group('Prompt 5: Evidence & Location Models and Services Unit Tests', () {
    test('MockEvidenceService captures photo, picks gallery, handles cancel and errors', () async {
      final service = MockEvidenceService();

      // 1. Camera Capture
      final camItem = await service.captureFromCamera();
      expect(camItem, isNotNull);
      expect(camItem!.source, EvidenceSource.camera);
      expect(camItem.fileName.contains('camera'), isTrue);
      expect(camItem.formattedTime.isNotEmpty, isTrue);

      // 2. Gallery Pick
      final galItem = await service.pickFromGallery();
      expect(galItem, isNotNull);
      expect(galItem!.source, EvidenceSource.gallery);
      expect(galItem.fileName.contains('gallery'), isTrue);

      // 3. Simulated Cancellation (returns null gracefully)
      service.simulateCancellation = true;
      final cancelled = await service.captureFromCamera();
      expect(cancelled, isNull);
      service.simulateCancellation = false;

      // 4. Simulated Error
      service.simulateError = true;
      await expectLater(service.captureFromCamera(), throwsException);
      service.simulateError = false;

      // 5. Permission Check & Request
      service.cameraPermission = CivicPermissionStatus.denied;
      final perm = await service.checkPermission(EvidenceSource.camera);
      expect(perm, CivicPermissionStatus.denied);
      final requested = await service.requestPermission(EvidenceSource.camera);
      expect(requested, CivicPermissionStatus.granted);
    });

    test('MockLocationService acquires GPS, checks services, searches places, and geocodes', () async {
      final service = MockLocationService();

      // 1. GPS Acquisition
      final gpsLoc = await service.getCurrentLocation();
      expect(gpsLoc, isNotNull);
      expect(gpsLoc!.source, LocationSource.gps);
      expect(gpsLoc.isGps, isTrue);
      expect(gpsLoc.sourceLabel, 'GPS Detected');
      expect(gpsLoc.accuracyMeters, isNotNull);
      expect(gpsLoc.shortDisplayAddress.contains('4th Cross'), isTrue);

      // 2. Location Services Disabled
      service.isServiceEnabled = false;
      await expectLater(service.getCurrentLocation(), throwsException);
      service.isServiceEnabled = true;

      // 3. Location Permission Check & Request
      service.permissionStatus = CivicPermissionStatus.denied;
      final perm = await service.checkPermission();
      expect(perm, CivicPermissionStatus.denied);
      final requested = await service.requestPermission();
      expect(requested, CivicPermissionStatus.granted);

      // 4. Place Search Query
      final searchResults = await service.searchPlaces('MG Road');
      expect(searchResults.isNotEmpty, isTrue);
      expect(searchResults.first.address.contains('MG Road'), isTrue);

      // 5. Empty Search Query
      final emptyResults = await service.searchPlaces('');
      expect(emptyResults, isEmpty);

      // 6. Reverse Geocoding
      final geocoded = await service.reverseGeocode(12.9716, 77.5946);
      expect(geocoded.source, LocationSource.manual);
      expect(geocoded.address.isNotEmpty, isTrue);
    });

    test('EvidenceItem and CivicLocation data models support copyWith and formatting', () {
      final now = DateTime(2026, 9, 7, 14, 30);
      final evidence = EvidenceItem(
        id: 'ev_01',
        filePath: 'mock://evidence/1.jpg',
        fileName: 'broken_light.jpg',
        source: EvidenceSource.camera,
        capturedAt: now,
      );
      expect(evidence.formattedTime, '14:30');
      expect(evidence.source.label, 'Camera');

      final copiedEvidence = evidence.copyWith(fileName: 'updated_light.jpg');
      expect(copiedEvidence.fileName, 'updated_light.jpg');
      expect(copiedEvidence.id, 'ev_01');

      const location = CivicLocation(
        latitude: 12.9716,
        longitude: 77.5946,
        address: '8th Main Road',
        landmark: 'Near Water Tank',
        ward: 'Ward 14',
        city: 'Bengaluru',
        pincode: '560001',
        source: LocationSource.gps,
        accuracyMeters: 4.5,
      );
      expect(location.isGps, isTrue);
      expect(location.sourceLabel, 'GPS Detected');
      expect(location.shortDisplayAddress, 'Near Water Tank, 8th Main Road');
      expect(location.fullDisplayAddress.contains('Ward 14'), isTrue);
      expect(location.fullDisplayAddress.contains('560001'), isTrue);
    });
  });

  group('Prompt 5: Evidence Picker Widget Tests', () {
    testWidgets('Captures photo from camera, updates live counter and thumbnail', (WidgetTester tester) async {
      List<String> images = [];
      final evidenceService = MockEvidenceService();

      await tester.pumpWidget(
        _createTestableWidget(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: EvidencePicker(
                      images: images,
                      evidenceService: evidenceService,
                      onImagesChanged: (updated) {
                        setState(() {
                          images = updated;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('0/3 photos added'), findsOneWidget);
      expect(find.text('Add Photo Evidence'), findsOneWidget);

      // Tap Take Photo
      final takePhotoBtn = find.text('Take Photo');
      await tester.ensureVisible(takePhotoBtn);
      await tester.tap(takePhotoBtn);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('1/3 photos added'), findsOneWidget);
      expect(find.text('Photo 1'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
    });

    testWidgets('Picks from gallery, opens full preview dialog, and closes', (WidgetTester tester) async {
      List<String> images = [];
      final evidenceService = MockEvidenceService();

      await tester.pumpWidget(
        _createTestableWidget(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: EvidencePicker(
                      images: images,
                      evidenceService: evidenceService,
                      onImagesChanged: (updated) {
                        setState(() {
                          images = updated;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap Gallery
      final galleryBtn = find.text('Gallery');
      await tester.ensureVisible(galleryBtn);
      await tester.tap(galleryBtn);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('1/3 photos added'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Gallery'), findsOneWidget);

      // Tap photo thumbnail to open preview dialog
      final photoTitle = find.text('Photo 1');
      await tester.tap(photoTitle);
      await tester.pumpAndSettle();

      expect(find.textContaining('Photo Preview'), findsOneWidget);

      // Close preview
      final closeBtn = find.byTooltip('Close Preview');
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Photo Preview'), findsNothing);
    });

    testWidgets('Removes photo via accessible remove button [ ✕ ] and updates counter', (WidgetTester tester) async {
      List<String> images = ['mock://photo1.jpg', 'mock://photo2.jpg'];

      await tester.pumpWidget(
        _createTestableWidget(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: EvidencePicker(
                      images: images,
                      onImagesChanged: (updated) {
                        setState(() {
                          images = updated;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('2/3 photos added'), findsOneWidget);
      expect(find.text('Photo 1'), findsOneWidget);
      expect(find.text('Photo 2'), findsOneWidget);

      // Tap remove on first photo
      final removeButtons = find.byIcon(Icons.close_rounded);
      expect(removeButtons, findsWidgets);
      await tester.tap(removeButtons.at(0));
      await tester.pumpAndSettle();

      expect(find.text('1/3 photos added'), findsOneWidget);
      expect(find.text('Photo 2'), findsNothing);
    });

    testWidgets('Enforces 3-photo maximum cap with banner and disables extra adding', (WidgetTester tester) async {
      List<String> images = ['photo1.jpg', 'photo2.jpg', 'photo3.jpg'];

      await tester.pumpWidget(
        _createTestableWidget(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: EvidencePicker(
                      images: images,
                      onImagesChanged: (updated) {
                        setState(() {
                          images = updated;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('3/3 photos (Max)'), findsOneWidget);
      expect(find.textContaining('Maximum limit of 3 photos reached'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Take Photo'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Gallery'), findsNothing);
    });

    testWidgets('Handles cancellation gracefully without error state', (WidgetTester tester) async {
      List<String> images = [];
      final evidenceService = MockEvidenceService(simulateCancellation: true);

      await tester.pumpWidget(
        _createTestableWidget(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return EvidencePicker(
                  images: images,
                  evidenceService: evidenceService,
                  onImagesChanged: (updated) {
                    setState(() {
                      images = updated;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      final takePhotoBtn = find.text('Take Photo');
      await tester.ensureVisible(takePhotoBtn);
      await tester.tap(takePhotoBtn);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('0/3 photos added'), findsOneWidget);
      expect(find.textContaining("Couldn't add"), findsNothing);
    });

    testWidgets('Displays error recovery banner and retries successfully while preserving existing photos', (WidgetTester tester) async {
      List<String> images = ['existing_photo_1.jpg'];
      final evidenceService = MockEvidenceService(simulateError: true);

      await tester.pumpWidget(
        _createTestableWidget(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: EvidencePicker(
                      images: images,
                      evidenceService: evidenceService,
                      onImagesChanged: (updated) {
                        setState(() {
                          images = updated;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('1/3 photos added'), findsOneWidget);

      // Trigger capture with simulated error
      final takePhotoBtn = find.text('Take Photo');
      await tester.ensureVisible(takePhotoBtn);
      await tester.tap(takePhotoBtn);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Error banner is displayed
      expect(find.textContaining("Couldn't add the photo"), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      // Existing photo preserved
      expect(find.text('1/3 photos added'), findsOneWidget);
      expect(find.text('Photo 1'), findsOneWidget);

      // Clear simulated error and tap Try Again
      evidenceService.simulateError = false;
      final tryAgainBtn = find.text('Try Again');
      await tester.ensureVisible(tryAgainBtn);
      await tester.tap(tryAgainBtn);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.textContaining("Couldn't add the photo"), findsNothing);
      expect(find.text('2/3 photos added'), findsOneWidget);
      expect(find.text('Photo 2'), findsOneWidget);
    });
  });

  group('Prompt 5: Location Selection & Map Screen Tests', () {
    testWidgets('Use My Location detects GPS with loading state and renders verified card', (WidgetTester tester) async {
      CivicLocation? selectedLocation;
      final locationService = MockLocationService();

      await tester.pumpWidget(
        _createTestableWidget(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LocationSelectionCard(
                      selectedLocation: selectedLocation,
                      locationService: locationService,
                      onOpenMapPicker: () {},
                      onLocationSelected: (loc) {
                        setState(() {
                          selectedLocation = loc;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Use Device Location'), findsOneWidget);
      expect(find.text('Use My Location'), findsOneWidget);

      // Tap Use My Location
      final useLocationBtn = find.text('Use My Location');
      await tester.ensureVisible(useLocationBtn);
      await tester.tap(useLocationBtn);
      await tester.pump(); // Starts loading state

      expect(find.text('Detecting GPS location...'), findsOneWidget);

      // Wait for mock GPS resolve
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.textContaining('Location Selected'), findsOneWidget);
      expect(find.text('GPS Detected'), findsOneWidget);
      expect(find.text('4th Cross, 2nd Main Road'), findsOneWidget);
      expect(find.textContaining('Ward 14'), findsOneWidget);
      expect(find.text('Change Location'), findsOneWidget);
    });

    testWidgets('Location services disabled displays warning banner with manual fallback', (WidgetTester tester) async {
      CivicLocation? selectedLocation;
      final locationService = MockLocationService(isServiceEnabled: false);
      bool openedMap = false;

      await tester.pumpWidget(
        _createTestableWidget(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LocationSelectionCard(
                      selectedLocation: selectedLocation,
                      locationService: locationService,
                      onOpenMapPicker: () {
                        openedMap = true;
                      },
                      onLocationSelected: (loc) {
                        setState(() {
                          selectedLocation = loc;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      final useLocationBtn = find.text('Use My Location');
      await tester.ensureVisible(useLocationBtn);
      await tester.tap(useLocationBtn);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Location Services Disabled'), findsOneWidget);
      expect(find.text('Select on Map Instead'), findsOneWidget);

      final selectMapInsteadBtn = find.text('Select on Map Instead');
      await tester.ensureVisible(selectMapInsteadBtn);
      await tester.tap(selectMapInsteadBtn);
      expect(openedMap, isTrue);
    });

    testWidgets('SelectLocationScreen renders map, search suggestions, pin tap, and confirms manual location', (WidgetTester tester) async {
      final locationService = MockLocationService();

      await tester.pumpWidget(
        _createTestableWidget(
          SelectLocationScreen(
            locationService: locationService,
          ),
        ),
      );

      expect(find.text('Confirm Location'), findsOneWidget);
      expect(find.text('Tap map to position pin'), findsOneWidget);
      expect(find.text('Selected Location'), findsOneWidget);
      expect(find.text('Confirm This Location'), findsOneWidget);

      // Search place
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'MG Road');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.textContaining('MG Road Boulevard'), findsWidgets);

      // Select suggestion
      await tester.tap(find.textContaining('MG Road Boulevard').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('MG Road Boulevard'), findsWidgets);
      expect(find.text('Manually Selected'), findsOneWidget);

      // Tap GPS centering button
      final gpsBtn = find.byTooltip('Center on My GPS');
      await tester.ensureVisible(gpsBtn);
      await tester.tap(gpsBtn);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('4th Cross, 2nd Main Road'), findsOneWidget);
      expect(find.text('GPS Detected'), findsOneWidget);

      // Tap Confirm Location
      final confirmBtn = find.text('Confirm This Location');
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();
    });
  });

  group('Prompt 5: Review Step & Draft Integration Tests', () {
    testWidgets('Review card renders photo thumbnails with preview and location source badge', (WidgetTester tester) async {
      final draft = ComplaintDraft(
        title: 'Dangerous uncovered drainage hole',
        category: CivicCategory.defaultCategories[5], // Drainage
        description: 'Large drain hole left open on main sidewalk without barrier.',
        imageUrls: const ['mock://drain_photo_1.jpg', 'mock://drain_photo_2.jpg'],
        evidence: [
          EvidenceItem(
            id: 'e1',
            filePath: 'mock://drain_photo_1.jpg',
            fileName: 'drain_wide_view.jpg',
            source: EvidenceSource.camera,
            capturedAt: DateTime(2026, 9, 7, 10, 15),
          ),
          EvidenceItem(
            id: 'e2',
            filePath: 'mock://drain_photo_2.jpg',
            fileName: 'drain_close_up.jpg',
            source: EvidenceSource.gallery,
            capturedAt: DateTime(2026, 9, 7, 10, 20),
          ),
        ],
        location: const CivicLocation(
          latitude: 12.9716,
          longitude: 77.5946,
          address: '4th Cross, 2nd Main Road',
          landmark: 'Opposite Community Park',
          ward: 'Ward 14 (Central Ward)',
          city: 'Bengaluru',
          source: LocationSource.gps,
        ),
        isHazard: true,
      );

      int editedStep = 0;

      await tester.pumpWidget(
        _createTestableWidget(
          Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ComplaintReviewCard(
                  draft: draft,
                  onEditStep: (step) => editedStep = step,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Review your issue'), findsOneWidget);
      expect(find.text('Dangerous uncovered drainage hole'), findsOneWidget);
      expect(find.text('Photo Evidence (2)'), findsOneWidget);
      expect(find.text('Photo 1'), findsOneWidget);
      expect(find.text('Photo 2'), findsOneWidget);
      expect(find.text('GPS Detected'), findsOneWidget);
      expect(find.text('Marked as Immediate Safety Hazard'), findsOneWidget);
      expect(find.text('This issue will be routed to Drainage Department.'), findsOneWidget);

      // Tap thumbnail to open preview dialog
      await tester.tap(find.text('Photo 1'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Photo Preview'), findsOneWidget);
      expect(find.text('drain_wide_view.jpg'), findsOneWidget);
      expect(find.text('Captured via Camera • 10:15'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Test Edit buttons
      final editButtons = find.text('Edit');
      expect(editButtons, findsNWidgets(3));

      // Tap Edit Location (Step 3)
      await tester.ensureVisible(editButtons.at(2));
      await tester.tap(editButtons.at(2));
      await tester.pumpAndSettle();
      expect(editedStep, 3);
    });

    testWidgets('Full Report Issue flow allows skipping optional photos and requires location', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const ReportIssueScreen()));
      await tester.pumpAndSettle();

      // Step 1: Fill Information
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Overflowing garbage bin on street');
      final wasteBtn = find.text('Waste Management');
      await tester.ensureVisible(wasteBtn);
      await tester.tap(wasteBtn);
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(1), 'Garbage has not been collected for 4 days.');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next: Add Evidence'));
      await tester.pumpAndSettle();

      // Step 2: Skip Photos (Photos are optional)
      expect(find.text('Skip & Continue'), findsOneWidget);
      await tester.tap(find.text('Skip & Continue'));
      await tester.pumpAndSettle();

      // Step 3: Location is REQUIRED
      expect(find.text('Where is the issue?'), findsOneWidget);
      final nextReviewBtn = find.text('Next: Review');
      await tester.ensureVisible(nextReviewBtn);
      await tester.tap(nextReviewBtn);
      await tester.pumpAndSettle();

      // Location validation error shown
      expect(find.text('Please select or detect the issue location.'), findsOneWidget);

      // Detect location
      final useLocationBtn = find.text('Use My Location');
      await tester.ensureVisible(useLocationBtn);
      await tester.tap(useLocationBtn);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Advance to Review
      await tester.tap(find.text('Next: Review'));
      await tester.pumpAndSettle();

      expect(find.text('Review your issue'), findsOneWidget);
      expect(find.text('No photos attached (Optional)'), findsOneWidget);
      expect(find.text('GPS Detected'), findsOneWidget);
      expect(find.text('This issue will be routed to Sanitation / Waste Department.'), findsOneWidget);
    });
  });

  // =========================================================================
  // PROMPT 6 TESTS: CITIZEN MY COMPLAINTS EXPERIENCE
  // =========================================================================

  group('Prompt 6: Complaint Repository & Ownership Unit Tests', () {
    test('MockComplaintRepository fetches complaints filtered by citizen ownership', () async {
      final repo = MockComplaintRepository();
      final complaints = await repo.getCitizenComplaints('user_citizen_001');

      expect(complaints.isNotEmpty, isTrue);
      expect(complaints.length, greaterThanOrEqualTo(5));
      expect(complaints.every((c) => c.citizenId == 'user_citizen_001' || c.citizenId == 'user_001'), isTrue);

      // Verify all 5 key statuses are covered
      final statuses = complaints.map((c) => c.status).toSet();
      expect(statuses.contains(ComplaintStatus.reported), isTrue);
      expect(statuses.contains(ComplaintStatus.inProgress), isTrue);
      expect(statuses.contains(ComplaintStatus.verified), isTrue);
      expect(statuses.contains(ComplaintStatus.assigned), isTrue);
      expect(statuses.contains(ComplaintStatus.resolved), isTrue);
    });

    test('MockComplaintRepository gets complaint by ticket ID or internal ID', () async {
      final repo = MockComplaintRepository();
      final byTicket = await repo.getComplaintById('CF-2026-000024');
      expect(byTicket, isNotNull);
      expect(byTicket!.title, 'Broken street light near park');

      final byId = await repo.getComplaintById('cmp_102');
      expect(byId, isNotNull);
      expect(byId!.ticketNumber, 'CF-2026-000021');

      final nonExistent = await repo.getComplaintById('invalid_id_999');
      expect(nonExistent, isNull);
    });

    test('MockComplaintRepository creates new complaint with citizenId and auto-generated CF-2026 ticket number', () async {
      final repo = MockComplaintRepository();
      final newComplaint = await repo.createComplaint(
        citizenId: 'user_citizen_001',
        title: 'Broken bench in community park',
        description: 'Wooden bench is broken and has exposed nails.',
        category: CivicCategory.defaultCategories[6], // Public Infrastructure
        location: const CivicLocation(
          latitude: 12.9716,
          longitude: 77.5946,
          address: 'Central Park East',
        ),
        priority: ComplaintPriority.low,
      );

      expect(newComplaint.ticketNumber.startsWith('CF-2026-'), isTrue);
      expect(newComplaint.citizenId, 'user_citizen_001');
      expect(newComplaint.status, ComplaintStatus.reported);

      final fetched = await repo.getComplaintById(newComplaint.id);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Broken bench in community park');
    });

    test('MockComplaintRepository upvotes complaint', () async {
      final repo = MockComplaintRepository();
      final initial = await repo.getComplaintById('cmp_101');
      final initialVotes = initial?.upvotes ?? 0;

      await repo.upvoteComplaint('cmp_101');
      final updated = await repo.getComplaintById('cmp_101');
      expect(updated?.upvotes, initialVotes + 1);
    });
  });

  group('Prompt 6: ComplaintCard Widget Tests', () {
    testWidgets('Renders all required card fields in proper visual hierarchy with status badge', (WidgetTester tester) async {
      final complaint = ComplaintModel(
        id: 'cmp_test_1',
        citizenId: 'user_citizen_001',
        ticketNumber: 'CF-2026-000024',
        title: 'Broken street light near park',
        description: 'Dark area at night.',
        category: CivicCategory.defaultCategories[4], // Street Lights
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.medium,
        location: const CivicLocation(
          latitude: 12.9716,
          longitude: 77.5946,
          address: '4th Cross Road',
          landmark: 'Near Andheri East',
        ),
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );

      bool cardTapped = false;

      await tester.pumpWidget(
        _createTestableWidget(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ComplaintCard(
                complaint: complaint,
                onTap: () => cardTapped = true,
              ),
            ),
          ),
        ),
      );

      // Visual elements check
      expect(find.text('Broken street light near park'), findsOneWidget);
      expect(find.text('CF-2026-000024'), findsOneWidget);
      expect(find.text('Street Lights'), findsOneWidget);
      expect(find.text('Reported'), findsOneWidget);
      expect(find.textContaining('Near Andheri East'), findsOneWidget);
      expect(find.textContaining('Updated'), findsOneWidget);

      // Tap card
      await tester.tap(find.text('Broken street light near park'));
      expect(cardTapped, isTrue);
    });

    testWidgets('Tapping complaint ID copies ticket number and shows SnackBar feedback', (WidgetTester tester) async {
      final complaint = ComplaintModel(
        id: 'cmp_test_2',
        citizenId: 'user_citizen_001',
        ticketNumber: 'CF-2026-000021',
        title: 'Road damage near junction',
        description: 'Potholes on road.',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.inProgress,
        priority: ComplaintPriority.high,
        location: const CivicLocation(
          latitude: 12.9750,
          longitude: 77.5980,
          address: '4th Main Road',
        ),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        isHazard: true,
      );

      await tester.pumpWidget(
        _createTestableWidget(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ComplaintCard(
                complaint: complaint,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Safety Hazard'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);

      // Tap ticket number to copy
      await tester.tap(find.text('CF-2026-000021'));
      await tester.pump();

      expect(find.text('Complaint ID CF-2026-000021 copied.'), findsOneWidget);
    });
  });

  group('Prompt 6: MyComplaintsScreen Loaded & State Tests', () {
    testWidgets('Renders full complaints list with header, search bar, filter chips, and summary count', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const MyComplaintsScreen()));
      await tester.pumpAndSettle();

      // Header & Subtitle
      expect(find.text('My Complaints'), findsOneWidget);
      expect(find.text("Track the civic issues you've reported."), findsOneWidget);

      // Search field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search complaints...'), findsOneWidget);

      // Filter chips
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Reported'), findsWidgets);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.text('Verified'), findsWidgets);
      expect(find.text('Assigned'), findsWidgets);
      expect(find.text('Resolved'), findsWidgets);

      // Summary count (e.g. 5 complaints)
      expect(find.textContaining('complaints'), findsWidgets);

      // Cards rendered
      expect(find.text('Broken street light near park'), findsOneWidget);
      expect(find.text('Road damage near junction'), findsOneWidget);
      expect(find.text('Garbage accumulation'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(find.text('Blocked drainage'), findsOneWidget);
      expect(find.text('Water leakage'), findsOneWidget);
    });

    testWidgets('Renders empty state when citizen has 0 complaints and navigates to Report Issue', (WidgetTester tester) async {
      final emptyRepo = MockComplaintRepository();
      // Temporarily clear complaints
      final backup = List<ComplaintModel>.from(MockDataSource().complaints);
      MockDataSource().complaints.clear();

      await tester.pumpWidget(_createTestableWidget(MyComplaintsScreen(repository: emptyRepo)));
      await tester.pumpAndSettle();

      expect(find.text('No complaints yet'), findsOneWidget);
      expect(find.text('Report a civic issue and track its progress here.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Report an Issue'), findsOneWidget);

      // Restore mock complaints
      MockDataSource().complaints.addAll(backup);
    });

    testWidgets('Pull to refresh reloads complaint data', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const MyComplaintsScreen()));
      await tester.pumpAndSettle();

      // Trigger pull to refresh gesture
      await tester.fling(find.byType(CustomScrollView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('My Complaints'), findsOneWidget);
      expect(find.text('Broken street light near park'), findsOneWidget);
    });
  });

  group('Prompt 6: Search & Filter Integration Tests', () {
    testWidgets('Search filters complaints by title (case-insensitive) and clear button restores list', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const MyComplaintsScreen()));
      await tester.pumpAndSettle();

      // Search 'street light'
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'street light');
      await tester.pumpAndSettle();

      expect(find.text('Broken street light near park'), findsOneWidget);
      expect(find.text('Road damage near junction'), findsNothing);
      expect(find.text('Garbage accumulation'), findsNothing);
      expect(find.text('1 complaint found'), findsOneWidget);

      // Tap clear search button (X)
      final clearBtn = find.byIcon(Icons.clear_rounded);
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.text('Broken street light near park'), findsOneWidget);
      expect(find.text('Road damage near junction'), findsOneWidget);
      expect(find.text('Garbage accumulation'), findsOneWidget);
    });

    testWidgets('Search filters complaints by ticket ID (e.g. CF-2026-000021)', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const MyComplaintsScreen()));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'CF-2026-000021');
      await tester.pumpAndSettle();

      expect(find.text('Road damage near junction'), findsOneWidget);
      expect(find.text('Broken street light near park'), findsNothing);
      expect(find.text('1 complaint found'), findsOneWidget);
    });

    testWidgets('Status quick filter chips filter list by status', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const MyComplaintsScreen()));
      await tester.pumpAndSettle();

      // Tap 'In Progress' filter chip in quick filters row
      final inProgressChip = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.text('In Progress'),
      );
      await tester.ensureVisible(inProgressChip);
      await tester.pumpAndSettle();
      await tester.tap(inProgressChip);
      await tester.pumpAndSettle();

      expect(find.text('Road damage near junction'), findsOneWidget);
      expect(find.text('Broken street light near park'), findsNothing);
      expect(find.text('Water leakage'), findsNothing);

      // Tap 'Resolved' filter chip
      final resolvedChip = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.text('Resolved'),
      );
      await tester.ensureVisible(resolvedChip);
      await tester.pumpAndSettle();
      await tester.tap(resolvedChip);
      await tester.pumpAndSettle();

      expect(find.text('Water leakage'), findsOneWidget);
      expect(find.text('Road damage near junction'), findsNothing);

      // Tap 'All' to restore
      final allChip = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.text('All'),
      );
      await tester.ensureVisible(allChip);
      await tester.pumpAndSettle();
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      expect(find.text('Broken street light near park'), findsOneWidget);
      expect(find.text('Road damage near junction'), findsOneWidget);
    });

    testWidgets('Non-matching search displays "No complaints found" with "Clear Filters" button', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const MyComplaintsScreen()));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'NonExistentIssueXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No complaints found'), findsOneWidget);
      expect(find.text('Try a different search or filter.'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);

      // Tap 'Clear Filters' button in empty state
      final clearFiltersBtn = find.widgetWithText(ElevatedButton, 'Clear Filters');
      await tester.ensureVisible(clearFiltersBtn);
      await tester.tap(clearFiltersBtn);
      await tester.pumpAndSettle();

      expect(find.text('Broken street light near park'), findsOneWidget);
      expect(find.text('Road damage near junction'), findsOneWidget);
    });

    testWidgets('Category filter via ComplaintFilterBottomSheet filters complaints correctly', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const MyComplaintsScreen()));
      await tester.pumpAndSettle();

      // Open filter bottom sheet
      final filterBtn = find.text('Filter');
      await tester.ensureVisible(filterBtn);
      await tester.tap(filterBtn);
      await tester.pumpAndSettle();

      expect(find.text('Filter & Sort'), findsOneWidget);
      expect(find.text('Complaint Status'), findsOneWidget);
      expect(find.text('Issue Category'), findsOneWidget);

      // Select 'Water' category chip inside bottom sheet
      final waterChoice = find.widgetWithText(ChoiceChip, 'Water');
      await tester.ensureVisible(waterChoice);
      await tester.tap(waterChoice);
      await tester.pumpAndSettle();

      // Tap Apply Filters
      final applyBtn = find.text('Apply Filters');
      await tester.ensureVisible(applyBtn);
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      // Only Water complaints visible
      expect(find.text('Water leakage'), findsOneWidget);
      expect(find.text('Broken street light near park'), findsNothing);
    });
  });

  group('Prompt 6: Navigation & Report Issue Integration Tests', () {
    testWidgets('Tapping a complaint card navigates to ComplaintDetailsScreen with selected complaint', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const MyComplaintsScreen()));
      await tester.pumpAndSettle();

      // Tap on first complaint
      final cardTitle = find.text('Broken street light near park');
      await tester.ensureVisible(cardTitle);
      await tester.tap(cardTitle);
      await tester.pumpAndSettle();

      // Complaint Details screen
      expect(find.text('CF-2026-000024'), findsOneWidget);
      expect(find.text('Broken street light near park'), findsOneWidget);
      expect(find.text('Complaint Details'), findsOneWidget);

      // Tap Back button in App Bar
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('My Complaints'), findsOneWidget);
    });

    testWidgets('Newly submitted complaint from Report Issue appears in My Complaints and Home', (WidgetTester tester) async {
      // 1. Submit a complaint via MockComplaintService
      final draft = ComplaintDraft(
        title: 'Fallen tree branch blocking walkway',
        category: CivicCategory.defaultCategories[6], // Public Infrastructure
        description: 'Large branch fell during storm and blocks footpath.',
        location: const CivicLocation(
          latitude: 12.9716,
          longitude: 77.5946,
          address: '4th Cross, 2nd Main Road',
          ward: 'Ward 14 (Central)',
        ),
      );

      final newComplaint = await MockComplaintService().submitComplaint(draft);
      expect(newComplaint.title, 'Fallen tree branch blocking walkway');

      // 2. Open My Complaints Screen
      await tester.pumpWidget(_createTestableWidget(const MyComplaintsScreen()));
      await tester.pumpAndSettle();

      // The newly submitted complaint should be at the very top
      expect(find.text('Fallen tree branch blocking walkway'), findsOneWidget);
      expect(find.text(newComplaint.ticketNumber), findsOneWidget);
    });
  });

  // =========================================================================
  // PROMPT 7 TESTS: COMPLAINT DETAILS & 5-STAGE COMPLAINT TRACKER
  // =========================================================================

  group('Prompt 7: Department Helper & Date Formatter Unit Tests', () {
    test('DepartmentHelper correctly maps all 9 civic categories to departments', () {
      expect(DepartmentHelper.getDepartmentName(CivicCategory.defaultCategories[0]), 'Roads Department');
      expect(DepartmentHelper.getDepartmentName(CivicCategory.defaultCategories[1]), 'Water Department');
      expect(DepartmentHelper.getDepartmentName(CivicCategory.defaultCategories[2]), 'Sanitation Department');
      expect(DepartmentHelper.getDepartmentName(CivicCategory.defaultCategories[3]), 'Sanitation / Waste Department');
      expect(DepartmentHelper.getDepartmentName(CivicCategory.defaultCategories[4]), 'Electrical / Public Works');
      expect(DepartmentHelper.getDepartmentName(CivicCategory.defaultCategories[5]), 'Drainage Department');
      expect(DepartmentHelper.getDepartmentName(CivicCategory.defaultCategories[6]), 'Public Works');
      expect(DepartmentHelper.getDepartmentName(CivicCategory.defaultCategories[7]), 'Traffic / Road Safety Department');
      expect(DepartmentHelper.getDepartmentName(CivicCategory.defaultCategories[8]), 'Manual Review & Municipal Desk');
      expect(DepartmentHelper.getDepartmentName(null), 'General Municipal Desk');
    });

    test('DateFormatter formats full dates and timeline relative dates accurately', () {
      final now = DateTime.now();
      final todayEvent = now.subtract(const Duration(hours: 1));
      final yesterdayEvent = now.subtract(const Duration(days: 1));
      final pastDate = DateTime(2026, 8, 28, 14, 30);

      expect(DateFormatter.formatFullDate(pastDate), 'August 28, 2026');
      expect(DateFormatter.formatTimelineDate(todayEvent).startsWith('Today,'), isTrue);
      expect(DateFormatter.formatTimelineDate(yesterdayEvent).startsWith('Yesterday,'), isTrue);
    });
  });

  group('Prompt 7: 5-Stage ComplaintTracker Widget Tests', () {
    testWidgets('Renders exactly 5 stages in canonical order with correct states for In Progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        _createTestableWidget(
          const Scaffold(
            body: ComplaintTracker(currentStatus: ComplaintStatus.inProgress),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progress Tracker'), findsOneWidget);
      expect(find.text('Stage 4 of 5'), findsOneWidget);

      // Verify 5 stages exist
      expect(find.text('Reported'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);

      // Current stage pill
      expect(find.text('CURRENT'), findsOneWidget);

      // Contextual status message
      expect(find.text('The responsible team is currently working on this issue.'), findsOneWidget);
    });

    testWidgets('Tapping a stage toggles explanation details card', (WidgetTester tester) async {
      await tester.pumpWidget(
        _createTestableWidget(
          const Scaffold(
            body: ComplaintTracker(currentStatus: ComplaintStatus.reported),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your issue has been submitted and is awaiting review.'), findsNothing);

      // Tap Reported stage
      await tester.tap(find.text('Reported'));
      await tester.pumpAndSettle();

      expect(find.text('Your issue has been submitted and is awaiting review.'), findsOneWidget);

      // Tap again to collapse
      await tester.tap(find.text('Reported'));
      await tester.pumpAndSettle();

      expect(find.text('Your issue has been submitted and is awaiting review.'), findsNothing);
    });

    testWidgets('Renders all 5 stages completed for Resolved status', (WidgetTester tester) async {
      await tester.pumpWidget(
        _createTestableWidget(
          const Scaffold(
            body: ComplaintTracker(currentStatus: ComplaintStatus.resolved),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stage 5 of 5'), findsOneWidget);
      expect(find.text('CURRENT'), findsNothing); // No pending pulsing, all 5 completed
      expect(find.text('This issue has been marked as resolved.'), findsOneWidget);
    });
  });

  group('Prompt 7: ComplaintDetailsScreen Lifecycle & UI Tests', () {
    testWidgets('Renders full complaint details screen for In Progress complaint', (WidgetTester tester) async {
      final complaint = MockDataSource().complaints.firstWhere((c) => c.status == ComplaintStatus.inProgress);

      await tester.pumpWidget(
        _createTestableWidget(
          ComplaintDetailsScreen(complaint: complaint),
        ),
      );
      await tester.pumpAndSettle();

      // App Bar
      expect(find.text('Complaint Details'), findsOneWidget);

      // Ticket ID & Copy
      expect(find.text(complaint.ticketNumber), findsOneWidget);

      // Title & Status
      expect(find.text(complaint.title), findsOneWidget);
      expect(find.text('In Progress'), findsWidgets);

      // Issue Info Card
      expect(find.text('Issue Information'), findsOneWidget);
      expect(find.text(complaint.category.name), findsOneWidget);
      expect(find.text('Roads Department'), findsOneWidget);
      expect(find.text(complaint.description), findsOneWidget);
      expect(find.text('High Priority'), findsOneWidget);
      expect(find.text('Safety Hazard'), findsOneWidget);

      // Location Card
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('View Location'), findsOneWidget);
      expect(find.textContaining('Metro Cross'), findsOneWidget);

      // Evidence Gallery
      expect(find.text('Evidence'), findsOneWidget);
      expect(find.text('2 photos'), findsOneWidget);

      // Updates Timeline (Newest first)
      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('Repair In Progress'), findsOneWidget);
      expect(find.text('Site Inspected & Verified'), findsOneWidget);
      expect(find.text('Issue Reported'), findsOneWidget);

      // Timestamps footer
      expect(find.textContaining('Reported on'), findsOneWidget);
      expect(find.textContaining('Last updated'), findsOneWidget);
    });

    testWidgets('Tapping complaint ID copies ticket number and shows SnackBar', (WidgetTester tester) async {
      final complaint = MockDataSource().complaints.first;

      await tester.pumpWidget(
        _createTestableWidget(
          ComplaintDetailsScreen(complaint: complaint),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(complaint.ticketNumber));
      await tester.pump();

      expect(find.text('Complaint ID ${complaint.ticketNumber} copied.'), findsOneWidget);
    });

    testWidgets('Renders completion banner when complaint status is Resolved', (WidgetTester tester) async {
      final resolvedComplaint = MockDataSource().complaints.firstWhere((c) => c.status == ComplaintStatus.resolved);

      await tester.pumpWidget(
        _createTestableWidget(
          ComplaintDetailsScreen(complaint: resolvedComplaint),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('✓ Issue Resolved'), findsOneWidget);
      expect(find.text('This complaint has been marked as resolved.'), findsWidgets);
    });

    testWidgets('Renders empty photos state when complaint has no images', (WidgetTester tester) async {
      final complaintNoImages = MockDataSource().complaints.firstWhere((c) => c.imageUrls.isEmpty);

      await tester.pumpWidget(
        _createTestableWidget(
          ComplaintDetailsScreen(complaint: complaintNoImages),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No photos were added to this report.'), findsOneWidget);
    });

    testWidgets('Tapping thumbnail opens full-screen image viewer modal and closes on X tap', (WidgetTester tester) async {
      final complaint = MockDataSource().complaints.firstWhere((c) => c.imageUrls.isNotEmpty);

      await tester.pumpWidget(
        _createTestableWidget(
          ComplaintDetailsScreen(complaint: complaint),
        ),
      );
      await tester.pumpAndSettle();

      // Tap first photo thumbnail
      final thumbnail = find.bySemanticsLabel(RegExp(r'Evidence photo 1'));
      expect(thumbnail, findsOneWidget);
      await tester.ensureVisible(thumbnail);
      await tester.pumpAndSettle();
      await tester.tap(thumbnail);
      await tester.pumpAndSettle();

      // Image Viewer Modal
      expect(find.byType(ImageViewerModal), findsOneWidget);
      expect(find.textContaining('1 of'), findsOneWidget);

      // Close modal
      final closeBtn = find.byTooltip('Close image viewer');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ImageViewerModal), findsNothing);
    });

    testWidgets('Tapping View Location navigates to SelectLocationScreen', (WidgetTester tester) async {
      final complaint = MockDataSource().complaints.first;

      await tester.pumpWidget(
        _createTestableWidget(
          ComplaintDetailsScreen(complaint: complaint),
        ),
      );
      await tester.pumpAndSettle();

      final viewLocBtn = find.text('View Location');
      expect(viewLocBtn, findsOneWidget);
      await tester.ensureVisible(viewLocBtn);
      await tester.pumpAndSettle();
      await tester.tap(viewLocBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SelectLocationScreen), findsOneWidget);
    });
  });

  group('Prompt 7: Security Ownership & Resilient Error Tests', () {
    testWidgets('Ownership guard blocks unauthorized citizen and displays access state', (WidgetTester tester) async {
      final unauthorizedComplaint = ComplaintModel(
        id: 'cmp_other_citizen',
        citizenId: 'other_user_999',
        ticketNumber: 'CF-2026-999999',
        title: 'Secret neighborhood complaint',
        description: 'Private information.',
        category: CivicCategory.defaultCategories[0],
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.low,
        location: const CivicLocation(latitude: 12.9, longitude: 77.5, address: 'Private St'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        _createTestableWidget(
          ComplaintDetailsScreen(complaint: unauthorizedComplaint),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to open this complaint.'), findsOneWidget);
      expect(find.text('This report belongs to a different citizen account.'), findsOneWidget);
      expect(find.text('Back to My Complaints'), findsOneWidget);
      expect(find.text('Secret neighborhood complaint'), findsNothing);
    });

    testWidgets('Invalid complaint ID displays "Complaint not found." error state', (WidgetTester tester) async {
      await tester.pumpWidget(
        _createTestableWidget(
          const ComplaintDetailsScreen(complaintId: 'non_existent_id_404'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('Complaint not found.'), findsOneWidget);
      expect(find.text('This complaint may no longer be available.'), findsOneWidget);
      expect(find.text('Back to My Complaints'), findsOneWidget);
    });

    testWidgets('Gracefully handles missing optional fields without crashing', (WidgetTester tester) async {
      final minimalComplaint = ComplaintModel(
        id: 'cmp_minimal',
        citizenId: 'user_citizen_001',
        ticketNumber: 'CF-2026-000099',
        title: 'Minimal Issue',
        description: '',
        category: CivicCategory.defaultCategories[8], // Other
        status: ComplaintStatus.reported,
        priority: ComplaintPriority.low,
        location: const CivicLocation(latitude: 0, longitude: 0, address: ''),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        timeline: const [],
      );

      await tester.pumpWidget(
        _createTestableWidget(
          ComplaintDetailsScreen(complaint: minimalComplaint),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minimal Issue'), findsOneWidget);
      expect(find.text('No additional description provided.'), findsOneWidget);
      expect(find.text('Location selected.'), findsOneWidget);
      expect(find.text('No photos were added to this report.'), findsOneWidget);
      expect(find.text('No updates yet.'), findsOneWidget);
    });
  });

  group('Prompt 7: Navigation Flows Integration Tests', () {
    testWidgets('Navigation from Home Recent Complaints opens ComplaintDetailsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Tap on first recent complaint card
      final complaintTitle = find.text('Broken street light near park');
      expect(complaintTitle, findsOneWidget);
      await tester.tap(complaintTitle);
      await tester.pumpAndSettle();

      expect(find.byType(ComplaintDetailsScreen), findsOneWidget);
      expect(find.text('CF-2026-000024'), findsOneWidget);
      expect(find.text('Broken street light near park'), findsOneWidget);
    });

    testWidgets('Navigation from Complaint Submitted success screen opens ComplaintDetailsScreen', (WidgetTester tester) async {
      final complaint = MockDataSource().complaints.first;

      await tester.pumpWidget(
        _createTestableWidget(
          ComplaintSubmittedScreen(complaint: complaint),
        ),
      );
      await tester.pumpAndSettle();

      final viewBtn = find.text('View Complaint');
      expect(viewBtn, findsOneWidget);
      await tester.tap(viewBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ComplaintDetailsScreen), findsOneWidget);
      expect(find.text(complaint.ticketNumber), findsOneWidget);
    });
  });

  group('Prompt 8: Hazard Model & MockHazardRepository Unit Tests', () {
    test('HazardModel fromComplaint derives valid fields and category icon', () {
      final complaint = MockDataSource().complaints.first;
      final hazard = HazardModel.fromComplaint(complaint);

      expect(hazard.complaintId, complaint.id);
      expect(hazard.ticketNumber, complaint.ticketNumber);
      expect(hazard.title, complaint.title);
      expect(hazard.categoryIcon, isNotNull);
      expect(hazard.statusLabel, complaint.status.label);
    });

    test('MockHazardRepository fetches all hazards, gets by ID, and filters by category & status', () async {
      final repo = MockHazardRepository();
      final all = await repo.getHazards();
      expect(all.length, greaterThanOrEqualTo(5));

      // Get by internal ID
      final first = await repo.getHazardById(all.first.id);
      expect(first, isNotNull);
      expect(first!.id, all.first.id);

      // Filter by Status (e.g. inProgress)
      final inProgressHazards = await repo.getHazards(status: ComplaintStatus.inProgress);
      expect(inProgressHazards.every((h) => h.status == ComplaintStatus.inProgress), isTrue);

      // Search query filter (e.g. CF-2026-000021)
      final searchResults = await repo.getHazards(searchQuery: 'CF-2026-000021');
      expect(searchResults.length, 1);
      expect(searchResults.first.ticketNumber, 'CF-2026-000021');
    });
  });

  group('Prompt 8: Notification Model & MockNotificationRepository Unit Tests', () {
    test('NotificationModel supports all notification types and formatted getters', () {
      final notif = NotificationModel(
        id: 'notif_test',
        title: 'Complaint Verified',
        message: 'Your report has been verified.',
        type: NotificationType.complaintVerified,
        complaintId: 'cmp_103',
        isRead: false,
      );

      expect(notif.type.label, 'Verified');
      expect(notif.type.icon, Icons.verified_outlined);
      expect(notif.isRead, isFalse);
      expect(notif.complaintId, 'cmp_103');
    });

    test('MockNotificationRepository manages notifications, read state, and unread count', () async {
      final repo = MockNotificationRepository();
      final all = await repo.getNotifications();
      expect(all.isNotEmpty, isTrue);

      final initialUnread = await repo.getUnreadCount();
      expect(initialUnread, greaterThanOrEqualTo(1));

      // Mark single as read
      final unreadItem = all.firstWhere((n) => !n.isRead);
      await repo.markAsRead(unreadItem.id);
      final newUnread = await repo.getUnreadCount();
      expect(newUnread, initialUnread - 1);

      // Mark all as read
      await repo.markAllAsRead();
      final afterAllRead = await repo.getUnreadCount();
      expect(afterAllRead, 0);
    });
  });

  group('Prompt 8: Hazard Marker, Info Card & Map Filter Sheet Widget Tests', () {
    testWidgets('HazardMarker renders with accessible semantics and triggers onTap', (WidgetTester tester) async {
      final hazard = MockDataSource().hazards.first;
      bool tapped = false;

      await tester.pumpWidget(
        _createTestableWidget(
          Scaffold(
            body: Center(
              child: HazardMarker(
                hazard: hazard,
                isSelected: false,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HazardMarker), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(hazard.title)), findsOneWidget);

      await tester.tap(find.byType(HazardMarker));
      expect(tapped, isTrue);
    });

    testWidgets('HazardInfoCard renders hazard info and navigates to Complaint Details', (WidgetTester tester) async {
      final hazard = MockDataSource().hazards.firstWhere((h) => h.complaintId != null);
      bool closed = false;

      await tester.pumpWidget(
        _createTestableWidget(
          Scaffold(
            body: Center(
              child: HazardInfoCard(
                hazard: hazard,
                onClose: () => closed = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(hazard.title), findsOneWidget);
      expect(find.text(hazard.category.name), findsOneWidget);
      if (hazard.ticketNumber != null) {
        expect(find.text(hazard.ticketNumber!), findsOneWidget);
      }
      expect(find.text('View Complaint'), findsOneWidget);

      // Close button
      final closeBtn = find.byTooltip('Close hazard details');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      expect(closed, isTrue);

      // Tap View Complaint
      await tester.tap(find.text('View Complaint'));
      await tester.pumpAndSettle();
      expect(find.byType(ComplaintDetailsScreen), findsOneWidget);
    });
  });

  group('Prompt 8: HazardMapScreen Feature & Interaction Tests', () {
    testWidgets('HazardMapScreen renders map canvas, search bar, legend toggle, and markers', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const HazardMapScreen()));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('Hazard Map'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('civic issues near you'), findsOneWidget);
      expect(find.byType(HazardMarker), findsWidgets);

      // Toggle Legend
      final legendBtn = find.byTooltip('Toggle Map Legend');
      expect(legendBtn, findsOneWidget);
      await tester.tap(legendBtn);
      await tester.pumpAndSettle();
      expect(find.text('Status Legend'), findsOneWidget);

      // Tap zoom in and out
      await tester.tap(find.byTooltip('Zoom In'));
      await tester.pump();
      await tester.tap(find.byTooltip('Zoom Out'));
      await tester.pump();
    });

    testWidgets('Tapping hazard marker opens HazardInfoCard and shows details', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const HazardMapScreen()));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Tap on first hazard marker
      final markers = find.byType(HazardMarker);
      expect(markers, findsWidgets);
      await tester.tap(markers.first);
      await tester.pumpAndSettle();

      expect(find.byType(HazardInfoCard), findsOneWidget);
      expect(find.text('View Complaint'), findsOneWidget);
    });

    testWidgets('Search input filters map markers and shows empty state on no match', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const HazardMapScreen()));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byType(TextField), 'CF-2026-000021');
      await tester.pumpAndSettle();

      expect(find.text('1 civic issue near you'), findsOneWidget);

      // Non-matching search
      await tester.enterText(find.byType(TextField), 'NonExistentXYZ999');
      await tester.pumpAndSettle();

      expect(find.text('No civic issues found.'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);

      // Tap Clear Filters
      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();

      expect(find.textContaining('civic issues near you'), findsOneWidget);
    });

    testWidgets('Use My Location button triggers GPS positioning', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const HazardMapScreen()));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      final myLocBtn = find.byTooltip('Use My Location');
      expect(myLocBtn, findsOneWidget);
      await tester.tap(myLocBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Centered on your location'), findsOneWidget);
    });
  });

  group('Prompt 8: NotificationsScreen & NotificationCard Tests', () {
    testWidgets('NotificationsScreen renders list, filter chips, and mark all read', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const NotificationsScreen()));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.textContaining('Unread ('), findsOneWidget);
      expect(find.textContaining('Read ('), findsOneWidget);
      expect(find.byType(NotificationCard), findsWidgets);

      // Filter by Unread
      await tester.tap(find.textContaining('Unread ('));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationCard), findsWidgets);

      // Tap Mark all as read
      final markAllBtn = find.text('Mark all as read');
      if (markAllBtn.evaluate().isNotEmpty) {
        await tester.tap(markAllBtn);
        await tester.pumpAndSettle();
        expect(find.text('All notifications marked as read.'), findsOneWidget);
      }
    });

    testWidgets('Tapping notification with complaint ID navigates to ComplaintDetailsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const NotificationsScreen()));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      final firstCard = find.byType(NotificationCard).first;
      expect(firstCard, findsOneWidget);
      await tester.tap(firstCard);
      await tester.pumpAndSettle();

      expect(find.byType(ComplaintDetailsScreen), findsOneWidget);
    });

    testWidgets('Tapping general civic notification without complaint displays info dialog', (WidgetTester tester) async {
      final generalNotif = NotificationModel(
        id: 'general_notice_1',
        title: 'Community Cleanliness Drive',
        message: 'Join your ward members this Saturday for green cleanliness.',
        type: NotificationType.generalCivic,
        isRead: false,
      );

      await tester.pumpWidget(
        _createTestableWidget(
          Scaffold(
            body: Center(
              child: NotificationCard(
                notification: generalNotif,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NotificationCard));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Community Cleanliness Drive'), findsWidgets);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('Prompt 8: Bottom Navigation & Cross-Feature Data Consistency Tests', () {
    testWidgets('Main Navigation tabs switch between Home, Complaints, Map, Notifications, Profile', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const MainNavigationScreen(initialIndex: 0)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // 1. Home
      expect(find.byType(HomeScreen), findsOneWidget);

      // 2. Switch to Map tab (index 2)
      await tester.tap(find.text('Map'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byType(HazardMapScreen), findsOneWidget);

      // 3. Switch to Notifications tab (index 3)
      await tester.tap(find.text('Notifications'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);

      // 4. Switch to Complaints tab (index 1)
      await tester.tap(find.text('Complaints'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byType(MyComplaintsScreen), findsOneWidget);
    });

    testWidgets('Home screen "View hazard map →" switches to Hazard Map tab', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const MainNavigationScreen(initialIndex: 0)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      final hazardMapLink = find.text('View hazard map →');
      expect(hazardMapLink, findsOneWidget);
      await tester.ensureVisible(hazardMapLink);
      await tester.pumpAndSettle();
      await tester.tap(hazardMapLink);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byType(HazardMapScreen), findsOneWidget);
    });

    test('All feature screens share consistent mock complaint IDs', () async {
      final complaints = MockDataSource().complaints;
      final hazards = MockDataSource().hazards;
      final notifications = MockDataSource().notifications;

      // Check CF-2026-000021 exists in complaints, hazards, and notifications
      final complaint21 = complaints.firstWhere((c) => c.ticketNumber == 'CF-2026-000021');
      final hazard21 = hazards.firstWhere((h) => h.ticketNumber == 'CF-2026-000021');
      final notif21 = notifications.firstWhere((n) => n.complaintId == complaint21.id);

      expect(hazard21.title, complaint21.title);
      expect(notif21.complaintId, complaint21.id);
    });
  });

  // =========================================================================
  // PROMPT 9 TESTS: PROFILE, REWARDS, ASSISTANT & SETTINGS
  // =========================================================================

  group('Prompt 9: User Model & UserRepository Unit Tests', () {
    test('UserModel computes initials correctly for avatar fallback', () {
      const user1 = UserModel(
        id: 'u1',
        fullName: 'Shreyas Shigwan',
        email: 'citizen@civicfix.test',
        phone: '+91 98765 43210',
      );
      expect(user1.initials, 'SS');

      const user2 = UserModel(
        id: 'u2',
        fullName: 'Rahul Sharma',
        email: 'r@test.com',
        phone: '',
      );
      expect(user2.initials, 'RS');

      const user3 = UserModel(
        id: 'u3',
        fullName: 'Priya',
        email: 'p@test.com',
        phone: '',
      );
      expect(user3.initials, 'PR');

      const userEmpty = UserModel(
        id: 'u4',
        fullName: '',
        email: '',
        phone: '',
      );
      expect(userEmpty.initials, 'CF');
    });

    test('UserModel languageName maps codes to human-readable names', () {
      const userEn = UserModel(id: '1', fullName: 'User', email: 'e', phone: 'p', languageCode: 'en');
      const userHi = UserModel(id: '2', fullName: 'User', email: 'e', phone: 'p', languageCode: 'hi');
      const userMr = UserModel(id: '3', fullName: 'User', email: 'e', phone: 'p', languageCode: 'mr');

      expect(userEn.languageName, 'English');
      expect(userHi.languageName, 'हिन्दी (Hindi)');
      expect(userMr.languageName, 'मराठी (Marathi)');
    });

    test('MockUserRepository updates profile and notifies listeners', () async {
      final repo = MockUserRepository();
      final initial = await repo.getCurrentUser();
      expect(initial.fullName, 'Shreyas Shigwan');

      final updated = await repo.updateUserProfile(
        fullName: 'Shreyas S.',
        phone: '+91 99999 88888',
        languageCode: 'hi',
      );

      expect(updated.fullName, 'Shreyas S.');
      expect(updated.phone, '+91 99999 88888');
      expect(updated.languageCode, 'hi');
      expect(repo.getUserListenable().value.fullName, 'Shreyas S.');

      // Restore
      await repo.updateUserProfile(
        fullName: 'Shreyas Shigwan',
        phone: '+91 98765 43210',
        languageCode: 'en',
      );
    });
  });

  group('Prompt 9: Rewards Model & MockRewardsRepository Unit Tests', () {
    test('RewardDataModel computes milestone progress and points to next milestone', () {
      final model = RewardDataModel(
        userId: 'u1',
        currentPoints: 850,
        nextMilestoneTarget: 1000,
        reportsSubmitted: 12,
        reportsResolved: 8,
        achievements: CivicAchievement.defaultAchievements(),
      );

      expect(model.pointsToNextMilestone, 150);
      expect(model.progressRatio, 0.85);
      expect(model.achievements.length, 4);
    });

    test('CivicAchievement returns 4 canonical MVP achievements with locked/unlocked states', () {
      final achievements = CivicAchievement.defaultAchievements();
      expect(achievements.length, 4);

      expect(achievements[0].title, 'First Report');
      expect(achievements[0].isUnlocked, isTrue);

      expect(achievements[1].title, 'Civic Contributor');
      expect(achievements[1].isUnlocked, isTrue);

      expect(achievements[2].title, 'Community Helper');
      expect(achievements[2].isUnlocked, isTrue);

      expect(achievements[3].title, 'Active Citizen');
      expect(achievements[3].isUnlocked, isFalse);
    });

    test('MockRewardsRepository fetches reward data and handles perk redemption', () async {
      final repo = MockRewardsRepository();
      final user = await MockUserRepository().getCurrentUser();
      final data = await repo.getRewardData(user.id);

      expect(data.currentPoints, user.civicPoints);
      expect(data.reportsSubmitted, user.reportsSubmitted);
      expect(data.reportsResolved, user.reportsResolved);

      final perks = await repo.getRewardsCatalog();
      expect(perks.isNotEmpty, isTrue);
    });
  });

  group('Prompt 9: Civic Assistant Service Unit Tests', () {
    test('CivicAssistantService matches 12+ civic question intents in English', () async {
      final service = CivicAssistantService();

      // 1. Report Issue
      final r1 = await service.processQuery(query: 'How do I report an issue?', languageCode: 'en');
      expect(r1.text.contains("Tap 'Report an Issue'"), isTrue);

      // 2. Track Complaint
      final r2 = await service.processQuery(query: 'How can I track my complaint?', languageCode: 'en');
      expect(r2.text.contains('My Complaints'), isTrue);

      // 3. Status Reported
      final r3 = await service.processQuery(query: 'What does Reported mean?', languageCode: 'en');
      expect(r3.text.contains('Stage 1'), isTrue);

      // 4. Status Verified
      final r4 = await service.processQuery(query: 'What does Verified mean?', languageCode: 'en');
      expect(r4.text.contains('Stage 2'), isTrue);

      // 5. Status Assigned
      final r5 = await service.processQuery(query: 'What does Assigned mean?', languageCode: 'en');
      expect(r5.text.contains('Stage 3'), isTrue);

      // 6. Status In Progress
      final r6 = await service.processQuery(query: 'What does In Progress mean?', languageCode: 'en');
      expect(r6.text.contains('Stage 4'), isTrue);

      // 7. Status Resolved
      final r7 = await service.processQuery(query: 'What does Resolved mean?', languageCode: 'en');
      expect(r7.text.contains('Stage 5'), isTrue);

      // 8. Category
      final r8 = await service.processQuery(query: 'Which category should I choose for potholes?', languageCode: 'en');
      expect(r8.text.contains('categories'), isTrue);

      // 9. Photo
      final r9 = await service.processQuery(query: 'How do I add a photo evidence?', languageCode: 'en');
      expect(r9.text.contains('Camera'), isTrue);

      // 10. Location
      final r10 = await service.processQuery(query: 'How do I select a location on map?', languageCode: 'en');
      expect(r10.text.contains('Location'), isTrue);

      // 11. View My Complaints
      final r11 = await service.processQuery(query: 'Where can I see my complaints history?', languageCode: 'en');
      expect(r11.text.contains('Complaints'), isTrue);

      // 12. Hazard Map
      final r12 = await service.processQuery(query: 'Where can I see nearby hazard issues?', languageCode: 'en');
      expect(r12.text.contains('Hazard Map'), isTrue);
    });

    test('CivicAssistantService returns Hindi and Marathi responses when selected', () async {
      final service = CivicAssistantService();

      final hiResp = await service.processQuery(query: 'समस्या कैसे दर्ज करें?', languageCode: 'hi');
      expect(hiResp.text.contains('दर्ज करें'), isTrue);

      final mrResp = await service.processQuery(query: 'तक्रार कशी नोंदवायची?', languageCode: 'mr');
      expect(mrResp.text.contains('तक्रार'), isTrue);
    });

    test('CivicAssistantService returns friendly fallback for unrecognized query', () async {
      final service = CivicAssistantService();
      final fallback = await service.processQuery(query: 'What is the recipe for chocolate cake?', languageCode: 'en');
      expect(fallback.text.contains("I'm still learning how to help with that"), isTrue);
      expect(fallback.followUpSuggestions.isNotEmpty, isTrue);
    });
  });

  group('Prompt 9: ProfileScreen & EditProfileScreen Widget Tests', () {
    testWidgets('ProfileScreen renders user avatar initials, credentials, contribution stats, and settings links', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      // Avatar Initials "SS"
      expect(find.text('SS'), findsOneWidget);

      // User Credentials
      expect(find.text('Shreyas Shigwan'), findsOneWidget);
      expect(find.text('citizen@civicfix.test'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('Ward 14 (Central Ward)'), findsOneWidget);
      expect(find.text('English'), findsWidgets);

      // Civic Contribution Stats (12 reports, 8 resolved, 850 points)
      expect(find.text('Civic Contribution'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('850'), findsOneWidget);

      // Menu links
      expect(find.text('Civic Rewards & Achievements'), findsOneWidget);
      expect(find.text('Civic Assistant'), findsOneWidget);
      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Privacy & Safety'), findsOneWidget);
      expect(find.text('About CivicFix'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('Tapping Edit Profile navigates to EditProfileScreen with populated fields', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      final editBtn = find.text('Edit Profile');
      await tester.ensureVisible(editBtn);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Shreyas Shigwan'), findsOneWidget);
      expect(find.text('citizen@civicfix.test'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsWidgets);
    });

    testWidgets('EditProfileScreen validates name input and saves updated user data', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const EditProfileScreen()));
      await tester.pumpAndSettle();

      // Clear name to test validation
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();

      final saveBtn = find.widgetWithText(ElevatedButton, 'Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full name.'), findsOneWidget);

      // Enter valid updated name
      await tester.enterText(nameField, 'Shreyas S.');
      await tester.pumpAndSettle();

      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(MockDataSource().currentUser.fullName, 'Shreyas S.');
    });
  });

  group('Prompt 9: RewardsScreen & Achievements Widget Tests', () {
    testWidgets('RewardsScreen renders PointsProgressCard with 850 points and 150 points to milestone', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const RewardsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Civic Rewards & Badges'), findsOneWidget);
      expect(find.text('850'), findsWidgets);
      expect(find.text('Civic Points'), findsOneWidget);
      expect(find.text('150 points to next milestone'), findsOneWidget);
      expect(find.text('850 / 1000'), findsOneWidget);

      // Contribution Summary
      expect(find.text('Your Contribution'), findsOneWidget);
      expect(find.text('Total Reports'), findsOneWidget);
      expect(find.text('Resolved Reports'), findsOneWidget);
    });

    testWidgets('RewardsScreen renders 4 MVP achievements with unlocked and locked states', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const RewardsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Achievements'), findsOneWidget);
      expect(find.text('First Report'), findsOneWidget);
      expect(find.text('Civic Contributor'), findsOneWidget);
      expect(find.text('Community Helper'), findsOneWidget);
      expect(find.text('Active Citizen'), findsOneWidget);

      // Tap Active Citizen (Locked) to view how to unlock dialog
      final lockedAchievement = find.text('Active Citizen');
      await tester.ensureVisible(lockedAchievement);
      await tester.tap(lockedAchievement);
      await tester.pumpAndSettle();

      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('How to Unlock'), findsOneWidget);
      expect(find.text('Achieve 1,000 Civic Points and participate in 15 resolved community actions.'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('How to Unlock'), findsNothing);
    });
  });

  group('Prompt 9: AssistantScreen Conversational Interaction Tests', () {
    testWidgets('AssistantScreen renders greeting, suggested prompt chips, and responds to tapped chip', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const AssistantScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Civic Assistant'), findsOneWidget);
      expect(find.textContaining('Hello! I am your CivicFix Assistant'), findsOneWidget);

      // Suggested chips
      expect(find.text('How do I report an issue?'), findsWidgets);
      expect(find.text('How can I track my complaint?'), findsWidgets);

      // Tap first prompt chip
      await tester.tap(find.text('How do I report an issue?').first);
      await tester.pump();
      await tester.pumpAndSettle();

      // User message + Assistant response
      expect(find.text('How do I report an issue?'), findsWidgets);
      expect(find.textContaining("Tap 'Report an Issue' on the Home screen"), findsOneWidget);
    });

    testWidgets('AssistantScreen accepts text input and answers typed question', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const AssistantScreen()));
      await tester.pumpAndSettle();

      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'What does Verified mean?');
      await tester.pumpAndSettle();

      final sendBtn = find.byIcon(Icons.send_rounded);
      await tester.tap(sendBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('What does Verified mean?'), findsWidgets);
      expect(find.textContaining('Stage 2: The ward municipal engineer has reviewed'), findsOneWidget);
    });

    testWidgets('AssistantScreen clear chat button resets conversation', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const AssistantScreen()));
      await tester.pumpAndSettle();

      // Send a message first
      await tester.tap(find.text('How can I track my complaint?').first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('How can I track my complaint?'), findsWidgets);

      // Tap Clear Chat button
      final clearBtn = find.byIcon(Icons.refresh_rounded);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageBubble), findsOneWidget);
      expect(find.textContaining('Hello! I am your CivicFix Assistant'), findsOneWidget);
    });
  });

  group('Prompt 9: Settings, Notifications, Privacy & About Widget Tests', () {
    testWidgets('SettingsScreen renders all sections and opens language selector modal', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Account & Preferences'), findsOneWidget);
      expect(find.text('Preferred Language'), findsOneWidget);
      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Privacy & Safety'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('About CivicFix'), findsOneWidget);
      expect(find.text('1.0.0 (Phase 1 Citizen UI)'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      // Tap Language tile to open sheet
      final langTile = find.text('Preferred Language');
      await tester.tap(langTile);
      await tester.pumpAndSettle();

      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('English'), findsWidgets);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('मराठी'), findsOneWidget);

      // Select Marathi
      await tester.tap(find.text('मराठी'));
      await tester.pumpAndSettle();

      expect(MockDataSource().currentUser.languageCode, 'mr');

      // Restore to English
      MockUserRepository().updateUserProfile(languageCode: 'en');
    });

    testWidgets('NotificationSettingsScreen toggles status and hazard alerts with feedback', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const NotificationSettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Notification Settings'), findsOneWidget);
      expect(find.text('Complaint Status Updates'), findsOneWidget);
      expect(find.text('Community Hazard Warnings'), findsOneWidget);

      // Toggle first switch
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(4));
      await tester.tap(switches.first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Complaint status alerts disabled'), findsOneWidget);
    });

    testWidgets('PrivacySettingsScreen renders confidentiality banner and safety cards', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const PrivacySettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Safety'), findsOneWidget);
      expect(find.text('Citizen Privacy Guaranteed'), findsOneWidget);
      expect(find.text('Personal Identity Confidentiality'), findsOneWidget);
      expect(find.text('Public Civic Issue Visibility'), findsOneWidget);
      expect(find.text('Location Services & GPS Usage'), findsOneWidget);
    });

    testWidgets('AboutScreen renders app branding, version, and mission statement', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const AboutScreen()));
      await tester.pumpAndSettle();

      expect(find.text('About CivicFix'), findsOneWidget);
      expect(find.text('CivicFix'), findsOneWidget);
      expect(find.text('Version 1.0.0 (Phase 1 Citizen UI)'), findsOneWidget);
      expect(find.text('Making civic issue reporting more transparent, accessible, and connected.'), findsOneWidget);
      expect(find.text('Five-Stage Lifecycle Tracking'), findsOneWidget);
      expect(find.text('Interactive Hazard Map'), findsOneWidget);
      expect(find.text('Civic Recognition & Rewards'), findsOneWidget);
    });

    testWidgets('Logout action shows confirmation dialog and navigates to Login on confirmation', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      final logoutTile = find.text('Log Out');
      await tester.ensureVisible(logoutTile);
      await tester.tap(logoutTile);
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsOneWidget);
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);

      // Confirm Logout
      final confirmLogoutBtn = find.widgetWithText(ElevatedButton, 'Log Out');
      await tester.tap(confirmLogoutBtn);
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
    });
  });

  group('Prompt 9: Cross-Feature Shared State & Navigation Integration Tests', () {
    testWidgets('Bottom Navigation maintains exactly 5 tabs and switches to Profile tab', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const MainNavigationScreen(initialIndex: 0)));
      await tester.pumpAndSettle();

      // Tap Profile tab (index 4)
      await tester.tap(find.text('Profile'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Shreyas Shigwan'), findsOneWidget);
    });

    testWidgets('Home screen Civic Progress card navigates to RewardsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const MainNavigationScreen(initialIndex: 0)));
      await tester.pumpAndSettle();

      final progressCard = find.byType(CivicProgressCard);
      expect(progressCard, findsOneWidget);
      await tester.ensureVisible(progressCard);
      await tester.tap(progressCard);
      await tester.pumpAndSettle();

      expect(find.byType(RewardsScreen), findsOneWidget);
    });

    testWidgets('Home screen Assistant quick action card navigates to AssistantScreen', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableWidget(const MainNavigationScreen(initialIndex: 0)));
      await tester.pumpAndSettle();

      final assistantCard = find.widgetWithText(QuickActionCard, 'Assistant');
      expect(assistantCard, findsOneWidget);
      await tester.ensureVisible(assistantCard);
      await tester.tap(assistantCard);
      await tester.pumpAndSettle();

      expect(find.byType(AssistantScreen), findsOneWidget);
    });

    test('All screens share consistent mock user points, reports, and resolved count', () async {
      final user = MockDataSource().currentUser;
      final rewards = await MockRewardsRepository().getRewardData(user.id);
      final progress = CivicProgressSummary.fromUser(user);

      expect(user.civicPoints, 850);
      expect(rewards.currentPoints, 850);
      expect(progress.points, 850);

      expect(user.reportsSubmitted, 12);
      expect(rewards.reportsSubmitted, 12);
      expect(progress.reportsSubmitted, 12);

      expect(user.reportsResolved, 8);
      expect(rewards.reportsResolved, 8);
      expect(progress.reportsResolved, 8);
    });
  });

  // =========================================================================
  // PROMPT 10: GOVERNMENT UI FOUNDATION & DESIGN SYSTEM TESTS
  // =========================================================================
  group('Prompt 10: Government Models & Repositories Unit Tests', () {
    test('GovtUserModel computes initials and supports copyWith', () {
      const officer = GovtUserModel(
        id: 'off_test',
        fullName: 'Rajesh Sharma',
        email: 'rajesh@civicfix.gov.in',
        employeeId: 'EMP-001',
        departmentId: 'dept_roads',
        departmentName: 'Roads & Infrastructure',
        designation: 'Executive Engineer',
        assignedWard: 'Ward 14 (Central)',
      );

      expect(officer.initials, 'RS');
      expect(officer.role, 'government');
      expect(officer.permissions.contains('update_status'), isTrue);

      final updated = officer.copyWith(designation: 'Superintending Engineer');
      expect(updated.designation, 'Superintending Engineer');
      expect(updated.fullName, 'Rajesh Sharma');
    });

    test('GovtDepartmentModel provides standard municipal departments', () {
      final depts = GovtDepartmentModel.defaultDepartments;
      expect(depts.length, greaterThanOrEqualTo(5));
      expect(depts.any((d) => d.id == 'dept_roads'), isTrue);
      expect(depts.any((d) => d.id == 'dept_water'), isTrue);
      expect(depts.any((d) => d.id == 'dept_sanitation'), isTrue);
      expect(depts.any((d) => d.id == 'dept_electrical'), isTrue);
      expect(depts.any((d) => d.id == 'dept_drainage'), isTrue);
    });

    test('MockGovtAuthService handles login, logout, and department switching', () async {
      final auth = MockGovtAuthService();
      final user = await auth.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.role, 'government');

      // Switch department
      auth.switchDepartment('dept_water', 'Water Supply & Distribution');
      expect(auth.userListenable.value?.departmentId, 'dept_water');

      // Test login validation
      final failResult = await auth.login(emailOrEmployeeId: '', password: '');
      expect(failResult.isSuccess, isFalse);

      final successResult = await auth.login(
        emailOrEmployeeId: 'officer@civicfix.gov.in',
        password: 'GovtAdmin2026',
      );
      expect(successResult.isSuccess, isTrue);
    });

    test('MockGovtComplaintRepository provides metrics and supports status updates', () async {
      final repo = MockGovtComplaintRepository();
      final metrics = await repo.getDashboardMetrics();

      expect(metrics.totalComplaints, greaterThanOrEqualTo(5));
      expect(metrics.reportedCount, greaterThanOrEqualTo(1));

      final complaints = await repo.getComplaints();
      expect(complaints.isNotEmpty, isTrue);

      final targetId = complaints.first.id;
      final updateSuccess = await repo.updateStatus(
        complaintId: targetId,
        nextStatus: ComplaintStatus.inProgress,
        updateMessage: 'Field repair underway.',
      );
      expect(updateSuccess, isTrue);

      final updated = await repo.getComplaintById(targetId);
      expect(updated?.status, ComplaintStatus.inProgress);
    });
  });

  group('Prompt 10: Government UI Widgets & Components Widget Tests', () {
    testWidgets('PriorityBadge renders correct icon and color for each priority level', (tester) async {
      await tester.pumpWidget(_createTestableWidget(
        const Scaffold(
          body: Column(
            children: [
              PriorityBadge(priority: ComplaintPriority.low),
              PriorityBadge(priority: ComplaintPriority.medium),
              PriorityBadge(priority: ComplaintPriority.high),
              PriorityBadge(priority: ComplaintPriority.emergency),
            ],
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
    });

    testWidgets('StatCard renders title, value, icon, and trend badge', (tester) async {
      await tester.pumpWidget(_createTestableWidget(
        const Scaffold(
          body: StatCard(
            title: 'Active Tickets',
            value: '42',
            icon: Icons.assignment_outlined,
            trendText: '+5 today',
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Active Tickets'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('+5 today'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
    });

    testWidgets('GovtAppBar renders title, department badge, and ward information', (tester) async {
      const testOfficer = GovtUserModel(
        id: 'off_1',
        fullName: 'Officer Sharma',
        email: 'sharma@civicfix.gov.in',
        employeeId: 'EMP-1',
        departmentId: 'dept_roads',
        departmentName: 'Roads & Infrastructure',
        designation: 'Nodal Officer',
        assignedWard: 'Ward 14 (Central)',
      );

      await tester.pumpWidget(_createTestableWidget(
        const Scaffold(
          body: GovtAppBar(
            title: 'Grievance Control',
            user: testOfficer,
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Grievance Control'), findsWidgets);
      expect(find.text('Roads & Infrastructure'), findsOneWidget);
      expect(find.text('Ward 14 (Central)'), findsOneWidget);
    });
  });

  group('Prompt 10: Government Navigation & Shell Responsiveness Integration Tests', () {
    testWidgets('GovtLoginScreen renders branding, form fields, and fills mock credentials', (tester) async {
      await tester.pumpWidget(_createTestableWidget(const GovtLoginScreen()));
      await tester.pump();

      expect(find.text('CivicFix'), findsOneWidget);
      expect(find.text('MUNICIPAL OFFICER CONTROL DESK'), findsOneWidget);
      expect(find.text('Enter Government Portal'), findsOneWidget);

      final fillButton = find.text('Fill Test Officer Credentials');
      expect(fillButton, findsOneWidget);
      await tester.ensureVisible(fillButton);
      await tester.tap(fillButton);
      await tester.pump();

      expect(find.text('government@civicfix.test'), findsOneWidget);
    });

    testWidgets('GovtShellScreen adapts to desktop layout and switches tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestableWidget(const GovtShellScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GovtSidebar), findsOneWidget);
      expect(find.text('Executive Dashboard'), findsWidgets);

      // Tap Complaints Nav item in Sidebar
      final complaintsNav = find.widgetWithText(InkWell, 'Complaints');
      expect(complaintsNav, findsWidgets);
      await tester.tap(complaintsNav.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Grievance Management'), findsWidgets);
    });
  });

  group('Prompt 11 (Prompt 2): Government Authentication UI & Workflow Tests', () {
    test('MockGovtAuthService handles full state lifecycle and credential checks', () async {
      final auth = MockGovtAuthService();
      expect(auth.isAuthenticated, isTrue);

      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentAuthState, GovtAuthState.unauthenticated);

      // Attempt invalid credentials
      final failResult = await auth.login(
        emailOrEmployeeId: 'invalid@civicfix.test',
        password: 'WrongPassword',
      );
      expect(failResult.isSuccess, isFalse);
      expect(failResult.errorMessage, contains('Invalid government officer credentials'));
      expect(auth.currentAuthState, GovtAuthState.authenticationError);

      // Attempt valid login with Prompt 2 mock credentials
      final successResult = await auth.login(
        emailOrEmployeeId: 'government@civicfix.test',
        password: 'CivicFix123',
      );
      expect(successResult.isSuccess, isTrue);
      expect(successResult.user?.email, 'government@civicfix.test');
      expect(auth.currentAuthState, GovtAuthState.authenticated);
    });

    test('MockGovtAuthService validates and processes password recovery', () async {
      final auth = MockGovtAuthService();

      // Empty email
      final emptyResult = await auth.requestPasswordReset(email: '');
      expect(emptyResult.isSuccess, isFalse);

      // Invalid email syntax
      final invalidResult = await auth.requestPasswordReset(email: 'notanemail');
      expect(invalidResult.isSuccess, isFalse);

      // Valid email
      final validResult = await auth.requestPasswordReset(email: 'government@civicfix.test');
      expect(validResult.isSuccess, isTrue);
      expect(validResult.successMessage, contains('secure password reset link'));
    });

    testWidgets('GovtLoginScreen performs valid login and error display on invalid attempt', (tester) async {
      await tester.pumpWidget(_createTestableWidget(const GovtLoginScreen()));
      await tester.pump();

      // Clear email and enter invalid credentials
      final emailField = find.widgetWithText(TextField, 'government@civicfix.test');
      await tester.enterText(emailField, 'bad_officer@test.com');

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'wrongpassword');
      await tester.pump();

      final loginBtn = find.text('Enter Government Portal');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump(); // Start loading
      await tester.pump(const Duration(milliseconds: 600)); // Finish delay

      expect(find.textContaining('Invalid government officer credentials'), findsOneWidget);

      // Tap fill credentials
      final fillBtn = find.text('Fill Test Officer Credentials');
      await tester.ensureVisible(fillBtn);
      await tester.tap(fillBtn);
      await tester.pump();

      expect(find.text('government@civicfix.test'), findsOneWidget);
    });

    testWidgets('GovtLoginScreen toggles password visibility and remember session', (tester) async {
      await tester.pumpWidget(_createTestableWidget(const GovtLoginScreen()));
      await tester.pump();

      expect(find.text('Remember session'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      // Toggle remember session
      await tester.tap(find.text('Remember session'));
      await tester.pump();

      // Toggle password visibility
      final visibilityBtn = find.byTooltip('Show password');
      expect(visibilityBtn, findsOneWidget);
      await tester.tap(visibilityBtn);
      await tester.pump();

      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets('GovtForgotPasswordScreen validates input, shows loading and success view', (tester) async {
      await tester.pumpWidget(_createTestableWidget(const GovtForgotPasswordScreen()));
      await tester.pump();

      expect(find.text('OFFICER PASSWORD RECOVERY'), findsOneWidget);
      expect(find.text('Reset Municipal Access Passcode'), findsOneWidget);

      // Submit with default email
      final submitBtn = find.text('Send Recovery Instructions');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump(); // Start loading
      await tester.pump(const Duration(milliseconds: 700)); // Finish delay

      expect(find.text('Recovery Token Dispatched'), findsOneWidget);
      expect(find.text('Return to Government Login'), findsOneWidget);

      // Tap return button
      await tester.tap(find.text('Return to Government Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Protected government routes redirect unauthenticated users to login', (tester) async {
      final auth = MockGovtAuthService();
      auth.resetForTesting(authenticated: false);
      await tester.pump();

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRouter.generateRoute,
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.govtDashboard),
              child: const Text('Go to Govt Dashboard'),
            );
          },
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Go to Govt Dashboard'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should render GovtLoginScreen instead of Dashboard
      expect(find.text('MUNICIPAL OFFICER CONTROL DESK'), findsOneWidget);

      // Re-login for subsequent tests
      auth.resetForTesting(authenticated: true);
      await tester.pump();
    });
  });

  group('Prompt 12 (Prompt 3): Government Operations Dashboard Tests', () {
    test('MockGovtComplaintRepository computes metrics, status distribution, and 9-category breakdown', () async {
      final repo = MockGovtComplaintRepository();

      final metrics = await repo.getDashboardMetrics();
      expect(metrics.totalComplaints, greaterThanOrEqualTo(1));
      expect(metrics.reportedCount, greaterThanOrEqualTo(0));
      expect(metrics.verifiedCount, greaterThanOrEqualTo(0));
      expect(metrics.assignedCount, greaterThanOrEqualTo(0));
      expect(metrics.inProgressCount, greaterThanOrEqualTo(0));
      expect(metrics.resolvedCount, greaterThanOrEqualTo(0));
      expect(metrics.criticalHazardsCount, greaterThanOrEqualTo(0));

      final catDist = await repo.getCategoryDistribution();
      expect(catDist.length, 9);
      expect(catDist.any((c) => c.category.id == 'roads'), isTrue);
      expect(catDist.any((c) => c.category.id == 'water'), isTrue);
      expect(catDist.any((c) => c.category.id == 'streetlights'), isTrue);

      final statusDist = await repo.getStatusDistribution();
      expect(statusDist.length, 5);
      expect(statusDist.any((s) => s.status == ComplaintStatus.reported), isTrue);
      expect(statusDist.any((s) => s.status == ComplaintStatus.resolved), isTrue);

      final attentionList = await repo.getAttentionRequiredComplaints(limit: 5);
      expect(attentionList, isNotEmpty);
      expect(attentionList.every((c) => c.status != ComplaintStatus.resolved), isTrue);
    });

    testWidgets('StatusDistributionWidget renders progress bar and status legends', (tester) async {
      final items = [
        const StatusDistributionItem(status: ComplaintStatus.reported, count: 4, percentage: 40.0),
        const StatusDistributionItem(status: ComplaintStatus.verified, count: 2, percentage: 20.0),
        const StatusDistributionItem(status: ComplaintStatus.assigned, count: 1, percentage: 10.0),
        const StatusDistributionItem(status: ComplaintStatus.inProgress, count: 1, percentage: 10.0),
        const StatusDistributionItem(status: ComplaintStatus.resolved, count: 2, percentage: 20.0),
      ];

      ComplaintStatus? tappedStatus;

      await tester.pumpWidget(_createTestableWidget(
        StatusDistributionWidget(
          items: items,
          onStatusSelected: (status) => tappedStatus = status,
        ),
      ));
      await tester.pump();

      expect(find.text('Lifecycle Status Overview'), findsOneWidget);
      expect(find.textContaining('10 active and closed municipal grievances'), findsOneWidget);
      expect(find.text('Reported'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);

      // Tap status legend item
      await tester.tap(find.text('Reported'));
      await tester.pump();
      expect(tappedStatus, ComplaintStatus.reported);
    });

    testWidgets('CategoryBreakdownWidget renders 9 municipal categories with workload bars', (tester) async {
      final items = CivicCategory.defaultCategories.map((c) {
        return CategoryDistributionItem(category: c, count: 2, percentage: 11.1);
      }).toList();

      String? selectedCategory;

      await tester.pumpWidget(_createTestableWidget(
        CategoryBreakdownWidget(
          items: items,
          onCategorySelected: (catId) => selectedCategory = catId,
        ),
      ));
      await tester.pump();

      expect(find.text('Municipal Category Distribution'), findsOneWidget);
      expect(find.text('Roads'), findsOneWidget);
      expect(find.text('Street Lights'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsWidgets);

      // Tap category item
      await tester.tap(find.text('Roads'));
      await tester.pump();
      expect(selectedCategory, 'roads');
    });

    testWidgets('AttentionRequiredCard renders priority items and handles empty list', (tester) async {
      final mockComplaints = MockDataSource().complaints.take(2).toList();
      ComplaintModel? inspected;
      bool viewAllCalled = false;

      await tester.pumpWidget(_createTestableWidget(
        AttentionRequiredCard(
          complaints: mockComplaints,
          onInspect: (c) => inspected = c,
          onViewAll: () => viewAllCalled = true,
        ),
      ));
      await tester.pump();

      expect(find.text('Action & Triage Required'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);

      // Tap View All
      await tester.tap(find.text('View All'));
      await tester.pump();
      expect(viewAllCalled, isTrue);

      // Tap Inspect button on first item
      final inspectButtons = find.byTooltip('Inspect Grievance');
      if (inspectButtons.evaluate().isNotEmpty) {
        await tester.tap(inspectButtons.first);
        await tester.pump();
        expect(inspected, isNotNull);
      }

      // Test Empty State
      await tester.pumpWidget(_createTestableWidget(
        const AttentionRequiredCard(complaints: []),
      ));
      await tester.pump();

      expect(find.text('All urgent civic grievances have been triaged.'), findsOneWidget);
    });

    testWidgets('GovtDashboardScreen renders complete operational dashboard and widgets', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool complaintsNav = false;
      bool mapNav = false;
      bool analyticsNav = false;

      await tester.pumpWidget(_createTestableWidget(
        GovtDashboardScreen(
          onNavigateToComplaints: () => complaintsNav = true,
          onNavigateToMap: () => mapNav = true,
          onNavigateToAnalytics: () => analyticsNav = true,
        ),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Municipal Operations Overview'), findsOneWidget);
      expect(find.text('Real-time grievance telemetry & nodal department workload'), findsOneWidget);

      // 6 KPI Stat Cards
      expect(find.widgetWithText(StatCard, 'Total Grievances'), findsOneWidget);
      expect(find.widgetWithText(StatCard, 'Reported / New'), findsOneWidget);
      expect(find.widgetWithText(StatCard, 'Verified'), findsOneWidget);
      expect(find.widgetWithText(StatCard, 'Assigned'), findsOneWidget);
      expect(find.widgetWithText(StatCard, 'In Progress'), findsOneWidget);
      expect(find.widgetWithText(StatCard, 'Resolved'), findsOneWidget);

      // Operational Highlights
      expect(find.text('Action & Triage Required'), findsOneWidget);
      expect(find.text('Lifecycle Status Overview'), findsOneWidget);
      expect(find.text('Municipal Category Distribution'), findsOneWidget);

      // Recent Complaints Data Table
      expect(find.text('Recent Civic Grievances'), findsOneWidget);
      expect(find.text('View All Complaints'), findsOneWidget);

      // Quick Operations Panel
      expect(find.text('Quick Operations'), findsOneWidget);
      expect(find.text('Manage Grievances'), findsOneWidget);
      expect(find.text('Live Hazard Map'), findsOneWidget);
      expect(find.text('Resolution Analytics'), findsOneWidget);

      // Test navigation triggers
      final viewAllBtn = find.text('View All Complaints');
      await tester.ensureVisible(viewAllBtn);
      await tester.tap(viewAllBtn);
      await tester.pump();
      expect(complaintsNav, isTrue);

      final mapBtn = find.text('Live Hazard Map');
      await tester.ensureVisible(mapBtn);
      await tester.tap(mapBtn);
      await tester.pump();
      expect(mapNav, isTrue);

      final analyticsBtn = find.text('Resolution Analytics');
      await tester.ensureVisible(analyticsBtn);
      await tester.tap(analyticsBtn);
      await tester.pump();
      expect(analyticsNav, isTrue);
    });

    testWidgets('GovtDashboardScreen adapts to mobile viewport cleanly', (tester) async {
      tester.view.physicalSize = const Size(380, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestableWidget(
        const GovtDashboardScreen(),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Municipal Operations Overview'), findsOneWidget);
      expect(find.text('Total Grievances'), findsOneWidget);
      expect(find.text('Action & Triage Required'), findsOneWidget);
    });
  });

  group('Prompt 13 (Prompt 4): Government Complaint Management Tests', () {
    test('MockGovtComplaintRepository filters by category, status, priority, and assignment', () async {
      final repo = MockGovtComplaintRepository();
      
      // Filter by status
      final reported = await repo.getComplaints(status: ComplaintStatus.reported);
      expect(reported.every((c) => c.status == ComplaintStatus.reported), isTrue);

      // Filter by priority
      final emergency = await repo.getComplaints(priority: ComplaintPriority.emergency);
      expect(emergency.every((c) => c.priority == ComplaintPriority.emergency), isTrue);

      // Filter by assignment
      final unassigned = await repo.getComplaints(isAssigned: false);
      expect(unassigned.every((c) => c.assignedTo == null || c.assignedTo!.isEmpty), isTrue);

      final assigned = await repo.getComplaints(isAssigned: true);
      expect(assigned.every((c) => c.assignedTo != null && c.assignedTo!.isNotEmpty), isTrue);

      // Filter by category
      final roads = await repo.getComplaints(categoryId: 'roads');
      expect(roads.every((c) => c.category.id == 'roads' || c.category.name.toLowerCase() == 'roads'), isTrue);
    });

    test('MockGovtComplaintRepository sorts by newest, oldest, recently updated, and highest priority', () async {
      final repo = MockGovtComplaintRepository();

      final newest = await repo.getComplaints(sortBy: GovtComplaintSort.newest);
      expect(newest.isNotEmpty, isTrue);
      for (int i = 0; i < newest.length - 1; i++) {
        expect(newest[i].createdAt.isAfter(newest[i + 1].createdAt) || newest[i].createdAt.isAtSameMomentAs(newest[i + 1].createdAt), isTrue);
      }

      final oldest = await repo.getComplaints(sortBy: GovtComplaintSort.oldest);
      expect(oldest.isNotEmpty, isTrue);
      for (int i = 0; i < oldest.length - 1; i++) {
        expect(oldest[i].createdAt.isBefore(oldest[i + 1].createdAt) || oldest[i].createdAt.isAtSameMomentAs(oldest[i + 1].createdAt), isTrue);
      }

      final highestPrio = await repo.getComplaints(sortBy: GovtComplaintSort.highestPriority);
      expect(highestPrio.isNotEmpty, isTrue);
      expect(highestPrio.first.priority, isIn([ComplaintPriority.emergency, ComplaintPriority.high]));
    });

    test('MockGovtComplaintRepository verifies complaint and records timeline event', () async {
      final repo = MockGovtComplaintRepository();
      final all = await repo.getComplaints();
      final target = all.firstWhere((c) => c.status == ComplaintStatus.reported);

      final success = await repo.verifyComplaint(
        complaintId: target.id,
        notes: 'Field engineer verified road depression.',
        officerName: 'Senior Inspector Verma',
      );
      expect(success, isTrue);

      final updated = await repo.getComplaintById(target.id);
      expect(updated?.status, equals(ComplaintStatus.verified));
      expect(updated?.timeline.first.description, contains('Field engineer verified'));
    });

    testWidgets('GovtComplaintCard renders all grievance fields and handles actions', (tester) async {
      bool detailsTapped = false;
      bool assignTapped = false;
      bool updateTapped = false;

      final complaint = MockDataSource().complaints.first;

      await tester.pumpWidget(_createTestableWidget(
        GovtComplaintCard(
          complaint: complaint,
          onTap: () => detailsTapped = true,
          onAssign: () => assignTapped = true,
          onUpdateStatus: () => updateTapped = true,
        ),
      ));
      await tester.pump();

      expect(find.text(complaint.ticketNumber), findsOneWidget);
      expect(find.text(complaint.title), findsOneWidget);
      expect(find.text(complaint.category.name), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Assign'), findsOneWidget);
      expect(find.text('Update Status'), findsOneWidget);

      await tester.tap(find.text('Details'));
      expect(detailsTapped, isTrue);

      await tester.tap(find.text('Assign'));
      expect(assignTapped, isTrue);

      await tester.tap(find.text('Update Status'));
      expect(updateTapped, isTrue);
    });

    testWidgets('GovtComplaintListScreen renders desktop table with filters and search', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestableWidget(
        const GovtComplaintListScreen(),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Check Toolbar elements
      expect(find.byType(GovtSearchField), findsOneWidget);
      expect(find.widgetWithText(GovtFilterChip, 'All Grievances'), findsOneWidget);
      expect(find.widgetWithText(GovtFilterChip, 'Reported'), findsOneWidget);
      expect(find.widgetWithText(GovtFilterChip, 'Verified'), findsOneWidget);
      expect(find.widgetWithText(GovtFilterChip, 'Assigned'), findsOneWidget);
      expect(find.widgetWithText(GovtFilterChip, 'In Progress'), findsOneWidget);
      expect(find.widgetWithText(GovtFilterChip, 'Resolved'), findsOneWidget);

      // Check Dropdown Buttons
      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('All Priorities'), findsOneWidget);
      expect(find.text('All Assignments'), findsOneWidget);
      expect(find.text('Newest First'), findsOneWidget);

      // Check Table
      expect(find.byType(GovtDataTable), findsOneWidget);
      expect(find.text('TICKET #'), findsOneWidget);
      expect(find.text('SUBJECT / CATEGORY'), findsOneWidget);
      expect(find.text('LOCATION / WARD'), findsOneWidget);
      expect(find.text('PRIORITY'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('ACTIONS'), findsOneWidget);

      // Test Status filter tap
      await tester.tap(find.widgetWithText(GovtFilterChip, 'Reported'));
      await tester.pumpAndSettle();
      expect(find.text('Clear Filters'), findsOneWidget);

      // Clear filters
      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();
    });

    testWidgets('GovtComplaintListScreen handles search and empty state', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestableWidget(
        const GovtComplaintListScreen(),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Enter search query with zero matches
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'XYZNONEXISTENTCOMPLAINT12345');
      await tester.pumpAndSettle();

      // Empty state should be visible
      expect(find.text('No complaints found'), findsOneWidget);
      expect(find.text('Clear All Filters'), findsOneWidget);

      // Tap Clear All Filters
      await tester.tap(find.text('Clear All Filters'));
      await tester.pumpAndSettle();

      expect(find.text('No complaints found'), findsNothing);
    });

    testWidgets('GovtComplaintListScreen renders mobile cards list on small screens', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestableWidget(
        const GovtComplaintListScreen(),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(GovtDataTable), findsNothing);
      expect(find.byType(GovtComplaintCard), findsWidgets);
    });

    testWidgets('GovtComplaintDetailsScreen renders complete grievance info, gallery, timeline, and actions', (tester) async {
      final complaint = MockDataSource().complaints.firstWhere((c) => c.status == ComplaintStatus.reported);

      await tester.pumpWidget(_createTestableWidget(
        GovtComplaintDetailsScreen(complaint: complaint),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Grievance ${complaint.ticketNumber}'), findsOneWidget);
      expect(find.text('Grievance Overview'), findsOneWidget);
      expect(find.text(complaint.title), findsOneWidget);
      expect(find.text(complaint.description), findsOneWidget);
      expect(find.text('Photo & Geographic Evidence'), findsOneWidget);
      expect(find.text('Department & Crew Assignment'), findsOneWidget);
      expect(find.text('Status & Audit Trail'), findsOneWidget);

      // Reported status should show Verify button
      expect(find.text('Verify'), findsOneWidget);
      expect(find.text('Assign Crew'), findsOneWidget);
      expect(find.text('Update Status'), findsOneWidget);

      // Tap Verify button to open verification dialog
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(find.text('Verify Grievance ${complaint.ticketNumber}'), findsOneWidget);
      expect(find.text('Confirm Verification'), findsOneWidget);

      // Confirm verification
      await tester.tap(find.text('Confirm Verification'));
      await tester.pumpAndSettle();

      expect(find.text('Grievance ${complaint.ticketNumber} marked as Verified.'), findsOneWidget);
    });
  });

  group('Prompt 14 (Prompt 5): Government Verification, Assignment & Status Updates Tests', () {
    test('MockGovtComplaintRepository verifies complaint and records timeline event', () async {
      final repo = MockGovtComplaintRepository();
      final all = await repo.getComplaints();
      final target = all.firstWhere((c) => c.status == ComplaintStatus.reported);

      final success = await repo.verifyComplaint(
        complaintId: target.id,
        notes: 'Field engineer verified road depression.',
        officerName: 'Senior Inspector Verma',
      );
      expect(success, isTrue);

      final updated = await repo.getComplaintById(target.id);
      expect(updated?.status, equals(ComplaintStatus.verified));
      expect(updated?.timeline.first.description, contains('Field engineer verified'));
    });

    test('MockGovtComplaintRepository flags and rejects complaints with moderation timeline audit', () async {
      final repo = MockGovtComplaintRepository();
      final all = await repo.getComplaints();
      final target = all.first;

      // Flag complaint
      final flagSuccess = await repo.flagComplaint(
        complaintId: target.id,
        reason: 'Duplicate of grievance CF-2024-001.',
        officerName: 'Control Room Officer',
      );
      expect(flagSuccess, isTrue);

      var updated = await repo.getComplaintById(target.id);
      expect(updated?.timeline.first.title, contains('Flagged for Review'));
      expect(updated?.timeline.first.description, contains('Duplicate of grievance'));

      // Reject complaint
      final rejectSuccess = await repo.rejectComplaint(
        complaintId: target.id,
        reason: 'Private property jurisdiction.',
        officerName: 'Zonal Commissioner',
      );
      expect(rejectSuccess, isTrue);

      updated = await repo.getComplaintById(target.id);
      expect(updated?.status, equals(ComplaintStatus.rejected));
      expect(updated?.timeline.first.title, contains('Complaint Closed'));
    });

    test('MockGovtComplaintRepository assigns complaint to department and officer', () async {
      final repo = MockGovtComplaintRepository();
      final all = await repo.getComplaints();
      final target = all.first;

      final assignSuccess = await repo.assignComplaint(
        complaintId: target.id,
        departmentId: 'dept_water',
        officerName: 'Officer B (Water Inspection Lead)',
        assignmentNote: 'Investigate main pipeline pressure drop.',
      );
      expect(assignSuccess, isTrue);

      final updated = await repo.getComplaintById(target.id);
      expect(updated?.status, equals(ComplaintStatus.assigned));
      expect(updated?.effectiveDepartment, equals('Water Department'));
      expect(updated?.assignedTo, equals('Officer B (Water Inspection Lead)'));
      expect(updated?.timeline.first.title, equals('Assigned to Officer B (Water Inspection Lead)'));
      expect(updated?.timeline.first.description, contains('Investigate main pipeline'));
    });

    test('MockGovtComplaintRepository updates status to resolved and sets resolvedAt', () async {
      final repo = MockGovtComplaintRepository();
      final all = await repo.getComplaints();
      final target = all.first;

      final updateSuccess = await repo.updateStatus(
        complaintId: target.id,
        nextStatus: ComplaintStatus.resolved,
        updateMessage: 'Pothole filled with cold mix asphalt and steam rolled.',
      );
      expect(updateSuccess, isTrue);

      final updated = await repo.getComplaintById(target.id);
      expect(updated?.status, equals(ComplaintStatus.resolved));
      expect(updated?.resolvedAt, isNotNull);
      expect(updated?.timeline.first.title, contains('Issue Resolved'));
    });

    testWidgets('GovtComplaintAssignmentScreen renders departments, filters officers, and executes dispatch', (tester) async {
      final complaint = MockDataSource().complaints.first;

      await tester.pumpWidget(_createTestableWidget(
        GovtComplaintAssignmentScreen(complaint: complaint),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Assign Grievance ${complaint.ticketNumber}'), findsOneWidget);
      expect(find.text(complaint.title), findsOneWidget);
      expect(find.text('Select Municipal Department'), findsOneWidget);
      expect(find.text('Designated Field Engineer / Crew'), findsOneWidget);
      expect(find.text('Dispatch Instructions & Priority Notes'), findsOneWidget);
      expect(find.widgetWithText(CivicFixButton, 'Confirm & Dispatch'), findsOneWidget);

      // Tap Confirm & Dispatch button on screen -> opens confirmation dialog
      await tester.tap(find.widgetWithText(CivicFixButton, 'Confirm & Dispatch'));
      await tester.pumpAndSettle();

      expect(find.byType(GovtConfirmationDialog), findsOneWidget);
      expect(find.text('Confirm Crew Dispatch'), findsOneWidget);

      // Cancel dialog -> dialog closes without popping assignment screen
      final dialogCancelBtn = find.descendant(
        of: find.byType(GovtConfirmationDialog),
        matching: find.text('Cancel'),
      );
      await tester.tap(dialogCancelBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GovtConfirmationDialog), findsNothing);
      expect(find.widgetWithText(CivicFixButton, 'Confirm & Dispatch'), findsOneWidget);

      // Re-open and Confirm
      await tester.tap(find.widgetWithText(CivicFixButton, 'Confirm & Dispatch'));
      await tester.pumpAndSettle();

      // Tap confirm button in dialog
      final confirmBtn = find.descendant(
        of: find.byType(GovtConfirmationDialog),
        matching: find.widgetWithText(ElevatedButton, 'Confirm & Dispatch'),
      );
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verified state updated in repository
      final updated = await MockGovtComplaintRepository().getComplaintById(complaint.id);
      expect(updated?.status, equals(ComplaintStatus.assigned));
    });

    testWidgets('GovtStatusUpdateScreen enforces validation, handles admin override, and updates status', (tester) async {
      final complaint = MockDataSource().complaints.firstWhere((c) => c.status == ComplaintStatus.reported);

      await tester.pumpWidget(_createTestableWidget(
        GovtStatusUpdateScreen(complaint: complaint),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Update Status: ${complaint.ticketNumber}'), findsOneWidget);
      expect(find.text('Select Next Lifecycle Status'), findsOneWidget);
      expect(find.text('Official Status Notes & Citizen Update Message *'), findsOneWidget);

      // Clear update notes to trigger validation error
      final messageField = find.byType(TextFormField).first;
      await tester.enterText(messageField, '');
      await tester.pumpAndSettle();

      // Submit with empty message
      final updateBtn = find.text('Update Grievance Status');
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please provide an update note for this status change.'), findsOneWidget);

      // Select Administrative Override
      final adminCheckbox = find.byType(Checkbox);
      await tester.tap(adminCheckbox);
      await tester.pumpAndSettle();

      // Enter valid message
      await tester.enterText(messageField, 'Site inspected and verified by municipal team.');
      await tester.pumpAndSettle();

      // Tap submit -> opens confirmation dialog
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GovtConfirmationDialog), findsOneWidget);
      expect(find.text('Confirm Status Update'), findsOneWidget);

      // Cancel dialog
      final dialogCancelBtn = find.descendant(
        of: find.byType(GovtConfirmationDialog),
        matching: find.text('Cancel'),
      );
      await tester.tap(dialogCancelBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GovtConfirmationDialog), findsNothing);

      // Tap submit again and Confirm
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      final confirmBtn = find.descendant(
        of: find.byType(GovtConfirmationDialog),
        matching: find.widgetWithText(ElevatedButton, 'Confirm Update'),
      );
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      final updated = await MockGovtComplaintRepository().getComplaintById(complaint.id);
      expect(updated?.status, equals(ComplaintStatus.verified));
    });

    testWidgets('GovtComplaintDetailsScreen allows Flag / Review and updates state', (tester) async {
      final complaint = MockDataSource().complaints.firstWhere((c) => c.status == ComplaintStatus.reported);

      await tester.pumpWidget(_createTestableWidget(
        GovtComplaintDetailsScreen(complaint: complaint),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Flag / Review'), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);

      // Tap Flag / Review button
      await tester.tap(find.text('Flag / Review'));
      await tester.pumpAndSettle();

      expect(find.text('Flag Grievance ${complaint.ticketNumber}'), findsOneWidget);
      expect(find.text('Confirm Flag'), findsOneWidget);

      // Tap Confirm Flag
      await tester.tap(find.text('Confirm Flag'));
      await tester.pumpAndSettle();

      expect(find.text('Grievance ${complaint.ticketNumber} flagged for review.'), findsOneWidget);
    });

    test('Full 5-stage grievance lifecycle maintains end-to-end consistency', () async {
      final repo = MockGovtComplaintRepository();
      final all = await repo.getComplaints();
      final c = all.firstWhere((item) => item.status == ComplaintStatus.reported);
      final id = c.id;

      // Stage 1: Reported -> Verify
      await repo.verifyComplaint(complaintId: id, notes: 'Verified on-site.');
      var current = await repo.getComplaintById(id);
      expect(current?.status, equals(ComplaintStatus.verified));

      // Stage 2: Verified -> Assign
      await repo.assignComplaint(
        complaintId: id,
        departmentId: 'dept_roads',
        officerName: 'Officer A (Roads Supervisor)',
        assignmentNote: 'Dispatched road repair crew.',
      );
      current = await repo.getComplaintById(id);
      expect(current?.status, equals(ComplaintStatus.assigned));
      expect(current?.assignedTo, equals('Officer A (Roads Supervisor)'));

      // Stage 3: Assigned -> In Progress
      await repo.updateStatus(
        complaintId: id,
        nextStatus: ComplaintStatus.inProgress,
        updateMessage: 'Asphalt milling machine on site.',
      );
      current = await repo.getComplaintById(id);
      expect(current?.status, equals(ComplaintStatus.inProgress));

      // Stage 4: In Progress -> Resolved
      await repo.updateStatus(
        complaintId: id,
        nextStatus: ComplaintStatus.resolved,
        updateMessage: 'Pothole completely filled and road restored.',
      );
      current = await repo.getComplaintById(id);
      expect(current?.status, equals(ComplaintStatus.resolved));
      expect(current?.resolvedAt, isNotNull);
      expect(current?.timeline.length, greaterThanOrEqualTo(4));
    });
  });

  group('Prompt 15 (Prompt 6): Government Hazard Map Tests', () {
    test('MockHazardRepository fetches all hazards and filters by category, status, severity, and search', () async {
      final repo = MockHazardRepository();

      // 1. Fetch all
      final all = await repo.getHazards();
      expect(all.length, greaterThanOrEqualTo(7));

      // 2. Filter by status
      final inProgress = await repo.getHazards(status: ComplaintStatus.inProgress);
      expect(inProgress.every((h) => h.status == ComplaintStatus.inProgress), isTrue);

      // 3. Filter by severity
      final critical = await repo.getHazards(severity: HazardSeverity.critical);
      expect(critical.every((h) => h.severity == HazardSeverity.critical), isTrue);

      // 4. Search query by ticket number
      final searchTicket = await repo.getHazards(searchQuery: 'CF-2026-000021');
      expect(searchTicket.isNotEmpty, isTrue);
      expect(searchTicket.first.ticketNumber, equals('CF-2026-000021'));

      // 5. Search query by address / keyword
      final searchAddr = await repo.getHazards(searchQuery: 'Park View Road');
      expect(searchAddr.isNotEmpty, isTrue);

      // 6. Get hazard by ID
      final single = await repo.getHazardById(all.first.id);
      expect(single, isNotNull);
      expect(single?.id, equals(all.first.id));
    });

    testWidgets('GovtHazardMarker renders category icon, status indicator, and responds to tap', (tester) async {
      bool tapped = false;
      final hazard = MockDataSource().hazards.first;

      await tester.pumpWidget(_createTestableWidget(
        GovtHazardMarker(
          hazard: hazard,
          isSelected: true,
          onTap: () => tapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(GovtHazardMarker), findsOneWidget);
      expect(find.byIcon(hazard.categoryIcon), findsOneWidget);

      await tester.tap(find.byType(GovtHazardMarker));
      expect(tapped, isTrue);
    });

    testWidgets('GovtHazardInfoCard renders hazard metadata and navigates to complaint details', (tester) async {
      final hazard = MockDataSource().hazards.firstWhere((h) => h.complaintId != null);
      bool closed = false;

      await tester.pumpWidget(_createTestableWidget(
        GovtHazardInfoCard(
          hazard: hazard,
          onClose: () => closed = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(hazard.title), findsOneWidget);
      expect(find.text(hazard.category.name), findsOneWidget);
      expect(find.text(hazard.ticketNumber!), findsOneWidget);
      expect(find.text('View Grievance Details'), findsOneWidget);

      // Test close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closed, isTrue);

      // Test View Grievance Details navigation
      await tester.tap(find.text('View Grievance Details'));
      await tester.pumpAndSettle();

      expect(find.byType(GovtComplaintDetailsScreen), findsOneWidget);
    });

    testWidgets('GovtMapLegend renders hazard categories, lifecycle status, and severity indicators', (tester) async {
      bool closed = false;

      await tester.pumpWidget(_createTestableWidget(
        GovtMapLegend(onClose: () => closed = true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('GIS Map Legend'), findsOneWidget);
      expect(find.text('HAZARD CATEGORIES'), findsOneWidget);
      expect(find.text('Road Damage'), findsOneWidget);
      expect(find.text('Waterlogging'), findsOneWidget);
      expect(find.text('Open Manhole'), findsOneWidget);
      expect(find.text('Garbage'), findsOneWidget);
      expect(find.text('Drainage'), findsOneWidget);
      expect(find.text('Street Light'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      expect(find.text('LIFECYCLE STATUS'), findsOneWidget);
      expect(find.text('Reported'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);

      expect(find.text('PRIORITY SEVERITY'), findsOneWidget);
      expect(find.text('P1 Critical'), findsOneWidget);
      expect(find.text('P2 High'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closed, isTrue);
    });

    testWidgets('GovtHazardMapScreen renders search, filter toolbar, markers, and handles filters', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestableWidget(
        const GovtHazardMapScreen(),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Check toolbar widgets
      expect(find.byType(GovtSearchField), findsOneWidget);
      expect(find.widgetWithText(GovtFilterChip, 'All Hazards'), findsOneWidget);
      expect(find.widgetWithText(GovtFilterChip, 'In Progress'), findsOneWidget);
      expect(find.widgetWithText(GovtFilterChip, 'Verified'), findsOneWidget);

      // Check map canvas
      expect(find.byType(GovtMapCanvas), findsOneWidget);
      expect(find.byType(GovtHazardMarker), findsWidgets);

      // Test status filter selection
      await tester.tap(find.widgetWithText(GovtFilterChip, 'In Progress'));
      await tester.pumpAndSettle();

      // Should show Clear button in toolbar
      expect(find.text('Clear'), findsOneWidget);

      // Tap Clear filters
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Test search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'CF-2026-000021');
      await tester.pumpAndSettle();

      expect(find.text('1 Active Hazards'), findsOneWidget);

      // Search non-existent query to test empty state
      await tester.enterText(searchField, 'NONEXISTENTHAZARDQUERY12345');
      await tester.pumpAndSettle();

      expect(find.text('No hazards match your filter criteria'), findsOneWidget);
      expect(find.text('Reset All Filters'), findsOneWidget);

      // Tap Reset All Filters
      await tester.tap(find.text('Reset All Filters'));
      await tester.pumpAndSettle();

      expect(find.text('No hazards match your filter criteria'), findsNothing);
    });

    testWidgets('GovtHazardMapScreen toggles legend, GPS location, and zoom controls', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestableWidget(
        const GovtHazardMapScreen(),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Toggle Legend on
      final legendBtn = find.byTooltip('Toggle GIS Legend');
      expect(legendBtn, findsOneWidget);
      await tester.tap(legendBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GovtMapLegend), findsOneWidget);

      // Toggle Legend off
      await tester.tap(legendBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GovtMapLegend), findsNothing);

      // Test GPS location button
      final gpsBtn = find.byTooltip('Center on My GPS Location');
      expect(gpsBtn, findsOneWidget);
      await tester.tap(gpsBtn);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Test Zoom In & Zoom Out
      final zoomInBtn = find.byTooltip('Zoom In');
      final zoomOutBtn = find.byTooltip('Zoom Out');
      final resetWardBtn = find.byTooltip('Reset to Ward Center');

      expect(zoomInBtn, findsOneWidget);
      expect(zoomOutBtn, findsOneWidget);
      expect(resetWardBtn, findsOneWidget);

      await tester.tap(zoomInBtn);
      await tester.pumpAndSettle();

      await tester.tap(zoomOutBtn);
      await tester.pumpAndSettle();

      await tester.tap(resetWardBtn);
      await tester.pumpAndSettle();
    });

    testWidgets('GovtHazardMapScreen marker interaction opens info card and navigates to details', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestableWidget(
        const GovtHazardMapScreen(),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap first visible marker
      final markers = find.byType(GovtHazardMarker);
      expect(markers, findsWidgets);
      await tester.tap(markers.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Info card should be visible
      expect(find.byType(GovtHazardInfoCard), findsOneWidget);
      expect(find.text('View Grievance Details'), findsOneWidget);

      // Tap View Grievance Details -> Navigates to GovtComplaintDetailsScreen
      await tester.tap(find.text('View Grievance Details'));
      await tester.pumpAndSettle();

      expect(find.byType(GovtComplaintDetailsScreen), findsOneWidget);
    });
  });

  group('Prompt 16 (Prompt 7): Government Analytics Tests', () {
    test('MockAnalyticsRepository calculates KPI summaries, date range filtering, category, status, department, and priority metrics', () async {
      final repo = MockAnalyticsRepository();

      // 1. Fetch default (Last 30 Days)
      final defaultData = await repo.getAnalytics();
      expect(defaultData.summary.totalComplaints, greaterThanOrEqualTo(5));
      expect(defaultData.summary.resolvedComplaints, greaterThanOrEqualTo(1));
      expect(defaultData.summary.resolutionRate, greaterThanOrEqualTo(0.0));
      expect(defaultData.summary.resolutionRate, lessThanOrEqualTo(1.0));
      expect(defaultData.summary.avgResolutionHours, greaterThan(0));
      expect(defaultData.summary.formattedAvgResolutionTime.isNotEmpty, isTrue);
      expect(defaultData.summary.formattedResolutionPercentage.contains('%'), isTrue);

      // Verify category breakdown covers all 9 categories
      expect(defaultData.categoryBreakdowns.length, equals(9));

      // Verify status breakdown covers all 5 statuses
      expect(defaultData.statusBreakdowns.length, equals(5));

      // Verify department breakdown covers all 9 departments
      expect(defaultData.departmentBreakdowns.length, equals(9));

      // Verify time trends generated
      expect(defaultData.timeTrends.isNotEmpty, isTrue);

      // 2. Filter by category
      final catFiltered = await repo.getAnalytics(
        filter: const AnalyticsFilter(categoryId: 'roads'),
      );
      expect(catFiltered.summary.totalComplaints, lessThanOrEqualTo(defaultData.summary.totalComplaints));

      // 3. Filter by status
      final statusFiltered = await repo.getAnalytics(
        filter: const AnalyticsFilter(status: ComplaintStatus.inProgress),
      );
      expect(statusFiltered.summary.inProgressComplaints, equals(statusFiltered.summary.totalComplaints));

      // 4. Filter by priority
      final priorityFiltered = await repo.getAnalytics(
        filter: const AnalyticsFilter(priority: ComplaintPriority.high),
      );
      expect(priorityFiltered.summary.totalComplaints, lessThanOrEqualTo(defaultData.summary.totalComplaints));

      // 5. Filter by department
      final deptFiltered = await repo.getAnalytics(
        filter: const AnalyticsFilter(departmentId: 'dept_roads'),
      );
      expect(deptFiltered.summary.totalComplaints, lessThanOrEqualTo(defaultData.summary.totalComplaints));
    });

    testWidgets('GovtAnalyticsFilterBar renders filters, responds to chip and dropdown selections, and resets', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      AnalyticsFilter currentFilter = const AnalyticsFilter();
      bool resetCalled = false;

      await tester.pumpWidget(_createTestableWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: GovtAnalyticsFilterBar(
                activeFilter: currentFilter,
                totalCount: 25,
                onFilterChanged: (newFilter) {
                  setState(() => currentFilter = newFilter);
                },
                onResetFilters: () {
                  setState(() {
                    currentFilter = const AnalyticsFilter();
                    resetCalled = true;
                  });
                },
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Analytics Filters & Time Range'), findsOneWidget);
      expect(find.text('25 Grievances Analyzed'), findsOneWidget);
      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('Last 90 Days'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);

      // Tap Last 7 Days chip
      await tester.tap(find.text('Last 7 Days'));
      await tester.pumpAndSettle();
      expect(currentFilter.dateRange, equals(DateRangeOption.last7Days));

      // Reset button should now be visible since filter is active
      expect(find.text('Reset'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(resetCalled, isTrue);
      expect(currentFilter.dateRange, equals(DateRangeOption.last30Days));
    });

    testWidgets('GovtTimeTrendChart renders time points, dual bars, legend, and toggles tooltips', (tester) async {
      final points = [
        TimeTrendPoint(date: DateTime.now().subtract(const Duration(days: 2)), label: 'Mon', reportedCount: 6, resolvedCount: 4),
        TimeTrendPoint(date: DateTime.now().subtract(const Duration(days: 1)), label: 'Tue', reportedCount: 8, resolvedCount: 5),
        TimeTrendPoint(date: DateTime.now(), label: 'Wed', reportedCount: 4, resolvedCount: 7),
      ];

      await tester.pumpWidget(_createTestableWidget(
        Scaffold(
          body: GovtTimeTrendChart(
            points: points,
            dateRange: DateRangeOption.last7Days,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Complaint Volume & Resolution Trend'), findsOneWidget);
      expect(find.text('Reported'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);

      // Tap first bar point to trigger tooltip pill
      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();

      expect(find.text('Rep: 6 | Res: 4'), findsOneWidget);
    });

    testWidgets('GovtResolutionPerformanceWidget renders SLA efficiency, resolution percentage, and duration tiles', (tester) async {
      const summary = AnalyticsSummary(
        totalComplaints: 20,
        resolvedComplaints: 16,
        pendingComplaints: 2,
        inProgressComplaints: 2,
        assignedComplaints: 1,
        highPriorityComplaints: 4,
        unassignedComplaints: 1,
        resolutionRate: 0.80,
        avgResolutionHours: 32.5,
        slaComplianceRate: 0.92,
      );

      await tester.pumpWidget(_createTestableWidget(
        const Scaffold(
          body: GovtResolutionPerformanceWidget(summary: summary),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Resolution SLA & Performance'), findsOneWidget);
      expect(find.text('80.0%'), findsOneWidget);
      expect(find.text('16 of 20 Resolved'), findsOneWidget);
      expect(find.text('Average Duration'), findsOneWidget);
      expect(find.text('Active Pipeline'), findsOneWidget);
      expect(find.text('Operational benchmark: 91.2% first-time field triage resolution.'), findsOneWidget);
    });

    testWidgets('GovtDepartmentAnalyticsTable renders 9 departments on desktop and card view on mobile', (tester) async {
      final departments = [
        const DepartmentAnalytics(
          departmentId: 'dept_roads',
          departmentName: 'Roads & Infrastructure',
          total: 10,
          pending: 2,
          inProgress: 3,
          resolved: 5,
          resolutionRate: 0.50,
          avgResolutionHours: 36.0,
        ),
        const DepartmentAnalytics(
          departmentId: 'dept_water',
          departmentName: 'Water Supply',
          total: 8,
          pending: 1,
          inProgress: 2,
          resolved: 5,
          resolutionRate: 0.625,
          avgResolutionHours: 28.0,
        ),
      ];

      // Desktop test
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestableWidget(
        Scaffold(
          body: GovtDepartmentAnalyticsTable(departments: departments),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Department Workload & Performance Breakdown'), findsOneWidget);
      expect(find.text('Department'), findsOneWidget);
      expect(find.text('Roads & Infrastructure'), findsOneWidget);
      expect(find.text('Water Supply'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('63%'), findsWidgets);

      // Mobile viewport test
      tester.view.physicalSize = const Size(500, 800);
      await tester.pumpWidget(_createTestableWidget(
        Scaffold(
          body: GovtDepartmentAnalyticsTable(departments: departments),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('10 Total'), findsOneWidget);
      expect(find.text('8 Total'), findsOneWidget);
    });

    testWidgets('GovtAnalyticsScreen loads dashboard, handles filter updates, and renders empty and error states', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestableWidget(
        const GovtAnalyticsScreen(),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Check 7 KPI stat cards
      expect(find.text('Total Complaints'), findsOneWidget);
      expect(find.text('Resolved Complaints'), findsOneWidget);
      expect(find.text('Pending Triage'), findsOneWidget);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.text('Avg Resolution Time'), findsOneWidget);
      expect(find.text('High-Priority Tickets'), findsOneWidget);
      expect(find.text('Unassigned Queue'), findsOneWidget);

      // Check sub-widgets
      expect(find.byType(GovtTimeTrendChart), findsOneWidget);
      expect(find.byType(GovtResolutionPerformanceWidget), findsOneWidget);
      expect(find.byType(GovtDepartmentAnalyticsTable), findsOneWidget);
      expect(find.byType(GovtAnalyticsCard), findsNWidgets(2)); // Category + Status breakdown cards

      // Tap 7 Days filter chip
      await tester.tap(find.text('Last 7 Days'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Reset'), findsOneWidget);

      // Tap Reset All Filters
      await tester.tap(find.text('Reset'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Reset'), findsNothing);
    });
  });

  group('Prompt 17 (Prompt 8): Government Profile & Settings Tests', () {
    test('GovtUserModel contains all required fields, computes initials, and supports copyWith', () {
      const user = GovtUserModel(
        id: 'govt_100',
        fullName: 'Arun Kumar',
        email: 'arun.kumar@civicfix.gov.in',
        employeeId: 'MC-2026-ENG-100',
        phone: '+91 91234 56789',
        organization: 'Municipal Corporation Zone 5',
        departmentId: 'dept_water',
        departmentName: 'Water Supply',
        designation: 'Executive Engineer',
        assignedWard: 'Ward 22 (South)',
        role: 'government',
      );

      expect(user.fullName, 'Arun Kumar');
      expect(user.email, 'arun.kumar@civicfix.gov.in');
      expect(user.phone, '+91 91234 56789');
      expect(user.organization, 'Municipal Corporation Zone 5');
      expect(user.departmentName, 'Water Supply');
      expect(user.designation, 'Executive Engineer');
      expect(user.role, 'government');
      expect(user.initials, 'AK');

      final modified = user.copyWith(
        fullName: 'Arun K. Sharma',
        phone: '+91 98888 77777',
        designation: 'Chief Engineer',
      );

      expect(modified.fullName, 'Arun K. Sharma');
      expect(modified.phone, '+91 98888 77777');
      expect(modified.designation, 'Chief Engineer');
      expect(modified.email, 'arun.kumar@civicfix.gov.in'); // Read-only preserved
      expect(modified.role, 'government'); // Read-only preserved
    });

    test('GovtSettingsModel supports defaults, copyWith, toMap, and config enums', () {
      const settings = GovtSettingsModel();

      expect(settings.notifications.newComplaintAlerts, isTrue);
      expect(settings.notifications.assignmentAlerts, isTrue);
      expect(settings.notifications.statusUpdateAlerts, isTrue);
      expect(settings.notifications.highPriorityAlerts, isTrue);
      expect(settings.notifications.systemNotifications, isTrue);
      expect(settings.language, GovtLanguage.english);
      expect(settings.themeMode, GovtPortalThemeMode.system);
      expect(settings.density, GovtLayoutDensity.comfortable);

      final map = settings.notifications.toMap();
      expect(map['newComplaintAlerts'], isTrue);

      final updated = settings.copyWith(
        notifications: settings.notifications.copyWith(newComplaintAlerts: false),
        language: GovtLanguage.hindi,
        themeMode: GovtPortalThemeMode.dark,
        density: GovtLayoutDensity.compact,
      );

      expect(updated.notifications.newComplaintAlerts, isFalse);
      expect(updated.notifications.assignmentAlerts, isTrue);
      expect(updated.language, GovtLanguage.hindi);
      expect(updated.themeMode, GovtPortalThemeMode.dark);
      expect(updated.density, GovtLayoutDensity.compact);
    });

    test('MockGovernmentUserRepository updates profile and enforces validation & immutability', () async {
      final repo = MockGovernmentUserRepository();
      final profile = await repo.getProfile();
      expect(profile, isNotNull);

      // Successfully update editable fields
      final updated = await repo.updateProfile(
        fullName: 'Vikramaditya S.',
        phone: '+91 99999 11111',
        designation: 'Principal Civic Administrator',
      );

      expect(updated.fullName, 'Vikramaditya S.');
      expect(updated.phone, '+91 99999 11111');
      expect(updated.designation, 'Principal Civic Administrator');
      expect(updated.email, 'government@civicfix.test'); // Unchanged
      expect(updated.role, 'government'); // Unchanged

      // Verify sync with auth service
      expect(MockGovtAuthService().currentUser?.fullName, 'Vikramaditya S.');

      // Validates non-empty inputs
      expect(
        () => repo.updateProfile(fullName: '  ', phone: '123', designation: 'Eng'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repo.updateProfile(fullName: 'Name', phone: '  ', designation: 'Eng'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repo.updateProfile(fullName: 'Name', phone: '123', designation: '  '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('MockGovernmentUserRepository updates notification preferences, language, and appearance', () async {
      final repo = MockGovernmentUserRepository();

      await repo.updateNotificationSettings(const GovtNotificationSettings(
        newComplaintAlerts: false,
        highPriorityAlerts: true,
      ));
      expect(repo.currentSettings.notifications.newComplaintAlerts, isFalse);

      await repo.updateLanguage(GovtLanguage.marathi);
      expect(repo.currentSettings.language, GovtLanguage.marathi);

      await repo.updateAppearance(
        themeMode: GovtPortalThemeMode.light,
        density: GovtLayoutDensity.compact,
      );
      expect(repo.currentSettings.themeMode, GovtPortalThemeMode.light);
      expect(repo.currentSettings.density, GovtLayoutDensity.compact);
    });

    testWidgets('GovtEditProfileDialog renders fields, validates inputs, and saves updates', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockGovernmentUserRepository();
      final user = await repo.getProfile();

      await tester.pumpWidget(_createTestableWidget(
        Scaffold(
          body: SingleChildScrollView(
            child: GovtEditProfileDialog(user: user!, userRepository: repo),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Officer Profile'), findsOneWidget);
      expect(find.text('Officer Full Name *'), findsOneWidget);
      expect(find.text('Official Contact Phone *'), findsOneWidget);
      expect(find.text('Operational Designation *'), findsOneWidget);

      // System locked indicators
      expect(find.text('System-Locked Administrative Identifiers'), findsOneWidget);
      expect(find.text('GOVERNMENT (Authorized Nodal Officer)'), findsOneWidget);
      expect(find.text('government@civicfix.test'), findsOneWidget);

      // Clear full name to trigger validation
      final nameFinder = find.byType(TextFormField).first;
      await tester.enterText(nameFinder, '');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_profile_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter officer full name'), findsOneWidget);

      // Enter valid updated name and save
      await tester.enterText(nameFinder, 'Nodal Officer Sharma');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_profile_button')));
      await tester.pumpAndSettle();

      expect(repo.currentProfile?.fullName, 'Nodal Officer Sharma');
    });

    testWidgets('GovtNotificationSettingsWidget renders 5 alert toggles and switches values', (tester) async {
      final repo = MockGovernmentUserRepository();

      await tester.pumpWidget(_createTestableWidget(
        Scaffold(
          body: SingleChildScrollView(
            child: GovtNotificationSettingsWidget(userRepository: repo),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('New Complaint Alerts'), findsOneWidget);
      expect(find.text('Assignment Alerts'), findsOneWidget);
      expect(find.text('Status Update Alerts'), findsOneWidget);
      expect(find.text('High-Priority & Emergency Alerts'), findsOneWidget);
      expect(find.text('System & Maintenance Notifications'), findsOneWidget);

      // Toggle New Complaint Alerts switch
      final switchFinder = find.byType(SwitchListTile).first;
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(repo.currentSettings.notifications.newComplaintAlerts, isFalse);
    });

    testWidgets('GovtLanguageSettingsWidget renders language choices and selects Hindi and Marathi', (tester) async {
      final repo = MockGovernmentUserRepository();

      await tester.pumpWidget(_createTestableWidget(
        Scaffold(
          body: SingleChildScrollView(
            child: GovtLanguageSettingsWidget(userRepository: repo),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Language & Regional Localization'), findsOneWidget);
      expect(find.text('English (Default)'), findsOneWidget);
      expect(find.text('हिन्दी (Hindi)'), findsOneWidget);
      expect(find.text('मराठी (Marathi)'), findsOneWidget);

      // Tap Hindi option
      await tester.tap(find.text('हिन्दी (Hindi)'));
      await tester.pumpAndSettle();

      expect(repo.currentSettings.language, GovtLanguage.hindi);
      expect(find.text('Portal language changed to Hindi (हिन्दी (Hindi)).'), findsOneWidget);
    });

    testWidgets('GovtAppearanceSettingsWidget allows selecting theme mode and density options', (tester) async {
      final repo = MockGovernmentUserRepository();

      await tester.pumpWidget(_createTestableWidget(
        Scaffold(
          body: SingleChildScrollView(
            child: GovtAppearanceSettingsWidget(userRepository: repo),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Display & Workspace Density'), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('Table & Card Density'), findsOneWidget);

      // Select Dark Mode
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();
      expect(repo.currentSettings.themeMode, GovtPortalThemeMode.dark);

      // Select Compact Density
      await tester.tap(find.text('Compact'));
      await tester.pumpAndSettle();
      expect(repo.currentSettings.density, GovtLayoutDensity.compact);
    });

    testWidgets('GovtPrivacyPrinciplesWidget renders all 4 governance standards', (tester) async {
      await tester.pumpWidget(_createTestableWidget(
        const Scaffold(
          body: SingleChildScrollView(
            child: GovtPrivacyPrinciplesWidget(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Municipal Data Governance Principles'), findsOneWidget);
      expect(find.text('Data Minimization'), findsOneWidget);
      expect(find.text('Citizen Privacy Restrictions'), findsOneWidget);
      expect(find.text('Authorized Role-Based Access'), findsOneWidget);
      expect(find.text('Evidence Protection & Audit Integrity'), findsOneWidget);
    });

    testWidgets('GovtAboutWidget renders portal branding, version v1.0.0-gov, and municipal mission', (tester) async {
      await tester.pumpWidget(_createTestableWidget(
        const Scaffold(
          body: SingleChildScrollView(
            child: GovtAboutWidget(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('About CivicFix Municipal Portal'), findsOneWidget);
      expect(find.text('CivicFix Operations Suite'), findsOneWidget);
      expect(find.text('v1.0.0-gov'), findsOneWidget);
      expect(find.text('Municipal Mission'), findsOneWidget);
      expect(find.text('Municipal IT Support & Helpdesk'), findsOneWidget);
    });

    testWidgets('GovtProfileScreen renders complete profile, department switcher, and triggers edit and sign out dialogs', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authService = MockGovtAuthService();
      final userRepo = MockGovernmentUserRepository();

      await tester.pumpWidget(_createTestableWidget(
        GovtProfileScreen(
          authService: authService,
          userRepository: userRepo,
        ),
      ));
      await tester.pumpAndSettle();

      // Profile Header Details
      expect(find.text('OFFICER ROLE'), findsOneWidget);
      expect(find.textContaining('Municipal Civic Administration'), findsWidgets);
      expect(find.text('government@civicfix.test'), findsOneWidget);
      expect(find.text('MC-2026-ENG-842'), findsOneWidget);
      expect(find.text('Ward 14 (Central Zone)'), findsWidgets);

      // Jurisdiction & Permissions
      expect(find.text('Active Municipal Jurisdiction & Department'), findsOneWidget);
      expect(find.text('Role-Based Access & Permissions'), findsOneWidget);

      // Settings sections present
      expect(find.byType(GovtNotificationSettingsWidget), findsOneWidget);
      expect(find.byType(GovtLanguageSettingsWidget), findsOneWidget);
      expect(find.byType(GovtAppearanceSettingsWidget), findsOneWidget);
      expect(find.byType(GovtPrivacyPrinciplesWidget), findsOneWidget);
      expect(find.byType(GovtAboutWidget), findsOneWidget);

      // Open Edit Profile Dialog
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(GovtEditProfileDialog), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(GovtEditProfileDialog), findsNothing);

      // Trigger Sign Out
      await tester.ensureVisible(find.text('Sign Out'));
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(find.text('Sign Out Officer Session'), findsOneWidget);
      expect(find.text('Are you sure you want to end your active administrative session?'), findsOneWidget);
    });
  });

  group('Prompt 18 (Prompt 9): Complete Government UI Integration Tests', () {
    setUp(() {
      MockDataSource().resetMockData();
      MockGovtAuthService().resetForTesting(authenticated: true);
    });

    test('Grievance Processing Workflow integrates Verification, Assignment, In-Progress, and Resolution', () async {
      final repo = MockGovtComplaintRepository();
      
      // 1. Fetch initial reported complaint
      final reported = await repo.getComplaintById('cmp_101');
      expect(reported, isNotNull);
      expect(reported!.status, ComplaintStatus.reported);

      // 2. Verify
      final verifySuccess = await repo.verifyComplaint(
        complaintId: reported.id,
        notes: 'Field verified by Executive Officer.',
        officerName: 'Executive Officer',
      );
      expect(verifySuccess, isTrue);

      final verified = await repo.getComplaintById('cmp_101');
      expect(verified!.status, ComplaintStatus.verified);
      expect(verified.timeline.first.title, 'Verified by Municipal Authority');

      // 3. Assign
      final assignSuccess = await repo.assignComplaint(
        complaintId: reported.id,
        departmentId: 'dept_electrical',
        officerName: 'Inspector Patil',
        assignmentNote: 'Assigned to Streetlight Maintenance Unit 3.',
      );
      expect(assignSuccess, isTrue);

      final assigned = await repo.getComplaintById('cmp_101');
      expect(assigned!.status, ComplaintStatus.assigned);
      expect(assigned.assignedTo, 'Inspector Patil');
      expect(assigned.timeline.first.title, 'Assigned to Inspector Patil');

      // 4. In Progress
      final inProgressSuccess = await repo.updateStatus(
        complaintId: reported.id,
        nextStatus: ComplaintStatus.inProgress,
        updateMessage: 'Crew has begun pole wiring and bulb replacement.',
        officerName: 'Inspector Patil',
      );
      expect(inProgressSuccess, isTrue);

      final inProgress = await repo.getComplaintById('cmp_101');
      expect(inProgress!.status, ComplaintStatus.inProgress);
      expect(inProgress.timeline.first.title, 'Work in Progress');

      // 5. Resolve
      final resolveSuccess = await repo.updateStatus(
        complaintId: reported.id,
        nextStatus: ComplaintStatus.resolved,
        updateMessage: 'Street light fixture replaced and tested operational.',
        officerName: 'Inspector Patil',
      );
      expect(resolveSuccess, isTrue);

      final resolved = await repo.getComplaintById('cmp_101');
      expect(resolved!.status, ComplaintStatus.resolved);
      expect(resolved.resolvedAt, isNotNull);
      expect(resolved.timeline.first.title, 'Issue Resolved & Inspected');
    });

    test('Single source of truth updates reflect synchronously across Dashboard, Hazard Map, and Analytics', () async {
      final complaintRepo = MockGovtComplaintRepository();
      final hazardRepo = MockHazardRepository();
      final analyticsRepo = MockAnalyticsRepository();

      // Check initial state of cmp_102 (Road damage - In Progress, linked to haz_101)
      final initialComplaint = await complaintRepo.getComplaintById('cmp_102');
      expect(initialComplaint!.status, ComplaintStatus.inProgress);

      final initialHazard = await hazardRepo.getHazardById('haz_101');
      expect(initialHazard!.status, ComplaintStatus.inProgress);

      final initialMetrics = await complaintRepo.getDashboardMetrics();
      expect(initialMetrics.inProgressCount, greaterThanOrEqualTo(1));

      // Resolve cmp_102
      await complaintRepo.updateStatus(
        complaintId: 'cmp_102',
        nextStatus: ComplaintStatus.resolved,
        updateMessage: 'Pothole filled with bitumen and compacted.',
        officerName: 'Road Works Supervisor',
      );

      // Verify Complaint Repository reflected
      final updatedComplaint = await complaintRepo.getComplaintById('cmp_102');
      expect(updatedComplaint!.status, ComplaintStatus.resolved);

      // Verify Hazard Repository synchronized
      final updatedHazard = await hazardRepo.getHazardById('haz_101');
      expect(updatedHazard!.status, ComplaintStatus.resolved);

      // Verify Dashboard Metrics updated
      final updatedMetrics = await complaintRepo.getDashboardMetrics();
      expect(updatedMetrics.resolvedCount, initialMetrics.resolvedCount + 1);

      // Verify Analytics aggregates updated
      final analytics = await analyticsRepo.getAnalytics();
      expect(analytics.summary.resolvedComplaints, updatedMetrics.resolvedCount);
    });

    testWidgets('Hazard GIS Map allows selecting marker, viewing info card, and navigating to complaint details', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hazardRepo = MockHazardRepository();

      await tester.pumpWidget(_createTestableWidget(
        GovtHazardMapScreen(hazardRepository: hazardRepo),
      ));
      await tester.pumpAndSettle();

      // Verify Map Screen header and canvas
      expect(find.textContaining('Active Hazards'), findsOneWidget);
      expect(find.byType(GovtMapCanvas), findsOneWidget);
      expect(find.byType(GovtHazardMarker), findsWidgets);

      // Tap on first hazard marker to open bottom/floating Info Card
      final firstMarker = find.byType(GovtHazardMarker).first;
      await tester.tap(firstMarker);
      await tester.pumpAndSettle();

      expect(find.byType(GovtHazardInfoCard), findsOneWidget);
      expect(find.text('View Grievance Details'), findsOneWidget);

      // Tap "View Grievance Details" button
      await tester.tap(find.text('View Grievance Details'));
      await tester.pumpAndSettle();

      // Navigated into GovtComplaintDetailsScreen
      expect(find.byType(GovtComplaintDetailsScreen), findsOneWidget);
      expect(find.text('Assign Crew'), findsOneWidget);
      expect(find.text('Update Status'), findsOneWidget);
    });

    testWidgets('Executive Dashboard quick actions navigate to Complaints, Map, and Analytics tabs', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestableWidget(
        const GovtShellScreen(initialIndex: 0),
      ));
      await tester.pumpAndSettle();

      // Initially on Dashboard
      expect(find.text('Municipal Operations Overview'), findsOneWidget);

      // Tap "Manage Grievances" quick action tile
      await tester.ensureVisible(find.text('Manage Grievances'));
      await tester.tap(find.text('Manage Grievances'));
      await tester.pumpAndSettle();

      // Switched to Complaints Tab
      expect(find.text('Grievance Management'), findsWidgets);
      expect(find.byType(GovtComplaintListScreen), findsOneWidget);

      // Tap "Hazard Map" on sidebar
      await tester.tap(find.text('Hazard Map'));
      await tester.pumpAndSettle();

      // Switched to Hazard Map Tab
      expect(find.text('Live Hazard GIS Map'), findsWidgets);
      expect(find.byType(GovtHazardMapScreen), findsOneWidget);

      // Tap "Analytics" on sidebar
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Switched to Analytics Tab
      expect(find.text('Operational Analytics'), findsWidgets);
      expect(find.byType(GovtAnalyticsScreen), findsOneWidget);

      // Tap "Profile" on sidebar
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Switched to Profile Tab
      expect(find.text('Officer Profile & Settings'), findsWidgets);
      expect(find.byType(GovtProfileScreen), findsOneWidget);
    });

    testWidgets('GovtShellScreen adapts cleanly to Desktop, Tablet, and Mobile viewports', (tester) async {
      // 1. Desktop Viewport (1200x800) -> Full Sidebar
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(_createTestableWidget(
        const GovtShellScreen(initialIndex: 0),
      ));
      await tester.pumpAndSettle();

      expect(find.text('GOVERNMENT PORTAL'), findsOneWidget);
      expect(find.byType(GovtSidebar), findsOneWidget);

      // 2. Tablet Viewport (800x800) -> Collapsed Rail
      tester.view.physicalSize = const Size(800, 800);
      await tester.pumpWidget(_createTestableWidget(
        const GovtShellScreen(initialIndex: 0),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(GovtSidebar), findsOneWidget);

      // 3. Mobile Viewport (400x800) -> Drawer via Hamburger Menu
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpWidget(_createTestableWidget(
        const GovtShellScreen(initialIndex: 0),
      ));
      await tester.pumpAndSettle();

      // Hamburger Menu button is present in AppBar on mobile
      final menuButtonFinder = find.byIcon(Icons.menu_rounded);
      expect(menuButtonFinder, findsOneWidget);

      await tester.tap(menuButtonFinder);
      await tester.pumpAndSettle();

      // Drawer opened containing GovtSidebar
      expect(find.byType(Drawer), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('Profile and settings flow supports department switching and signs out session safely', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authService = MockGovtAuthService();
      final userRepo = MockGovernmentUserRepository();

      await tester.pumpWidget(_createTestableWidget(
        GovtProfileScreen(
          authService: authService,
          userRepository: userRepo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('OFFICER ROLE'), findsOneWidget);
      expect(authService.isAuthenticated, isTrue);

      // Switch Department to Water Department
      final dropdown = find.byType(DropdownButtonFormField<String>);
      expect(dropdown, findsOneWidget);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Water Department').last);
      await tester.pumpAndSettle();

      expect(authService.currentUser?.departmentId, 'dept_water');

      // Trigger Sign Out
      await tester.ensureVisible(find.text('Sign Out'));
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(find.text('Sign Out Officer Session'), findsOneWidget);
      
      // Confirm Sign Out inside dialog
      final confirmButton = find.descendant(
        of: find.byType(GovtConfirmationDialog),
        matching: find.widgetWithText(ElevatedButton, 'Sign Out'),
      );
      await tester.tap(confirmButton);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(authService.isAuthenticated, isFalse);
    });

    testWidgets('Protected government routes strictly block unauthenticated sessions', (tester) async {
      // Sign out government session
      MockGovtAuthService().resetForTesting(authenticated: false);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRouter.generateRoute,
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.govtDashboard),
              child: const Text('Go to Govt Dashboard'),
            );
          },
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Go to Govt Dashboard'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Redirected to Login
      expect(find.byType(GovtLoginScreen), findsOneWidget);
      expect(find.text('MUNICIPAL OFFICER CONTROL DESK'), findsOneWidget);

      // Re-login for subsequent tests
      MockGovtAuthService().resetForTesting(authenticated: true);
    });
  });

  group('Prompt 19 (Prompt 10): Final Government UI Polish & Handoff Audit Tests', () {
    setUp(() {
      MockDataSource().resetMockData();
      MockGovtAuthService().resetForTesting(authenticated: true);
    });

    test('Government Theme Tokens match exact CivicFix brand palette specifications', () {
      expect(GovtThemeTokens.primary.toARGB32(), const Color(0xFF12304A).toARGB32());
      expect(GovtThemeTokens.secondary.toARGB32(), const Color(0xFF2E8B57).toARGB32());
      expect(GovtThemeTokens.accent.toARGB32(), const Color(0xFF7ED6A5).toARGB32());
      expect(GovtThemeTokens.background.toARGB32(), const Color(0xFFF7F9F7).toARGB32());
      expect(GovtThemeTokens.alert.toARGB32(), const Color(0xFFF4B942).toARGB32());
      expect(GovtThemeTokens.textPrimary.toARGB32(), const Color(0xFF17212B).toARGB32());
      expect(GovtThemeTokens.textSecondary.toARGB32(), const Color(0xFF5F6B73).toARGB32());
      expect(GovtThemeTokens.border.toARGB32(), const Color(0xFFD9E0DC).toARGB32());
      expect(GovtThemeTokens.error.toARGB32(), const Color(0xFFC62828).toARGB32());
      expect(GovtThemeTokens.info.toARGB32(), const Color(0xFF2F6F95).toARGB32());
    });

    test('Government Route Inventory generates valid MaterialPageRoutes for all 10 endpoints', () {
      final routes = [
        AppRoutes.govtLogin,
        AppRoutes.govtForgotPassword,
        AppRoutes.govtDashboard,
        AppRoutes.govtComplaints,
        AppRoutes.govtHazardMap,
        AppRoutes.govtAnalytics,
        AppRoutes.govtProfile,
        AppRoutes.govtComplaintDetails,
        AppRoutes.govtComplaintAssignment,
        AppRoutes.govtStatusUpdate,
      ];

      for (final routeName in routes) {
        final route = AppRouter.generateRoute(RouteSettings(name: routeName));
        expect(route, isA<MaterialPageRoute>());
      }
    });

    testWidgets('Citizen Navigation and Government Navigation maintain complete structural isolation', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Citizen Navigation has 5 tabs: Home, Complaints, Map, Notifications, Profile
      await tester.pumpWidget(_createTestableWidget(
        const MainNavigationScreen(initialIndex: 0),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Complaints'), findsWidgets);
      expect(find.text('Map'), findsWidgets);
      expect(find.text('Notifications'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);

      // 2. Government Shell has 5 tabs: Dashboard, Complaints, Hazard Map, Analytics, Profile
      await tester.pumpWidget(_createTestableWidget(
        const GovtShellScreen(initialIndex: 0),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(GovtSidebar), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Complaints'), findsWidgets);
      expect(find.text('Hazard Map'), findsWidgets);
      expect(find.text('Analytics'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);
    });

    test('Full 5-Stage Complaint Workflow maintains synchronous integrity across Repositories', () async {
      final complaintRepo = MockGovtComplaintRepository();
      final hazardRepo = MockHazardRepository();
      final analyticsRepo = MockAnalyticsRepository();

      // Start with reported complaint
      final complaint = await complaintRepo.getComplaintById('cmp_101');
      expect(complaint!.status, ComplaintStatus.reported);

      // 1. Verify
      await complaintRepo.verifyComplaint(
        complaintId: 'cmp_101',
        notes: 'Verified by Field Inspector.',
      );
      var current = await complaintRepo.getComplaintById('cmp_101');
      expect(current!.status, ComplaintStatus.verified);

      // 2. Assign
      await complaintRepo.assignComplaint(
        complaintId: 'cmp_101',
        departmentId: 'dept_electrical',
        officerName: 'Officer Patil',
        assignmentNote: 'Assigned crew.',
      );
      current = await complaintRepo.getComplaintById('cmp_101');
      expect(current!.status, ComplaintStatus.assigned);
      expect(current.assignedTo, 'Officer Patil');

      // 3. In Progress
      await complaintRepo.updateStatus(
        complaintId: 'cmp_101',
        nextStatus: ComplaintStatus.inProgress,
        updateMessage: 'Crew on site replacing fixture.',
      );
      current = await complaintRepo.getComplaintById('cmp_101');
      expect(current!.status, ComplaintStatus.inProgress);

      // 4. Resolved
      await complaintRepo.updateStatus(
        complaintId: 'cmp_101',
        nextStatus: ComplaintStatus.resolved,
        updateMessage: 'Fixture replaced and verified functional.',
      );
      current = await complaintRepo.getComplaintById('cmp_101');
      expect(current!.status, ComplaintStatus.resolved);
      expect(current.resolvedAt, isNotNull);

      // Check Analytics and Hazard sync
      final analytics = await analyticsRepo.getAnalytics();
      expect(analytics.summary.resolvedComplaints, greaterThanOrEqualTo(1));
      final allHazards = await hazardRepo.getHazards();
      expect(allHazards, isNotEmpty);
    });

    testWidgets('GovtComplaintListScreen and GovtHazardMapScreen handle empty search states gracefully', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Complaint list empty search state
      await tester.pumpWidget(_createTestableWidget(
        const GovtComplaintListScreen(),
      ));
      await tester.pumpAndSettle();

      final searchField = find.byType(GovtSearchField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'XYZ_NONEXISTENT_QUERY_12345');
      await tester.pumpAndSettle();

      expect(find.text('No complaints found'), findsOneWidget);

      // 2. Hazard Map empty search state
      await tester.pumpWidget(_createTestableWidget(
        const GovtHazardMapScreen(),
      ));
      await tester.pumpAndSettle();

      final mapSearch = find.byType(GovtSearchField);
      expect(mapSearch, findsOneWidget);
      await tester.enterText(mapSearch, 'NON_EXISTING_HAZARD_LOC_9999');
      await tester.pumpAndSettle();

      expect(find.text('No hazards match your filter criteria'), findsOneWidget);
    });
  });
}


