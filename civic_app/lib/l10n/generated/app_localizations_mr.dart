// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'CivicFix';

  @override
  String get appName => 'CivicFix';

  @override
  String get commonRetry => 'पुन्हा प्रयत्न करा';

  @override
  String get commonCancel => 'रद्द करा';

  @override
  String get appTagline => 'नागरी तक्रार निवारण आणि प्रशासन';

  @override
  String get ok => 'ठीक आहे';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get save => 'जतन करा';

  @override
  String get submit => 'सादर करा';

  @override
  String get close => 'बंद करा';

  @override
  String get retry => 'पुन्हा प्रयत्न करा';

  @override
  String get back => 'मागे';

  @override
  String get confirm => 'पुष्टी करा';

  @override
  String get delete => 'हटवा';

  @override
  String get edit => 'संपादित करा';

  @override
  String get search => 'शोधा';

  @override
  String get filter => 'फिल्टर';

  @override
  String get refresh => 'रिफ्रेश करा';

  @override
  String get loading => 'लोड होत आहे...';

  @override
  String get error => 'त्रुटी';

  @override
  String get success => 'यशस्वी';

  @override
  String get warning => 'इशारा';

  @override
  String get yes => 'होय';

  @override
  String get no => 'नाही';

  @override
  String get home => 'मुख्यपृष्ठ';

  @override
  String get complaints => 'तक्रारी';

  @override
  String get reportIssue => 'तक्रार नोंदवा';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get notifications => 'सूचना';

  @override
  String get dashboard => 'डॅशबोर्ड';

  @override
  String get map => 'नकाशा';

  @override
  String get navMap => 'नकाशा';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा निवडा';

  @override
  String get languageEnglish => 'इंग्रजी';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get languageMarathi => 'मराठी';

  @override
  String get complaint => 'तक्रार';

  @override
  String get juniorEngineer => 'कनिष्ठ अभियंता';

  @override
  String get fieldOfficer => 'क्षेत्र अधिकारी';

  @override
  String get ward => 'प्रभाग';

  @override
  String get department => 'विभाग';

  @override
  String get statusUnderVerification => 'पडताळणी सुरू आहे';

  @override
  String get statusReported => 'नोंदवली';

  @override
  String get statusAssigned => 'नियुक्त';

  @override
  String get statusInProgress => 'प्रगतीपथावर';

  @override
  String get statusResolved => 'निवारण झाले';

  @override
  String get statusClosed => 'बंद';

  @override
  String get statusReopened => 'पुन्हा उघडली';

  @override
  String get trackComplaint => 'तक्रार ट्रॅक करा';

  @override
  String get viewAll => 'सर्व पहा';

  @override
  String get submitReport => 'तक्रार सादर करा';

  @override
  String get continueText => 'पुढे चालू ठेवा';

  @override
  String get backToHome => 'मुख्यपृष्ठावर परत जा';

  @override
  String get saveChanges => 'बदल जतन करा';

  @override
  String get assistantHelp => 'नागरी सहाय्यकाला विचारा';

  @override
  String get myComplaintsTitle => 'माझ्या तक्रारी';

  @override
  String get recentIssues => 'अलीकडील नागरी तक्रारी';

  @override
  String get nearbyHazards => 'जवळील धोके';

  @override
  String get quickActions => 'त्वरित कृती';

  @override
  String get rewardsTitle => 'नागरी पुरस्कार';

  @override
  String get assistantTitle => 'नागरी एआय सहाय्यक';

  @override
  String get settingsTitle => 'सेटिंग्ज आणि प्राधान्ये';

  @override
  String get noInternetConnection => 'इंटरनेट कनेक्शन नाही';

  @override
  String get somethingWentWrong => 'काहीतरी चूक झाली';

  @override
  String get operationSuccess => 'क्रिया यशस्वीरित्या पूर्ण झाली';

  @override
  String welcomeUser(String userName) {
    return 'स्वागत आहे, $userName';
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
      other: '$countString तक्रारी',
      one: '1 तक्रार',
      zero: 'कोणतीही तक्रार नाही',
    );
    return '$_temp0';
  }

  @override
  String get welcomeBack => 'पुन्हा स्वागत आहे';

  @override
  String get signInSubtitle =>
      'नागरी तक्रारी नोंदवण्यासाठी, प्रभागातील कामे ट्रॅक करण्यासाठी आणि सहभाग घेण्यासाठी साइन इन करा.';

  @override
  String get email => 'ईमेल';

  @override
  String get emailHint => 'उदा. name@example.com';

  @override
  String get password => 'पासवर्ड';

  @override
  String get passwordHint => 'आपला पासवर्ड प्रविष्ट करा';

  @override
  String get forgotPassword => 'पासवर्ड विसरलात?';

  @override
  String get login => 'लॉग इन करा';

  @override
  String get orDivider => 'किंवा';

  @override
  String get continueWithGoogle => 'Google सह पुढे चालू ठेवा';

  @override
  String get dontHaveAccount => 'खाते नाही का?';

  @override
  String get createAccount => 'खाते तयार करा';

  @override
  String get govtOfficerLogin => 'शासकीय अधिकारी लॉगिन';

  @override
  String get pleaseEnterEmail => 'कृपया आपला ईमेल प्रविष्ट करा.';

  @override
  String get pleaseEnterValidEmail => 'कृपया वैध ईमेल पत्ता प्रविष्ट करा.';

  @override
  String get pleaseEnterPassword => 'कृपया आपला पासवर्ड प्रविष्ट करा.';

  @override
  String get incorrectEmailOrPassword => 'चुकीचा ईमेल किंवा पासवर्ड.';

  @override
  String get googleSignInFailed =>
      'Google साइन-इन अयशस्वी झाले. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get verifyYourPhone => 'आपला फोन सत्यापित करा';

  @override
  String get verifyPhoneSubtitle =>
      'दुबार नागरी तक्रारी रोखण्यासाठी आणि सत्यता राखण्यासाठी, एसएमएसद्वारे आपला मोबाइल नंबर सत्यापित करा.';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get mobileNumberHint => 'उदा. 9876543210';

  @override
  String get sendVerificationCode => 'सत्यापन कोड पाठवा';

  @override
  String get verificationCode => 'सत्यापन कोड';

  @override
  String get enterOtpHint => '६-अंकी ओटीपी प्रविष्ट करा';

  @override
  String get verifyAndContinue => 'सत्यापित करा आणि पुढे चला';

  @override
  String get changeNumber => 'नंबर बदला';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds सेकंदात पुन्हा कोड पाठवा';
  }

  @override
  String get resendVerificationCode => 'सत्यापन कोड पुन्हा पाठवा';

  @override
  String get phoneVerifiedSuccess =>
      'फोन यशस्वीरित्या सत्यापित झाला! पुनर्निर्देशित करत आहे...';

  @override
  String get codeExpired =>
      'सत्यापन कोड कालबाह्य झाला आहे. कृपया नवीन कोडसाठी पुन्हा पाठवा वर टॅप करा.';

  @override
  String get invalidVerificationCode => 'अवैध सत्यापन कोड.';

  @override
  String get codeSentViaSms => 'एसएमएसद्वारे सत्यापन कोड पाठवला गेला.';

  @override
  String get failedToSendCode => 'सत्यापन कोड पाठवण्यात अयशस्वी.';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get createCivicFixAccount => 'आपले CivicFix खाते तयार करा';

  @override
  String get civicParticipationStarts => 'आपला नागरी सहभाग येथून सुरू होतो.';

  @override
  String get fullName => 'पूर्ण नाव';

  @override
  String get fullNameHint => 'आपले पूर्ण नाव प्रविष्ट करा';

  @override
  String get phoneOptional => 'फोन नंबर (पर्यायी)';

  @override
  String get confirmPassword => 'पासवर्डची पुष्टी करा';

  @override
  String get confirmPasswordHint => 'आपला पासवर्ड पुन्हा प्रविष्ट करा';

  @override
  String get preferredLanguage => 'प्राधान्य दिलेली भाषा';

  @override
  String get alreadyHaveAccount => 'आधीच खाते आहे का?';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड जुळत नाहीत.';

  @override
  String get passwordMinLength => 'पासवर्ड किमान ८ अक्षरांचा असावा.';

  @override
  String get nameMinLength => 'नाव किमान २ अक्षरांचे असावे.';

  @override
  String get resetYourPassword => 'आपला पासवर्ड रीसेट करा';

  @override
  String get resetPasswordSubtitle =>
      'पासवर्ड रीसेट सूचना प्राप्त करण्यासाठी आपल्या खात्याशी संबंधित ईमेल प्रविष्ट करा.';

  @override
  String get sendResetLink => 'रीसेट लिंक पाठवा';

  @override
  String get backToLogin => 'लॉगिनवर परत जा';

  @override
  String get resetLinkSent => 'पासवर्ड रीसेट सूचना पाठवण्यात आल्या आहेत.';

  @override
  String get loadingCivicDashboard => 'नागरी डॅशबोर्ड लोड होत आहे...';

  @override
  String get viewAllComplaints => 'सर्व तक्रारी पहा →';

  @override
  String get viewHazardMap => 'धोका नकाशा पहा →';

  @override
  String get yourCivicProgress => 'आपली नागरी प्रगती';

  @override
  String get noComplaintsYet => 'अद्याप कोणतीही तक्रार नाही';

  @override
  String get reportIssueToGetStarted => 'सुरू करण्यासाठी नागरी तक्रार नोंदवा.';

  @override
  String get noImmediateHazards =>
      'आपल्या परिसरात कोणताही तात्काळ धोका नोंदवलेला नाही.';

  @override
  String get assistantSubtitle => 'CivicFix सह मदत मिळवा';

  @override
  String get rewardsSubtitle => 'आपली नागरी प्रगती पहा';

  @override
  String get reportCivicIssueAction => 'नागरी तक्रार नोंदवा';

  @override
  String get recentCivicReports => 'अलीकडील तक्रारी';

  @override
  String get nearbyCivicIssues => 'जवळपासच्या नागरी समस्या';

  @override
  String get issueInformation => 'समस्येची माहिती';

  @override
  String get issueInfoSubtitle =>
      'समस्या समजून घेण्यास मदत करा जेणेकरून ती योग्य विभागापर्यंत पोहोचेल.';

  @override
  String get issueTitle => 'समस्येचे शीर्षक';

  @override
  String get issueTitleHint => 'उदा. उद्यानाजवळ बंद असलेला पथदिवा';

  @override
  String get selectCategoryError => 'कृपया समस्येचा प्रकार निवडा.';

  @override
  String get describeTheIssue => 'समस्येचे वर्णन करा';

  @override
  String get describeIssueHint =>
      'काय घडले आणि आपल्याला कुठे समस्या आढळली ते आम्हाला सांगा.';

  @override
  String get describeIssueHelp =>
      'काय नुकसान झाले आहे, किती दिवसांपासून समस्या आहे किंवा परिसरावर काय परिणाम होतो यासारखे तपशील द्या.';

  @override
  String get immediateSafetyHazard => 'तात्काळ सुरक्षा धोका';

  @override
  String get safetyHazardSubtitle =>
      'या समस्येमुळे नागरिक किंवा वाहतुकीस तात्काळ धोका असल्यास निवडा';

  @override
  String get addEvidence => 'पुरावा जोडा';

  @override
  String get addEvidenceSubtitle =>
      'फोटोमुळे संबंधित विभागाला समस्या समजण्यास मदत होईल.';

  @override
  String get whereIsTheIssue => 'समस्या कुठे आहे?';

  @override
  String get whereIsIssueSubtitle =>
      'स्थान जोडा जेणेकरून संबंधित विभाग ते शोधू शकेल.';

  @override
  String get selectLocationError => 'कृपया समस्येचे स्थान निवडा किंवा शोधा.';

  @override
  String get reviewYourIssue => 'तुमच्या तक्रारीचे पुनरावलोकन करा';

  @override
  String get reviewIssueSubtitle =>
      'आपल्या प्रभागात सादर करण्यापूर्वी सर्व माहितीची खात्री करा.';

  @override
  String get nextAddEvidence => 'पुढे: पुरावा जोडा';

  @override
  String get nextLocation => 'पुढे: स्थान';

  @override
  String get skipAndContinue => 'वगळा आणि पुढे चला';

  @override
  String get nextReview => 'पुढे: पुनरावलोकन';

  @override
  String get discardReportTitle => 'ही तक्रार रद्द करायची का?';

  @override
  String get discardReportMessage => 'तुम्ही भरलेली माहिती नष्ट होईल.';

  @override
  String get keepEditing => 'संपादन चालू ठेवा';

  @override
  String get discard => 'रद्द करा';

  @override
  String get stepInformation => 'माहिती';

  @override
  String get stepEvidence => 'पुरावा';

  @override
  String get stepLocation => 'स्थान';

  @override
  String get stepReview => 'पुनरावलोकन';

  @override
  String get complaintSavedOffline => 'तक्रार ऑफलाइन जतन केली';

  @override
  String get issueReportedSuccess => 'तक्रार नोंदवली गेली';

  @override
  String get offlineSubmissionNote =>
      'तक्रार जतन झाली. आपण ऑनलाइन आल्यावर ती सादर केली जाईल.';

  @override
  String get onlineSubmissionNote =>
      'आपली तक्रार यशस्वीरित्या सादर केली गेली आहे.';

  @override
  String get localReference => 'स्थानिक संदर्भ';

  @override
  String get complaintId => 'तक्रार आयडी';

  @override
  String get status => 'स्थिती';

  @override
  String get pendingSync => 'सिंक प्रलंबित';

  @override
  String get syncing => 'सिंक होत आहे...';

  @override
  String get syncFailed => 'सिंक अयशस्वी';

  @override
  String get civicReward => 'नागरी बक्षीस';

  @override
  String pointsReward(int count) {
    return '+$count गुण';
  }

  @override
  String get viewComplaint => 'तक्रार पहा';

  @override
  String get trackFromMyComplaints =>
      'आपण \'माझ्या तक्रारी\' मधून या समस्येची प्रगती ट्रॅक करू शकता.';

  @override
  String get offlineStoredSecurely =>
      'आपली तक्रार या डिव्हाइसवर सुरक्षितपणे जतन केली आहे आणि इंटरनेट कनेक्ट होताच सिंक होईल.';

  @override
  String get confirmLocation => 'स्थानाची पुष्टी करा';

  @override
  String get confirmThisLocation => 'या स्थानाची पुष्टी करा';

  @override
  String get selectedLocation => 'निवडलेले स्थान';

  @override
  String get tapMapToPositionPin => 'पिन ठेवण्यासाठी नकाशावर टॅप करा';

  @override
  String get searchLocationHint => 'रस्ता, परिसर किंवा लँडमार्क शोधा...';

  @override
  String get couldNotAcquireGps =>
      'GPS स्थान मिळवता आले नाही. कृपया पिन स्वतः समायोजित करा.';

  @override
  String get trackCivicIssuesSubtitle =>
      'आपण नोंदवलेल्या नागरी तक्रारींचा मागोवा घ्या.';

  @override
  String get searchComplaintsHint => 'तक्रारी शोधा...';

  @override
  String get all => 'सर्व';

  @override
  String get allStatuses => 'सर्व स्थिती';

  @override
  String get allCategories => 'सर्व प्रकार';

  @override
  String complaintsFound(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString तक्रारी आढळल्या',
      one: '1 तक्रार आढळली',
      zero: 'कोणतीही तक्रार आढळली नाही',
    );
    return '$_temp0';
  }

  @override
  String get clearAll => 'सर्व साफ करा';

  @override
  String get clearFilters => 'फिल्टर साफ करा';

  @override
  String get noComplaintsFound => 'कोणतीही तक्रार आढळली नाही';

  @override
  String get tryDifferentSearch => 'वेगळा शोध किंवा फिल्टर वापरून पहा.';

  @override
  String get filterAndSort => 'फिल्टर आणि क्रमवारी';

  @override
  String get complaintStatus => 'तक्रारीची स्थिती';

  @override
  String get issueCategory => 'समस्येचा प्रकार';

  @override
  String get sortBy => 'यानुसार क्रमवारी लावा';

  @override
  String get applyFilters => 'फिल्टर लागू करा';

  @override
  String get recentlyUpdated => 'नुकतेच अपडेट केलेले';

  @override
  String get newestFirst => 'नवीनतम प्रथम';

  @override
  String get oldestFirst => 'जुने प्रथम';

  @override
  String get support => 'समर्थन द्या';

  @override
  String supportsCount(int count) {
    return '$count पाठिंबा';
  }

  @override
  String get supportedComplaint => 'तक्रारीला समर्थन दिले!';

  @override
  String get alreadySupported => 'आपण आधीच या तक्रारीला समर्थन दिले आहे.';

  @override
  String get safetyHazard => 'सुरक्षा धोका';

  @override
  String updatedTime(String time) {
    return 'अपडेट: $time';
  }

  @override
  String reportedTime(String time) {
    return 'नोंद: $time';
  }

  @override
  String copiedTicketId(String ticket) {
    return 'तक्रार आयडी $ticket कॉपी केला.';
  }

  @override
  String get complaintDetails => 'तक्रारीचे तपशील';

  @override
  String get assignedMunicipalTeam => 'नियुक्त पालिका पथक';

  @override
  String get responsibleOfficersSubtitle =>
      'आपल्या तक्रारीचे व्यवस्थापन आणि निवारण करणारे जबाबदार अधिकारी';

  @override
  String get supervisingJuniorEngineer => 'पर्यवेक्षी कनिष्ठ अभियंता';

  @override
  String get supervising => 'पर्यवेक्षण';

  @override
  String get autoRoutingToWard =>
      'प्रभाग अभियंत्याकडे स्वयंचलित पाठवले जात आहे...';

  @override
  String get fieldExecutionOfficer => 'क्षेत्र अंमलबजावणी अधिकारी';

  @override
  String get pendingFieldAllocation => 'फील्ड नियुक्ती प्रलंबित';

  @override
  String get temporarilyOnHold => 'तात्पुरते स्थगित';

  @override
  String get workCompleted => 'काम पूर्ण झाले';

  @override
  String get workInProgress => 'काम प्रगतीपथावर आहे';

  @override
  String get assignedForFieldWork => 'फील्ड कामासाठी नियुक्त';

  @override
  String get awaitingFieldOfficerAssignment =>
      'पर्यवेक्षी कनिष्ठ अभियंत्याकडून क्षेत्रीय अधिकारी नियुक्तीची प्रतीक्षा आहे.';

  @override
  String groundObstacle(String reason) {
    return 'घटनास्थळावरील अडथळा: $reason';
  }

  @override
  String get groundWorkPaused =>
      'जागेवरील अडचणींमुळे काम तात्पुरते थांबवले आहे.';

  @override
  String get groundRepairExecuted =>
      'दुरुस्तीचे काम यशस्वीरित्या पूर्ण आणि सत्यापित झाले.';

  @override
  String get reopenedForQualityRework => 'गुणवत्ता सुधारणेसाठी पुन्हा उघडले';

  @override
  String get supervisoryReviewAction => 'पर्यवेक्षी गुणवत्ता पुनरावलोकन कारवाई';

  @override
  String get reworkRequired => 'पुन्हा काम आवश्यक';

  @override
  String reworkCycle(int count) {
    return 'पुनः काम चक्र #$count';
  }

  @override
  String get reasonForReopening => 'पुन्हा उघडण्याचे कारण';

  @override
  String get slaPreservedNote =>
      'मूळ एसएलए कायम ठेवला आहे. प्राधान्याने प्रत्यक्ष काम चालू आहे.';

  @override
  String get resolutionAndVerification => 'निवारण आणि काम पडताळणी';

  @override
  String get groundInspectionEvidence =>
      'घटनास्थळ तपासणी आणि पूर्णत्वाचा पुरावा';

  @override
  String get reportedIssueBefore => 'नोंदवलेली समस्या (पूर्वी)';

  @override
  String get resolvedConditionAfter => 'निवारणानंतरची स्थिती (नंतर)';

  @override
  String get officerResolutionRemarks => 'अधिकारी निवारण टिप्पणी';

  @override
  String executedByOfficer(String officer) {
    return '$officer द्वारे पूर्ण';
  }

  @override
  String resolvedOnDate(String date) {
    return '$date रोजी निवारण झाले';
  }

  @override
  String get issueResolvedBanner => '✓ समस्येचे निवारण झाले';

  @override
  String get issueResolvedSubtitle =>
      'ही तक्रार निवारण झाल्याचे चिन्हांकित केले आहे.';

  @override
  String get currentPhase => 'सध्याचा टप्पा';

  @override
  String get progress => 'प्रगती';

  @override
  String get updates => 'अपडेट';

  @override
  String get noUpdatesYet => 'अद्याप कोणतेही अपडेट नाहीत.';

  @override
  String reportedOn(String date) {
    return '$date रोजी नोंदवली';
  }

  @override
  String get viewLocation => 'स्थान पहा';

  @override
  String evidencePhotos(int count) {
    return 'फोटो पुरावा ($count)';
  }

  @override
  String get noPhotosAttached => 'कोणताही फोटो जोडलेला नाही (ऐच्छिक)';

  @override
  String photoPreview(int current, int total) {
    return 'फोटो पूर्वावलोकन ($current पैकी $total)';
  }

  @override
  String get closePreview => 'पूर्वावलोकन बंद करा';

  @override
  String routedToDepartment(String department) {
    return 'ही तक्रार $department कडे पाठवली जाईल.';
  }

  @override
  String get markAllAsRead => 'सर्व वाचलेले म्हणून चिन्हांकित करा';

  @override
  String get allNotificationsMarkedRead =>
      'सर्व सूचना वाचल्याचे चिन्हांकित केले.';

  @override
  String get unread => 'न वाचलेले';

  @override
  String get read => 'वाचलेले';

  @override
  String get noUnreadNotifications => 'कोणतीही न वाचलेली सूचना नाही';

  @override
  String get noUnreadNotificationsDesc =>
      'आपण आपल्या तक्रारींचे आणि प्रभाग सूचनांचे सर्व अपडेट वाचले आहेत.';

  @override
  String get noNotificationsYet => 'अद्याप कोणतीही सूचना नाही.';

  @override
  String get noNotificationsYetDesc =>
      'आपल्या तक्रारीवर काही अपडेट आल्यास ते येथे दिसेल.';

  @override
  String get citizenProfile => 'नागरिक प्रोफाइल';

  @override
  String get editProfile => 'प्रोफाइल संपादित करा';

  @override
  String get civicContribution => 'नागरी योगदान';

  @override
  String get viewAchievements => 'उपलब्धी पहा';

  @override
  String get reports => 'नोंदवलेल्या';

  @override
  String get resolved => 'निवारण झाले';

  @override
  String get civicPoints => 'नागरी गुण';

  @override
  String get civicEngagement => 'नागरी सहभाग';

  @override
  String get civicRewardsAndAchievements => 'नागरी पुरस्कार आणि उपलब्धी';

  @override
  String get civicAssistant => 'सिविक सहाय्यक';

  @override
  String get assistantSubtitleLong =>
      'नेहमी विचारले जाणारे प्रश्न, तक्रार नियम आणि प्रकार मदत';

  @override
  String get settingsAndPrivacy => 'सेटिंग्ज आणि गोपनीयता';

  @override
  String get notificationPreferences => 'सूचना प्राधान्ये';

  @override
  String get notificationPreferencesSubtitle =>
      'स्थिती सूचना, धोका इशारा आणि आवाज';

  @override
  String get privacyAndSafety => 'गोपनीयता आणि सुरक्षा';

  @override
  String get privacyAndSafetySubtitle => 'गोपनीयता आणि सार्वजनिक नकाशा धोरण';

  @override
  String get aboutCivicFix => 'CivicFix बद्दल';

  @override
  String get aboutCivicFixSubtitle => 'ध्येय, प्रशासन मॉडेल आणि तंत्रज्ञान';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get logoutConfirmTitle => 'लॉग आउट करायचे?';

  @override
  String get logoutConfirmMessage => 'आपण नक्की लॉग आउट करू इच्छिता?';

  @override
  String get profileUpdatedSuccess => 'प्रोफाइल यशस्वीरित्या अपडेट केली.';

  @override
  String get profileUpdateFailed =>
      'प्रोफाइल अपडेट करता आली नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get viewDetails => 'तपशील पहा';

  @override
  String get closeComplaintCard => 'तक्रार कार्ड बंद करा';

  @override
  String get searchHazardsHint => 'धोके किंवा तक्रारी शोधा...';

  @override
  String get unableToOpenComplaint => 'ही तक्रार उघडता येत नाही.';

  @override
  String get complaintBelongsToOther => 'ही तक्रार दुसऱ्या नागरी खात्याची आहे.';

  @override
  String get backToMyComplaints => 'माझ्या तक्रारींवर परत जा';

  @override
  String get complaintNotFound => 'तक्रार आढळली नाही.';

  @override
  String get complaintNotFoundDesc => 'ही तक्रार आता उपलब्ध नसू शकते.';

  @override
  String get couldNotLoadComplaint => 'ही तक्रार लोड करता आली नाही.';

  @override
  String get couldNotLoadNotifications => 'सूचना लोड करता आल्या नाहीत.';

  @override
  String get checkConnectionAndRetry =>
      'कृपया आपले इंटरनेट कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.';

  @override
  String get pleaseEnterName => 'कृपया आपले नाव प्रविष्ट करा.';

  @override
  String get pleaseEnterValidPhone =>
      'कृपया एक वैध फोन नंबर प्रविष्ट करा (किमान 10 अंक).';

  @override
  String get passwordMinCharsHint => 'किमान 8 अक्षरे';

  @override
  String get pleaseConfirmPassword => 'कृपया आपल्या पासवर्डची पुष्टी करा.';

  @override
  String get accountCreatedSuccess => 'खाते यशस्वीरित्या तयार झाले.';

  @override
  String get registrationFailed =>
      'नोंदणी अयशस्वी झाली. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get createAccountBtn => 'खाते तयार करा';

  @override
  String get changeAction => 'बदला';

  @override
  String get verificationCodeHint => '6-अंकी ओटीपी प्रविष्ट करा';

  @override
  String get pleaseEnterVerificationCode => 'कृपया सत्यापन कोड प्रविष्ट करा.';

  @override
  String get verificationCodeMinLength => 'सत्यापन कोड किमान 4 अंकांचा असावा.';

  @override
  String get unableToResendCode => 'सत्यापन कोड पुन्हा पाठवता आला नाही.';

  @override
  String get enterRegisteredEmail => 'आपला नोंदणीकृत ईमेल प्रविष्ट करा';

  @override
  String get passwordResetSent => 'पासवर्ड रीसेट सूचना पाठवल्या गेल्या आहेत.';

  @override
  String get unableToProcessReset => 'रीसेट विनंतीवर प्रक्रिया करता आली नाही.';

  @override
  String get navHome => 'मुख्यपृष्ठ';

  @override
  String get navComplaints => 'तक्रारी';

  @override
  String get navNotifications => 'सूचना';

  @override
  String get navProfile => 'प्रोफाइल';

  @override
  String get loadingDashboard => 'नागरी डॅशबोर्ड लोड होत आहे...';

  @override
  String get unableToLoadUpdates =>
      'नागरी अपडेट लोड करण्यात अक्षम. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get assistant => 'सहाय्यक';

  @override
  String get reportToGetStarted =>
      'सुरू करण्यासाठी नागरी समस्येची तक्रार नोंदवा.';

  @override
  String get noNearbyHazards =>
      'आपल्या लगतच्या परिसरात कोणताही तात्काळ धोका नोंदवला गेलेला नाही.';

  @override
  String get issueInformationTitle => 'समस्येची माहिती';

  @override
  String get issueInformationSubtitle =>
      'समस्या समजून घेण्यास आम्हाला मदत करा जेणेकरून ती योग्य पथकापर्यंत पोहोचेल.';

  @override
  String get issueTitleLabel => 'समस्येचे शीर्षक';

  @override
  String get pleaseEnterIssueTitle => 'कृपया समस्येसाठी शीर्षक प्रविष्ट करा.';

  @override
  String get issueTitleMinLength => 'शीर्षक किमान 5 अक्षरांचे असावे.';

  @override
  String get pleaseSelectCategory => 'कृपया समस्येची श्रेणी निवडा.';

  @override
  String get pleaseDescribeIssue => 'कृपया समस्येचे वर्णन करा.';

  @override
  String get describeIssueMinLength => 'वर्णन किमान 10 अक्षरांचे असावे.';

  @override
  String get describeIssueHelper =>
      'नुकसान काय झाले आहे, हे किती काळापासून होत आहे किंवा त्याचा परिसरावर कसा परिणाम होत आहे यासारखे उपयुक्त तपशील समाविष्ट करा.';

  @override
  String get addLocationSubtitle =>
      'स्थान जोडा जेणेकरून संबंधित पथक ते शोधू शकेल.';

  @override
  String get submitIssue => 'तक्रार दाखल करा';

  @override
  String get supervisingStatus => 'पर्यवेक्षण';

  @override
  String get routingStatus => 'मार्गनिर्देशित करत आहे...';

  @override
  String get awaitingFieldAllocationNote =>
      'पर्यवेक्षी कनिष्ठ अभियंत्याकडून क्षेत्र अधिकारी नेमणुकीची प्रतीक्षा आहे.';

  @override
  String get groundRepairVerified =>
      'जागेवरील दुरुस्तीचे काम पूर्ण झाले आणि यशस्वीरित्या सत्यापित झाले.';

  @override
  String get executionUnderway => 'जागेवर काम सध्या सुरू आहे.';

  @override
  String get fieldOfficerAllocatedNote =>
      'क्षेत्र अधिकारी नियुक्त. जागेवरील काम नियोजित.';

  @override
  String get originalSlaPreserved =>
      'तक्रार नोंदणीपासूनची मूळ मुदत कायम. प्राधान्याने जागेवरील काम सुरू आहे.';

  @override
  String get resolutionAndWorkVerification => 'निराकरण आणि काम पडताळणी';

  @override
  String get issueReportedTitle => 'तक्रार नोंदवली गेली';

  @override
  String get issueSubmittedSuccess =>
      'आपली तक्रार यशस्वीरित्या नोंदवली गेली आहे.';

  @override
  String get plusTwentyPoints => '+20 गुण';

  @override
  String get storedLocallyNote =>
      'आपली तक्रार या डिव्हाइसवर सुरक्षितपणे जतन केली आहे आणि इंटरनेट कनेक्ट झाल्यावर सिंक होईल.';

  @override
  String get trackFromMyComplaintsNote =>
      'आपण \'माझ्या तक्रारी\' मधून या समस्येची प्रगती ट्रॅक करू शकता.';

  @override
  String get noComplaintsFoundDesc => 'वेगळा शोध किंवा फिल्टर वापरून पहा.';

  @override
  String get noComplaintsReportedYet => 'अद्याप कोणतीही तक्रार नोंदवली नाही';

  @override
  String get supportedComplaintSuccess => 'तक्रारीला पाठिंबा दिला!';

  @override
  String get alreadySupportedComplaint =>
      'तुम्ही आधीच या तक्रारीला पाठिंबा दिला आहे.';

  @override
  String get statusVerified => 'पडताळणी झाली';

  @override
  String get statusRejected => 'नाकारली';

  @override
  String get loadingComplaints => 'आपल्या तक्रारी लोड होत आहेत...';

  @override
  String get failedToLoadComplaints => 'आपल्या तक्रारी लोड करता आल्या नाहीत.';

  @override
  String get reportCivicIssueTrackProgress =>
      'नागरी तक्रार नोंदवा आणि येथे तिची प्रगती ट्रॅक करा.';

  @override
  String get reportAnIssue => 'तक्रार नोंदवा';

  @override
  String get trackCivicIssuesReported =>
      'आपण नोंदवलेल्या नागरी तक्रारींचा मागोवा घ्या.';

  @override
  String get clearSearch => 'शोध साफ करा';

  @override
  String complaintIdCopied(String ticketNumber) {
    return 'तक्रार आयडी $ticketNumber कॉपी केली.';
  }

  @override
  String get locationSelected => 'स्थान निवडले';

  @override
  String get supports => 'पाठिंबा';

  @override
  String get closeFilters => 'फिल्टर बंद करा';

  @override
  String get noComplaintSpecified => 'कोणतीही तक्रार निर्दिष्ट केलेली नाही.';

  @override
  String get waitingForConnection => 'इंटरनेट कनेक्शनची प्रतीक्षा';

  @override
  String get complaintStoredSecurelyOffline =>
      'आपली तक्रार या डिव्हाइसवर सुरक्षितपणे साठवली आहे आणि इंटरनेट उपलब्ध झाल्यावर सादर केली जाईल.';

  @override
  String get synchronizingWithCloud => 'क्लाउडसह सिंक होत आहे';

  @override
  String get uploadingComplaintData =>
      'महानगरपालिका नेटवर्कवर तक्रार डेटा आणि पुरावे अपलोड होत आहेत...';

  @override
  String get synchronizationFailed => 'सिंक्रोनाइझेशन अयशस्वी';

  @override
  String get failedToSyncWithCloud =>
      'क्लाउड बॅकएंडसह हा अहवाल सिंक करण्यात अयशस्वी. कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.';

  @override
  String get retrySync => 'पुन्हा सिंक करा';

  @override
  String get complaintMarkedResolved =>
      'ही तक्रार निवारण झालेली म्हणून चिन्हांकित केली आहे.';

  @override
  String reportedOnDate(String date) {
    return '$date रोजी नोंदवली';
  }

  @override
  String lastUpdatedTime(String time) {
    return 'शेवटचे अपडेट $time';
  }

  @override
  String get wardLabel => 'प्रभाग';

  @override
  String get central => 'मध्यवर्ती';

  @override
  String get groundWorkTemporarilyPaused =>
      'जागेवरील अडचणींमुळे प्रत्यक्ष काम तात्पुरते थांबवले आहे.';

  @override
  String commencedTime(String time) {
    return '$time सुरू झाले.';
  }

  @override
  String get executionUnderwayOnSite => 'जागेवर काम सध्या सुरू आहे.';

  @override
  String get pendingAllocation => 'वाटप प्रलंबित';

  @override
  String get defaultReopenReason =>
      'ऑडिट पुनरावलोकनात कामाचा दर्जा महानगरपालिकेच्या निकषांनुसार आढळला नाही. दुरुस्तीच्या कारवाईसाठी पुन्हा सोपवले.';

  @override
  String get deptLeadQualityAudit => 'विभाग प्रमुख गुणवत्ता ऑडिट';

  @override
  String get reviewedBy => 'पुनरावलोकनकर्ते';

  @override
  String get slaPreservedPriorityExecution =>
      'नोंदणीपासून मूळ SLA कायम. प्राधान्याने प्रत्यक्ष काम सुरू.';

  @override
  String get hidePreviousResolutionRecord => 'मागील निवारण नोंद लपवा';

  @override
  String get viewPreviousResolutionRecord => 'मागील निवारण नोंद पहा';

  @override
  String get photos => 'छायाचित्रे';

  @override
  String get priorResolutionTimestamp => 'मागील निवारण वेळ';

  @override
  String executedBy(String name) {
    return '$name द्वारे पूर्ण केले';
  }

  @override
  String get progressTracker => 'प्रगती ट्रॅकर';

  @override
  String get stage => 'टप्पा';

  @override
  String get ofFive => 'पैकी ५';

  @override
  String get currentCaps => 'सध्याचा';

  @override
  String get categoryLabel => 'वर्ग';

  @override
  String get departmentLabel => 'विभाग';

  @override
  String get priorityLabel => 'प्राधान्य';

  @override
  String get noDescriptionProvided => 'कोणतेही अतिरिक्त वर्णन दिलेले नाही.';

  @override
  String get landmark => 'लँडमार्क';

  @override
  String get jurisdiction => 'अधिकारक्षेत्र';

  @override
  String get updatesTitle => 'अपडेट्स';

  @override
  String get entry => 'नोंद';

  @override
  String get entries => 'नोंदी';

  @override
  String get hazardMapTitle => 'धोका नकाशा';

  @override
  String get couldNotLoadCivicIssues => 'नागरी समस्या लोड करता आल्या नाहीत.';

  @override
  String get checkConnectionRetry =>
      'कृपया आपले इंटरनेट कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.';

  @override
  String get loadingHazardMap => 'नागरी धोका नकाशा लोड होत आहे...';

  @override
  String get offlineCachedHazardsBanner =>
      'ऑफलाइन — कॅश केलेले धोके दाखवत आहे. नकाशा टाइल्ससाठी नेटवर्क आवश्यक आहे.';

  @override
  String get locationServicesDisabled =>
      'आपल्या डिव्हाइसवर स्थान सेवा अक्षम आहेत.';

  @override
  String get locationPermissionRequired =>
      'नकाशा केंद्रित करण्यासाठी स्थान परवानगी आवश्यक आहे.';

  @override
  String centeredOnLocation(String wardText) {
    return 'आपल्या स्थानावर$wardText केंद्रित';
  }

  @override
  String get unableToDetermineLocation =>
      'आपले स्थान निश्चित करण्यात अक्षम. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get gpsTimeoutRetry =>
      'जीपीएस शोधण्याची वेळ संपली. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get hideHeatmapLayer => 'हीटमॅप स्तर लपवा';

  @override
  String get showHeatmapLayer => 'हीटमॅप स्तर दाखवा';

  @override
  String get toggleMapLegend => 'नकाशा सूची टॉगल करा';

  @override
  String get useMyLocation => 'माझे स्थान वापरा';

  @override
  String get zoomIn => 'झूम इन';

  @override
  String get zoomOut => 'झूम आउट';

  @override
  String get statusLegend => 'स्थिती सूची';

  @override
  String get civicIssuesNearYou => 'आपल्या जवळच्या नागरी समस्या';

  @override
  String get noCivicIssuesFound => 'कोणतीही नागरी समस्या आढळली नाही.';

  @override
  String get tryChangingFiltersOrSearch =>
      'आपले फिल्टर किंवा शोध बदलण्याचा प्रयत्न करा.';

  @override
  String get logoutConfirmationTitle => 'लॉग आउट करायचे?';

  @override
  String get logoutConfirmationDesc => 'आपण नक्की लॉग आउट करू इच्छिता?';

  @override
  String get viewMilestones => 'टप्पे पहा';

  @override
  String get civicAssistantSubtitle =>
      'वारंवार विचारले जाणारे प्रश्न, तक्रार नियम आणि वर्ग मदत';

  @override
  String get accountAndPreferences => 'खाते आणि प्राधान्ये';

  @override
  String get appearance => 'दिसणे';

  @override
  String get themeMode => 'थीम मोड';

  @override
  String get systemDefault => 'सिस्टम डीफॉल्ट';

  @override
  String get lightTheme => 'लाइट थीम';

  @override
  String get darkTheme => 'डार्क थीम';

  @override
  String get appVersion => 'अॅप आवृत्ती';

  @override
  String get actions => 'कृती';

  @override
  String get personalInformation => 'वैयक्तिक माहिती';

  @override
  String get enterFullName => 'आपले पूर्ण नाव प्रविष्ट करा';

  @override
  String get emailCannotBeChanged => 'नागरी खात्यासाठी ईमेल बदलता येत नाही.';

  @override
  String get phoneHelperText =>
      'तातडीच्या परिसरातील सूचनांवर एसएमएस अपडेटसाठी वापरले जाते.';

  @override
  String get registeredCitizenAccount => 'नोंदणीकृत नागरिक खाते';

  @override
  String get citizen => 'नागरिक';

  @override
  String get nameTooShort => 'नाव किमान २ अक्षरांचे असणे आवश्यक आहे.';

  @override
  String get nameTooLong => 'नाव ५० अक्षरांपेक्षा जास्त असू शकत नाही.';

  @override
  String get phoneInvalid => 'कृपया वैध १०-अंकी फोन नंबर प्रविष्ट करा.';

  @override
  String get discardReportDesc => 'आपण प्रविष्ट केलेली माहिती नष्ट होईल.';

  @override
  String get filterCivicIssues => 'नागरी समस्या फिल्टर करा';

  @override
  String get closeFilter => 'फिल्टर बंद करा';

  @override
  String get hazardCategory => 'धोका वर्ग';

  @override
  String get issueStatus => 'तक्रारीची स्थिती';

  @override
  String get reportTimeframe => 'अहवाल कालमर्यादा';

  @override
  String get civicStanding => 'नागरी प्रतिष्ठा';

  @override
  String get tierProgress => 'योगदान श्रेणी प्रगती';

  @override
  String get totalPoints => 'एकूण गुण';

  @override
  String get reportsFiled => 'नोंदवलेल्या तक्रारी';

  @override
  String get resolvedFixes => 'निवारण झालेली कामे';

  @override
  String get selectCategorySubtitle => 'समस्येशी सर्वाधिक जुळणारा वर्ग निवडा.';

  @override
  String get stepInfo => 'माहिती';

  @override
  String get recentComplaints => 'अलीकडील तक्रारी';

  @override
  String get rewards => 'बक्षिसे';

  @override
  String resendCodeInSeconds(int seconds) {
    return '$seconds सेकंदात कोड पुन्हा पाठवा';
  }

  @override
  String get immediateSafetyHazardTitle => 'तातडीचा सुरक्षा धोका';

  @override
  String get addEvidenceTitle => 'पुरावा जोडा';

  @override
  String get aiFallbackReviewTitle => 'विभागीय पुनरावलोकनाधीन';

  @override
  String get aiFallbackReviewMessage =>
      'स्वयंचलित पडताळणी तात्पुरती अनुपलब्ध आहे. आपली तक्रार विभागीय पुनरावलोकनासाठी पाठवली आहे. एसएलए सक्रिय असून निवारण सुरळीत सुरू आहे.';

  @override
  String get aiFallbackConfirmedMessage =>
      'मॅन्युअल पुनरावलोकनाद्वारे विभागाची पुष्टी झाली. कनिष्ठ अभियंत्याकडे वर्ग केले.';

  @override
  String get aiFallbackTransferredMessage =>
      'मॅन्युअल पुनरावलोकनाद्वारे दुसऱ्या बीएमसी विभागात वर्ग केले.';

  @override
  String get useDeviceLocation => 'डिव्हाइस स्थानाचा वापर करा';

  @override
  String get selectOnMap => 'नकाशावर निवडा';

  @override
  String get centerOnGps => 'माझ्या GPS वर केंद्रित करा';

  @override
  String get verifyBeforeSubmitting =>
      'कृपया तुमच्या प्रभागात सादर करण्यापूर्वी सर्व माहिती तपासा.';

  @override
  String get markedImmediateSafetyHazard =>
      'तातडीचा सुरक्षा धोका म्हणून चिन्हांकित';

  @override
  String photoEvidenceCount(int count) {
    return 'फोटो पुरावा ($count)';
  }

  @override
  String nearLandmark(String landmark) {
    return '$landmark जवळ';
  }

  @override
  String landmarkLabel(String landmark) {
    return 'लँडमार्क: $landmark';
  }

  @override
  String jurisdictionLabel(String ward) {
    return 'कार्यक्षेत्र: $ward';
  }

  @override
  String issueRoutedTo(String department) {
    return 'ही तक्रार $department कडे पाठवली जाईल.';
  }

  @override
  String get categoryRoads => 'रस्ते';

  @override
  String get categoryRoadsDesc =>
      'रस्त्यांचे नुकसान, खड्डे आणि असुरक्षित रस्ते.';

  @override
  String get categoryWater => 'पाणीपुरवठा';

  @override
  String get categoryWaterDesc => 'पाणीपुरवठा समस्या, गळती किंवा दूषित पाणी.';

  @override
  String get categorySanitation => 'स्वच्छता';

  @override
  String get categorySanitationDesc =>
      'सार्वजनिक स्वच्छता, शौचालये आणि रस्ते स्वच्छता.';

  @override
  String get categoryWaste => 'कचरा व्यवस्थापन';

  @override
  String get categoryWasteDesc => 'कचरा साचणे आणि कचरा संकलन समस्या.';

  @override
  String get categoryStreetlights => 'रस्त्यावरील दिवे';

  @override
  String get categoryStreetlightsDesc => 'बंद किंवा नादुरुस्त असलेले पथदिवे.';

  @override
  String get categoryDrainage => 'सांडपाणी निचरा';

  @override
  String get categoryDrainageDesc =>
      'तुंबलेली गटारे, पाणी साचणे, उघडी मॅनहोल्स.';

  @override
  String get categoryInfrastructure => 'सार्वजनिक पायाभूत सुविधा';

  @override
  String get categoryInfrastructureDesc => 'खराब झालेले पदपथ, पूल, बस थांबे.';

  @override
  String get categoryTraffic => 'वाहतूक / रस्ता सुरक्षा';

  @override
  String get categoryTrafficDesc =>
      'खराब झालेले फलक, गायब सिग्नल, धोकादायक चौक.';

  @override
  String get categoryOther => 'इतर';

  @override
  String get categoryOtherDesc =>
      'इतर सार्वजनिक किंवा महापालिका देखभाल समस्या.';

  @override
  String get categoryPotholes => 'रस्त्यावरील खड्डे';

  @override
  String get categoryGarbageOverflow => 'कचरा साचणे';

  @override
  String get categoryWaterlogging => 'पाणी साचणे';

  @override
  String get categoryWaterLeakage => 'पाणी गळती';

  @override
  String get categoryDamagedWater => 'खराब झालेली पाणी यंत्रणा';

  @override
  String get categorySewageOverflow => 'सांडपाणी वाहणे';

  @override
  String get categoryManholes => 'उघडी मॅनहोल्स';

  @override
  String get categoryFootpaths => 'खराब झालेले पदपथ';

  @override
  String get categoryTrees => 'पडलेली / धोकादायक झाडे';

  @override
  String get priorityLow => 'कमी';

  @override
  String get priorityMedium => 'मध्यम';

  @override
  String get priorityHigh => 'उच्च';

  @override
  String get priorityEmergency => 'अतिगंभीर';

  @override
  String get deptRoadsTraffic => 'रस्ते आणि वाहतूक विभाग';

  @override
  String get deptSolidWaste => 'घनकचरा व्यवस्थापन विभाग';

  @override
  String get deptWaterSewerage => 'पाणीपुरवठा आणि मलनिस्सारण विभाग';

  @override
  String get deptElectricalStreetlights => 'विद्युत आणि पथदिवे विभाग';

  @override
  String get deptStormDrainage => 'पर्जन्य जलवाहिन्या विभाग';

  @override
  String get deptPublicHealth => 'सार्वजनिक आरोग्य विभाग';

  @override
  String get deptGardensTrees => 'उद्यान व वृक्ष प्राधिकरण';

  @override
  String get deptBuildingInfrastructure => 'इमारत आणि पायाभूत सुविधा विभाग';

  @override
  String get deptGeneral => 'सामान्य महापालिका कक्ष';

  @override
  String get verificationPending => 'पडताळणी प्रलंबित';

  @override
  String get verificationProcessing => 'विश्लेषण आणि पडताळणी सुरू...';

  @override
  String get verificationPassed => 'पडताळणी यशस्वी';

  @override
  String get verificationFailed => 'पडताळणी अयशस्वी';

  @override
  String get verificationDelayed => 'स्वयंचलित पडताळणीस विलंब';

  @override
  String get verificationOfficerReview => 'विभागीय अधिकारी पुनरावलोकन';

  @override
  String get verificationCompleted => 'पडताळणी पूर्ण';

  @override
  String get routingUnassigned => 'नियुक्त नाही';

  @override
  String get routingAssigned => 'नियुक्त केले';

  @override
  String get routingReassignmentRequested => 'पुनर्नियुक्तीची विनंती';

  @override
  String get routingTransferred => 'हस्तांतरित';

  @override
  String get routingInProgress => 'प्रगतीपथावर';

  @override
  String get routingResolved => 'निवारण झाले';

  @override
  String get assignmentUnassigned => 'नियुक्त नाही';

  @override
  String get assignmentLeadAssigned => 'प्रभाग प्रमुखांकडे नियुक्त';

  @override
  String get assignmentCrewAssigned => 'ग्राउंड क्रूकडे नियुक्त';

  @override
  String get assignmentFieldOfficerAssigned => 'फील्ड ऑफिसरकडे नियुक्त';

  @override
  String get syncSynced => 'सिंक केले';

  @override
  String get syncPending => 'सिंक प्रलंबित';

  @override
  String get syncSyncing => 'सिंक होत आहे...';

  @override
  String get basemapStyle => 'नकाशा प्रकार';

  @override
  String get chooseMapViewMode => 'नकाशा दृश्य आणि उपग्रह प्रकार निवडा';

  @override
  String get basemapStreets => 'रस्ते';

  @override
  String get basemapStreetsDesc =>
      'तपशीलवार रस्ते नेटवर्क, प्रभाग आणि नागरी सुविधा';

  @override
  String get basemapSatellite => 'उपग्रह';

  @override
  String get basemapSatelliteDesc => 'उच्च-रिझोल्यूशन उपग्रह छायाचित्रे';

  @override
  String get basemapHybrid => 'हायब्रिड';

  @override
  String get basemapHybridDesc =>
      'रस्त्यांची नावे, सीमा आणि भागांच्या नावांसह उपग्रह दृश्य';

  @override
  String get badgeFirstReport => 'पहिली तक्रार';

  @override
  String get badgeFirstReportDesc => 'पहिली नागरी तक्रार नोंदवली';

  @override
  String get badgeActiveCitizen => 'सक्रिय नागरिक';

  @override
  String get badgeActiveCitizenDesc => '5 किंवा अधिक नागरी समस्या नोंदवल्या';

  @override
  String get badgeNeighborhoodHero => 'वॉर्ड हिरो';

  @override
  String get badgeNeighborhoodHeroDesc =>
      'तुमच्या वॉर्डमध्ये 10 समस्यांचे निवारण झाले';

  @override
  String get badgeSharpEye => 'सतर्क नागरिक';

  @override
  String get badgeSharpEyeDesc => 'तात्काळ सुरक्षा धोक्याची तक्रार केली';

  @override
  String get badgeCommunityPillar => 'समुदायाचा आधारस्तंभ';

  @override
  String get badgeCommunityPillarDesc => '500+ नागरी गुण मिळवले';

  @override
  String get unlocked => 'अनलॉक केले';

  @override
  String get locked => 'लॉक';

  @override
  String get howToUnlock => 'अनलॉक कसे करावे';

  @override
  String get communityPerks => 'समुदाय लाभ';

  @override
  String get communityPerksSubtitle =>
      'स्थानिक प्रशासन आणि भागीदार सवलतींसाठी पॉइंट्स वापरा';

  @override
  String get claimPerk => 'मिळवा';

  @override
  String get yourContribution => 'तुमचे योगदान';

  @override
  String get totalReports => 'एकूण तक्रारी';

  @override
  String get resolvedReports => 'निवारण झालेल्या तक्रारी';

  @override
  String get pointsEarned => 'मिळवलेले पॉइंट्स';

  @override
  String get achievements => 'यशस्वी टप्पे';

  @override
  String get achievementsSubtitle => 'सक्रिय वॉर्ड सहभागासाठी बॅज मिळवा';

  @override
  String get loadingRewards => 'तुमचे नागरी टप्पे लोड होत आहेत...';

  @override
  String get allNotificationsMarkedAsRead =>
      'सर्व सूचना वाचल्या म्हणून चिन्हांकित केल्या.';

  @override
  String get filterAll => 'सर्व';

  @override
  String get filterUnread => 'न वाचलेले';

  @override
  String get filterRead => 'वाचलेले';

  @override
  String get logOutQuestion => 'लॉग आउट करायचे?';

  @override
  String get logoutConfirmationMessage =>
      'तुम्हाला नक्की लॉग आउट करायचे आहे का?';

  @override
  String get clearChat => 'चॅट साफ करा';

  @override
  String get assistantThinking => 'सहाय्यक विचार करत आहे...';

  @override
  String get assistantMessageHint =>
      'तक्रार, ट्रॅकिंग किंवा श्रेणींबद्दल विचारा...';

  @override
  String get resolutionWorkVerification => 'निवारण आणि काम पडताळणी';

  @override
  String get groundInspectionSubtitle =>
      'प्रत्यक्ष पाहणी आणि काम पूर्ण झाल्याचा पुरावा';

  @override
  String get govPortalTitle => 'CivicFix शासकीय पोर्टल';

  @override
  String get govLoginTitle => 'शासकीय अधिकारी साइन इन';

  @override
  String get govLoginSubtitle =>
      'बीएमसी महापालिका अधिकाऱ्यांसाठी सुरक्षित प्रशासकीय प्रवेश';

  @override
  String get govEmployeeIdOrEmail => 'कर्मचारी आयडी किंवा अधिकृत ईमेल';

  @override
  String get govPassword => 'पासवर्ड';

  @override
  String get govSignInButton => 'पोर्टलवर साइन इन करा';

  @override
  String get govInvalidCredentials => 'अवैध कर्मचारी आयडी, ईमेल किंवा पासवर्ड.';

  @override
  String get govAccountDisabled =>
      'खाते निष्क्रिय आहे. महापालिका प्रशासकाशी संपर्क साधा.';

  @override
  String get govSessionExpired =>
      'सत्र समाप्त झाले आहे. कृपया पुन्हा साइन इन करा.';

  @override
  String get govAccessDenied => 'प्रवेश नाकारला';

  @override
  String get govAccessDeniedDesc =>
      'तुमच्याकडे या भागात प्रवेश करण्याचे प्रशासकीय अधिकार नाहीत.';

  @override
  String get govReturnToDashboard => 'डॅशबोर्डवर परत जा';

  @override
  String get govAuthenticating => 'प्रशासकीय ओळखपत्रे पडताळली जात आहेत...';

  @override
  String get govForgotPassword => 'पासवर्ड विसरलात';

  @override
  String get govResetPasswordInstruction =>
      'पासवर्ड रीसेट सूचना प्राप्त करण्यासाठी तुमचा नोंदणीकृत अधिकृत ईमेल प्रविष्ट करा.';

  @override
  String get govSendResetLink => 'रीसेट लिंक पाठवा';

  @override
  String get govNavDashboard => 'डॅशबोर्ड';

  @override
  String get govNavComplaints => 'तक्रारी';

  @override
  String get govNavHazardMap => 'धोका नकाशा';

  @override
  String get govNavAnalytics => 'विश्लेषण';

  @override
  String get govNavProfile => 'प्रोफाइल';

  @override
  String get govNavMyWork => 'माझे काम';

  @override
  String get govNavOperations => 'कामकाज';

  @override
  String get govNavSla => 'एसएलए मॉनिटर';

  @override
  String get govNavHistory => 'ऑडिट इतिहास';

  @override
  String get govNavVerification => 'पडताळणी रांग';

  @override
  String get govNavAssignments => 'नियुक्ती';

  @override
  String get govExecutiveDashboard => 'कार्यकारी डॅशबोर्ड';

  @override
  String get govGrievanceManagement => 'तक्रार निवारण व्यवस्थापन';

  @override
  String get govLiveHazardGisMap => 'थेट धोका जीआयएस नकाशा';

  @override
  String get govOperationalAnalytics => 'कार्यकारी विश्लेषण';

  @override
  String get govOfficerProfileSettings => 'अधिकारी प्रोफाइल आणि सेटिंग्ज';

  @override
  String get govCollapseSidebar => 'साइडबार बंद करा';

  @override
  String get govExpandSidebar => 'साइडबार उघडा';

  @override
  String get govMunicipalCorporation => 'बृहन्मुंबई महानगरपालिका';

  @override
  String get govRoleSuperAdmin => 'महानगरपालिका आयुक्त / सुपर अ‍ॅडमिन';

  @override
  String get govRoleZonalDmc => 'परिमंडळ सहआयुक्त';

  @override
  String get govRoleCentralHod => 'मध्यवर्ती विभागप्रमुख';

  @override
  String get govRoleWardOfficer => 'सहायक आयुक्त (प्रभाग अधिकारी)';

  @override
  String get govRoleWardLead => 'प्रभाग विभाग प्रमुख';

  @override
  String get govRoleDepartmentCrew =>
      'कनिष्ठ अभियंता / क्षेत्रीय अंमलबजावणी अधिकारी';

  @override
  String get govRoleAssistantEngineer => 'सहायक अभियंता';

  @override
  String get govRoleExecutiveEngineer => 'कार्यकारी अभियंता';

  @override
  String get govRoleSubEngineer => 'उप-अभियंता';

  @override
  String get govRoleMedicalOfficer => 'आरोग्य वैद्यकीय अधिकारी';

  @override
  String get govRoleSuperintendent => 'सहायक अधीक्षक';

  @override
  String get deptMaintenanceRoads => 'रस्ते आणि देखभाल विभाग';

  @override
  String get deptWaterWorks => 'जलकामे आणि पाणीपुरवठा विभाग';

  @override
  String get deptSolidWasteManagement => 'घनकचरा व्यवस्थापन विभाग';

  @override
  String get deptBuildingFactory => 'इमारत आणि कारखाना विभाग';

  @override
  String get deptGardenTrees => 'उद्यान व वृक्ष प्राधिकरण';

  @override
  String get deptPestControlInsecticide => 'कीटक नियंत्रण आणि कीटकनाशक विभाग';

  @override
  String get deptEncroachment => 'अतिक्रमण निर्मूलन विभाग';

  @override
  String get deptLicence => 'परवाना विभाग';

  @override
  String get deptShopsEstablishments => 'दुकाने आणि आस्थापने विभाग';

  @override
  String get deptAssessmentCollection => 'कर निर्धारणा व संकलन विभाग';

  @override
  String get deptEstate => 'मालमत्ता विभाग';

  @override
  String get deptColonySlum => 'वसाहत आणि झोपडपट्टी सुधारणा विभाग';

  @override
  String get deptEducationSchools => 'शिक्षण आणि महापालिका शाळा विभाग';

  @override
  String get deptSecurity => 'सुरक्षा दल विभाग';

  @override
  String get deptLegal => 'विधी विभाग';

  @override
  String get deptAdministrationEstablishment => 'प्रशासन आणि आस्थापना विभाग';

  @override
  String get deptTownPlanning => 'नगर रचना आणि विकास योजना विभाग';

  @override
  String get govPendingComplaints => 'प्रलंबित तक्रारी';

  @override
  String get govAssignedComplaints => 'नियुक्त तक्रारी';

  @override
  String get govInProgressComplaints => 'काम प्रगतीपथावर';

  @override
  String get govResolvedComplaints => 'निवारण झालेल्या तक्रारी';

  @override
  String get govOverdueComplaints => 'मुदत उलटलेल्या तक्रारी';

  @override
  String get govSlaBreaches => 'एसएलए उल्लंघन';

  @override
  String get govAwaitingVerification => 'पडताळणी प्रलंबित';

  @override
  String get govReworkRequired => 'पुन्हा काम करणे आवश्यक';

  @override
  String get govTodayTasks => 'आजची दैनंदिन कामे';

  @override
  String get govRecentActivity => 'अलीकडील विभागीय कामकाज';

  @override
  String get govWardSummary => 'प्रभाग कामगिरी सारांश';

  @override
  String get govDepartmentSummary => 'विभागीय कामकाज सारांश';

  @override
  String get govResolutionRate => 'निवारण दर';

  @override
  String get govAvgResolutionTime => 'सरासरी निवारण वेळ';

  @override
  String get govTotalGrievances => 'एकूण तक्रारी';

  @override
  String get govCriticalHazards => 'अतिधोकादायक समस्या';

  @override
  String get govActiveFieldCrew => 'सक्रिय क्षेत्रीय पथके';

  @override
  String get govMyWorkTitle => 'माझे नियुक्त काम';

  @override
  String get govStartJob => 'जागेवर काम सुरू करा';

  @override
  String get govWorkStarted => 'काम सुरू झाले';

  @override
  String get govUploadBeforeEvidence => 'कामापूर्वीचे पुरावे अपलोड करा';

  @override
  String get govUploadAfterEvidence => 'कामानंतरचे पुरावे अपलोड करा';

  @override
  String get govAddWorkRemarks => 'अंमलबजावणीच्या नोंदी जोडा';

  @override
  String get govMarkBlocked => 'काम अडकले म्हणून चिन्हांकित करा';

  @override
  String get govResumeWork => 'काम पुन्हा सुरू करा';

  @override
  String get govSubmitResolution => 'निवारण पडताळणीसाठी सादर करा';

  @override
  String get govBlockedReasonLabel => 'विलंब / अडथळ्याचे कारण';

  @override
  String get govWorkInProgressBanner => 'जागेवर प्रत्यक्ष काम सुरू आहे.';

  @override
  String get govWorkCompletedBanner =>
      'काम पूर्ण झाले असून तपासणीसाठी सादर केले आहे.';

  @override
  String get govComplaintDetailsTitle => 'तक्रार पाहणी व तपासणी';

  @override
  String get govCitizenDetails => 'नागरिक तपशील';

  @override
  String get govIssueDetails => 'समस्येचा तपशील';

  @override
  String get govVerificationResult => 'पडताळणी निकाल';

  @override
  String get govAiVerification => 'स्वयंचलित एआय पडताळणी';

  @override
  String get govManualReviewRequired => 'मॅन्युअल पडताळणी आवश्यक';

  @override
  String get govAiCouldNotVerify => 'एआय खात्रीशीरपणे विभाग ठरवू शकले नाही.';

  @override
  String get govApproveAndRoute => 'मंजूर करा आणि पाठवा';

  @override
  String get govRejectGrievance => 'तक्रार नाकारा';

  @override
  String get govOverrideDepartment => 'विभाग / प्रकार बदला';

  @override
  String get govSelectTargetDepartment => 'योग्य विभाग निवडा';

  @override
  String get govReviewNotesLabel => 'अधिकारी तपासणी नोंदी';

  @override
  String get govConfirmDepartment => 'विभागीय नियुक्तीची पुष्टी करा';

  @override
  String get govAuditTimeline => 'तक्रार कालमर्यादा व तपासणी इतिहास';

  @override
  String get govAssignOfficer => 'अधिकारी नियुक्त करा';

  @override
  String get govAssignedOfficerLabel => 'नियुक्त क्षेत्रीय अधिकारी';

  @override
  String get govAssignFieldOfficer =>
      'क्षेत्रीय अंमलबजावणी अधिकारी नियुक्त करा';

  @override
  String get govReassignOfficer => 'पुन्हा नियुक्त करा';

  @override
  String get govAvailableOfficers => 'उपलब्ध क्षेत्रीय अधिकारी';

  @override
  String get govOfficerWorkload => 'सक्रिय कामाचा भार';

  @override
  String get govConfirmAssignment => 'नियुक्तीची पुष्टी करा';

  @override
  String get govCancelAssignment => 'रद्द करा';

  @override
  String govAssignmentSuccess(String officerName) {
    return 'तक्रार यशस्वीपणे $officerName यांच्याकडे सोपवली गेली.';
  }

  @override
  String get govAssignmentFailed =>
      'अधिकारी नियुक्त करण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get govSlaStatus => 'एसएलए पूर्तता';

  @override
  String get govWithinSla => 'एसएलए मुदतीत';

  @override
  String get govApproachingSlaDeadline => 'एसएलए मुदत संपत आली आहे';

  @override
  String get govSlaBreached => 'एसएलए मुदत उलटली';

  @override
  String govHoursRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count तास शिल्लक',
      one: '1 तास शिल्लक',
    );
    return '$_temp0';
  }

  @override
  String govDaysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिवस शिल्लक',
      one: '1 दिवस शिल्लक',
    );
    return '$_temp0';
  }

  @override
  String govDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिवसांचा विलंब',
      one: '1 दिवसाचा विलंब',
    );
    return '$_temp0';
  }

  @override
  String govHoursOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count तासांचा विलंब',
      one: '1 तासाचा विलंब',
    );
    return '$_temp0';
  }

  @override
  String get govResolutionReview => 'निवारण गुणवत्ता तपासणी';

  @override
  String get govApproveResolution => 'निवारण मंजूर करा व तक्रार बंद करा';

  @override
  String get govSendForRework => 'पुन्हा कामासाठी परत पाठवा';

  @override
  String get govReworkReasonLabel => 'पुन्हा काम सांगण्याचे कारण';

  @override
  String get govCloseComplaint => 'तक्रार बंद करा';

  @override
  String get govReopenComplaint => 'तक्रार पुन्हा उघडा';

  @override
  String get govTableHeaderId => 'तक्रार क्रमांक';

  @override
  String get govTableHeaderCategory => 'प्रकार';

  @override
  String get govTableHeaderWard => 'प्रभाग';

  @override
  String get govTableHeaderDepartment => 'विभाग';

  @override
  String get govTableHeaderStatus => 'स्थिती';

  @override
  String get govTableHeaderPriority => 'प्राधान्य';

  @override
  String get govTableHeaderSla => 'उर्वरित एसएलए';

  @override
  String get govTableHeaderReported => 'नोंदणी तारीख';

  @override
  String get govTableHeaderActions => 'कृती';

  @override
  String get govSearchComplaintsHint =>
      'तक्रार क्रमांक, नागरिकाचे नाव, ठिकाण यानुसार शोधा...';

  @override
  String get govNoMatchingComplaints => 'कोणतीही जुळणारी तक्रार सापडली नाही.';

  @override
  String get govAllWards => 'सर्व प्रभाग';

  @override
  String get govAllDepartments => 'सर्व विभाग';

  @override
  String get govAllStatuses => 'सर्व स्थिती';

  @override
  String get govRowsPerPage => 'प्रति पृष्ठ पंक्ती';

  @override
  String get govPreviousPage => 'मागील';

  @override
  String get govNextPage => 'पुढील';

  @override
  String get govOfficerProfile => 'शासकीय अधिकारी प्रोफाइल';

  @override
  String get govOfficerName => 'अधिकाऱ्याचे नाव';

  @override
  String get govEmployeeId => 'कर्मचारी आयडी';

  @override
  String get govOfficialEmail => 'अधिकृत ईमेल';

  @override
  String get govDesignation => 'पदनाम';

  @override
  String get govJurisdiction => 'नियुक्त कार्यक्षेत्र';

  @override
  String get govCitywide => 'शहरव्यापी (सर्व परिमंडळे व प्रभाग)';

  @override
  String govWardJurisdiction(String wardName) {
    return 'प्रभाग $wardName';
  }

  @override
  String govZoneJurisdiction(String zoneName) {
    return 'परिमंडळ $zoneName';
  }

  @override
  String get govSignOut => 'शासकीय पोर्टलवरून बाहेर पडा';

  @override
  String get govSignOutConfirm => 'तुम्हाला नक्की साइन आउट करायचे आहे का?';

  @override
  String get govLanguageSettings => 'पोर्टलची भाषा';

  @override
  String get govAppearanceSettings => 'थीम आणि दृश्य रचना';

  @override
  String get govPrivacyPrinciples => 'प्रशासन व डेटा मानके';

  @override
  String get govAboutPortal => 'महापालिका पोर्टलविषयी';

  @override
  String get govVersionInfo => 'CivicFix प्रशासन संच v1.0.0-gov';

  @override
  String get govDashboard => 'महानगरपालिका कामकाज विहंगावलोकन';

  @override
  String get govDashboardSubtitle =>
      'रिअल-टाइम तक्रार टेलीमेट्री आणि नोडल विभाग कार्यभार';

  @override
  String get govTotalComplaints => 'एकूण तक्रारी';

  @override
  String get govReportedComplaints => 'नोंदवलेल्या / नवीन';

  @override
  String get details => 'तपशील';

  @override
  String get unassignedOfficer => 'नियुक्त नाही';

  @override
  String get govInspectAction => 'तपशील पहा';

  @override
  String get govUpdateStatus => 'स्थिती अपडेट करा';

  @override
  String get executionNotStarted => 'सुरू करण्यास तयार';

  @override
  String get executionInProgress => 'काम प्रगतीपथावर आहे';

  @override
  String get executionBlocked => 'काम थांबलेले आहे';

  @override
  String get executionAwaitingEvidence => 'घटनास्थळावरील पुराव्याची प्रतीक्षा';

  @override
  String get executionCompleted => 'काम पूर्ण झाले';

  @override
  String get resolutionPending => 'निवारण प्रलंबित';

  @override
  String get resolutionSubmitted => 'निवारण सादर केले';

  @override
  String get resolutionApproved => 'निवारण मंजूर';

  @override
  String get resolutionRejected => 'निवारण नाकारले';

  @override
  String get resolutionClosed => 'निवारण बंद';

  @override
  String get reworkNotRequired => 'पुन्हा कामाची गरज नाही';

  @override
  String get reworkRequiredState => 'पुन्हा काम आवश्यक';

  @override
  String get reworkInProgress => 'पुन्हा काम प्रगतीपथावर';

  @override
  String get reworkSubmitted => 'पुन्हा काम सादर केले';

  @override
  String get reworkApproved => 'पुन्हा काम मंजूर';

  @override
  String get syncOffline => 'ऑफलाइन रांग';

  @override
  String get syncRetrying => 'सिंकचा पुन्हा प्रयत्न...';

  @override
  String get notifComplaintSubmitted => 'तक्रार नोंदवली';

  @override
  String get notifComplaintVerified => 'तक्रार पडताळली गेली';

  @override
  String get notifComplaintAssigned => 'तक्रार नियुक्त केली';

  @override
  String get notifComplaintStatusChanged => 'स्थिती अद्यतन';

  @override
  String get notifComplaintResolved => 'तक्रारीचे निवारण झाले';

  @override
  String get notifGeneralCivic => 'नागरी सूचना';

  @override
  String get notifHazardAlert => 'धोक्याचा इशारा';

  @override
  String get notifRewardEarned => 'बक्षीस मिळाले';

  @override
  String get notifSlaWarning => 'एसएलए मुदत इशारा';

  @override
  String get notifReworkRequested => 'पुन्हा काम करण्याची विनंती';

  @override
  String get badgeGroundReporter => 'ग्राउंड रिपोर्टर';

  @override
  String get badgeGroundReporterDesc =>
      'नियुक्त केलेल्या वॉर्डशी जुळणारे अचूक निर्देशांक दिले.';

  @override
  String get badgeCommunityVoice => 'सामुदायिक आवाज';

  @override
  String get badgeCommunityVoiceDesc =>
      'पडताळलेल्या तक्रारींवर नागरिकांचा पाठिंबा मिळवला.';

  @override
  String get badgeResolutionChampion => 'निवारण चॅम्पियन';

  @override
  String get badgeResolutionChampionDesc =>
      'पात्र तक्रारींचे पडताळणीसह यशस्वी निवारण पूर्ण केले.';

  @override
  String get civicLevelStarter => 'नागरी नवशिक्या';

  @override
  String get civicLevelContributor => 'नागरी योगदानकर्ता';

  @override
  String get civicLevelChampion => 'नागरी चॅम्पियन';

  @override
  String get civicLevelLeader => 'नागरी मार्गदर्शक';

  @override
  String get civicLevelHero => 'नागरी नायक';

  @override
  String get jurisdictionZone => 'परिमंडळ कार्यक्षेत्र';

  @override
  String get jurisdictionWard => 'प्रभाग कार्यक्षेत्र';

  @override
  String get jurisdictionDepartment => 'विभाग कार्यक्षेत्र';

  @override
  String get jurisdictionRole => 'पद कार्यक्षेत्र';

  @override
  String get routingTicketPending => 'प्रभाग अधिकारी पुनरावलोकन प्रलंबित';

  @override
  String get routingTicketApproved => 'पुनर्नियुक्ती मंजूर';

  @override
  String get routingTicketRejected => 'पुनर्नियुक्ती नाकारली';

  @override
  String get routingTicketCancelled => 'तक्रार रद्द';

  @override
  String get translatedFromEnglish => 'इंग्रजीतून भाषांतरित';

  @override
  String get translatedFromHindi => 'हिंदीमधून भाषांतरित';

  @override
  String get translatedFromMarathi => 'मराठीतून भाषांतरित';

  @override
  String translatedFromLanguage(String language) {
    return '$languageमधून भाषांतरित';
  }

  @override
  String get originalEnglish => 'मूळ — इंग्रजी';

  @override
  String get originalHindi => 'मूळ — हिंदी';

  @override
  String get originalMarathi => 'मूळ — मराठी';

  @override
  String originalLanguage(String language) {
    return 'मूळ — $language';
  }

  @override
  String get viewOriginal => 'मूळ पहा';

  @override
  String get viewTranslation => 'भाषांतर पहा';

  @override
  String get translating => 'भाषांतर होत आहे...';

  @override
  String get translationUnavailable => 'भाषांतर उपलब्ध नाही';

  @override
  String get retryTranslation => 'पुन्हा प्रयत्न करा';

  @override
  String get translationUnavailableOffline => 'ऑफलाइन भाषांतर उपलब्ध नाही';

  @override
  String get complaintRejected => 'तक्रार नाकारली';

  @override
  String get complaintRejectedAuthenticityBody =>
      'या तक्रारीसोबत अपलोड केलेले पुरावे CivicFix च्या सत्यता पडताळणीत अयशस्वी झाले असून ते AI-निर्मित किंवा डिजिटल फेरफार केलेले असल्याचे आढळले आहे.\n\nनागरी तक्रारींसाठी, कृपया प्रत्यक्ष घटनास्थळावरून काढलेले अस्सल छायाचित्र अपलोड करा.';

  @override
  String get reportAgain => 'पुन्हा तक्रार नोंदवा';

  @override
  String get evidenceVerificationFailed => 'पुरावा पडताळणी अयशस्वी';

  @override
  String get aiGeneratedEvidenceDetected =>
      'AI-निर्मित किंवा फेरफार केलेले पुरावे आढळले.';
}
