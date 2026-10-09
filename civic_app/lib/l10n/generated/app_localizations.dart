import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'CivicFix'**
  String get appTitle;

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'CivicFix'**
  String get appName;

  /// Common retry action label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Common cancel action label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Application tagline
  ///
  /// In en, this message translates to:
  /// **'Citizen Issue Reporting & Governance'**
  String get appTagline;

  /// Standard OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Standard Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Standard Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Standard Submit button text
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Standard Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Standard Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Standard Back button text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Standard Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Standard Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Standard Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Standard Search button text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Standard Filter button text
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Standard Refresh button text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Standard loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Standard error title text
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Standard success title text
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Standard warning title text
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// Standard Yes option text
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Standard No option text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Home bottom navigation bar label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Complaints navigation label
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get complaints;

  /// Report Issue navigation and button label
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// Profile navigation label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings navigation label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Notifications navigation label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Dashboard navigation label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Map view label
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// Hazard map tab label in citizen navigation
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// Language label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Select language prompt
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Hindi language name
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHindi;

  /// Marathi language name
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get languageMarathi;

  /// Canonical municipal complaint label
  ///
  /// In en, this message translates to:
  /// **'Complaint'**
  String get complaint;

  /// Canonical municipal Junior Engineer role
  ///
  /// In en, this message translates to:
  /// **'Junior Engineer'**
  String get juniorEngineer;

  /// Canonical municipal Field Officer role
  ///
  /// In en, this message translates to:
  /// **'Field Officer'**
  String get fieldOfficer;

  /// Canonical municipal ward label
  ///
  /// In en, this message translates to:
  /// **'Ward'**
  String get ward;

  /// Canonical municipal department label
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// Under verification complaint status
  ///
  /// In en, this message translates to:
  /// **'Under Verification'**
  String get statusUnderVerification;

  /// Reported complaint status
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get statusReported;

  /// Assigned complaint status
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// In Progress complaint status
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// Resolved complaint status
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// Closed complaint status
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// Reopened complaint status
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get statusReopened;

  /// Track complaint button label
  ///
  /// In en, this message translates to:
  /// **'Track Complaint'**
  String get trackComplaint;

  /// View all items link
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Submit report button label
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// Continue action button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// Button to return to home dashboard
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// Save changes button label
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Ask assistant action label
  ///
  /// In en, this message translates to:
  /// **'Ask Civic Assistant'**
  String get assistantHelp;

  /// App bar title for citizen complaints list
  ///
  /// In en, this message translates to:
  /// **'My Complaints'**
  String get myComplaintsTitle;

  /// Recent civic reports section title
  ///
  /// In en, this message translates to:
  /// **'Recent Civic Reports'**
  String get recentIssues;

  /// Nearby hazards section title
  ///
  /// In en, this message translates to:
  /// **'Nearby Hazards'**
  String get nearbyHazards;

  /// Section header for quick actions on dashboard
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Civic rewards section title
  ///
  /// In en, this message translates to:
  /// **'Civic Rewards'**
  String get rewardsTitle;

  /// Civic AI assistant section title
  ///
  /// In en, this message translates to:
  /// **'Civic AI Assistant'**
  String get assistantTitle;

  /// Settings and preferences section title
  ///
  /// In en, this message translates to:
  /// **'Settings & Preferences'**
  String get settingsTitle;

  /// No internet connection message
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// Generic error title
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Generic success message
  ///
  /// In en, this message translates to:
  /// **'Operation completed successfully'**
  String get operationSuccess;

  /// Welcome message with user name
  ///
  /// In en, this message translates to:
  /// **'Welcome, {userName}'**
  String welcomeUser(String userName);

  /// Pluralized count of complaints
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No complaints} =1{1 complaint} other{{count} complaints}}'**
  String complaintCount(num count);

  /// Title on citizen login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// Subtitle on citizen login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to report civic issues, track community fixes, and participate in your ward.'**
  String get signInSubtitle;

  /// Email input field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Email field hint text
  ///
  /// In en, this message translates to:
  /// **'e.g. name@example.com'**
  String get emailHint;

  /// Password input field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// Forgot password action button
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Divider text separating options
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// Google Sign-In button text
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Prompt on login screen for users without account
  ///
  /// In en, this message translates to:
  /// **'Don\'\'t have an account?'**
  String get dontHaveAccount;

  /// Action link to registration screen
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// Switch button to government officer portal
  ///
  /// In en, this message translates to:
  /// **'Government Officer Login'**
  String get govtOfficerLogin;

  /// Validation error for empty email
  ///
  /// In en, this message translates to:
  /// **'Please enter your email.'**
  String get pleaseEnterEmail;

  /// Validation error for invalid email format
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get pleaseEnterValidEmail;

  /// Validation error for empty password
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get pleaseEnterPassword;

  /// Error message for invalid credentials
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get incorrectEmailOrPassword;

  /// Error message when Google authentication fails
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed. Please try again.'**
  String get googleSignInFailed;

  /// Title of phone verification screen
  ///
  /// In en, this message translates to:
  /// **'Verify Your Phone'**
  String get verifyYourPhone;

  /// Subtitle of phone verification screen
  ///
  /// In en, this message translates to:
  /// **'To prevent duplicate civic complaints and protect community authenticity, verify your mobile number via SMS.'**
  String get verifyPhoneSubtitle;

  /// Label for mobile number field
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// Hint for mobile number field
  ///
  /// In en, this message translates to:
  /// **'e.g. 9876543210'**
  String get mobileNumberHint;

  /// Button to trigger SMS OTP
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendVerificationCode;

  /// Label for OTP input field
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// OTP field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP'**
  String get enterOtpHint;

  /// Button to verify phone code and proceed
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinue;

  /// Tooltip to change mobile number
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// Resend countdown cooldown label
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(int seconds);

  /// Resend OTP action button
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Code'**
  String get resendVerificationCode;

  /// Success banner after phone verification
  ///
  /// In en, this message translates to:
  /// **'Phone verified successfully! Redirecting...'**
  String get phoneVerifiedSuccess;

  /// Error message when OTP expires
  ///
  /// In en, this message translates to:
  /// **'The verification code has expired. Please tap Resend Code to request a new one.'**
  String get codeExpired;

  /// Error message for invalid OTP
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code.'**
  String get invalidVerificationCode;

  /// Success message when OTP is dispatched
  ///
  /// In en, this message translates to:
  /// **'Verification code sent via SMS.'**
  String get codeSentViaSms;

  /// Error message when sending OTP fails
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification code.'**
  String get failedToSendCode;

  /// Sign out action text
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Registration screen title
  ///
  /// In en, this message translates to:
  /// **'Create your CivicFix account'**
  String get createCivicFixAccount;

  /// Registration screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Your civic participation starts here.'**
  String get civicParticipationStarts;

  /// Full name input field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Full name hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// Optional phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number (Optional)'**
  String get phoneOptional;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Confirm password hint text
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// Preferred language dropdown label
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get preferredLanguage;

  /// Registration screen link to login prompt
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Validation error when passwords do not match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// Validation error for short password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordMinLength;

  /// Validation error for short name
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters.'**
  String get nameMinLength;

  /// Forgot password screen title
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetYourPassword;

  /// Forgot password screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter the email associated with your account to receive password reset instructions.'**
  String get resetPasswordSubtitle;

  /// Button to request password reset email
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// Tooltip to go back to login screen
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// Success banner when reset email is sent
  ///
  /// In en, this message translates to:
  /// **'Password reset instructions have been sent.'**
  String get resetLinkSent;

  /// Loading indicator text on home screen
  ///
  /// In en, this message translates to:
  /// **'Loading civic dashboard...'**
  String get loadingCivicDashboard;

  /// Link text to see all complaints
  ///
  /// In en, this message translates to:
  /// **'View all complaints →'**
  String get viewAllComplaints;

  /// Action button to view hazard map
  ///
  /// In en, this message translates to:
  /// **'View hazard map →'**
  String get viewHazardMap;

  /// Section header for civic progress
  ///
  /// In en, this message translates to:
  /// **'Your Civic Progress'**
  String get yourCivicProgress;

  /// Empty state title when citizen has no complaints
  ///
  /// In en, this message translates to:
  /// **'No complaints yet'**
  String get noComplaintsYet;

  /// Empty state subtitle prompting issue reporting
  ///
  /// In en, this message translates to:
  /// **'Report a civic issue to get started.'**
  String get reportIssueToGetStarted;

  /// Empty state card for nearby hazards
  ///
  /// In en, this message translates to:
  /// **'No immediate hazards reported in your immediate vicinity.'**
  String get noImmediateHazards;

  /// AI Assistant feature subtitle
  ///
  /// In en, this message translates to:
  /// **'Get help with CivicFix'**
  String get assistantSubtitle;

  /// Rewards quick action card subtitle
  ///
  /// In en, this message translates to:
  /// **'View your civic progress'**
  String get rewardsSubtitle;

  /// Accessibility label for report issue CTA
  ///
  /// In en, this message translates to:
  /// **'Report a civic issue'**
  String get reportCivicIssueAction;

  /// Section title for recent complaints
  ///
  /// In en, this message translates to:
  /// **'Recent Complaints'**
  String get recentCivicReports;

  /// Section header for nearby issues
  ///
  /// In en, this message translates to:
  /// **'Nearby Civic Issues'**
  String get nearbyCivicIssues;

  /// Heading for issue details section
  ///
  /// In en, this message translates to:
  /// **'Issue Information'**
  String get issueInformation;

  /// Step 1 subtitle in report issue
  ///
  /// In en, this message translates to:
  /// **'Help us understand the problem so it can reach the right team.'**
  String get issueInfoSubtitle;

  /// Title input field label in report issue
  ///
  /// In en, this message translates to:
  /// **'Issue Title'**
  String get issueTitle;

  /// Hint text for issue title field
  ///
  /// In en, this message translates to:
  /// **'e.g. Broken street light near the park'**
  String get issueTitleHint;

  /// Validation error when category not selected
  ///
  /// In en, this message translates to:
  /// **'Please select an issue category.'**
  String get selectCategoryError;

  /// Label for description field in report issue
  ///
  /// In en, this message translates to:
  /// **'Describe the issue'**
  String get describeTheIssue;

  /// Hint text for description textarea
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened and where you noticed the problem.'**
  String get describeIssueHint;

  /// Help text below description field
  ///
  /// In en, this message translates to:
  /// **'Include useful details such as what is damaged, how long it has been happening, or how it affects the area.'**
  String get describeIssueHelp;

  /// Hazard toggle switch label
  ///
  /// In en, this message translates to:
  /// **'Immediate Safety Hazard'**
  String get immediateSafetyHazard;

  /// Hazard toggle switch explanation
  ///
  /// In en, this message translates to:
  /// **'Check if this issue poses an immediate risk to citizens or traffic'**
  String get safetyHazardSubtitle;

  /// Step 2 title in report issue
  ///
  /// In en, this message translates to:
  /// **'Add Evidence'**
  String get addEvidence;

  /// Step 2 subtitle in report issue
  ///
  /// In en, this message translates to:
  /// **'A photo can help the responsible team understand the issue.'**
  String get addEvidenceSubtitle;

  /// Title for location selection step
  ///
  /// In en, this message translates to:
  /// **'Where is the issue?'**
  String get whereIsTheIssue;

  /// Step 3 subtitle in report issue
  ///
  /// In en, this message translates to:
  /// **'Add the location so the responsible team can find it.'**
  String get whereIsIssueSubtitle;

  /// Error message when location is missing
  ///
  /// In en, this message translates to:
  /// **'Please select or detect the issue location.'**
  String get selectLocationError;

  /// Title on report review screen
  ///
  /// In en, this message translates to:
  /// **'Review your issue'**
  String get reviewYourIssue;

  /// Step 4 subtitle in report issue
  ///
  /// In en, this message translates to:
  /// **'Please verify all information before submitting to your ward.'**
  String get reviewIssueSubtitle;

  /// Button to advance to step 2
  ///
  /// In en, this message translates to:
  /// **'Next: Add Evidence'**
  String get nextAddEvidence;

  /// Button to advance to step 3
  ///
  /// In en, this message translates to:
  /// **'Next: Location'**
  String get nextLocation;

  /// Action button when skipping optional photo evidence
  ///
  /// In en, this message translates to:
  /// **'Skip & Continue'**
  String get skipAndContinue;

  /// Button to advance to review step
  ///
  /// In en, this message translates to:
  /// **'Next: Review'**
  String get nextReview;

  /// Confirmation title when exiting active draft
  ///
  /// In en, this message translates to:
  /// **'Discard this report?'**
  String get discardReportTitle;

  /// Confirmation body when exiting active draft
  ///
  /// In en, this message translates to:
  /// **'Your entered information will be lost.'**
  String get discardReportMessage;

  /// Button to cancel draft discard
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get keepEditing;

  /// Button to confirm draft discard
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Step 1 label in issue report flow
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get stepInformation;

  /// Step 2 label in issue report flow
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get stepEvidence;

  /// Step 3 label in issue report flow
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get stepLocation;

  /// Step 4 label in issue report flow
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get stepReview;

  /// Title when complaint saved offline
  ///
  /// In en, this message translates to:
  /// **'Complaint Saved Offline'**
  String get complaintSavedOffline;

  /// Title on submission screen when online
  ///
  /// In en, this message translates to:
  /// **'Issue Reported'**
  String get issueReportedSuccess;

  /// Note on offline submission screen
  ///
  /// In en, this message translates to:
  /// **'Complaint saved. It will be submitted when you\'\'re back online.'**
  String get offlineSubmissionNote;

  /// Note on online submission screen
  ///
  /// In en, this message translates to:
  /// **'Your issue has been submitted successfully.'**
  String get onlineSubmissionNote;

  /// Label for offline ticket reference
  ///
  /// In en, this message translates to:
  /// **'Local Reference'**
  String get localReference;

  /// Label for complaint ID
  ///
  /// In en, this message translates to:
  /// **'Complaint ID'**
  String get complaintId;

  /// Label for status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Badge label for offline pending synchronization
  ///
  /// In en, this message translates to:
  /// **'Pending Sync'**
  String get pendingSync;

  /// Offline syncing in progress badge
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// Sync failed status
  ///
  /// In en, this message translates to:
  /// **'Sync Failed'**
  String get syncFailed;

  /// Label for reward points earned
  ///
  /// In en, this message translates to:
  /// **'Civic Reward'**
  String get civicReward;

  /// Points earned display
  ///
  /// In en, this message translates to:
  /// **'+{count} Points'**
  String pointsReward(int count);

  /// Button to navigate to complaint details
  ///
  /// In en, this message translates to:
  /// **'View Complaint'**
  String get viewComplaint;

  /// Help text on complaint submitted screen
  ///
  /// In en, this message translates to:
  /// **'You can track the progress of this issue from My Complaints.'**
  String get trackFromMyComplaints;

  /// Help text for offline complaint submission
  ///
  /// In en, this message translates to:
  /// **'Your complaint is securely stored on this device and will sync once internet is connected.'**
  String get offlineStoredSecurely;

  /// Title of select location map screen
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// Confirmation button for picked location
  ///
  /// In en, this message translates to:
  /// **'Confirm This Location'**
  String get confirmThisLocation;

  /// Title for selected location card
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get selectedLocation;

  /// Instruction on interactive map picker
  ///
  /// In en, this message translates to:
  /// **'Tap map to position pin'**
  String get tapMapToPositionPin;

  /// Search bar hint on location map screen
  ///
  /// In en, this message translates to:
  /// **'Search street, area or landmark...'**
  String get searchLocationHint;

  /// Error when GPS position cannot be acquired
  ///
  /// In en, this message translates to:
  /// **'Could not acquire GPS position. Please adjust pin manually.'**
  String get couldNotAcquireGps;

  /// Subtitle on my complaints screen
  ///
  /// In en, this message translates to:
  /// **'Track the civic issues you\'\'ve reported.'**
  String get trackCivicIssuesSubtitle;

  /// Search field hint text on my complaints screen
  ///
  /// In en, this message translates to:
  /// **'Search complaints...'**
  String get searchComplaintsHint;

  /// All option chip
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// All statuses chip label
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// All categories chip label
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// Summary count of complaints found
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 complaints found} =1{1 complaint found} other{{count} complaints found}}'**
  String complaintsFound(num count);

  /// Clear all search/filters text
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// Button to reset search and filter criteria
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// Empty state title when search or filter returns no results
  ///
  /// In en, this message translates to:
  /// **'No complaints found'**
  String get noComplaintsFound;

  /// Empty state description when search yields no complaints
  ///
  /// In en, this message translates to:
  /// **'Try a different search or filter.'**
  String get tryDifferentSearch;

  /// Filter bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort'**
  String get filterAndSort;

  /// Complaint status filter section title
  ///
  /// In en, this message translates to:
  /// **'Complaint Status'**
  String get complaintStatus;

  /// Issue category filter section title
  ///
  /// In en, this message translates to:
  /// **'Issue Category'**
  String get issueCategory;

  /// Sort section title in filter sheet
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// Apply filters button in bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// Sort option: recently updated
  ///
  /// In en, this message translates to:
  /// **'Recently Updated'**
  String get recentlyUpdated;

  /// Sort option: newest first
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get newestFirst;

  /// Sort option: oldest first
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get oldestFirst;

  /// Upvote button label when count is 0
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Upvote count label
  ///
  /// In en, this message translates to:
  /// **'{count} supports'**
  String supportsCount(int count);

  /// Snackbar when user supports a complaint
  ///
  /// In en, this message translates to:
  /// **'Supported complaint!'**
  String get supportedComplaint;

  /// Snackbar when user already supported complaint
  ///
  /// In en, this message translates to:
  /// **'You already supported this complaint.'**
  String get alreadySupported;

  /// Safety hazard pill label on complaint card
  ///
  /// In en, this message translates to:
  /// **'Safety Hazard'**
  String get safetyHazard;

  /// Updated relative time label
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String updatedTime(String time);

  /// Reported relative time label
  ///
  /// In en, this message translates to:
  /// **'Reported {time}'**
  String reportedTime(String time);

  /// Snackbar when ticket number is copied
  ///
  /// In en, this message translates to:
  /// **'Complaint ID {ticket} copied.'**
  String copiedTicketId(String ticket);

  /// App bar title on complaint details screen
  ///
  /// In en, this message translates to:
  /// **'Complaint Details'**
  String get complaintDetails;

  /// Card title for assigned officers
  ///
  /// In en, this message translates to:
  /// **'Assigned Municipal Team'**
  String get assignedMunicipalTeam;

  /// Subtitle for assigned officers card
  ///
  /// In en, this message translates to:
  /// **'Responsible officers managing and executing your grievance'**
  String get responsibleOfficersSubtitle;

  /// Role title for junior engineer supervisor
  ///
  /// In en, this message translates to:
  /// **'Supervising Junior Engineer'**
  String get supervisingJuniorEngineer;

  /// Badge label for active supervising engineer
  ///
  /// In en, this message translates to:
  /// **'Supervising'**
  String get supervising;

  /// Temporary state while auto-routing JE
  ///
  /// In en, this message translates to:
  /// **'Auto-Routing to Ward Engineer...'**
  String get autoRoutingToWard;

  /// Role title for field officer
  ///
  /// In en, this message translates to:
  /// **'Field Execution Officer'**
  String get fieldExecutionOfficer;

  /// Badge when field officer not yet assigned
  ///
  /// In en, this message translates to:
  /// **'Pending Field Allocation'**
  String get pendingFieldAllocation;

  /// Badge status when ground work is paused
  ///
  /// In en, this message translates to:
  /// **'Temporarily On Hold'**
  String get temporarilyOnHold;

  /// Badge status when repair is finished
  ///
  /// In en, this message translates to:
  /// **'Work Completed'**
  String get workCompleted;

  /// Badge when field officer is actively working
  ///
  /// In en, this message translates to:
  /// **'Work In Progress'**
  String get workInProgress;

  /// Badge when field officer is allocated
  ///
  /// In en, this message translates to:
  /// **'Assigned for Field Work'**
  String get assignedForFieldWork;

  /// Note when field officer is pending
  ///
  /// In en, this message translates to:
  /// **'Awaiting field officer assignment by the Supervising Junior Engineer.'**
  String get awaitingFieldOfficerAssignment;

  /// Note displaying obstacle reason
  ///
  /// In en, this message translates to:
  /// **'Ground obstacle: {reason}'**
  String groundObstacle(String reason);

  /// Fallback obstacle message
  ///
  /// In en, this message translates to:
  /// **'Ground work is temporarily paused due to site constraints.'**
  String get groundWorkPaused;

  /// Completion message in officer card
  ///
  /// In en, this message translates to:
  /// **'Ground repair executed and verified successfully.'**
  String get groundRepairExecuted;

  /// Header on supervisory rework card
  ///
  /// In en, this message translates to:
  /// **'Reopened for Quality Rework'**
  String get reopenedForQualityRework;

  /// Rework banner subtitle
  ///
  /// In en, this message translates to:
  /// **'Supervisory Quality Review Action'**
  String get supervisoryReviewAction;

  /// Badge label on rework status card
  ///
  /// In en, this message translates to:
  /// **'Rework Required'**
  String get reworkRequired;

  /// Cycle count tag on rework banner
  ///
  /// In en, this message translates to:
  /// **'Rework Cycle #{count}'**
  String reworkCycle(int count);

  /// Title of reason section in rework card
  ///
  /// In en, this message translates to:
  /// **'Reason for Reopening'**
  String get reasonForReopening;

  /// Note on SLA preservation during rework
  ///
  /// In en, this message translates to:
  /// **'Original SLA preserved from submission. Priority ground execution underway.'**
  String get slaPreservedNote;

  /// Card title for before/after comparison
  ///
  /// In en, this message translates to:
  /// **'Resolution & Work Verification'**
  String get resolutionAndVerification;

  /// Subtitle for before/after comparison
  ///
  /// In en, this message translates to:
  /// **'Ground inspection & completion evidence'**
  String get groundInspectionEvidence;

  /// Tile label for before photo
  ///
  /// In en, this message translates to:
  /// **'Reported Issue (Before)'**
  String get reportedIssueBefore;

  /// Tile label for after photo
  ///
  /// In en, this message translates to:
  /// **'Resolved Condition (After)'**
  String get resolvedConditionAfter;

  /// Label for officer remarks
  ///
  /// In en, this message translates to:
  /// **'Officer Resolution Remarks'**
  String get officerResolutionRemarks;

  /// Resolution card footer with officer name
  ///
  /// In en, this message translates to:
  /// **'Executed by {officer}'**
  String executedByOfficer(String officer);

  /// Resolved date text
  ///
  /// In en, this message translates to:
  /// **'Resolved on {date}'**
  String resolvedOnDate(String date);

  /// Resolved banner header
  ///
  /// In en, this message translates to:
  /// **'✓ Issue Resolved'**
  String get issueResolvedBanner;

  /// Resolved banner subtitle
  ///
  /// In en, this message translates to:
  /// **'This complaint has been marked as resolved.'**
  String get issueResolvedSubtitle;

  /// Current phase label
  ///
  /// In en, this message translates to:
  /// **'Current Phase'**
  String get currentPhase;

  /// Progress label
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// Timeline section header
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// Empty timeline message
  ///
  /// In en, this message translates to:
  /// **'No updates yet.'**
  String get noUpdatesYet;

  /// Reported date text in details footer
  ///
  /// In en, this message translates to:
  /// **'Reported on {date}'**
  String reportedOn(String date);

  /// Button to view location on map
  ///
  /// In en, this message translates to:
  /// **'View Location'**
  String get viewLocation;

  /// Header for photo evidence in review and details
  ///
  /// In en, this message translates to:
  /// **'Photo Evidence ({count})'**
  String evidencePhotos(int count);

  /// Label when no photos are attached to report
  ///
  /// In en, this message translates to:
  /// **'No photos attached (Optional)'**
  String get noPhotosAttached;

  /// Photo preview dialog header
  ///
  /// In en, this message translates to:
  /// **'Photo Preview ({current} of {total})'**
  String photoPreview(int current, int total);

  /// Tooltip to close preview dialog
  ///
  /// In en, this message translates to:
  /// **'Close Preview'**
  String get closePreview;

  /// Department routing note in review card
  ///
  /// In en, this message translates to:
  /// **'This issue will be routed to {department}.'**
  String routedToDepartment(String department);

  /// Action button on notifications screen
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// Snackbar when all notifications marked read
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read.'**
  String get allNotificationsMarkedRead;

  /// Filter chip: unread
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// Filter chip: read
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// Empty state title for unread filter
  ///
  /// In en, this message translates to:
  /// **'No unread notifications'**
  String get noUnreadNotifications;

  /// Empty state description when no unread notifications
  ///
  /// In en, this message translates to:
  /// **'You have read all updates on your complaints and ward notices.'**
  String get noUnreadNotificationsDesc;

  /// Empty state title when no notifications exist
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get noNotificationsYet;

  /// Empty state description when zero notifications
  ///
  /// In en, this message translates to:
  /// **'When there is an update to one of your complaints, it will appear here.'**
  String get noNotificationsYetDesc;

  /// Screen title for citizen profile
  ///
  /// In en, this message translates to:
  /// **'Citizen Profile'**
  String get citizenProfile;

  /// Edit profile screen title and action
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Contribution stats card title
  ///
  /// In en, this message translates to:
  /// **'Civic Contribution'**
  String get civicContribution;

  /// Action button in contribution stats
  ///
  /// In en, this message translates to:
  /// **'View Achievements'**
  String get viewAchievements;

  /// Reports metric title in contribution card
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// Resolved metric title in contribution card
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// Civic points metric title in contribution card
  ///
  /// In en, this message translates to:
  /// **'Civic Points'**
  String get civicPoints;

  /// Profile section title for civic engagement
  ///
  /// In en, this message translates to:
  /// **'Civic Engagement'**
  String get civicEngagement;

  /// Profile menu item for rewards
  ///
  /// In en, this message translates to:
  /// **'Civic Rewards & Achievements'**
  String get civicRewardsAndAchievements;

  /// Profile menu item for assistant
  ///
  /// In en, this message translates to:
  /// **'Civic Assistant'**
  String get civicAssistant;

  /// Assistant menu tile subtitle
  ///
  /// In en, this message translates to:
  /// **'FAQ, complaint rules & category help'**
  String get assistantSubtitleLong;

  /// Profile section title for settings
  ///
  /// In en, this message translates to:
  /// **'Settings & Privacy'**
  String get settingsAndPrivacy;

  /// Menu title for notification settings
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// Notification preferences subtitle
  ///
  /// In en, this message translates to:
  /// **'Status alerts, hazard warnings & sound'**
  String get notificationPreferencesSubtitle;

  /// Menu title for privacy settings
  ///
  /// In en, this message translates to:
  /// **'Privacy & Safety'**
  String get privacyAndSafety;

  /// Privacy preferences subtitle
  ///
  /// In en, this message translates to:
  /// **'Confidentiality and public map policy'**
  String get privacyAndSafetySubtitle;

  /// Menu title for about screen
  ///
  /// In en, this message translates to:
  /// **'About CivicFix'**
  String get aboutCivicFix;

  /// About screen menu subtitle
  ///
  /// In en, this message translates to:
  /// **'Mission, governance model, and technology'**
  String get aboutCivicFixSubtitle;

  /// Log out button text
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// Logout dialog title
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// Logout dialog content
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmMessage;

  /// Snackbar when profile is updated
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully.'**
  String get profileUpdatedSuccess;

  /// Snackbar when profile update fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'\'t update profile. Please try again.'**
  String get profileUpdateFailed;

  /// View details button
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// Tooltip to close floating map card
  ///
  /// In en, this message translates to:
  /// **'Close complaint card'**
  String get closeComplaintCard;

  /// Search hint on hazard map screen
  ///
  /// In en, this message translates to:
  /// **'Search hazards or complaints...'**
  String get searchHazardsHint;

  /// Unauthorized complaint title
  ///
  /// In en, this message translates to:
  /// **'Unable to open this complaint.'**
  String get unableToOpenComplaint;

  /// Unauthorized complaint description
  ///
  /// In en, this message translates to:
  /// **'This report belongs to a different citizen account.'**
  String get complaintBelongsToOther;

  /// Button to navigate back to my complaints
  ///
  /// In en, this message translates to:
  /// **'Back to My Complaints'**
  String get backToMyComplaints;

  /// Not found complaint title
  ///
  /// In en, this message translates to:
  /// **'Complaint not found.'**
  String get complaintNotFound;

  /// Not found complaint description
  ///
  /// In en, this message translates to:
  /// **'This complaint may no longer be available.'**
  String get complaintNotFoundDesc;

  /// Error title when complaint load fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'\'t load this complaint.'**
  String get couldNotLoadComplaint;

  /// Error title when notifications load fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'\'t load notifications.'**
  String get couldNotLoadNotifications;

  /// Error message prompting retry
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get checkConnectionAndRetry;

  /// Validation error for empty name
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get pleaseEnterName;

  /// Validation error for invalid phone
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number (at least 10 digits).'**
  String get pleaseEnterValidPhone;

  /// Hint text for minimum password length
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get passwordMinCharsHint;

  /// Validation error for empty confirm password
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password.'**
  String get pleaseConfirmPassword;

  /// Success banner when account registration completes
  ///
  /// In en, this message translates to:
  /// **'Account created successfully.'**
  String get accountCreatedSuccess;

  /// Error message when registration fails
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registrationFailed;

  /// Button text to submit registration
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountBtn;

  /// Action button to change phone number
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeAction;

  /// Hint text for OTP field
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP'**
  String get verificationCodeHint;

  /// Validation error for empty OTP
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code.'**
  String get pleaseEnterVerificationCode;

  /// Validation error for short OTP
  ///
  /// In en, this message translates to:
  /// **'Verification code must be at least 4 digits.'**
  String get verificationCodeMinLength;

  /// Error message when resending OTP fails
  ///
  /// In en, this message translates to:
  /// **'Unable to resend verification code.'**
  String get unableToResendCode;

  /// Hint text on forgot password screen
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email'**
  String get enterRegisteredEmail;

  /// Success message when reset link dispatched
  ///
  /// In en, this message translates to:
  /// **'Password reset instructions have been sent.'**
  String get passwordResetSent;

  /// Error message when reset request fails
  ///
  /// In en, this message translates to:
  /// **'Unable to process reset request.'**
  String get unableToProcessReset;

  /// Home tab label in citizen navigation
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Complaints tab label in citizen navigation
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get navComplaints;

  /// Notifications tab label in citizen navigation
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// Profile tab label in citizen navigation
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Loading indicator text on home screen
  ///
  /// In en, this message translates to:
  /// **'Loading civic dashboard...'**
  String get loadingDashboard;

  /// Error description when dashboard data load fails
  ///
  /// In en, this message translates to:
  /// **'Unable to load civic updates. Please try again.'**
  String get unableToLoadUpdates;

  /// AI Assistant feature title
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistant;

  /// Empty state prompt to report first issue
  ///
  /// In en, this message translates to:
  /// **'Report a civic issue to get started.'**
  String get reportToGetStarted;

  /// Empty state card for nearby hazards
  ///
  /// In en, this message translates to:
  /// **'No immediate hazards reported in your immediate vicinity.'**
  String get noNearbyHazards;

  /// Step 1 title in report issue flow
  ///
  /// In en, this message translates to:
  /// **'Issue Information'**
  String get issueInformationTitle;

  /// Step 1 subtitle in report issue flow
  ///
  /// In en, this message translates to:
  /// **'Help us understand the problem so it can reach the right team.'**
  String get issueInformationSubtitle;

  /// Label for issue title field
  ///
  /// In en, this message translates to:
  /// **'Issue Title'**
  String get issueTitleLabel;

  /// Validation error for empty title
  ///
  /// In en, this message translates to:
  /// **'Please enter a title for the issue.'**
  String get pleaseEnterIssueTitle;

  /// Validation error for short issue title
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 5 characters.'**
  String get issueTitleMinLength;

  /// Validation error for unselected category
  ///
  /// In en, this message translates to:
  /// **'Please select an issue category.'**
  String get pleaseSelectCategory;

  /// Validation error for empty description
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue.'**
  String get pleaseDescribeIssue;

  /// Validation error for short description
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 10 characters.'**
  String get describeIssueMinLength;

  /// Helper guidance under description field
  ///
  /// In en, this message translates to:
  /// **'Include useful details such as what is damaged, how long it has been happening, or how it affects the area.'**
  String get describeIssueHelper;

  /// Subtitle for location selection step
  ///
  /// In en, this message translates to:
  /// **'Add the location so the responsible team can find it.'**
  String get addLocationSubtitle;

  /// Primary button to submit civic complaint
  ///
  /// In en, this message translates to:
  /// **'Submit Issue'**
  String get submitIssue;

  /// Badge indicating junior engineer supervision
  ///
  /// In en, this message translates to:
  /// **'Supervising'**
  String get supervisingStatus;

  /// Badge indicating auto routing to ward engineer
  ///
  /// In en, this message translates to:
  /// **'Routing...'**
  String get routingStatus;

  /// Status explanation when field officer not yet assigned
  ///
  /// In en, this message translates to:
  /// **'Awaiting field officer assignment by the Supervising Junior Engineer.'**
  String get awaitingFieldAllocationNote;

  /// Explanation when repair is verified
  ///
  /// In en, this message translates to:
  /// **'Ground repair executed and verified successfully.'**
  String get groundRepairVerified;

  /// Explanation when field work is running
  ///
  /// In en, this message translates to:
  /// **'Execution currently underway on site.'**
  String get executionUnderway;

  /// Explanation when field officer has been assigned
  ///
  /// In en, this message translates to:
  /// **'Field officer allocated. Ground operations scheduled.'**
  String get fieldOfficerAllocatedNote;

  /// Note clarifying SLA preservation upon rework
  ///
  /// In en, this message translates to:
  /// **'Original SLA preserved from submission. Priority ground execution underway.'**
  String get originalSlaPreserved;

  /// Header on resolution evidence card
  ///
  /// In en, this message translates to:
  /// **'Resolution & Work Verification'**
  String get resolutionAndWorkVerification;

  /// Title when complaint submitted online
  ///
  /// In en, this message translates to:
  /// **'Issue Reported'**
  String get issueReportedTitle;

  /// Subtitle on complaint submission screen
  ///
  /// In en, this message translates to:
  /// **'Your issue has been submitted successfully.'**
  String get issueSubmittedSuccess;

  /// Points awarded badge
  ///
  /// In en, this message translates to:
  /// **'+20 Points'**
  String get plusTwentyPoints;

  /// Note for offline submission
  ///
  /// In en, this message translates to:
  /// **'Your complaint is securely stored on this device and will sync once internet is connected.'**
  String get storedLocallyNote;

  /// Note for tracking complaint progress
  ///
  /// In en, this message translates to:
  /// **'You can track the progress of this issue from My Complaints.'**
  String get trackFromMyComplaintsNote;

  /// Empty state description for filtered complaints
  ///
  /// In en, this message translates to:
  /// **'Try a different search or filter.'**
  String get noComplaintsFoundDesc;

  /// Empty state title when citizen has no complaints on record
  ///
  /// In en, this message translates to:
  /// **'No complaints reported yet'**
  String get noComplaintsReportedYet;

  /// Snackbar confirmation when citizen upvotes a complaint
  ///
  /// In en, this message translates to:
  /// **'Supported complaint!'**
  String get supportedComplaintSuccess;

  /// Snackbar notification if complaint already upvoted
  ///
  /// In en, this message translates to:
  /// **'You already supported this complaint.'**
  String get alreadySupportedComplaint;

  /// Status badge for verified complaint
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get statusVerified;

  /// Status badge for rejected complaint
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// Loading state for complaints list
  ///
  /// In en, this message translates to:
  /// **'Loading your complaints...'**
  String get loadingComplaints;

  /// Error message when complaints fail to load
  ///
  /// In en, this message translates to:
  /// **'Couldn\'\'t load your complaints.'**
  String get failedToLoadComplaints;

  /// Empty state description for complaints list
  ///
  /// In en, this message translates to:
  /// **'Report a civic issue and track its progress here.'**
  String get reportCivicIssueTrackProgress;

  /// Action button to report an issue
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get reportAnIssue;

  /// Header subtitle for complaints list
  ///
  /// In en, this message translates to:
  /// **'Track the civic issues you\'\'ve reported.'**
  String get trackCivicIssuesReported;

  /// Tooltip for clear search button
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// Snackbar message when complaint ticket number is copied
  ///
  /// In en, this message translates to:
  /// **'Complaint ID {ticketNumber} copied.'**
  String complaintIdCopied(String ticketNumber);

  /// Placeholder when location is selected
  ///
  /// In en, this message translates to:
  /// **'Location selected'**
  String get locationSelected;

  /// Count label for supports
  ///
  /// In en, this message translates to:
  /// **'supports'**
  String get supports;

  /// Tooltip to close filters
  ///
  /// In en, this message translates to:
  /// **'Close Filters'**
  String get closeFilters;

  /// Error state when no complaint was passed
  ///
  /// In en, this message translates to:
  /// **'No complaint specified.'**
  String get noComplaintSpecified;

  /// Banner title for pending sync
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection'**
  String get waitingForConnection;

  /// Banner description for pending sync
  ///
  /// In en, this message translates to:
  /// **'Your complaint is stored securely on this device and will be submitted once internet is available.'**
  String get complaintStoredSecurelyOffline;

  /// Banner title for syncing state
  ///
  /// In en, this message translates to:
  /// **'Synchronizing with Cloud'**
  String get synchronizingWithCloud;

  /// Banner description for syncing state
  ///
  /// In en, this message translates to:
  /// **'Uploading complaint data and evidence to the municipal network...'**
  String get uploadingComplaintData;

  /// Banner title for failed sync
  ///
  /// In en, this message translates to:
  /// **'Synchronization Failed'**
  String get synchronizationFailed;

  /// Banner description for failed sync
  ///
  /// In en, this message translates to:
  /// **'Failed to synchronize this report with the cloud backend. Check connection and retry.'**
  String get failedToSyncWithCloud;

  /// Button to retry syncing complaint
  ///
  /// In en, this message translates to:
  /// **'Retry Sync'**
  String get retrySync;

  /// Banner description for resolved complaint
  ///
  /// In en, this message translates to:
  /// **'This complaint has been marked as resolved.'**
  String get complaintMarkedResolved;

  /// Reported timestamp line
  ///
  /// In en, this message translates to:
  /// **'Reported on {date}'**
  String reportedOnDate(String date);

  /// Last updated timestamp line
  ///
  /// In en, this message translates to:
  /// **'Last updated {time}'**
  String lastUpdatedTime(String time);

  /// Ward municipal designation
  ///
  /// In en, this message translates to:
  /// **'Ward'**
  String get wardLabel;

  /// Default central ward label
  ///
  /// In en, this message translates to:
  /// **'Central'**
  String get central;

  /// Note for paused ground execution
  ///
  /// In en, this message translates to:
  /// **'Ground work is temporarily paused due to site constraints.'**
  String get groundWorkTemporarilyPaused;

  /// Commenced relative time statement
  ///
  /// In en, this message translates to:
  /// **'Commenced {time}.'**
  String commencedTime(String time);

  /// Execution underway notice
  ///
  /// In en, this message translates to:
  /// **'Execution currently underway on site.'**
  String get executionUnderwayOnSite;

  /// Placeholder officer name for pending allocation
  ///
  /// In en, this message translates to:
  /// **'Pending Allocation'**
  String get pendingAllocation;

  /// Default reason for reopening complaint for rework
  ///
  /// In en, this message translates to:
  /// **'Work quality did not meet municipal standards upon audit review. Reassigned for corrective action.'**
  String get defaultReopenReason;

  /// Default department reviewer identity
  ///
  /// In en, this message translates to:
  /// **'Department Lead Quality Audit'**
  String get deptLeadQualityAudit;

  /// Reviewed by label
  ///
  /// In en, this message translates to:
  /// **'Reviewed by'**
  String get reviewedBy;

  /// SLA guarantee note for rework
  ///
  /// In en, this message translates to:
  /// **'Original SLA preserved from submission. Priority ground execution underway.'**
  String get slaPreservedPriorityExecution;

  /// Collapse previous resolution history
  ///
  /// In en, this message translates to:
  /// **'Hide Previous Resolution Record'**
  String get hidePreviousResolutionRecord;

  /// Expand previous resolution history
  ///
  /// In en, this message translates to:
  /// **'View Previous Resolution Record'**
  String get viewPreviousResolutionRecord;

  /// Count noun for photos
  ///
  /// In en, this message translates to:
  /// **'photos'**
  String get photos;

  /// Prior resolution timestamp label
  ///
  /// In en, this message translates to:
  /// **'Prior resolution timestamp'**
  String get priorResolutionTimestamp;

  /// Officer executor attribution
  ///
  /// In en, this message translates to:
  /// **'Executed by {name}'**
  String executedBy(String name);

  /// Header title for 5-stage progress tracker
  ///
  /// In en, this message translates to:
  /// **'Progress Tracker'**
  String get progressTracker;

  /// Stage label for progress tracker
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get stage;

  /// Denominator 5 for stages
  ///
  /// In en, this message translates to:
  /// **'of 5'**
  String get ofFive;

  /// Current stage chip label
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get currentCaps;

  /// Category label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// Department label
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get departmentLabel;

  /// Priority label
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// Empty description placeholder
  ///
  /// In en, this message translates to:
  /// **'No additional description provided.'**
  String get noDescriptionProvided;

  /// Landmark label
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get landmark;

  /// Jurisdiction label
  ///
  /// In en, this message translates to:
  /// **'Jurisdiction'**
  String get jurisdiction;

  /// Timeline updates section header
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updatesTitle;

  /// Singular entry noun
  ///
  /// In en, this message translates to:
  /// **'entry'**
  String get entry;

  /// Plural entries noun
  ///
  /// In en, this message translates to:
  /// **'entries'**
  String get entries;

  /// Hazard map screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Hazard Map'**
  String get hazardMapTitle;

  /// Error message for hazard map failure
  ///
  /// In en, this message translates to:
  /// **'Couldn\'\'t load civic issues.'**
  String get couldNotLoadCivicIssues;

  /// Retry connection suggestion
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get checkConnectionRetry;

  /// Loading state for hazard map
  ///
  /// In en, this message translates to:
  /// **'Loading civic hazard map...'**
  String get loadingHazardMap;

  /// Offline notice on hazard map
  ///
  /// In en, this message translates to:
  /// **'Offline — Showing cached hazards. Basemap tiles require network.'**
  String get offlineCachedHazardsBanner;

  /// Warning when GPS service is turned off
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled on your device.'**
  String get locationServicesDisabled;

  /// Warning when location permission denied
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to center the map.'**
  String get locationPermissionRequired;

  /// Snackbar confirming map recentered
  ///
  /// In en, this message translates to:
  /// **'Centered on your location{wardText}'**
  String centeredOnLocation(String wardText);

  /// GPS determination error
  ///
  /// In en, this message translates to:
  /// **'Unable to determine your location. Please try again.'**
  String get unableToDetermineLocation;

  /// GPS timeout error
  ///
  /// In en, this message translates to:
  /// **'GPS acquisition timed out. Please retry.'**
  String get gpsTimeoutRetry;

  /// Tooltip to hide heatmap
  ///
  /// In en, this message translates to:
  /// **'Hide Heatmap Layer'**
  String get hideHeatmapLayer;

  /// Tooltip to show heatmap
  ///
  /// In en, this message translates to:
  /// **'Show Heatmap Layer'**
  String get showHeatmapLayer;

  /// Tooltip to toggle map legend
  ///
  /// In en, this message translates to:
  /// **'Toggle Map Legend'**
  String get toggleMapLegend;

  /// Button to detect GPS location
  ///
  /// In en, this message translates to:
  /// **'Use My Location'**
  String get useMyLocation;

  /// Tooltip for zoom in button
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get zoomIn;

  /// Tooltip for zoom out button
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get zoomOut;

  /// Legend title for complaint status colors
  ///
  /// In en, this message translates to:
  /// **'Status Legend'**
  String get statusLegend;

  /// Count pill label for nearby hazards
  ///
  /// In en, this message translates to:
  /// **'civic issues near you'**
  String get civicIssuesNearYou;

  /// Empty search results title on hazard map
  ///
  /// In en, this message translates to:
  /// **'No civic issues found.'**
  String get noCivicIssuesFound;

  /// Empty search advice on hazard map
  ///
  /// In en, this message translates to:
  /// **'Try changing your filters or search.'**
  String get tryChangingFiltersOrSearch;

  /// Dialog title for logout confirmation
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmationTitle;

  /// Dialog description for logout confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmationDesc;

  /// Link to view milestones
  ///
  /// In en, this message translates to:
  /// **'View Milestones'**
  String get viewMilestones;

  /// Civic assistant subtitle
  ///
  /// In en, this message translates to:
  /// **'FAQ, complaint rules & category help'**
  String get civicAssistantSubtitle;

  /// Settings section title for account
  ///
  /// In en, this message translates to:
  /// **'Account & Preferences'**
  String get accountAndPreferences;

  /// Settings section title for appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Theme selector title
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// Theme option system default
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// Theme option light theme
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// Theme option dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// Actions section title
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// Personal information section header
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// Full name hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// Email helper text on edit profile
  ///
  /// In en, this message translates to:
  /// **'Email cannot be changed for citizen account.'**
  String get emailCannotBeChanged;

  /// Phone helper text on edit profile
  ///
  /// In en, this message translates to:
  /// **'Used for SMS updates on urgent neighborhood alerts.'**
  String get phoneHelperText;

  /// Citizen account status card title
  ///
  /// In en, this message translates to:
  /// **'Registered Citizen Account'**
  String get registeredCitizenAccount;

  /// Citizen role label
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get citizen;

  /// Name validation minimum length error
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters long.'**
  String get nameTooShort;

  /// Name validation maximum length error
  ///
  /// In en, this message translates to:
  /// **'Name cannot exceed 50 characters.'**
  String get nameTooLong;

  /// Phone validation 10 digits error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit phone number.'**
  String get phoneInvalid;

  /// Dialog description for discarding report draft
  ///
  /// In en, this message translates to:
  /// **'Your entered information will be lost.'**
  String get discardReportDesc;

  /// Modal title for hazard map filter sheet
  ///
  /// In en, this message translates to:
  /// **'Filter Civic Issues'**
  String get filterCivicIssues;

  /// Tooltip to close hazard map filter sheet
  ///
  /// In en, this message translates to:
  /// **'Close filter'**
  String get closeFilter;

  /// Category section header in hazard map filter sheet
  ///
  /// In en, this message translates to:
  /// **'Hazard Category'**
  String get hazardCategory;

  /// Status section header in hazard map filter sheet
  ///
  /// In en, this message translates to:
  /// **'Issue Status'**
  String get issueStatus;

  /// Timeframe section header in hazard map filter sheet
  ///
  /// In en, this message translates to:
  /// **'Report Timeframe'**
  String get reportTimeframe;

  /// Standing subtitle in civic progress card
  ///
  /// In en, this message translates to:
  /// **'Civic Standing'**
  String get civicStanding;

  /// Tier progress bar label
  ///
  /// In en, this message translates to:
  /// **'Contribution Tier Progress'**
  String get tierProgress;

  /// Total points stat column label
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get totalPoints;

  /// Reports filed stat column label
  ///
  /// In en, this message translates to:
  /// **'Reports Filed'**
  String get reportsFiled;

  /// Resolved fixes stat column label
  ///
  /// In en, this message translates to:
  /// **'Resolved Fixes'**
  String get resolvedFixes;

  /// Subtitle for selecting category
  ///
  /// In en, this message translates to:
  /// **'Select the category that best matches the problem.'**
  String get selectCategorySubtitle;

  /// Step 1 Information label
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get stepInfo;

  /// Header for recent complaints
  ///
  /// In en, this message translates to:
  /// **'Recent Complaints'**
  String get recentComplaints;

  /// Rewards title
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// Resend cooldown message
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeInSeconds(int seconds);

  /// Safety hazard toggle title
  ///
  /// In en, this message translates to:
  /// **'Immediate Safety Hazard'**
  String get immediateSafetyHazardTitle;

  /// Step 2 title
  ///
  /// In en, this message translates to:
  /// **'Add Evidence'**
  String get addEvidenceTitle;

  /// Title when AI is temporarily unavailable and human review is active
  ///
  /// In en, this message translates to:
  /// **'Under Departmental Review'**
  String get aiFallbackReviewTitle;

  /// Citizen safe message during AI outage
  ///
  /// In en, this message translates to:
  /// **'Automated verification is temporarily unavailable. Your grievance has been routed for departmental review. SLA is active and resolution is progressing normally.'**
  String get aiFallbackReviewMessage;

  /// Message when lead confirms department
  ///
  /// In en, this message translates to:
  /// **'Department confirmed via manual review. Auto-routed to Junior Engineer.'**
  String get aiFallbackConfirmedMessage;

  /// Message when lead transfers department
  ///
  /// In en, this message translates to:
  /// **'Transferred to another BMC department via manual review.'**
  String get aiFallbackTransferredMessage;

  /// Action card title to use device GPS
  ///
  /// In en, this message translates to:
  /// **'Use Device Location'**
  String get useDeviceLocation;

  /// Button to select location on interactive map
  ///
  /// In en, this message translates to:
  /// **'Select on Map'**
  String get selectOnMap;

  /// Tooltip for map recenter on GPS button
  ///
  /// In en, this message translates to:
  /// **'Center on My GPS'**
  String get centerOnGps;

  /// Subtitle on report review screen
  ///
  /// In en, this message translates to:
  /// **'Please verify all information before submitting to your ward.'**
  String get verifyBeforeSubmitting;

  /// Badge indicating report is flagged as safety hazard
  ///
  /// In en, this message translates to:
  /// **'Marked as Immediate Safety Hazard'**
  String get markedImmediateSafetyHazard;

  /// Photo evidence heading with count
  ///
  /// In en, this message translates to:
  /// **'Photo Evidence ({count})'**
  String photoEvidenceCount(int count);

  /// Nearby landmark display
  ///
  /// In en, this message translates to:
  /// **'Near {landmark}'**
  String nearLandmark(String landmark);

  /// Landmark field label with value
  ///
  /// In en, this message translates to:
  /// **'Landmark: {landmark}'**
  String landmarkLabel(String landmark);

  /// Ward jurisdiction display
  ///
  /// In en, this message translates to:
  /// **'Jurisdiction: {ward}'**
  String jurisdictionLabel(String ward);

  /// Department routing note
  ///
  /// In en, this message translates to:
  /// **'This issue will be routed to {department}.'**
  String issueRoutedTo(String department);

  /// Roads issue category
  ///
  /// In en, this message translates to:
  /// **'Roads'**
  String get categoryRoads;

  /// Description for Roads category
  ///
  /// In en, this message translates to:
  /// **'Road damage, potholes and unsafe road surfaces.'**
  String get categoryRoadsDesc;

  /// Water issue category
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get categoryWater;

  /// Description for Water category
  ///
  /// In en, this message translates to:
  /// **'Water supply issues, leakage or contamination.'**
  String get categoryWaterDesc;

  /// Sanitation issue category
  ///
  /// In en, this message translates to:
  /// **'Sanitation'**
  String get categorySanitation;

  /// Description for Sanitation category
  ///
  /// In en, this message translates to:
  /// **'Public hygiene, public toilets and street cleanliness.'**
  String get categorySanitationDesc;

  /// Waste management category
  ///
  /// In en, this message translates to:
  /// **'Waste Management'**
  String get categoryWaste;

  /// Description for Waste Management category
  ///
  /// In en, this message translates to:
  /// **'Garbage accumulation and waste collection issues.'**
  String get categoryWasteDesc;

  /// Streetlights category
  ///
  /// In en, this message translates to:
  /// **'Street Lights'**
  String get categoryStreetlights;

  /// Description for Streetlights category
  ///
  /// In en, this message translates to:
  /// **'Broken or non-functioning street lights.'**
  String get categoryStreetlightsDesc;

  /// Drainage category
  ///
  /// In en, this message translates to:
  /// **'Drainage'**
  String get categoryDrainage;

  /// Description for Drainage category
  ///
  /// In en, this message translates to:
  /// **'Blocked drains, water logging, open manholes.'**
  String get categoryDrainageDesc;

  /// Public infrastructure category
  ///
  /// In en, this message translates to:
  /// **'Public Infrastructure'**
  String get categoryInfrastructure;

  /// Description for Infrastructure category
  ///
  /// In en, this message translates to:
  /// **'Damaged footpaths, bridges, bus shelters.'**
  String get categoryInfrastructureDesc;

  /// Traffic and road safety category
  ///
  /// In en, this message translates to:
  /// **'Traffic / Road Safety'**
  String get categoryTraffic;

  /// Description for Traffic category
  ///
  /// In en, this message translates to:
  /// **'Damaged signs, missing signals, hazardous intersections.'**
  String get categoryTrafficDesc;

  /// Other issue category
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// Description for Other category
  ///
  /// In en, this message translates to:
  /// **'Other public infrastructure or municipal maintenance issues.'**
  String get categoryOtherDesc;

  /// Potholes category
  ///
  /// In en, this message translates to:
  /// **'Potholes'**
  String get categoryPotholes;

  /// Garbage overflow category
  ///
  /// In en, this message translates to:
  /// **'Garbage Overflow'**
  String get categoryGarbageOverflow;

  /// Waterlogging category
  ///
  /// In en, this message translates to:
  /// **'Waterlogging'**
  String get categoryWaterlogging;

  /// Water leakage category
  ///
  /// In en, this message translates to:
  /// **'Water Leakage'**
  String get categoryWaterLeakage;

  /// Damaged water infrastructure category
  ///
  /// In en, this message translates to:
  /// **'Damaged Water Infrastructure'**
  String get categoryDamagedWater;

  /// Sewage overflow category
  ///
  /// In en, this message translates to:
  /// **'Sewage Overflow'**
  String get categorySewageOverflow;

  /// Open manholes category
  ///
  /// In en, this message translates to:
  /// **'Open Manholes'**
  String get categoryManholes;

  /// Damaged footpaths category
  ///
  /// In en, this message translates to:
  /// **'Damaged Footpaths'**
  String get categoryFootpaths;

  /// Fallen or dangerous trees category
  ///
  /// In en, this message translates to:
  /// **'Fallen / Dangerous Trees'**
  String get categoryTrees;

  /// Low priority label
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// Medium priority label
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// High priority label
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// Critical emergency priority label
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get priorityEmergency;

  /// Roads & Traffic Department name
  ///
  /// In en, this message translates to:
  /// **'Roads & Traffic Department'**
  String get deptRoadsTraffic;

  /// Solid Waste Department name
  ///
  /// In en, this message translates to:
  /// **'Solid Waste Management'**
  String get deptSolidWaste;

  /// Water Supply & Sewerage Department name
  ///
  /// In en, this message translates to:
  /// **'Water Supply & Sewerage'**
  String get deptWaterSewerage;

  /// Electrical & Streetlights Department name
  ///
  /// In en, this message translates to:
  /// **'Electrical & Street Lighting'**
  String get deptElectricalStreetlights;

  /// Storm Water Drainage Department name
  ///
  /// In en, this message translates to:
  /// **'Storm Water Drainage'**
  String get deptStormDrainage;

  /// Public Health Department name
  ///
  /// In en, this message translates to:
  /// **'Public Health Department'**
  String get deptPublicHealth;

  /// Gardens & Tree Authority Department name
  ///
  /// In en, this message translates to:
  /// **'Gardens & Tree Authority'**
  String get deptGardensTrees;

  /// Building & Infrastructure Department name
  ///
  /// In en, this message translates to:
  /// **'Building & Infrastructure'**
  String get deptBuildingInfrastructure;

  /// General Municipal Desk name
  ///
  /// In en, this message translates to:
  /// **'General Municipal Desk'**
  String get deptGeneral;

  /// Verification pending state label
  ///
  /// In en, this message translates to:
  /// **'Verification Pending'**
  String get verificationPending;

  /// Verification processing state label
  ///
  /// In en, this message translates to:
  /// **'Analyzing & Verifying...'**
  String get verificationProcessing;

  /// Verification passed state label
  ///
  /// In en, this message translates to:
  /// **'Verification Passed'**
  String get verificationPassed;

  /// Verification failed state label
  ///
  /// In en, this message translates to:
  /// **'Verification Failed'**
  String get verificationFailed;

  /// Verification delayed state label
  ///
  /// In en, this message translates to:
  /// **'Automated Verification Delayed'**
  String get verificationDelayed;

  /// Officer review verification state label
  ///
  /// In en, this message translates to:
  /// **'Department Officer Review'**
  String get verificationOfficerReview;

  /// Verification completed state label
  ///
  /// In en, this message translates to:
  /// **'Verification Completed'**
  String get verificationCompleted;

  /// Unassigned routing state
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get routingUnassigned;

  /// Assigned routing state
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get routingAssigned;

  /// Reassignment requested routing state
  ///
  /// In en, this message translates to:
  /// **'Reassignment Requested'**
  String get routingReassignmentRequested;

  /// Transferred routing state
  ///
  /// In en, this message translates to:
  /// **'Transferred'**
  String get routingTransferred;

  /// In progress routing state
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get routingInProgress;

  /// Resolved routing state
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get routingResolved;

  /// Unassigned assignment state
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get assignmentUnassigned;

  /// Lead assigned state
  ///
  /// In en, this message translates to:
  /// **'Assigned to Ward Lead'**
  String get assignmentLeadAssigned;

  /// Crew assigned state
  ///
  /// In en, this message translates to:
  /// **'Assigned to Ground Crew'**
  String get assignmentCrewAssigned;

  /// Field officer assigned state
  ///
  /// In en, this message translates to:
  /// **'Assigned to Field Officer'**
  String get assignmentFieldOfficerAssigned;

  /// Synced status
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncSynced;

  /// Pending sync status
  ///
  /// In en, this message translates to:
  /// **'Pending Sync'**
  String get syncPending;

  /// Syncing in progress status
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncSyncing;

  /// Basemap style title
  ///
  /// In en, this message translates to:
  /// **'Basemap Style'**
  String get basemapStyle;

  /// Subtitle for basemap selector
  ///
  /// In en, this message translates to:
  /// **'Choose map view and imagery mode'**
  String get chooseMapViewMode;

  /// Streets basemap label
  ///
  /// In en, this message translates to:
  /// **'Streets'**
  String get basemapStreets;

  /// Streets basemap description
  ///
  /// In en, this message translates to:
  /// **'Detailed vector road networks, wards, and civic infrastructure'**
  String get basemapStreetsDesc;

  /// Satellite basemap label
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get basemapSatellite;

  /// Satellite basemap description
  ///
  /// In en, this message translates to:
  /// **'High-resolution aerial and satellite photographic imagery'**
  String get basemapSatelliteDesc;

  /// Hybrid basemap label
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get basemapHybrid;

  /// Hybrid basemap description
  ///
  /// In en, this message translates to:
  /// **'Satellite imagery overlaid with street names, borders, and locality labels'**
  String get basemapHybridDesc;

  /// First Report badge title
  ///
  /// In en, this message translates to:
  /// **'First Report'**
  String get badgeFirstReport;

  /// First Report badge description
  ///
  /// In en, this message translates to:
  /// **'Submitted your first civic grievance'**
  String get badgeFirstReportDesc;

  /// Active Citizen badge title
  ///
  /// In en, this message translates to:
  /// **'Active Citizen'**
  String get badgeActiveCitizen;

  /// Active Citizen badge description
  ///
  /// In en, this message translates to:
  /// **'Reported 5 or more civic issues'**
  String get badgeActiveCitizenDesc;

  /// Neighborhood Hero badge title
  ///
  /// In en, this message translates to:
  /// **'Neighborhood Hero'**
  String get badgeNeighborhoodHero;

  /// Neighborhood Hero badge description
  ///
  /// In en, this message translates to:
  /// **'Had 10 issues resolved in your community'**
  String get badgeNeighborhoodHeroDesc;

  /// Sharp Eye badge title
  ///
  /// In en, this message translates to:
  /// **'Sharp Eye'**
  String get badgeSharpEye;

  /// Sharp Eye badge description
  ///
  /// In en, this message translates to:
  /// **'Reported an immediate safety hazard'**
  String get badgeSharpEyeDesc;

  /// Community Pillar badge title
  ///
  /// In en, this message translates to:
  /// **'Community Pillar'**
  String get badgeCommunityPillar;

  /// Community Pillar badge description
  ///
  /// In en, this message translates to:
  /// **'Achieved 500+ Civic Points'**
  String get badgeCommunityPillarDesc;

  /// Unlocked status label
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// Locked status label
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// How to unlock label
  ///
  /// In en, this message translates to:
  /// **'How to Unlock'**
  String get howToUnlock;

  /// Community perks title
  ///
  /// In en, this message translates to:
  /// **'Community Perks'**
  String get communityPerks;

  /// Community perks subtitle
  ///
  /// In en, this message translates to:
  /// **'Redeem your points for local government & partner benefits'**
  String get communityPerksSubtitle;

  /// Button to claim reward perk
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get claimPerk;

  /// Heading for citizen contribution summary
  ///
  /// In en, this message translates to:
  /// **'Your Contribution'**
  String get yourContribution;

  /// Total reports metric label
  ///
  /// In en, this message translates to:
  /// **'Total Reports'**
  String get totalReports;

  /// Resolved reports metric label
  ///
  /// In en, this message translates to:
  /// **'Resolved Reports'**
  String get resolvedReports;

  /// Points earned metric label
  ///
  /// In en, this message translates to:
  /// **'Points Earned'**
  String get pointsEarned;

  /// Achievements section title
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// Achievements section subtitle
  ///
  /// In en, this message translates to:
  /// **'Earn badges for active neighborhood participation'**
  String get achievementsSubtitle;

  /// Loading state message for rewards
  ///
  /// In en, this message translates to:
  /// **'Loading your civic milestones...'**
  String get loadingRewards;

  /// Snackbar message on mark all as read
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read.'**
  String get allNotificationsMarkedAsRead;

  /// All filter option
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Unread filter option
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get filterUnread;

  /// Read filter option
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get filterRead;

  /// Dialog title for logout confirmation
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutQuestion;

  /// Dialog body for logout confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmationMessage;

  /// Tooltip/button to clear assistant chat
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// Loading indicator in assistant chat
  ///
  /// In en, this message translates to:
  /// **'Assistant is thinking...'**
  String get assistantThinking;

  /// Hint text for assistant input field
  ///
  /// In en, this message translates to:
  /// **'Ask about reporting, tracking, or categories...'**
  String get assistantMessageHint;

  /// Resolution section title
  ///
  /// In en, this message translates to:
  /// **'Resolution & Work Verification'**
  String get resolutionWorkVerification;

  /// Resolution section subtitle
  ///
  /// In en, this message translates to:
  /// **'Ground inspection & completion evidence'**
  String get groundInspectionSubtitle;

  /// Government Portal header branding
  ///
  /// In en, this message translates to:
  /// **'CivicFix Government Portal'**
  String get govPortalTitle;

  /// Login title for government officers
  ///
  /// In en, this message translates to:
  /// **'Government Officer Sign In'**
  String get govLoginTitle;

  /// Login subtitle on government portal
  ///
  /// In en, this message translates to:
  /// **'Secure administrative access for BMC municipal officers'**
  String get govLoginSubtitle;

  /// Username field label
  ///
  /// In en, this message translates to:
  /// **'Employee ID or Official Email'**
  String get govEmployeeIdOrEmail;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get govPassword;

  /// Submit button on government sign in screen
  ///
  /// In en, this message translates to:
  /// **'Sign In to Portal'**
  String get govSignInButton;

  /// Error message when authentication fails
  ///
  /// In en, this message translates to:
  /// **'Invalid employee ID, email, or password.'**
  String get govInvalidCredentials;

  /// Error message for deactivated officer accounts
  ///
  /// In en, this message translates to:
  /// **'Account is deactivated. Contact Municipal Administrator.'**
  String get govAccountDisabled;

  /// Session expired notification
  ///
  /// In en, this message translates to:
  /// **'Session has expired. Please sign in again.'**
  String get govSessionExpired;

  /// Access denied title
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get govAccessDenied;

  /// Access denied description
  ///
  /// In en, this message translates to:
  /// **'You do not have administrative privileges to access this area.'**
  String get govAccessDeniedDesc;

  /// Button to return to default landing screen
  ///
  /// In en, this message translates to:
  /// **'Return to Dashboard'**
  String get govReturnToDashboard;

  /// Loading state during government sign in
  ///
  /// In en, this message translates to:
  /// **'Verifying administrative credentials...'**
  String get govAuthenticating;

  /// Forgot password title
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get govForgotPassword;

  /// Instructions for password reset
  ///
  /// In en, this message translates to:
  /// **'Enter your registered official email to receive password reset instructions.'**
  String get govResetPasswordInstruction;

  /// Button to trigger password reset email
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get govSendResetLink;

  /// Navigation item: Dashboard
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get govNavDashboard;

  /// Navigation item: Complaints
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get govNavComplaints;

  /// Navigation item: Hazard Map
  ///
  /// In en, this message translates to:
  /// **'Hazard Map'**
  String get govNavHazardMap;

  /// Navigation item: Analytics
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get govNavAnalytics;

  /// Navigation item: Profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get govNavProfile;

  /// Navigation item: My Work
  ///
  /// In en, this message translates to:
  /// **'My Work'**
  String get govNavMyWork;

  /// Navigation item: Operations
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get govNavOperations;

  /// Navigation item: SLA
  ///
  /// In en, this message translates to:
  /// **'SLA Monitor'**
  String get govNavSla;

  /// Navigation item: Audit History
  ///
  /// In en, this message translates to:
  /// **'Audit History'**
  String get govNavHistory;

  /// Navigation item: Verification
  ///
  /// In en, this message translates to:
  /// **'Verification Queue'**
  String get govNavVerification;

  /// Navigation item: Assignments
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get govNavAssignments;

  /// Title for executive command dashboard
  ///
  /// In en, this message translates to:
  /// **'Executive Dashboard'**
  String get govExecutiveDashboard;

  /// Title for complaint management screen
  ///
  /// In en, this message translates to:
  /// **'Grievance Management'**
  String get govGrievanceManagement;

  /// Title for GIS map screen
  ///
  /// In en, this message translates to:
  /// **'Live Hazard GIS Map'**
  String get govLiveHazardGisMap;

  /// Title for analytics screen
  ///
  /// In en, this message translates to:
  /// **'Operational Analytics'**
  String get govOperationalAnalytics;

  /// Title for officer profile and settings
  ///
  /// In en, this message translates to:
  /// **'Officer Profile & Settings'**
  String get govOfficerProfileSettings;

  /// Tooltip to collapse sidebar
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get govCollapseSidebar;

  /// Tooltip to expand sidebar
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get govExpandSidebar;

  /// Municipal corporation full title
  ///
  /// In en, this message translates to:
  /// **'Brihanmumbai Municipal Corporation'**
  String get govMunicipalCorporation;

  /// Role: Super Admin
  ///
  /// In en, this message translates to:
  /// **'Municipal Commissioner / Super Admin'**
  String get govRoleSuperAdmin;

  /// Role: Zonal DMC
  ///
  /// In en, this message translates to:
  /// **'Zonal Deputy Municipal Commissioner'**
  String get govRoleZonalDmc;

  /// Role: Central HOD
  ///
  /// In en, this message translates to:
  /// **'Central Department Head of Department'**
  String get govRoleCentralHod;

  /// Role: Ward Officer
  ///
  /// In en, this message translates to:
  /// **'Assistant Municipal Commissioner (Ward Officer)'**
  String get govRoleWardOfficer;

  /// Role: Ward Department Lead
  ///
  /// In en, this message translates to:
  /// **'Ward Department Lead'**
  String get govRoleWardLead;

  /// Role: Field Officer / Crew
  ///
  /// In en, this message translates to:
  /// **'Junior Engineer / Field Execution Officer'**
  String get govRoleDepartmentCrew;

  /// Role designation: Assistant Engineer
  ///
  /// In en, this message translates to:
  /// **'Assistant Engineer'**
  String get govRoleAssistantEngineer;

  /// Role designation: Executive Engineer
  ///
  /// In en, this message translates to:
  /// **'Executive Engineer'**
  String get govRoleExecutiveEngineer;

  /// Role designation: Sub-Engineer
  ///
  /// In en, this message translates to:
  /// **'Sub-Engineer'**
  String get govRoleSubEngineer;

  /// Role designation: Medical Officer of Health
  ///
  /// In en, this message translates to:
  /// **'Medical Officer of Health'**
  String get govRoleMedicalOfficer;

  /// Role designation: Assistant Superintendent
  ///
  /// In en, this message translates to:
  /// **'Assistant Superintendent'**
  String get govRoleSuperintendent;

  /// Department: Roads & Maintenance
  ///
  /// In en, this message translates to:
  /// **'Roads & Maintenance'**
  String get deptMaintenanceRoads;

  /// Department: Water Works & Supply
  ///
  /// In en, this message translates to:
  /// **'Water Works & Supply'**
  String get deptWaterWorks;

  /// Department: Solid Waste Management
  ///
  /// In en, this message translates to:
  /// **'Solid Waste Management'**
  String get deptSolidWasteManagement;

  /// Department: Building & Factory
  ///
  /// In en, this message translates to:
  /// **'Building & Factory'**
  String get deptBuildingFactory;

  /// Department: Gardens & Trees
  ///
  /// In en, this message translates to:
  /// **'Gardens & Trees'**
  String get deptGardenTrees;

  /// Department: Pest Control & Insecticide
  ///
  /// In en, this message translates to:
  /// **'Pest Control & Insecticide'**
  String get deptPestControlInsecticide;

  /// Department: Encroachment Removal
  ///
  /// In en, this message translates to:
  /// **'Encroachment Removal'**
  String get deptEncroachment;

  /// Department: Licence Department
  ///
  /// In en, this message translates to:
  /// **'Licence Department'**
  String get deptLicence;

  /// Department: Shops & Establishments
  ///
  /// In en, this message translates to:
  /// **'Shops & Establishments'**
  String get deptShopsEstablishments;

  /// Department: Assessment & Collection
  ///
  /// In en, this message translates to:
  /// **'Assessment & Collection'**
  String get deptAssessmentCollection;

  /// Department: Estate Department
  ///
  /// In en, this message translates to:
  /// **'Estate Department'**
  String get deptEstate;

  /// Department: Colony & Slum Improvement
  ///
  /// In en, this message translates to:
  /// **'Colony & Slum Improvement'**
  String get deptColonySlum;

  /// Department: Education & Municipal Schools
  ///
  /// In en, this message translates to:
  /// **'Education & Municipal Schools'**
  String get deptEducationSchools;

  /// Department: Security Force
  ///
  /// In en, this message translates to:
  /// **'Security Force'**
  String get deptSecurity;

  /// Department: Legal Department
  ///
  /// In en, this message translates to:
  /// **'Legal Department'**
  String get deptLegal;

  /// Department: Administration & Establishment
  ///
  /// In en, this message translates to:
  /// **'Administration & Establishment'**
  String get deptAdministrationEstablishment;

  /// Department: Town Planning & Development Plan
  ///
  /// In en, this message translates to:
  /// **'Town Planning & Development Plan'**
  String get deptTownPlanning;

  /// Dashboard card: Pending complaints
  ///
  /// In en, this message translates to:
  /// **'Pending Complaints'**
  String get govPendingComplaints;

  /// Dashboard card: Assigned complaints
  ///
  /// In en, this message translates to:
  /// **'Assigned Complaints'**
  String get govAssignedComplaints;

  /// Dashboard card: Work in progress
  ///
  /// In en, this message translates to:
  /// **'Work In Progress'**
  String get govInProgressComplaints;

  /// Dashboard card: Resolved complaints
  ///
  /// In en, this message translates to:
  /// **'Resolved Complaints'**
  String get govResolvedComplaints;

  /// Dashboard card: Overdue grievances
  ///
  /// In en, this message translates to:
  /// **'Overdue Grievances'**
  String get govOverdueComplaints;

  /// Dashboard card: SLA breaches
  ///
  /// In en, this message translates to:
  /// **'SLA Breaches'**
  String get govSlaBreaches;

  /// Dashboard card: Awaiting verification
  ///
  /// In en, this message translates to:
  /// **'Awaiting Verification'**
  String get govAwaitingVerification;

  /// Dashboard card: Rework required
  ///
  /// In en, this message translates to:
  /// **'Rework Required'**
  String get govReworkRequired;

  /// Dashboard section: Today's tasks
  ///
  /// In en, this message translates to:
  /// **'Today\'\'s Operational Tasks'**
  String get govTodayTasks;

  /// Dashboard section: Recent activity
  ///
  /// In en, this message translates to:
  /// **'Recent Department Activity'**
  String get govRecentActivity;

  /// Dashboard section: Ward summary
  ///
  /// In en, this message translates to:
  /// **'Ward Performance Summary'**
  String get govWardSummary;

  /// Dashboard section: Department summary
  ///
  /// In en, this message translates to:
  /// **'Department Operational Summary'**
  String get govDepartmentSummary;

  /// KPI label: Resolution rate
  ///
  /// In en, this message translates to:
  /// **'Resolution Rate'**
  String get govResolutionRate;

  /// KPI label: Average resolution time
  ///
  /// In en, this message translates to:
  /// **'Avg. Resolution Time'**
  String get govAvgResolutionTime;

  /// KPI label: Total grievances
  ///
  /// In en, this message translates to:
  /// **'Total Grievances'**
  String get govTotalGrievances;

  /// Dashboard card: Critical hazards
  ///
  /// In en, this message translates to:
  /// **'Critical Hazards'**
  String get govCriticalHazards;

  /// Dashboard card: Active field crews
  ///
  /// In en, this message translates to:
  /// **'Active Field Crews'**
  String get govActiveFieldCrew;

  /// Header for field crew / officer work view
  ///
  /// In en, this message translates to:
  /// **'My Assigned Work'**
  String get govMyWorkTitle;

  /// Action button to commence site execution
  ///
  /// In en, this message translates to:
  /// **'Start Work on Site'**
  String get govStartJob;

  /// Status text for commenced work
  ///
  /// In en, this message translates to:
  /// **'Work Commenced'**
  String get govWorkStarted;

  /// Button to upload before-repair photographic evidence
  ///
  /// In en, this message translates to:
  /// **'Upload Before Evidence'**
  String get govUploadBeforeEvidence;

  /// Button to upload after-repair photographic evidence
  ///
  /// In en, this message translates to:
  /// **'Upload After / Completion Evidence'**
  String get govUploadAfterEvidence;

  /// Label for work remarks input
  ///
  /// In en, this message translates to:
  /// **'Add Execution Remarks'**
  String get govAddWorkRemarks;

  /// Action button when job encounters obstruction
  ///
  /// In en, this message translates to:
  /// **'Mark Work as Blocked'**
  String get govMarkBlocked;

  /// Action button to resume blocked job
  ///
  /// In en, this message translates to:
  /// **'Resume Work'**
  String get govResumeWork;

  /// Button to submit work for lead verification
  ///
  /// In en, this message translates to:
  /// **'Submit for Resolution Review'**
  String get govSubmitResolution;

  /// Label for blockage reason input
  ///
  /// In en, this message translates to:
  /// **'Reason for Delay / Blockage'**
  String get govBlockedReasonLabel;

  /// Status banner on work in progress
  ///
  /// In en, this message translates to:
  /// **'Execution in progress on site.'**
  String get govWorkInProgressBanner;

  /// Status banner on completed work
  ///
  /// In en, this message translates to:
  /// **'Work completed and submitted for audit.'**
  String get govWorkCompletedBanner;

  /// Title for complaint detail review
  ///
  /// In en, this message translates to:
  /// **'Grievance Inspection & Audit'**
  String get govComplaintDetailsTitle;

  /// Section header: Citizen details
  ///
  /// In en, this message translates to:
  /// **'Citizen Information'**
  String get govCitizenDetails;

  /// Section header: Issue particulars
  ///
  /// In en, this message translates to:
  /// **'Issue Particulars'**
  String get govIssueDetails;

  /// Label for verification state
  ///
  /// In en, this message translates to:
  /// **'Verification State'**
  String get govVerificationResult;

  /// Heading for AI verification
  ///
  /// In en, this message translates to:
  /// **'Automated AI Verification'**
  String get govAiVerification;

  /// Badge / title for manual fallback review
  ///
  /// In en, this message translates to:
  /// **'Manual Verification Required'**
  String get govManualReviewRequired;

  /// Explanatory text for manual review requirement
  ///
  /// In en, this message translates to:
  /// **'AI could not determine department with high confidence.'**
  String get govAiCouldNotVerify;

  /// Button to approve grievance verification
  ///
  /// In en, this message translates to:
  /// **'Approve & Route'**
  String get govApproveAndRoute;

  /// Button to reject invalid grievance
  ///
  /// In en, this message translates to:
  /// **'Reject Grievance'**
  String get govRejectGrievance;

  /// Action to re-route grievance to correct department
  ///
  /// In en, this message translates to:
  /// **'Override Department / Category'**
  String get govOverrideDepartment;

  /// Dropdown label to select target department
  ///
  /// In en, this message translates to:
  /// **'Select Target Department'**
  String get govSelectTargetDepartment;

  /// Input label for review remarks
  ///
  /// In en, this message translates to:
  /// **'Officer Review Remarks'**
  String get govReviewNotesLabel;

  /// Confirmation button for department review
  ///
  /// In en, this message translates to:
  /// **'Confirm Department Assignment'**
  String get govConfirmDepartment;

  /// Timeline heading in review screen
  ///
  /// In en, this message translates to:
  /// **'Grievance Timeline & Audit History'**
  String get govAuditTimeline;

  /// Button / title to assign grievance to officer
  ///
  /// In en, this message translates to:
  /// **'Assign Grievance'**
  String get govAssignOfficer;

  /// Label displaying currently assigned officer
  ///
  /// In en, this message translates to:
  /// **'Assigned Field Officer'**
  String get govAssignedOfficerLabel;

  /// Dialog title for field officer assignment
  ///
  /// In en, this message translates to:
  /// **'Assign Field Execution Officer'**
  String get govAssignFieldOfficer;

  /// Button to reassign grievance
  ///
  /// In en, this message translates to:
  /// **'Reassign Grievance'**
  String get govReassignOfficer;

  /// Header for list of available officers
  ///
  /// In en, this message translates to:
  /// **'Available Field Officers'**
  String get govAvailableOfficers;

  /// Workload label next to officer name
  ///
  /// In en, this message translates to:
  /// **'Active Workload'**
  String get govOfficerWorkload;

  /// Button to confirm assignment
  ///
  /// In en, this message translates to:
  /// **'Confirm Assignment'**
  String get govConfirmAssignment;

  /// Button to cancel assignment
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get govCancelAssignment;

  /// Snackbar message on assignment
  ///
  /// In en, this message translates to:
  /// **'Grievance successfully assigned to {officerName}.'**
  String govAssignmentSuccess(String officerName);

  /// Snackbar error on assignment failure
  ///
  /// In en, this message translates to:
  /// **'Failed to assign officer. Please try again.'**
  String get govAssignmentFailed;

  /// SLA header label
  ///
  /// In en, this message translates to:
  /// **'SLA Compliance'**
  String get govSlaStatus;

  /// Status badge: Within SLA
  ///
  /// In en, this message translates to:
  /// **'Within SLA Target'**
  String get govWithinSla;

  /// Status badge: Approaching SLA
  ///
  /// In en, this message translates to:
  /// **'Approaching SLA Deadline'**
  String get govApproachingSlaDeadline;

  /// Status badge: SLA Breached
  ///
  /// In en, this message translates to:
  /// **'SLA Breached'**
  String get govSlaBreached;

  /// Parameterized hours remaining for SLA
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour remaining} other{{count} hours remaining}}'**
  String govHoursRemaining(int count);

  /// Parameterized days remaining for SLA
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day remaining} other{{count} days remaining}}'**
  String govDaysRemaining(int count);

  /// Parameterized days overdue for SLA
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day overdue} other{{count} days overdue}}'**
  String govDaysOverdue(int count);

  /// Parameterized hours overdue for SLA
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour overdue} other{{count} hours overdue}}'**
  String govHoursOverdue(int count);

  /// Title for resolution review dialog
  ///
  /// In en, this message translates to:
  /// **'Resolution Quality Audit'**
  String get govResolutionReview;

  /// Button to approve resolution
  ///
  /// In en, this message translates to:
  /// **'Approve & Close Complaint'**
  String get govApproveResolution;

  /// Button to send back for rework
  ///
  /// In en, this message translates to:
  /// **'Send for Rework'**
  String get govSendForRework;

  /// Input label for rework reason
  ///
  /// In en, this message translates to:
  /// **'Reason for Rework'**
  String get govReworkReasonLabel;

  /// Button to close grievance
  ///
  /// In en, this message translates to:
  /// **'Close Grievance'**
  String get govCloseComplaint;

  /// Button to reopen grievance
  ///
  /// In en, this message translates to:
  /// **'Reopen Grievance'**
  String get govReopenComplaint;

  /// Table column: Ticket Number
  ///
  /// In en, this message translates to:
  /// **'Ticket Number'**
  String get govTableHeaderId;

  /// Table column: Category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get govTableHeaderCategory;

  /// Table column: Ward
  ///
  /// In en, this message translates to:
  /// **'Ward'**
  String get govTableHeaderWard;

  /// Table column: Department
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get govTableHeaderDepartment;

  /// Table column: Status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get govTableHeaderStatus;

  /// Table column: Priority
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get govTableHeaderPriority;

  /// Table column: SLA
  ///
  /// In en, this message translates to:
  /// **'SLA Remaining'**
  String get govTableHeaderSla;

  /// Table column: Reported date
  ///
  /// In en, this message translates to:
  /// **'Reported On'**
  String get govTableHeaderReported;

  /// Table column: Actions
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get govTableHeaderActions;

  /// Hint text for government search bar
  ///
  /// In en, this message translates to:
  /// **'Search by ticket number, citizen name, locality...'**
  String get govSearchComplaintsHint;

  /// Empty state message for table
  ///
  /// In en, this message translates to:
  /// **'No matching grievances found.'**
  String get govNoMatchingComplaints;

  /// Filter option: All Wards
  ///
  /// In en, this message translates to:
  /// **'All Wards'**
  String get govAllWards;

  /// Filter option: All Departments
  ///
  /// In en, this message translates to:
  /// **'All Departments'**
  String get govAllDepartments;

  /// Filter option: All Statuses
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get govAllStatuses;

  /// Table pagination label
  ///
  /// In en, this message translates to:
  /// **'Rows per page'**
  String get govRowsPerPage;

  /// Pagination button: Previous
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get govPreviousPage;

  /// Pagination button: Next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get govNextPage;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Government Officer Profile'**
  String get govOfficerProfile;

  /// Profile field: Name
  ///
  /// In en, this message translates to:
  /// **'Officer Name'**
  String get govOfficerName;

  /// Profile field: Employee ID
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get govEmployeeId;

  /// Profile field: Official email
  ///
  /// In en, this message translates to:
  /// **'Official Email'**
  String get govOfficialEmail;

  /// Profile field: Designation
  ///
  /// In en, this message translates to:
  /// **'Official Designation'**
  String get govDesignation;

  /// Profile field: Jurisdiction
  ///
  /// In en, this message translates to:
  /// **'Assigned Jurisdiction'**
  String get govJurisdiction;

  /// Jurisdiction label: Citywide
  ///
  /// In en, this message translates to:
  /// **'Citywide (All Zones & Wards)'**
  String get govCitywide;

  /// Jurisdiction label for ward
  ///
  /// In en, this message translates to:
  /// **'Ward {wardName}'**
  String govWardJurisdiction(String wardName);

  /// Jurisdiction label for zone
  ///
  /// In en, this message translates to:
  /// **'Zone {zoneName}'**
  String govZoneJurisdiction(String zoneName);

  /// Action to sign out of government portal
  ///
  /// In en, this message translates to:
  /// **'Sign Out of Government Portal'**
  String get govSignOut;

  /// Sign out confirmation dialog text
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get govSignOutConfirm;

  /// Settings section: Language
  ///
  /// In en, this message translates to:
  /// **'Portal Language'**
  String get govLanguageSettings;

  /// Settings section: Appearance
  ///
  /// In en, this message translates to:
  /// **'Theme & Density'**
  String get govAppearanceSettings;

  /// Settings section: Privacy & Governance
  ///
  /// In en, this message translates to:
  /// **'Governance & Data Standards'**
  String get govPrivacyPrinciples;

  /// Settings section: About
  ///
  /// In en, this message translates to:
  /// **'About Municipal Portal'**
  String get govAboutPortal;

  /// Version string for government portal
  ///
  /// In en, this message translates to:
  /// **'CivicFix Governance Suite v1.0.0-gov'**
  String get govVersionInfo;

  /// Government dashboard header title
  ///
  /// In en, this message translates to:
  /// **'Municipal Operations Overview'**
  String get govDashboard;

  /// Government dashboard header subtitle
  ///
  /// In en, this message translates to:
  /// **'Real-time grievance telemetry & nodal department workload'**
  String get govDashboardSubtitle;

  /// Total grievances KPI card label
  ///
  /// In en, this message translates to:
  /// **'Total Grievances'**
  String get govTotalComplaints;

  /// Reported new grievances KPI card label
  ///
  /// In en, this message translates to:
  /// **'Reported / New'**
  String get govReportedComplaints;

  /// Generic details button label
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Unassigned officer indicator label
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassignedOfficer;

  /// Inspect and view details action label
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get govInspectAction;

  /// Update status button label
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get govUpdateStatus;

  /// Field execution not started state
  ///
  /// In en, this message translates to:
  /// **'Ready to Start'**
  String get executionNotStarted;

  /// Field execution in progress state
  ///
  /// In en, this message translates to:
  /// **'Execution In Progress'**
  String get executionInProgress;

  /// Field execution blocked state
  ///
  /// In en, this message translates to:
  /// **'Execution Blocked'**
  String get executionBlocked;

  /// Field execution awaiting evidence state
  ///
  /// In en, this message translates to:
  /// **'Awaiting Ground Evidence'**
  String get executionAwaitingEvidence;

  /// Field execution completed state
  ///
  /// In en, this message translates to:
  /// **'Work Completed'**
  String get executionCompleted;

  /// Resolution pending state
  ///
  /// In en, this message translates to:
  /// **'Resolution Pending'**
  String get resolutionPending;

  /// Resolution submitted state
  ///
  /// In en, this message translates to:
  /// **'Resolution Submitted'**
  String get resolutionSubmitted;

  /// Resolution approved state
  ///
  /// In en, this message translates to:
  /// **'Resolution Approved'**
  String get resolutionApproved;

  /// Resolution rejected state
  ///
  /// In en, this message translates to:
  /// **'Resolution Rejected'**
  String get resolutionRejected;

  /// Resolution closed state
  ///
  /// In en, this message translates to:
  /// **'Resolution Closed'**
  String get resolutionClosed;

  /// Rework not required state
  ///
  /// In en, this message translates to:
  /// **'No Rework Required'**
  String get reworkNotRequired;

  /// Rework required state
  ///
  /// In en, this message translates to:
  /// **'Rework Required'**
  String get reworkRequiredState;

  /// Rework in progress state
  ///
  /// In en, this message translates to:
  /// **'Rework In Progress'**
  String get reworkInProgress;

  /// Rework submitted state
  ///
  /// In en, this message translates to:
  /// **'Rework Submitted'**
  String get reworkSubmitted;

  /// Rework approved state
  ///
  /// In en, this message translates to:
  /// **'Rework Approved'**
  String get reworkApproved;

  /// Offline queue state
  ///
  /// In en, this message translates to:
  /// **'Offline Queue'**
  String get syncOffline;

  /// Retrying sync state
  ///
  /// In en, this message translates to:
  /// **'Retrying Sync...'**
  String get syncRetrying;

  /// Notification type: complaint submitted
  ///
  /// In en, this message translates to:
  /// **'Complaint Submitted'**
  String get notifComplaintSubmitted;

  /// Notification type: complaint verified
  ///
  /// In en, this message translates to:
  /// **'Complaint Verified'**
  String get notifComplaintVerified;

  /// Notification type: complaint assigned
  ///
  /// In en, this message translates to:
  /// **'Complaint Assigned'**
  String get notifComplaintAssigned;

  /// Notification type: complaint status changed
  ///
  /// In en, this message translates to:
  /// **'Status Updated'**
  String get notifComplaintStatusChanged;

  /// Notification type: complaint resolved
  ///
  /// In en, this message translates to:
  /// **'Complaint Resolved'**
  String get notifComplaintResolved;

  /// Notification type: general civic notice
  ///
  /// In en, this message translates to:
  /// **'Civic Announcement'**
  String get notifGeneralCivic;

  /// Notification type: hazard alert
  ///
  /// In en, this message translates to:
  /// **'Hazard Warning'**
  String get notifHazardAlert;

  /// Notification type: reward earned
  ///
  /// In en, this message translates to:
  /// **'Reward Earned'**
  String get notifRewardEarned;

  /// Notification type: SLA deadline warning
  ///
  /// In en, this message translates to:
  /// **'SLA Deadline Warning'**
  String get notifSlaWarning;

  /// Notification type: rework requested
  ///
  /// In en, this message translates to:
  /// **'Rework Requested'**
  String get notifReworkRequested;

  /// Ground reporter badge title
  ///
  /// In en, this message translates to:
  /// **'Ground Reporter'**
  String get badgeGroundReporter;

  /// Ground reporter badge description
  ///
  /// In en, this message translates to:
  /// **'Provide accurate coordinates matching the assigned ward on 5 verified complaints.'**
  String get badgeGroundReporterDesc;

  /// Community voice badge title
  ///
  /// In en, this message translates to:
  /// **'Community Voice'**
  String get badgeCommunityVoice;

  /// Community voice badge description
  ///
  /// In en, this message translates to:
  /// **'Receive support from 10 different citizens on verified complaints.'**
  String get badgeCommunityVoiceDesc;

  /// Resolution champion badge title
  ///
  /// In en, this message translates to:
  /// **'Resolution Champion'**
  String get badgeResolutionChampion;

  /// Resolution champion badge description
  ///
  /// In en, this message translates to:
  /// **'Have 5 eligible complaints reach verified resolution.'**
  String get badgeResolutionChampionDesc;

  /// Civic level 1 title
  ///
  /// In en, this message translates to:
  /// **'Civic Starter'**
  String get civicLevelStarter;

  /// Civic level 2 title
  ///
  /// In en, this message translates to:
  /// **'Civic Contributor'**
  String get civicLevelContributor;

  /// Civic level 3 title
  ///
  /// In en, this message translates to:
  /// **'Civic Champion'**
  String get civicLevelChampion;

  /// Civic level 4 title
  ///
  /// In en, this message translates to:
  /// **'Civic Leader'**
  String get civicLevelLeader;

  /// Civic level 5 title
  ///
  /// In en, this message translates to:
  /// **'Civic Hero'**
  String get civicLevelHero;

  /// Zone jurisdiction type
  ///
  /// In en, this message translates to:
  /// **'Zone Jurisdiction'**
  String get jurisdictionZone;

  /// Ward jurisdiction type
  ///
  /// In en, this message translates to:
  /// **'Ward Jurisdiction'**
  String get jurisdictionWard;

  /// Department jurisdiction type
  ///
  /// In en, this message translates to:
  /// **'Department Jurisdiction'**
  String get jurisdictionDepartment;

  /// Role scope jurisdiction type
  ///
  /// In en, this message translates to:
  /// **'Role Scope'**
  String get jurisdictionRole;

  /// Routing ticket pending status
  ///
  /// In en, this message translates to:
  /// **'Pending Ward Officer Review'**
  String get routingTicketPending;

  /// Routing ticket approved status
  ///
  /// In en, this message translates to:
  /// **'Reassignment Approved'**
  String get routingTicketApproved;

  /// Routing ticket rejected status
  ///
  /// In en, this message translates to:
  /// **'Reassignment Rejected'**
  String get routingTicketRejected;

  /// Routing ticket cancelled status
  ///
  /// In en, this message translates to:
  /// **'Ticket Cancelled'**
  String get routingTicketCancelled;

  /// Label indicating translation source is English
  ///
  /// In en, this message translates to:
  /// **'Translated from English'**
  String get translatedFromEnglish;

  /// Label indicating translation source is Hindi
  ///
  /// In en, this message translates to:
  /// **'Translated from Hindi'**
  String get translatedFromHindi;

  /// Label indicating translation source is Marathi
  ///
  /// In en, this message translates to:
  /// **'Translated from Marathi'**
  String get translatedFromMarathi;

  /// Dynamic label indicating translation source language
  ///
  /// In en, this message translates to:
  /// **'Translated from {language}'**
  String translatedFromLanguage(String language);

  /// Label indicating original source is English
  ///
  /// In en, this message translates to:
  /// **'Original — English'**
  String get originalEnglish;

  /// Label indicating original source is Hindi
  ///
  /// In en, this message translates to:
  /// **'Original — Hindi'**
  String get originalHindi;

  /// Label indicating original source is Marathi
  ///
  /// In en, this message translates to:
  /// **'Original — Marathi'**
  String get originalMarathi;

  /// Dynamic label indicating original source language
  ///
  /// In en, this message translates to:
  /// **'Original — {language}'**
  String originalLanguage(String language);

  /// Button to toggle view to original user text
  ///
  /// In en, this message translates to:
  /// **'View original'**
  String get viewOriginal;

  /// Button to toggle view back to translated text
  ///
  /// In en, this message translates to:
  /// **'View translation'**
  String get viewTranslation;

  /// Indicator text when dynamic translation is loading
  ///
  /// In en, this message translates to:
  /// **'Translating...'**
  String get translating;

  /// Message when translation fails or is unavailable
  ///
  /// In en, this message translates to:
  /// **'Translation unavailable'**
  String get translationUnavailable;

  /// Button to retry a failed translation
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryTranslation;

  /// Message when offline and no translation is cached
  ///
  /// In en, this message translates to:
  /// **'Translation unavailable offline'**
  String get translationUnavailableOffline;

  /// Title for complaint rejection dialog and banner
  ///
  /// In en, this message translates to:
  /// **'Complaint Rejected'**
  String get complaintRejected;

  /// Explanatory body for complaint rejected due to AI/manipulated evidence
  ///
  /// In en, this message translates to:
  /// **'The evidence uploaded with this complaint did not pass CivicFix\'\'s authenticity verification and was identified as AI-generated or digitally manipulated.\n\nFor civic complaints, please upload a genuine photo of the issue captured from the actual location.'**
  String get complaintRejectedAuthenticityBody;

  /// Action button to submit a new complaint with genuine evidence
  ///
  /// In en, this message translates to:
  /// **'Report Again'**
  String get reportAgain;

  /// Label for failed evidence verification step
  ///
  /// In en, this message translates to:
  /// **'Evidence Verification Failed'**
  String get evidenceVerificationFailed;

  /// Subtext warning for detected synthetic evidence
  ///
  /// In en, this message translates to:
  /// **'AI-generated or manipulated evidence detected.'**
  String get aiGeneratedEvidenceDetected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
