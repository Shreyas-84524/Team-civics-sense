// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CivicFix';

  @override
  String get appName => 'CivicFix';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get appTagline => 'Citizen Issue Reporting & Governance';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get submit => 'Submit';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get refresh => 'Refresh';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get home => 'Home';

  @override
  String get complaints => 'Complaints';

  @override
  String get reportIssue => 'Report Issue';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get map => 'Map';

  @override
  String get navMap => 'Map';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get languageMarathi => 'Marathi';

  @override
  String get complaint => 'Complaint';

  @override
  String get juniorEngineer => 'Junior Engineer';

  @override
  String get fieldOfficer => 'Field Officer';

  @override
  String get ward => 'Ward';

  @override
  String get department => 'Department';

  @override
  String get statusUnderVerification => 'Under Verification';

  @override
  String get statusReported => 'Reported';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusReopened => 'Reopened';

  @override
  String get trackComplaint => 'Track Complaint';

  @override
  String get viewAll => 'View All';

  @override
  String get submitReport => 'Submit Report';

  @override
  String get continueText => 'Continue';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get assistantHelp => 'Ask Civic Assistant';

  @override
  String get myComplaintsTitle => 'My Complaints';

  @override
  String get recentIssues => 'Recent Civic Reports';

  @override
  String get nearbyHazards => 'Nearby Hazards';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get rewardsTitle => 'Civic Rewards';

  @override
  String get assistantTitle => 'Civic AI Assistant';

  @override
  String get settingsTitle => 'Settings & Preferences';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get operationSuccess => 'Operation completed successfully';

  @override
  String welcomeUser(String userName) {
    return 'Welcome, $userName';
  }

  @override
  String complaintCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString complaints',
      one: '1 complaint',
      zero: 'No complaints',
    );
    return '$_temp0';
  }

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInSubtitle =>
      'Sign in to report civic issues, track community fixes, and participate in your ward.';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'e.g. name@example.com';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get login => 'Login';

  @override
  String get orDivider => 'OR';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get createAccount => 'Create an account';

  @override
  String get govtOfficerLogin => 'Government Officer Login';

  @override
  String get pleaseEnterEmail => 'Please enter your email.';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address.';

  @override
  String get pleaseEnterPassword => 'Please enter your password.';

  @override
  String get incorrectEmailOrPassword => 'Incorrect email or password.';

  @override
  String get googleSignInFailed => 'Google Sign-In failed. Please try again.';

  @override
  String get verifyYourPhone => 'Verify Your Phone';

  @override
  String get verifyPhoneSubtitle =>
      'To prevent duplicate civic complaints and protect community authenticity, verify your mobile number via SMS.';

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get mobileNumberHint => 'e.g. 9876543210';

  @override
  String get sendVerificationCode => 'Send Verification Code';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get enterOtpHint => 'Enter 6-digit OTP';

  @override
  String get verifyAndContinue => 'Verify & Continue';

  @override
  String get changeNumber => 'Change number';

  @override
  String resendCodeIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get resendVerificationCode => 'Resend Verification Code';

  @override
  String get phoneVerifiedSuccess =>
      'Phone verified successfully! Redirecting...';

  @override
  String get codeExpired =>
      'The verification code has expired. Please tap Resend Code to request a new one.';

  @override
  String get invalidVerificationCode => 'Invalid verification code.';

  @override
  String get codeSentViaSms => 'Verification code sent via SMS.';

  @override
  String get failedToSendCode => 'Failed to send verification code.';

  @override
  String get signOut => 'Sign Out';

  @override
  String get createCivicFixAccount => 'Create your CivicFix account';

  @override
  String get civicParticipationStarts =>
      'Your civic participation starts here.';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameHint => 'Enter your full name';

  @override
  String get phoneOptional => 'Phone Number (Optional)';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get preferredLanguage => 'Preferred Language';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters.';

  @override
  String get nameMinLength => 'Name must be at least 2 characters.';

  @override
  String get resetYourPassword => 'Reset your password';

  @override
  String get resetPasswordSubtitle =>
      'Enter the email associated with your account to receive password reset instructions.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get resetLinkSent => 'Password reset instructions have been sent.';

  @override
  String get loadingCivicDashboard => 'Loading civic dashboard...';

  @override
  String get viewAllComplaints => 'View all complaints →';

  @override
  String get viewHazardMap => 'View hazard map →';

  @override
  String get yourCivicProgress => 'Your Civic Progress';

  @override
  String get noComplaintsYet => 'No complaints yet';

  @override
  String get reportIssueToGetStarted => 'Report a civic issue to get started.';

  @override
  String get noImmediateHazards =>
      'No immediate hazards reported in your immediate vicinity.';

  @override
  String get assistantSubtitle => 'Get help with CivicFix';

  @override
  String get rewardsSubtitle => 'View your civic progress';

  @override
  String get reportCivicIssueAction => 'Report a civic issue';

  @override
  String get recentCivicReports => 'Recent Complaints';

  @override
  String get nearbyCivicIssues => 'Nearby Civic Issues';

  @override
  String get issueInformation => 'Issue Information';

  @override
  String get issueInfoSubtitle =>
      'Help us understand the problem so it can reach the right team.';

  @override
  String get issueTitle => 'Issue Title';

  @override
  String get issueTitleHint => 'e.g. Broken street light near the park';

  @override
  String get selectCategoryError => 'Please select an issue category.';

  @override
  String get describeTheIssue => 'Describe the issue';

  @override
  String get describeIssueHint =>
      'Tell us what happened and where you noticed the problem.';

  @override
  String get describeIssueHelp =>
      'Include useful details such as what is damaged, how long it has been happening, or how it affects the area.';

  @override
  String get immediateSafetyHazard => 'Immediate Safety Hazard';

  @override
  String get safetyHazardSubtitle =>
      'Check if this issue poses an immediate risk to citizens or traffic';

  @override
  String get addEvidence => 'Add Evidence';

  @override
  String get addEvidenceSubtitle =>
      'A photo can help the responsible team understand the issue.';

  @override
  String get whereIsTheIssue => 'Where is the issue?';

  @override
  String get whereIsIssueSubtitle =>
      'Add the location so the responsible team can find it.';

  @override
  String get selectLocationError =>
      'Please select or detect the issue location.';

  @override
  String get reviewYourIssue => 'Review your issue';

  @override
  String get reviewIssueSubtitle =>
      'Please verify all information before submitting to your ward.';

  @override
  String get nextAddEvidence => 'Next: Add Evidence';

  @override
  String get nextLocation => 'Next: Location';

  @override
  String get skipAndContinue => 'Skip & Continue';

  @override
  String get nextReview => 'Next: Review';

  @override
  String get discardReportTitle => 'Discard this report?';

  @override
  String get discardReportMessage => 'Your entered information will be lost.';

  @override
  String get keepEditing => 'Keep Editing';

  @override
  String get discard => 'Discard';

  @override
  String get stepInformation => 'Information';

  @override
  String get stepEvidence => 'Evidence';

  @override
  String get stepLocation => 'Location';

  @override
  String get stepReview => 'Review';

  @override
  String get complaintSavedOffline => 'Complaint Saved Offline';

  @override
  String get issueReportedSuccess => 'Issue Reported';

  @override
  String get offlineSubmissionNote =>
      'Complaint saved. It will be submitted when you\'re back online.';

  @override
  String get onlineSubmissionNote =>
      'Your issue has been submitted successfully.';

  @override
  String get localReference => 'Local Reference';

  @override
  String get complaintId => 'Complaint ID';

  @override
  String get status => 'Status';

  @override
  String get pendingSync => 'Pending Sync';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncFailed => 'Sync Failed';

  @override
  String get civicReward => 'Civic Reward';

  @override
  String pointsReward(int count) {
    return '+$count Points';
  }

  @override
  String get viewComplaint => 'View Complaint';

  @override
  String get trackFromMyComplaints =>
      'You can track the progress of this issue from My Complaints.';

  @override
  String get offlineStoredSecurely =>
      'Your complaint is securely stored on this device and will sync once internet is connected.';

  @override
  String get confirmLocation => 'Confirm Location';

  @override
  String get confirmThisLocation => 'Confirm This Location';

  @override
  String get selectedLocation => 'Selected Location';

  @override
  String get tapMapToPositionPin => 'Tap map to position pin';

  @override
  String get searchLocationHint => 'Search street, area or landmark...';

  @override
  String get couldNotAcquireGps =>
      'Could not acquire GPS position. Please adjust pin manually.';

  @override
  String get trackCivicIssuesSubtitle =>
      'Track the civic issues you\'ve reported.';

  @override
  String get searchComplaintsHint => 'Search complaints...';

  @override
  String get all => 'All';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get allCategories => 'All Categories';

  @override
  String complaintsFound(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString complaints found',
      one: '1 complaint found',
      zero: '0 complaints found',
    );
    return '$_temp0';
  }

  @override
  String get clearAll => 'Clear all';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get noComplaintsFound => 'No complaints found';

  @override
  String get tryDifferentSearch => 'Try a different search or filter.';

  @override
  String get filterAndSort => 'Filter & Sort';

  @override
  String get complaintStatus => 'Complaint Status';

  @override
  String get issueCategory => 'Issue Category';

  @override
  String get sortBy => 'Sort By';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get recentlyUpdated => 'Recently Updated';

  @override
  String get newestFirst => 'Newest First';

  @override
  String get oldestFirst => 'Oldest First';

  @override
  String get support => 'Support';

  @override
  String supportsCount(int count) {
    return '$count supports';
  }

  @override
  String get supportedComplaint => 'Supported complaint!';

  @override
  String get alreadySupported => 'You already supported this complaint.';

  @override
  String get safetyHazard => 'Safety Hazard';

  @override
  String updatedTime(String time) {
    return 'Updated $time';
  }

  @override
  String reportedTime(String time) {
    return 'Reported $time';
  }

  @override
  String copiedTicketId(String ticket) {
    return 'Complaint ID $ticket copied.';
  }

  @override
  String get complaintDetails => 'Complaint Details';

  @override
  String get assignedMunicipalTeam => 'Assigned Municipal Team';

  @override
  String get responsibleOfficersSubtitle =>
      'Responsible officers managing and executing your grievance';

  @override
  String get supervisingJuniorEngineer => 'Supervising Junior Engineer';

  @override
  String get supervising => 'Supervising';

  @override
  String get autoRoutingToWard => 'Auto-Routing to Ward Engineer...';

  @override
  String get fieldExecutionOfficer => 'Field Execution Officer';

  @override
  String get pendingFieldAllocation => 'Pending Field Allocation';

  @override
  String get temporarilyOnHold => 'Temporarily On Hold';

  @override
  String get workCompleted => 'Work Completed';

  @override
  String get workInProgress => 'Work In Progress';

  @override
  String get assignedForFieldWork => 'Assigned for Field Work';

  @override
  String get awaitingFieldOfficerAssignment =>
      'Awaiting field officer assignment by the Supervising Junior Engineer.';

  @override
  String groundObstacle(String reason) {
    return 'Ground obstacle: $reason';
  }

  @override
  String get groundWorkPaused =>
      'Ground work is temporarily paused due to site constraints.';

  @override
  String get groundRepairExecuted =>
      'Ground repair executed and verified successfully.';

  @override
  String get reopenedForQualityRework => 'Reopened for Quality Rework';

  @override
  String get supervisoryReviewAction => 'Supervisory Quality Review Action';

  @override
  String get reworkRequired => 'Rework Required';

  @override
  String reworkCycle(int count) {
    return 'Rework Cycle #$count';
  }

  @override
  String get reasonForReopening => 'Reason for Reopening';

  @override
  String get slaPreservedNote =>
      'Original SLA preserved from submission. Priority ground execution underway.';

  @override
  String get resolutionAndVerification => 'Resolution & Work Verification';

  @override
  String get groundInspectionEvidence =>
      'Ground inspection & completion evidence';

  @override
  String get reportedIssueBefore => 'Reported Issue (Before)';

  @override
  String get resolvedConditionAfter => 'Resolved Condition (After)';

  @override
  String get officerResolutionRemarks => 'Officer Resolution Remarks';

  @override
  String executedByOfficer(String officer) {
    return 'Executed by $officer';
  }

  @override
  String resolvedOnDate(String date) {
    return 'Resolved on $date';
  }

  @override
  String get issueResolvedBanner => '✓ Issue Resolved';

  @override
  String get issueResolvedSubtitle =>
      'This complaint has been marked as resolved.';

  @override
  String get currentPhase => 'Current Phase';

  @override
  String get progress => 'Progress';

  @override
  String get updates => 'Updates';

  @override
  String get noUpdatesYet => 'No updates yet.';

  @override
  String reportedOn(String date) {
    return 'Reported on $date';
  }

  @override
  String get viewLocation => 'View Location';

  @override
  String evidencePhotos(int count) {
    return 'Photo Evidence ($count)';
  }

  @override
  String get noPhotosAttached => 'No photos attached (Optional)';

  @override
  String photoPreview(int current, int total) {
    return 'Photo Preview ($current of $total)';
  }

  @override
  String get closePreview => 'Close Preview';

  @override
  String routedToDepartment(String department) {
    return 'This issue will be routed to $department.';
  }

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get allNotificationsMarkedRead => 'All notifications marked as read.';

  @override
  String get unread => 'Unread';

  @override
  String get read => 'Read';

  @override
  String get noUnreadNotifications => 'No unread notifications';

  @override
  String get noUnreadNotificationsDesc =>
      'You have read all updates on your complaints and ward notices.';

  @override
  String get noNotificationsYet => 'No notifications yet.';

  @override
  String get noNotificationsYetDesc =>
      'When there is an update to one of your complaints, it will appear here.';

  @override
  String get citizenProfile => 'Citizen Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get civicContribution => 'Civic Contribution';

  @override
  String get viewAchievements => 'View Achievements';

  @override
  String get reports => 'Reports';

  @override
  String get resolved => 'Resolved';

  @override
  String get civicPoints => 'Civic Points';

  @override
  String get civicEngagement => 'Civic Engagement';

  @override
  String get civicRewardsAndAchievements => 'Civic Rewards & Achievements';

  @override
  String get civicAssistant => 'Civic Assistant';

  @override
  String get assistantSubtitleLong => 'FAQ, complaint rules & category help';

  @override
  String get settingsAndPrivacy => 'Settings & Privacy';

  @override
  String get notificationPreferences => 'Notification Preferences';

  @override
  String get notificationPreferencesSubtitle =>
      'Status alerts, hazard warnings & sound';

  @override
  String get privacyAndSafety => 'Privacy & Safety';

  @override
  String get privacyAndSafetySubtitle =>
      'Confidentiality and public map policy';

  @override
  String get aboutCivicFix => 'About CivicFix';

  @override
  String get aboutCivicFixSubtitle =>
      'Mission, governance model, and technology';

  @override
  String get logout => 'Log Out';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to log out?';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully.';

  @override
  String get profileUpdateFailed =>
      'Couldn\'t update profile. Please try again.';

  @override
  String get viewDetails => 'View Details';

  @override
  String get closeComplaintCard => 'Close complaint card';

  @override
  String get searchHazardsHint => 'Search hazards or complaints...';

  @override
  String get unableToOpenComplaint => 'Unable to open this complaint.';

  @override
  String get complaintBelongsToOther =>
      'This report belongs to a different citizen account.';

  @override
  String get backToMyComplaints => 'Back to My Complaints';

  @override
  String get complaintNotFound => 'Complaint not found.';

  @override
  String get complaintNotFoundDesc =>
      'This complaint may no longer be available.';

  @override
  String get couldNotLoadComplaint => 'Couldn\'t load this complaint.';

  @override
  String get couldNotLoadNotifications => 'Couldn\'t load notifications.';

  @override
  String get checkConnectionAndRetry =>
      'Please check your connection and try again.';

  @override
  String get pleaseEnterName => 'Please enter your name.';

  @override
  String get pleaseEnterValidPhone =>
      'Please enter a valid phone number (at least 10 digits).';

  @override
  String get passwordMinCharsHint => 'Minimum 8 characters';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password.';

  @override
  String get accountCreatedSuccess => 'Account created successfully.';

  @override
  String get registrationFailed => 'Registration failed. Please try again.';

  @override
  String get createAccountBtn => 'Create Account';

  @override
  String get changeAction => 'Change';

  @override
  String get verificationCodeHint => 'Enter 6-digit OTP';

  @override
  String get pleaseEnterVerificationCode =>
      'Please enter the verification code.';

  @override
  String get verificationCodeMinLength =>
      'Verification code must be at least 4 digits.';

  @override
  String get unableToResendCode => 'Unable to resend verification code.';

  @override
  String get enterRegisteredEmail => 'Enter your registered email';

  @override
  String get passwordResetSent => 'Password reset instructions have been sent.';

  @override
  String get unableToProcessReset => 'Unable to process reset request.';

  @override
  String get navHome => 'Home';

  @override
  String get navComplaints => 'Complaints';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navProfile => 'Profile';

  @override
  String get loadingDashboard => 'Loading civic dashboard...';

  @override
  String get unableToLoadUpdates =>
      'Unable to load civic updates. Please try again.';

  @override
  String get assistant => 'Assistant';

  @override
  String get reportToGetStarted => 'Report a civic issue to get started.';

  @override
  String get noNearbyHazards =>
      'No immediate hazards reported in your immediate vicinity.';

  @override
  String get issueInformationTitle => 'Issue Information';

  @override
  String get issueInformationSubtitle =>
      'Help us understand the problem so it can reach the right team.';

  @override
  String get issueTitleLabel => 'Issue Title';

  @override
  String get pleaseEnterIssueTitle => 'Please enter a title for the issue.';

  @override
  String get issueTitleMinLength => 'Title must be at least 5 characters.';

  @override
  String get pleaseSelectCategory => 'Please select an issue category.';

  @override
  String get pleaseDescribeIssue => 'Please describe the issue.';

  @override
  String get describeIssueMinLength =>
      'Description must be at least 10 characters.';

  @override
  String get describeIssueHelper =>
      'Include useful details such as what is damaged, how long it has been happening, or how it affects the area.';

  @override
  String get addLocationSubtitle =>
      'Add the location so the responsible team can find it.';

  @override
  String get submitIssue => 'Submit Issue';

  @override
  String get supervisingStatus => 'Supervising';

  @override
  String get routingStatus => 'Routing...';

  @override
  String get awaitingFieldAllocationNote =>
      'Awaiting field officer assignment by the Supervising Junior Engineer.';

  @override
  String get groundRepairVerified =>
      'Ground repair executed and verified successfully.';

  @override
  String get executionUnderway => 'Execution currently underway on site.';

  @override
  String get fieldOfficerAllocatedNote =>
      'Field officer allocated. Ground operations scheduled.';

  @override
  String get originalSlaPreserved =>
      'Original SLA preserved from submission. Priority ground execution underway.';

  @override
  String get resolutionAndWorkVerification => 'Resolution & Work Verification';

  @override
  String get issueReportedTitle => 'Issue Reported';

  @override
  String get issueSubmittedSuccess =>
      'Your issue has been submitted successfully.';

  @override
  String get plusTwentyPoints => '+20 Points';

  @override
  String get storedLocallyNote =>
      'Your complaint is securely stored on this device and will sync once internet is connected.';

  @override
  String get trackFromMyComplaintsNote =>
      'You can track the progress of this issue from My Complaints.';

  @override
  String get noComplaintsFoundDesc => 'Try a different search or filter.';

  @override
  String get noComplaintsReportedYet => 'No complaints reported yet';

  @override
  String get supportedComplaintSuccess => 'Supported complaint!';

  @override
  String get alreadySupportedComplaint =>
      'You already supported this complaint.';

  @override
  String get statusVerified => 'Verified';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get loadingComplaints => 'Loading your complaints...';

  @override
  String get failedToLoadComplaints => 'Couldn\'t load your complaints.';

  @override
  String get reportCivicIssueTrackProgress =>
      'Report a civic issue and track its progress here.';

  @override
  String get reportAnIssue => 'Report an Issue';

  @override
  String get trackCivicIssuesReported =>
      'Track the civic issues you\'ve reported.';

  @override
  String get clearSearch => 'Clear search';

  @override
  String complaintIdCopied(String ticketNumber) {
    return 'Complaint ID $ticketNumber copied.';
  }

  @override
  String get locationSelected => 'Location selected';

  @override
  String get supports => 'supports';

  @override
  String get closeFilters => 'Close Filters';

  @override
  String get noComplaintSpecified => 'No complaint specified.';

  @override
  String get waitingForConnection => 'Waiting for connection';

  @override
  String get complaintStoredSecurelyOffline =>
      'Your complaint is stored securely on this device and will be submitted once internet is available.';

  @override
  String get synchronizingWithCloud => 'Synchronizing with Cloud';

  @override
  String get uploadingComplaintData =>
      'Uploading complaint data and evidence to the municipal network...';

  @override
  String get synchronizationFailed => 'Synchronization Failed';

  @override
  String get failedToSyncWithCloud =>
      'Failed to synchronize this report with the cloud backend. Check connection and retry.';

  @override
  String get retrySync => 'Retry Sync';

  @override
  String get complaintMarkedResolved =>
      'This complaint has been marked as resolved.';

  @override
  String reportedOnDate(String date) {
    return 'Reported on $date';
  }

  @override
  String lastUpdatedTime(String time) {
    return 'Last updated $time';
  }

  @override
  String get wardLabel => 'Ward';

  @override
  String get central => 'Central';

  @override
  String get groundWorkTemporarilyPaused =>
      'Ground work is temporarily paused due to site constraints.';

  @override
  String commencedTime(String time) {
    return 'Commenced $time.';
  }

  @override
  String get executionUnderwayOnSite => 'Execution currently underway on site.';

  @override
  String get pendingAllocation => 'Pending Allocation';

  @override
  String get defaultReopenReason =>
      'Work quality did not meet municipal standards upon audit review. Reassigned for corrective action.';

  @override
  String get deptLeadQualityAudit => 'Department Lead Quality Audit';

  @override
  String get reviewedBy => 'Reviewed by';

  @override
  String get slaPreservedPriorityExecution =>
      'Original SLA preserved from submission. Priority ground execution underway.';

  @override
  String get hidePreviousResolutionRecord => 'Hide Previous Resolution Record';

  @override
  String get viewPreviousResolutionRecord => 'View Previous Resolution Record';

  @override
  String get photos => 'photos';

  @override
  String get priorResolutionTimestamp => 'Prior resolution timestamp';

  @override
  String executedBy(String name) {
    return 'Executed by $name';
  }

  @override
  String get progressTracker => 'Progress Tracker';

  @override
  String get stage => 'Stage';

  @override
  String get ofFive => 'of 5';

  @override
  String get currentCaps => 'CURRENT';

  @override
  String get categoryLabel => 'Category';

  @override
  String get departmentLabel => 'Department';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get noDescriptionProvided => 'No additional description provided.';

  @override
  String get landmark => 'Landmark';

  @override
  String get jurisdiction => 'Jurisdiction';

  @override
  String get updatesTitle => 'Updates';

  @override
  String get entry => 'entry';

  @override
  String get entries => 'entries';

  @override
  String get hazardMapTitle => 'Hazard Map';

  @override
  String get couldNotLoadCivicIssues => 'Couldn\'t load civic issues.';

  @override
  String get checkConnectionRetry =>
      'Please check your connection and try again.';

  @override
  String get loadingHazardMap => 'Loading civic hazard map...';

  @override
  String get offlineCachedHazardsBanner =>
      'Offline — Showing cached hazards. Basemap tiles require network.';

  @override
  String get locationServicesDisabled =>
      'Location services are disabled on your device.';

  @override
  String get locationPermissionRequired =>
      'Location permission is required to center the map.';

  @override
  String centeredOnLocation(String wardText) {
    return 'Centered on your location$wardText';
  }

  @override
  String get unableToDetermineLocation =>
      'Unable to determine your location. Please try again.';

  @override
  String get gpsTimeoutRetry => 'GPS acquisition timed out. Please retry.';

  @override
  String get hideHeatmapLayer => 'Hide Heatmap Layer';

  @override
  String get showHeatmapLayer => 'Show Heatmap Layer';

  @override
  String get toggleMapLegend => 'Toggle Map Legend';

  @override
  String get useMyLocation => 'Use My Location';

  @override
  String get zoomIn => 'Zoom In';

  @override
  String get zoomOut => 'Zoom Out';

  @override
  String get statusLegend => 'Status Legend';

  @override
  String get civicIssuesNearYou => 'civic issues near you';

  @override
  String get noCivicIssuesFound => 'No civic issues found.';

  @override
  String get tryChangingFiltersOrSearch =>
      'Try changing your filters or search.';

  @override
  String get logoutConfirmationTitle => 'Log out?';

  @override
  String get logoutConfirmationDesc => 'Are you sure you want to log out?';

  @override
  String get viewMilestones => 'View Milestones';

  @override
  String get civicAssistantSubtitle => 'FAQ, complaint rules & category help';

  @override
  String get accountAndPreferences => 'Account & Preferences';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get systemDefault => 'System Default';

  @override
  String get lightTheme => 'Light Theme';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get appVersion => 'App Version';

  @override
  String get actions => 'Actions';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String get emailCannotBeChanged =>
      'Email cannot be changed for citizen account.';

  @override
  String get phoneHelperText =>
      'Used for SMS updates on urgent neighborhood alerts.';

  @override
  String get registeredCitizenAccount => 'Registered Citizen Account';

  @override
  String get citizen => 'Citizen';

  @override
  String get nameTooShort => 'Name must be at least 2 characters long.';

  @override
  String get nameTooLong => 'Name cannot exceed 50 characters.';

  @override
  String get phoneInvalid => 'Please enter a valid 10-digit phone number.';

  @override
  String get discardReportDesc => 'Your entered information will be lost.';

  @override
  String get filterCivicIssues => 'Filter Civic Issues';

  @override
  String get closeFilter => 'Close filter';

  @override
  String get hazardCategory => 'Hazard Category';

  @override
  String get issueStatus => 'Issue Status';

  @override
  String get reportTimeframe => 'Report Timeframe';

  @override
  String get civicStanding => 'Civic Standing';

  @override
  String get tierProgress => 'Contribution Tier Progress';

  @override
  String get totalPoints => 'Total Points';

  @override
  String get reportsFiled => 'Reports Filed';

  @override
  String get resolvedFixes => 'Resolved Fixes';

  @override
  String get selectCategorySubtitle =>
      'Select the category that best matches the problem.';

  @override
  String get stepInfo => 'Information';

  @override
  String get recentComplaints => 'Recent Complaints';

  @override
  String get rewards => 'Rewards';

  @override
  String resendCodeInSeconds(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get immediateSafetyHazardTitle => 'Immediate Safety Hazard';

  @override
  String get addEvidenceTitle => 'Add Evidence';

  @override
  String get aiFallbackReviewTitle => 'Under Departmental Review';

  @override
  String get aiFallbackReviewMessage =>
      'Automated verification is temporarily unavailable. Your grievance has been routed for departmental review. SLA is active and resolution is progressing normally.';

  @override
  String get aiFallbackConfirmedMessage =>
      'Department confirmed via manual review. Auto-routed to Junior Engineer.';

  @override
  String get aiFallbackTransferredMessage =>
      'Transferred to another BMC department via manual review.';

  @override
  String get useDeviceLocation => 'Use Device Location';

  @override
  String get selectOnMap => 'Select on Map';

  @override
  String get centerOnGps => 'Center on My GPS';

  @override
  String get verifyBeforeSubmitting =>
      'Please verify all information before submitting to your ward.';

  @override
  String get markedImmediateSafetyHazard => 'Marked as Immediate Safety Hazard';

  @override
  String photoEvidenceCount(int count) {
    return 'Photo Evidence ($count)';
  }

  @override
  String nearLandmark(String landmark) {
    return 'Near $landmark';
  }

  @override
  String landmarkLabel(String landmark) {
    return 'Landmark: $landmark';
  }

  @override
  String jurisdictionLabel(String ward) {
    return 'Jurisdiction: $ward';
  }

  @override
  String issueRoutedTo(String department) {
    return 'This issue will be routed to $department.';
  }

  @override
  String get categoryRoads => 'Roads';

  @override
  String get categoryRoadsDesc =>
      'Road damage, potholes and unsafe road surfaces.';

  @override
  String get categoryWater => 'Water';

  @override
  String get categoryWaterDesc =>
      'Water supply issues, leakage or contamination.';

  @override
  String get categorySanitation => 'Sanitation';

  @override
  String get categorySanitationDesc =>
      'Public hygiene, public toilets and street cleanliness.';

  @override
  String get categoryWaste => 'Waste Management';

  @override
  String get categoryWasteDesc =>
      'Garbage accumulation and waste collection issues.';

  @override
  String get categoryStreetlights => 'Street Lights';

  @override
  String get categoryStreetlightsDesc =>
      'Broken or non-functioning street lights.';

  @override
  String get categoryDrainage => 'Drainage';

  @override
  String get categoryDrainageDesc =>
      'Blocked drains, water logging, open manholes.';

  @override
  String get categoryInfrastructure => 'Public Infrastructure';

  @override
  String get categoryInfrastructureDesc =>
      'Damaged footpaths, bridges, bus shelters.';

  @override
  String get categoryTraffic => 'Traffic / Road Safety';

  @override
  String get categoryTrafficDesc =>
      'Damaged signs, missing signals, hazardous intersections.';

  @override
  String get categoryOther => 'Other';

  @override
  String get categoryOtherDesc =>
      'Other public infrastructure or municipal maintenance issues.';

  @override
  String get categoryPotholes => 'Potholes';

  @override
  String get categoryGarbageOverflow => 'Garbage Overflow';

  @override
  String get categoryWaterlogging => 'Waterlogging';

  @override
  String get categoryWaterLeakage => 'Water Leakage';

  @override
  String get categoryDamagedWater => 'Damaged Water Infrastructure';

  @override
  String get categorySewageOverflow => 'Sewage Overflow';

  @override
  String get categoryManholes => 'Open Manholes';

  @override
  String get categoryFootpaths => 'Damaged Footpaths';

  @override
  String get categoryTrees => 'Fallen / Dangerous Trees';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityEmergency => 'Critical';

  @override
  String get deptRoadsTraffic => 'Roads & Traffic Department';

  @override
  String get deptSolidWaste => 'Solid Waste Management';

  @override
  String get deptWaterSewerage => 'Water Supply & Sewerage';

  @override
  String get deptElectricalStreetlights => 'Electrical & Street Lighting';

  @override
  String get deptStormDrainage => 'Storm Water Drainage';

  @override
  String get deptPublicHealth => 'Public Health Department';

  @override
  String get deptGardensTrees => 'Gardens & Tree Authority';

  @override
  String get deptBuildingInfrastructure => 'Building & Infrastructure';

  @override
  String get deptGeneral => 'General Municipal Desk';

  @override
  String get verificationPending => 'Verification Pending';

  @override
  String get verificationProcessing => 'Analyzing & Verifying...';

  @override
  String get verificationPassed => 'Verification Passed';

  @override
  String get verificationFailed => 'Verification Failed';

  @override
  String get verificationDelayed => 'Automated Verification Delayed';

  @override
  String get verificationOfficerReview => 'Department Officer Review';

  @override
  String get verificationCompleted => 'Verification Completed';

  @override
  String get routingUnassigned => 'Unassigned';

  @override
  String get routingAssigned => 'Assigned';

  @override
  String get routingReassignmentRequested => 'Reassignment Requested';

  @override
  String get routingTransferred => 'Transferred';

  @override
  String get routingInProgress => 'In Progress';

  @override
  String get routingResolved => 'Resolved';

  @override
  String get assignmentUnassigned => 'Unassigned';

  @override
  String get assignmentLeadAssigned => 'Assigned to Ward Lead';

  @override
  String get assignmentCrewAssigned => 'Assigned to Ground Crew';

  @override
  String get assignmentFieldOfficerAssigned => 'Assigned to Field Officer';

  @override
  String get syncSynced => 'Synced';

  @override
  String get syncPending => 'Pending Sync';

  @override
  String get syncSyncing => 'Syncing...';

  @override
  String get basemapStyle => 'Basemap Style';

  @override
  String get chooseMapViewMode => 'Choose map view and imagery mode';

  @override
  String get basemapStreets => 'Streets';

  @override
  String get basemapStreetsDesc =>
      'Detailed vector road networks, wards, and civic infrastructure';

  @override
  String get basemapSatellite => 'Satellite';

  @override
  String get basemapSatelliteDesc =>
      'High-resolution aerial and satellite photographic imagery';

  @override
  String get basemapHybrid => 'Hybrid';

  @override
  String get basemapHybridDesc =>
      'Satellite imagery overlaid with street names, borders, and locality labels';

  @override
  String get badgeFirstReport => 'First Report';

  @override
  String get badgeFirstReportDesc => 'Submitted your first civic grievance';

  @override
  String get badgeActiveCitizen => 'Active Citizen';

  @override
  String get badgeActiveCitizenDesc => 'Reported 5 or more civic issues';

  @override
  String get badgeNeighborhoodHero => 'Neighborhood Hero';

  @override
  String get badgeNeighborhoodHeroDesc =>
      'Had 10 issues resolved in your community';

  @override
  String get badgeSharpEye => 'Sharp Eye';

  @override
  String get badgeSharpEyeDesc => 'Reported an immediate safety hazard';

  @override
  String get badgeCommunityPillar => 'Community Pillar';

  @override
  String get badgeCommunityPillarDesc => 'Achieved 500+ Civic Points';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get locked => 'Locked';

  @override
  String get howToUnlock => 'How to Unlock';

  @override
  String get communityPerks => 'Community Perks';

  @override
  String get communityPerksSubtitle =>
      'Redeem your points for local government & partner benefits';

  @override
  String get claimPerk => 'Claim';

  @override
  String get yourContribution => 'Your Contribution';

  @override
  String get totalReports => 'Total Reports';

  @override
  String get resolvedReports => 'Resolved Reports';

  @override
  String get pointsEarned => 'Points Earned';

  @override
  String get achievements => 'Achievements';

  @override
  String get achievementsSubtitle =>
      'Earn badges for active neighborhood participation';

  @override
  String get loadingRewards => 'Loading your civic milestones...';

  @override
  String get allNotificationsMarkedAsRead =>
      'All notifications marked as read.';

  @override
  String get filterAll => 'All';

  @override
  String get filterUnread => 'Unread';

  @override
  String get filterRead => 'Read';

  @override
  String get logOutQuestion => 'Log out?';

  @override
  String get logoutConfirmationMessage => 'Are you sure you want to log out?';

  @override
  String get clearChat => 'Clear Chat';

  @override
  String get assistantThinking => 'Assistant is thinking...';

  @override
  String get assistantMessageHint =>
      'Ask about reporting, tracking, or categories...';

  @override
  String get resolutionWorkVerification => 'Resolution & Work Verification';

  @override
  String get groundInspectionSubtitle =>
      'Ground inspection & completion evidence';

  @override
  String get govPortalTitle => 'CivicFix Government Portal';

  @override
  String get govLoginTitle => 'Government Officer Sign In';

  @override
  String get govLoginSubtitle =>
      'Secure administrative access for BMC municipal officers';

  @override
  String get govEmployeeIdOrEmail => 'Employee ID or Official Email';

  @override
  String get govPassword => 'Password';

  @override
  String get govSignInButton => 'Sign In to Portal';

  @override
  String get govInvalidCredentials =>
      'Invalid employee ID, email, or password.';

  @override
  String get govAccountDisabled =>
      'Account is deactivated. Contact Municipal Administrator.';

  @override
  String get govSessionExpired => 'Session has expired. Please sign in again.';

  @override
  String get govAccessDenied => 'Access Denied';

  @override
  String get govAccessDeniedDesc =>
      'You do not have administrative privileges to access this area.';

  @override
  String get govReturnToDashboard => 'Return to Dashboard';

  @override
  String get govAuthenticating => 'Verifying administrative credentials...';

  @override
  String get govForgotPassword => 'Forgot Password';

  @override
  String get govResetPasswordInstruction =>
      'Enter your registered official email to receive password reset instructions.';

  @override
  String get govSendResetLink => 'Send Reset Link';

  @override
  String get govNavDashboard => 'Dashboard';

  @override
  String get govNavComplaints => 'Complaints';

  @override
  String get govNavHazardMap => 'Hazard Map';

  @override
  String get govNavAnalytics => 'Analytics';

  @override
  String get govNavProfile => 'Profile';

  @override
  String get govNavMyWork => 'My Work';

  @override
  String get govNavOperations => 'Operations';

  @override
  String get govNavSla => 'SLA Monitor';

  @override
  String get govNavHistory => 'Audit History';

  @override
  String get govNavVerification => 'Verification Queue';

  @override
  String get govNavAssignments => 'Assignments';

  @override
  String get govExecutiveDashboard => 'Executive Dashboard';

  @override
  String get govGrievanceManagement => 'Grievance Management';

  @override
  String get govLiveHazardGisMap => 'Live Hazard GIS Map';

  @override
  String get govOperationalAnalytics => 'Operational Analytics';

  @override
  String get govOfficerProfileSettings => 'Officer Profile & Settings';

  @override
  String get govCollapseSidebar => 'Collapse sidebar';

  @override
  String get govExpandSidebar => 'Expand sidebar';

  @override
  String get govMunicipalCorporation => 'Brihanmumbai Municipal Corporation';

  @override
  String get govRoleSuperAdmin => 'Municipal Commissioner / Super Admin';

  @override
  String get govRoleZonalDmc => 'Zonal Deputy Municipal Commissioner';

  @override
  String get govRoleCentralHod => 'Central Department Head of Department';

  @override
  String get govRoleWardOfficer =>
      'Assistant Municipal Commissioner (Ward Officer)';

  @override
  String get govRoleWardLead => 'Ward Department Lead';

  @override
  String get govRoleDepartmentCrew =>
      'Junior Engineer / Field Execution Officer';

  @override
  String get govRoleAssistantEngineer => 'Assistant Engineer';

  @override
  String get govRoleExecutiveEngineer => 'Executive Engineer';

  @override
  String get govRoleSubEngineer => 'Sub-Engineer';

  @override
  String get govRoleMedicalOfficer => 'Medical Officer of Health';

  @override
  String get govRoleSuperintendent => 'Assistant Superintendent';

  @override
  String get deptMaintenanceRoads => 'Roads & Maintenance';

  @override
  String get deptWaterWorks => 'Water Works & Supply';

  @override
  String get deptSolidWasteManagement => 'Solid Waste Management';

  @override
  String get deptBuildingFactory => 'Building & Factory';

  @override
  String get deptGardenTrees => 'Gardens & Trees';

  @override
  String get deptPestControlInsecticide => 'Pest Control & Insecticide';

  @override
  String get deptEncroachment => 'Encroachment Removal';

  @override
  String get deptLicence => 'Licence Department';

  @override
  String get deptShopsEstablishments => 'Shops & Establishments';

  @override
  String get deptAssessmentCollection => 'Assessment & Collection';

  @override
  String get deptEstate => 'Estate Department';

  @override
  String get deptColonySlum => 'Colony & Slum Improvement';

  @override
  String get deptEducationSchools => 'Education & Municipal Schools';

  @override
  String get deptSecurity => 'Security Force';

  @override
  String get deptLegal => 'Legal Department';

  @override
  String get deptAdministrationEstablishment =>
      'Administration & Establishment';

  @override
  String get deptTownPlanning => 'Town Planning & Development Plan';

  @override
  String get govPendingComplaints => 'Pending Complaints';

  @override
  String get govAssignedComplaints => 'Assigned Complaints';

  @override
  String get govInProgressComplaints => 'Work In Progress';

  @override
  String get govResolvedComplaints => 'Resolved Complaints';

  @override
  String get govOverdueComplaints => 'Overdue Grievances';

  @override
  String get govSlaBreaches => 'SLA Breaches';

  @override
  String get govAwaitingVerification => 'Awaiting Verification';

  @override
  String get govReworkRequired => 'Rework Required';

  @override
  String get govTodayTasks => 'Today\'s Operational Tasks';

  @override
  String get govRecentActivity => 'Recent Department Activity';

  @override
  String get govWardSummary => 'Ward Performance Summary';

  @override
  String get govDepartmentSummary => 'Department Operational Summary';

  @override
  String get govResolutionRate => 'Resolution Rate';

  @override
  String get govAvgResolutionTime => 'Avg. Resolution Time';

  @override
  String get govTotalGrievances => 'Total Grievances';

  @override
  String get govCriticalHazards => 'Critical Hazards';

  @override
  String get govActiveFieldCrew => 'Active Field Crews';

  @override
  String get govMyWorkTitle => 'My Assigned Work';

  @override
  String get govStartJob => 'Start Work on Site';

  @override
  String get govWorkStarted => 'Work Commenced';

  @override
  String get govUploadBeforeEvidence => 'Upload Before Evidence';

  @override
  String get govUploadAfterEvidence => 'Upload After / Completion Evidence';

  @override
  String get govAddWorkRemarks => 'Add Execution Remarks';

  @override
  String get govMarkBlocked => 'Mark Work as Blocked';

  @override
  String get govResumeWork => 'Resume Work';

  @override
  String get govSubmitResolution => 'Submit for Resolution Review';

  @override
  String get govBlockedReasonLabel => 'Reason for Delay / Blockage';

  @override
  String get govWorkInProgressBanner => 'Execution in progress on site.';

  @override
  String get govWorkCompletedBanner =>
      'Work completed and submitted for audit.';

  @override
  String get govComplaintDetailsTitle => 'Grievance Inspection & Audit';

  @override
  String get govCitizenDetails => 'Citizen Information';

  @override
  String get govIssueDetails => 'Issue Particulars';

  @override
  String get govVerificationResult => 'Verification State';

  @override
  String get govAiVerification => 'Automated AI Verification';

  @override
  String get govManualReviewRequired => 'Manual Verification Required';

  @override
  String get govAiCouldNotVerify =>
      'AI could not determine department with high confidence.';

  @override
  String get govApproveAndRoute => 'Approve & Route';

  @override
  String get govRejectGrievance => 'Reject Grievance';

  @override
  String get govOverrideDepartment => 'Override Department / Category';

  @override
  String get govSelectTargetDepartment => 'Select Target Department';

  @override
  String get govReviewNotesLabel => 'Officer Review Remarks';

  @override
  String get govConfirmDepartment => 'Confirm Department Assignment';

  @override
  String get govAuditTimeline => 'Grievance Timeline & Audit History';

  @override
  String get govAssignOfficer => 'Assign Grievance';

  @override
  String get govAssignedOfficerLabel => 'Assigned Field Officer';

  @override
  String get govAssignFieldOfficer => 'Assign Field Execution Officer';

  @override
  String get govReassignOfficer => 'Reassign Grievance';

  @override
  String get govAvailableOfficers => 'Available Field Officers';

  @override
  String get govOfficerWorkload => 'Active Workload';

  @override
  String get govConfirmAssignment => 'Confirm Assignment';

  @override
  String get govCancelAssignment => 'Cancel';

  @override
  String govAssignmentSuccess(String officerName) {
    return 'Grievance successfully assigned to $officerName.';
  }

  @override
  String get govAssignmentFailed =>
      'Failed to assign officer. Please try again.';

  @override
  String get govSlaStatus => 'SLA Compliance';

  @override
  String get govWithinSla => 'Within SLA Target';

  @override
  String get govApproachingSlaDeadline => 'Approaching SLA Deadline';

  @override
  String get govSlaBreached => 'SLA Breached';

  @override
  String govHoursRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours remaining',
      one: '1 hour remaining',
    );
    return '$_temp0';
  }

  @override
  String govDaysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days remaining',
      one: '1 day remaining',
    );
    return '$_temp0';
  }

  @override
  String govDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String govHoursOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours overdue',
      one: '1 hour overdue',
    );
    return '$_temp0';
  }

  @override
  String get govResolutionReview => 'Resolution Quality Audit';

  @override
  String get govApproveResolution => 'Approve & Close Complaint';

  @override
  String get govSendForRework => 'Send for Rework';

  @override
  String get govReworkReasonLabel => 'Reason for Rework';

  @override
  String get govCloseComplaint => 'Close Grievance';

  @override
  String get govReopenComplaint => 'Reopen Grievance';

  @override
  String get govTableHeaderId => 'Ticket Number';

  @override
  String get govTableHeaderCategory => 'Category';

  @override
  String get govTableHeaderWard => 'Ward';

  @override
  String get govTableHeaderDepartment => 'Department';

  @override
  String get govTableHeaderStatus => 'Status';

  @override
  String get govTableHeaderPriority => 'Priority';

  @override
  String get govTableHeaderSla => 'SLA Remaining';

  @override
  String get govTableHeaderReported => 'Reported On';

  @override
  String get govTableHeaderActions => 'Actions';

  @override
  String get govSearchComplaintsHint =>
      'Search by ticket number, citizen name, locality...';

  @override
  String get govNoMatchingComplaints => 'No matching grievances found.';

  @override
  String get govAllWards => 'All Wards';

  @override
  String get govAllDepartments => 'All Departments';

  @override
  String get govAllStatuses => 'All Statuses';

  @override
  String get govRowsPerPage => 'Rows per page';

  @override
  String get govPreviousPage => 'Previous';

  @override
  String get govNextPage => 'Next';

  @override
  String get govOfficerProfile => 'Government Officer Profile';

  @override
  String get govOfficerName => 'Officer Name';

  @override
  String get govEmployeeId => 'Employee ID';

  @override
  String get govOfficialEmail => 'Official Email';

  @override
  String get govDesignation => 'Official Designation';

  @override
  String get govJurisdiction => 'Assigned Jurisdiction';

  @override
  String get govCitywide => 'Citywide (All Zones & Wards)';

  @override
  String govWardJurisdiction(String wardName) {
    return 'Ward $wardName';
  }

  @override
  String govZoneJurisdiction(String zoneName) {
    return 'Zone $zoneName';
  }

  @override
  String get govSignOut => 'Sign Out of Government Portal';

  @override
  String get govSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get govLanguageSettings => 'Portal Language';

  @override
  String get govAppearanceSettings => 'Theme & Density';

  @override
  String get govPrivacyPrinciples => 'Governance & Data Standards';

  @override
  String get govAboutPortal => 'About Municipal Portal';

  @override
  String get govVersionInfo => 'CivicFix Governance Suite v1.0.0-gov';

  @override
  String get govDashboard => 'Municipal Operations Overview';

  @override
  String get govDashboardSubtitle =>
      'Real-time grievance telemetry & nodal department workload';

  @override
  String get govTotalComplaints => 'Total Grievances';

  @override
  String get govReportedComplaints => 'Reported / New';

  @override
  String get details => 'Details';

  @override
  String get unassignedOfficer => 'Unassigned';

  @override
  String get govInspectAction => 'View Details';

  @override
  String get govUpdateStatus => 'Update Status';

  @override
  String get executionNotStarted => 'Ready to Start';

  @override
  String get executionInProgress => 'Execution In Progress';

  @override
  String get executionBlocked => 'Execution Blocked';

  @override
  String get executionAwaitingEvidence => 'Awaiting Ground Evidence';

  @override
  String get executionCompleted => 'Work Completed';

  @override
  String get resolutionPending => 'Resolution Pending';

  @override
  String get resolutionSubmitted => 'Resolution Submitted';

  @override
  String get resolutionApproved => 'Resolution Approved';

  @override
  String get resolutionRejected => 'Resolution Rejected';

  @override
  String get resolutionClosed => 'Resolution Closed';

  @override
  String get reworkNotRequired => 'No Rework Required';

  @override
  String get reworkRequiredState => 'Rework Required';

  @override
  String get reworkInProgress => 'Rework In Progress';

  @override
  String get reworkSubmitted => 'Rework Submitted';

  @override
  String get reworkApproved => 'Rework Approved';

  @override
  String get syncOffline => 'Offline Queue';

  @override
  String get syncRetrying => 'Retrying Sync...';

  @override
  String get notifComplaintSubmitted => 'Complaint Submitted';

  @override
  String get notifComplaintVerified => 'Complaint Verified';

  @override
  String get notifComplaintAssigned => 'Complaint Assigned';

  @override
  String get notifComplaintStatusChanged => 'Status Updated';

  @override
  String get notifComplaintResolved => 'Complaint Resolved';

  @override
  String get notifGeneralCivic => 'Civic Announcement';

  @override
  String get notifHazardAlert => 'Hazard Warning';

  @override
  String get notifRewardEarned => 'Reward Earned';

  @override
  String get notifSlaWarning => 'SLA Deadline Warning';

  @override
  String get notifReworkRequested => 'Rework Requested';

  @override
  String get badgeGroundReporter => 'Ground Reporter';

  @override
  String get badgeGroundReporterDesc =>
      'Provide accurate coordinates matching the assigned ward on 5 verified complaints.';

  @override
  String get badgeCommunityVoice => 'Community Voice';

  @override
  String get badgeCommunityVoiceDesc =>
      'Receive support from 10 different citizens on verified complaints.';

  @override
  String get badgeResolutionChampion => 'Resolution Champion';

  @override
  String get badgeResolutionChampionDesc =>
      'Have 5 eligible complaints reach verified resolution.';

  @override
  String get civicLevelStarter => 'Civic Starter';

  @override
  String get civicLevelContributor => 'Civic Contributor';

  @override
  String get civicLevelChampion => 'Civic Champion';

  @override
  String get civicLevelLeader => 'Civic Leader';

  @override
  String get civicLevelHero => 'Civic Hero';

  @override
  String get jurisdictionZone => 'Zone Jurisdiction';

  @override
  String get jurisdictionWard => 'Ward Jurisdiction';

  @override
  String get jurisdictionDepartment => 'Department Jurisdiction';

  @override
  String get jurisdictionRole => 'Role Scope';

  @override
  String get routingTicketPending => 'Pending Ward Officer Review';

  @override
  String get routingTicketApproved => 'Reassignment Approved';

  @override
  String get routingTicketRejected => 'Reassignment Rejected';

  @override
  String get routingTicketCancelled => 'Ticket Cancelled';

  @override
  String get translatedFromEnglish => 'Translated from English';

  @override
  String get translatedFromHindi => 'Translated from Hindi';

  @override
  String get translatedFromMarathi => 'Translated from Marathi';

  @override
  String translatedFromLanguage(String language) {
    return 'Translated from $language';
  }

  @override
  String get originalEnglish => 'Original — English';

  @override
  String get originalHindi => 'Original — Hindi';

  @override
  String get originalMarathi => 'Original — Marathi';

  @override
  String originalLanguage(String language) {
    return 'Original — $language';
  }

  @override
  String get viewOriginal => 'View original';

  @override
  String get viewTranslation => 'View translation';

  @override
  String get translating => 'Translating...';

  @override
  String get translationUnavailable => 'Translation unavailable';

  @override
  String get retryTranslation => 'Retry';

  @override
  String get translationUnavailableOffline => 'Translation unavailable offline';

  @override
  String get complaintRejected => 'Complaint Rejected';

  @override
  String get complaintRejectedAuthenticityBody =>
      'The evidence uploaded with this complaint did not pass CivicFix\'s authenticity verification and was identified as AI-generated or digitally manipulated.\n\nFor civic complaints, please upload a genuine photo of the issue captured from the actual location.';

  @override
  String get reportAgain => 'Report Again';

  @override
  String get evidenceVerificationFailed => 'Evidence Verification Failed';

  @override
  String get aiGeneratedEvidenceDetected =>
      'AI-generated or manipulated evidence detected.';
}
