// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'CivicFix';

  @override
  String get appName => 'CivicFix';

  @override
  String get commonRetry => 'पुनः प्रयास करें';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get appTagline => 'नागरिक समस्या निवारण एवं प्रशासन';

  @override
  String get ok => 'ठीक है';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get submit => 'जमा करें';

  @override
  String get close => 'बंद करें';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get back => 'वापस';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get search => 'खोजें';

  @override
  String get filter => 'फ़िल्टर';

  @override
  String get refresh => 'ताज़ा करें';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get error => 'त्रुटि';

  @override
  String get success => 'सफल';

  @override
  String get warning => 'चेतावनी';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get home => 'होम';

  @override
  String get complaints => 'शिकायतें';

  @override
  String get reportIssue => 'समस्या दर्ज करें';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get map => 'नक्शा';

  @override
  String get navMap => 'नक्शा';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get languageEnglish => 'अंग्रेज़ी';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageMarathi => 'मराठी';

  @override
  String get complaint => 'शिकायत';

  @override
  String get juniorEngineer => 'कनिष्ठ अभियंता';

  @override
  String get fieldOfficer => 'क्षेत्र अधिकारी';

  @override
  String get ward => 'वार्ड';

  @override
  String get department => 'विभाग';

  @override
  String get statusUnderVerification => 'सत्यापन प्रक्रिया में';

  @override
  String get statusReported => 'दर्ज की गई';

  @override
  String get statusAssigned => 'आवंटित';

  @override
  String get statusInProgress => 'प्रगति पर';

  @override
  String get statusResolved => 'समाधान हुआ';

  @override
  String get statusClosed => 'बंद';

  @override
  String get statusReopened => 'पुनः खोली गई';

  @override
  String get trackComplaint => 'शिकायत ट्रैक करें';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get submitReport => 'रिपोर्ट जमा करें';

  @override
  String get continueText => 'जारी रखें';

  @override
  String get backToHome => 'होम पर वापस जाएं';

  @override
  String get saveChanges => 'बदलाव सहेजें';

  @override
  String get assistantHelp => 'सिविक सहायक से पूछें';

  @override
  String get myComplaintsTitle => 'मेरी शिकायतें';

  @override
  String get recentIssues => 'हाल की नागरिक रिपोर्ट';

  @override
  String get nearbyHazards => 'आसपास के खतरे';

  @override
  String get quickActions => 'त्वरित कार्य';

  @override
  String get rewardsTitle => 'नागरिक पुरस्कार';

  @override
  String get assistantTitle => 'सिविक एआई सहायक';

  @override
  String get settingsTitle => 'सेटिंग्स और प्राथमिकताएं';

  @override
  String get noInternetConnection => 'कोई इंटरनेट कनेक्शन नहीं है';

  @override
  String get somethingWentWrong => 'कुछ गलत हो गया';

  @override
  String get operationSuccess => 'कार्य सफलतापूर्वक पूर्ण हुआ';

  @override
  String welcomeUser(String userName) {
    return 'स्वागत है, $userName';
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
      other: '$countString शिकायतें',
      one: '1 शिकायत',
      zero: 'कोई शिकायत नहीं',
    );
    return '$_temp0';
  }

  @override
  String get welcomeBack => 'वापसी पर स्वागत है';

  @override
  String get signInSubtitle =>
      'नागरिक समस्याओं की शिकायत दर्ज करने, सामुदायिक समाधान ट्रैक करने और अपने वार्ड में भाग लेने के लिए साइन इन करें।';

  @override
  String get email => 'ईमेल';

  @override
  String get emailHint => 'उदा. name@example.com';

  @override
  String get password => 'पासवर्ड';

  @override
  String get passwordHint => 'अपना पासवर्ड दर्ज करें';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get login => 'लॉग इन करें';

  @override
  String get orDivider => 'या';

  @override
  String get continueWithGoogle => 'Google के साथ जारी रखें';

  @override
  String get dontHaveAccount => 'क्या आपका खाता नहीं है?';

  @override
  String get createAccount => 'खाता बनाएं';

  @override
  String get govtOfficerLogin => 'शासकीय अधिकारी लॉगिन';

  @override
  String get pleaseEnterEmail => 'कृपया अपना ईमेल दर्ज करें।';

  @override
  String get pleaseEnterValidEmail => 'कृपया एक मान्य ईमेल पता दर्ज करें।';

  @override
  String get pleaseEnterPassword => 'कृपया अपना पासवर्ड दर्ज करें।';

  @override
  String get incorrectEmailOrPassword => 'गलत ईमेल या पासवर्ड।';

  @override
  String get googleSignInFailed =>
      'Google साइन-इन विफल हुआ। कृपया पुनः प्रयास करें।';

  @override
  String get verifyYourPhone => 'अपना फ़ोन सत्यापित करें';

  @override
  String get verifyPhoneSubtitle =>
      'दोहरी नागरिक शिकायतों को रोकने और प्रामाणिकता बनाए रखने के लिए, एसएमएस द्वारा अपना मोबाइल नंबर सत्यापित करें।';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get mobileNumberHint => 'उदा. 9876543210';

  @override
  String get sendVerificationCode => 'सत्यापन कोड भेजें';

  @override
  String get verificationCode => 'सत्यापन कोड';

  @override
  String get enterOtpHint => '6-अंकों का ओटीपी दर्ज करें';

  @override
  String get verifyAndContinue => 'सत्यापित करें और आगे बढ़ें';

  @override
  String get changeNumber => 'नंबर बदलें';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds सेकंड में पुनः कोड भेजें';
  }

  @override
  String get resendVerificationCode => 'सत्यापन कोड पुनः भेजें';

  @override
  String get phoneVerifiedSuccess =>
      'फ़ोन सफलतापूर्वक सत्यापित हुआ! अग्रेषित किया जा रहा है...';

  @override
  String get codeExpired =>
      'सत्यापन कोड समाप्त हो गया है। कृपया नया कोड पाने के लिए पुनः भेजें पर टैप करें।';

  @override
  String get invalidVerificationCode => 'अमान्य सत्यापन कोड।';

  @override
  String get codeSentViaSms => 'एसएमएस द्वारा सत्यापन कोड भेजा गया।';

  @override
  String get failedToSendCode => 'सत्यापन कोड भेजने में विफल।';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get createCivicFixAccount => 'अपना CivicFix खाता बनाएं';

  @override
  String get civicParticipationStarts =>
      'आपकी नागरिक सहभागिता यहाँ से शुरू होती है।';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get fullNameHint => 'अपना पूरा नाम दर्ज करें';

  @override
  String get phoneOptional => 'फ़ोन नंबर (वैकल्पिक)';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get confirmPasswordHint => 'अपना पासवर्ड पुनः दर्ज करें';

  @override
  String get preferredLanguage => 'पसंदीदा भाषा';

  @override
  String get alreadyHaveAccount => 'क्या आपके पास पहले से खाता है?';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते।';

  @override
  String get passwordMinLength => 'पासवर्ड कम से कम 8 वर्णों का होना चाहिए।';

  @override
  String get nameMinLength => 'नाम कम से कम 2 अक्षरों का होना चाहिए।';

  @override
  String get resetYourPassword => 'अपना पासवर्ड रीसेट करें';

  @override
  String get resetPasswordSubtitle =>
      'पासवर्ड रीसेट निर्देश प्राप्त करने के लिए अपने खाते से जुड़ा ईमेल दर्ज करें।';

  @override
  String get sendResetLink => 'रीसेट लिंक भेजें';

  @override
  String get backToLogin => 'लॉगिन पर वापस जाएं';

  @override
  String get resetLinkSent => 'पासवर्ड रीसेट निर्देश भेज दिए गए हैं।';

  @override
  String get loadingCivicDashboard => 'नागरिक डैशबोर्ड लोड हो रहा है...';

  @override
  String get viewAllComplaints => 'सभी शिकायतें देखें →';

  @override
  String get viewHazardMap => 'खतरा नक्शा देखें →';

  @override
  String get yourCivicProgress => 'आपकी नागरिक प्रगति';

  @override
  String get noComplaintsYet => 'अभी तक कोई शिकायत नहीं';

  @override
  String get reportIssueToGetStarted =>
      'शुरुआत करने के लिए नागरिक समस्या दर्ज करें।';

  @override
  String get noImmediateHazards =>
      'आपके नजदीकी क्षेत्र में कोई तात्कालिक खतरा दर्ज नहीं है।';

  @override
  String get assistantSubtitle => 'CivicFix के साथ सहायता प्राप्त करें';

  @override
  String get rewardsSubtitle => 'अपनी नागरिक प्रगति देखें';

  @override
  String get reportCivicIssueAction => 'नागरिक समस्या दर्ज करें';

  @override
  String get recentCivicReports => 'हाल की शिकायतें';

  @override
  String get nearbyCivicIssues => 'आसपास की नागरिक समस्याएं';

  @override
  String get issueInformation => 'समस्या की जानकारी';

  @override
  String get issueInfoSubtitle =>
      'समस्या को समझने में हमारी सहायता करें ताकि यह सही टीम तक पहुँच सके।';

  @override
  String get issueTitle => 'समस्या का शीर्षक';

  @override
  String get issueTitleHint => 'उदा. पार्क के पास टूटी हुई स्ट्रीट लाइट';

  @override
  String get selectCategoryError => 'कृपया समस्या श्रेणी चुनें।';

  @override
  String get describeTheIssue => 'समस्या का वर्णन करें';

  @override
  String get describeIssueHint =>
      'हमें बताएं कि क्या हुआ और आपने समस्या कहाँ देखी।';

  @override
  String get describeIssueHelp =>
      'उपयोगी विवरण शामिल करें जैसे कि क्या क्षतिग्रस्त है, यह कब से हो रहा है, या यह क्षेत्र को कैसे प्रभावित करता है।';

  @override
  String get immediateSafetyHazard => 'तात्कालिक सुरक्षा खतरा';

  @override
  String get safetyHazardSubtitle =>
      'यदि यह समस्या नागरिकों या यातायात के लिए तात्कालिक जोखिम पैदा करती है तो चुनें';

  @override
  String get addEvidence => 'साक्ष्य जोड़ें';

  @override
  String get addEvidenceSubtitle =>
      'फ़ोटो जिम्मेदार टीम को समस्या समझने में मदद कर सकती है।';

  @override
  String get whereIsTheIssue => 'समस्या कहाँ है?';

  @override
  String get whereIsIssueSubtitle =>
      'स्थान जोड़ें ताकि जिम्मेदार टीम इसे ढूंढ सके।';

  @override
  String get selectLocationError => 'कृपया समस्या का स्थान चुनें या पहचानें।';

  @override
  String get reviewYourIssue => 'अपनी शिकायत की समीक्षा करें';

  @override
  String get reviewIssueSubtitle =>
      'अपने वार्ड में जमा करने से पहले सभी जानकारी की पुष्टि करें।';

  @override
  String get nextAddEvidence => 'अगला: साक्ष्य जोड़ें';

  @override
  String get nextLocation => 'अगला: स्थान';

  @override
  String get skipAndContinue => 'छोड़ें और आगे बढ़ें';

  @override
  String get nextReview => 'अगला: समीक्षा';

  @override
  String get discardReportTitle => 'क्या इस रिपोर्ट को रद्द करें?';

  @override
  String get discardReportMessage => 'आपकी दर्ज की गई जानकारी मिट जाएगी।';

  @override
  String get keepEditing => 'संपादन जारी रखें';

  @override
  String get discard => 'रद्द करें';

  @override
  String get stepInformation => 'जानकारी';

  @override
  String get stepEvidence => 'साक्ष्य';

  @override
  String get stepLocation => 'स्थान';

  @override
  String get stepReview => 'समीक्षा';

  @override
  String get complaintSavedOffline => 'शिकायत ऑफ़लाइन सुरक्षित की गई';

  @override
  String get issueReportedSuccess => 'समस्या दर्ज की गई';

  @override
  String get offlineSubmissionNote =>
      'शिकायत सहेजी गई। आपके ऑनलाइन आने पर इसे जमा किया जाएगा।';

  @override
  String get onlineSubmissionNote => 'आपकी शिकायत सफलतापूर्वक जमा कर दी गई है।';

  @override
  String get localReference => 'स्थानीय संदर्भ';

  @override
  String get complaintId => 'शिकायत आईडी';

  @override
  String get status => 'स्थिति';

  @override
  String get pendingSync => 'सिंक लंबित';

  @override
  String get syncing => 'सिंक हो रहा है...';

  @override
  String get syncFailed => 'सिंक विफल';

  @override
  String get civicReward => 'नागरिक पुरस्कार';

  @override
  String pointsReward(int count) {
    return '+$count अंक';
  }

  @override
  String get viewComplaint => 'शिकायत देखें';

  @override
  String get trackFromMyComplaints =>
      'आप \'मेरी शिकायतें\' से इस समस्या की प्रगति ट्रैक कर सकते हैं।';

  @override
  String get offlineStoredSecurely =>
      'आपकी शिकायत इस डिवाइस पर सुरक्षित रूप से सहेजी गई है और इंटरनेट कनेक्ट होते ही सिंक हो जाएगी।';

  @override
  String get confirmLocation => 'स्थान की पुष्टि करें';

  @override
  String get confirmThisLocation => 'इस स्थान की पुष्टि करें';

  @override
  String get selectedLocation => 'चुना गया स्थान';

  @override
  String get tapMapToPositionPin => 'पिन लगाने के लिए नक्शे पर टैप करें';

  @override
  String get searchLocationHint => 'सड़क, क्षेत्र या लैंडमार्क खोजें...';

  @override
  String get couldNotAcquireGps =>
      'GPS स्थिति प्राप्त नहीं हो सकी। कृपया पिन को मैन्युअल रूप से सेट करें।';

  @override
  String get trackCivicIssuesSubtitle =>
      'अपनी दर्ज की गई नागरिक समस्याओं को ट्रैक करें।';

  @override
  String get searchComplaintsHint => 'शिकायतें खोजें...';

  @override
  String get all => 'सभी';

  @override
  String get allStatuses => 'सभी स्थितियां';

  @override
  String get allCategories => 'सभी श्रेणियां';

  @override
  String complaintsFound(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString शिकायतें मिलीं',
      one: '1 शिकायत मिली',
      zero: 'कोई शिकायत नहीं मिली',
    );
    return '$_temp0';
  }

  @override
  String get clearAll => 'सभी हटाएं';

  @override
  String get clearFilters => 'फ़िल्टर साफ़ करें';

  @override
  String get noComplaintsFound => 'कोई शिकायत नहीं मिली';

  @override
  String get tryDifferentSearch => 'एक अलग खोज या फ़िल्टर आज़माएं।';

  @override
  String get filterAndSort => 'फ़िल्टर और क्रमबद्ध करें';

  @override
  String get complaintStatus => 'शिकायत की स्थिति';

  @override
  String get issueCategory => 'समस्या श्रेणी';

  @override
  String get sortBy => 'इसके अनुसार क्रमबद्ध करें';

  @override
  String get applyFilters => 'फ़िल्टर लागू करें';

  @override
  String get recentlyUpdated => 'हाल ही में अपडेट किया गया';

  @override
  String get newestFirst => 'सबसे नया पहले';

  @override
  String get oldestFirst => 'सबसे पुराना पहले';

  @override
  String get support => 'समर्थन करें';

  @override
  String supportsCount(int count) {
    return '$count समर्थन';
  }

  @override
  String get supportedComplaint => 'शिकायत का समर्थन किया!';

  @override
  String get alreadySupported => 'आप पहले ही इस शिकायत का समर्थन कर चुके हैं।';

  @override
  String get safetyHazard => 'सुरक्षा खतरा';

  @override
  String updatedTime(String time) {
    return 'अपडेट: $time';
  }

  @override
  String reportedTime(String time) {
    return 'दर्ज: $time';
  }

  @override
  String copiedTicketId(String ticket) {
    return 'शिकायत आईडी $ticket कॉपी किया गया।';
  }

  @override
  String get complaintDetails => 'शिकायत का विवरण';

  @override
  String get assignedMunicipalTeam => 'आवंटित नगरपालिका टीम';

  @override
  String get responsibleOfficersSubtitle =>
      'आपकी शिकायत का प्रबंधन और समाधान करने वाले जिम्मेदार अधिकारी';

  @override
  String get supervisingJuniorEngineer => 'पर्यवेक्षी कनिष्ठ अभियंता';

  @override
  String get supervising => 'पर्यवेक्षण';

  @override
  String get autoRoutingToWard => 'वार्ड इंजीनियर को ऑटो-रूट हो रहा है...';

  @override
  String get fieldExecutionOfficer => 'क्षेत्र निष्पादन अधिकारी';

  @override
  String get pendingFieldAllocation => 'फील्ड आवंटन लंबित';

  @override
  String get temporarilyOnHold => 'अस्थायी रूप से स्थगित';

  @override
  String get workCompleted => 'कार्य संपन्न';

  @override
  String get workInProgress => 'कार्य प्रगति पर है';

  @override
  String get assignedForFieldWork => 'फील्ड कार्य हेतु आवंटित';

  @override
  String get awaitingFieldOfficerAssignment =>
      'पर्यवेक्षी कनिष्ठ अभियंता द्वारा क्षेत्रीय अधिकारी आवंटन की प्रतीक्षा है।';

  @override
  String groundObstacle(String reason) {
    return 'जमीनी बाधा: $reason';
  }

  @override
  String get groundWorkPaused =>
      'साइट की बाधाओं के कारण कार्य अस्थायी रूप से रुका हुआ है।';

  @override
  String get groundRepairExecuted =>
      'जमीनी मरम्मत सफलतापूर्वक निष्पादित और सत्यापित की गई।';

  @override
  String get reopenedForQualityRework => 'गुणवत्ता सुधार हेतु पुनः खोला गया';

  @override
  String get supervisoryReviewAction => 'पर्यवेक्षी गुणवत्ता समीक्षा कार्रवाई';

  @override
  String get reworkRequired => 'पुनः कार्य आवश्यक';

  @override
  String reworkCycle(int count) {
    return 'पुनः कार्य चक्र #$count';
  }

  @override
  String get reasonForReopening => 'पुनः खोलने का कारण';

  @override
  String get slaPreservedNote =>
      'प्रस्तुत करने से मूल एसएलए संरक्षित। प्राथमिकता के साथ जमीनी कार्य जारी है।';

  @override
  String get resolutionAndVerification => 'समाधान एवं कार्य सत्यापन';

  @override
  String get groundInspectionEvidence => 'जमीनी निरीक्षण एवं समापन साक्ष्य';

  @override
  String get reportedIssueBefore => 'दर्ज की गई समस्या (पहले)';

  @override
  String get resolvedConditionAfter => 'समाधान के बाद की स्थिति (बाद में)';

  @override
  String get officerResolutionRemarks => 'अधिकारी समाधान टिप्पणी';

  @override
  String executedByOfficer(String officer) {
    return '$officer द्वारा निष्पादित';
  }

  @override
  String resolvedOnDate(String date) {
    return '$date को समाधान हुआ';
  }

  @override
  String get issueResolvedBanner => '✓ समस्या का समाधान हुआ';

  @override
  String get issueResolvedSubtitle =>
      'इस शिकायत को समाधान के रूप में चिह्नित किया गया है।';

  @override
  String get currentPhase => 'वर्तमान चरण';

  @override
  String get progress => 'प्रगति';

  @override
  String get updates => 'अपडेट्स';

  @override
  String get noUpdatesYet => 'अभी तक कोई अपडेट नहीं।';

  @override
  String reportedOn(String date) {
    return '$date को दर्ज की गई';
  }

  @override
  String get viewLocation => 'स्थान देखें';

  @override
  String evidencePhotos(int count) {
    return 'फ़ोटो साक्ष्य ($count)';
  }

  @override
  String get noPhotosAttached => 'कोई फ़ोटो संलग्न नहीं (वैकल्पिक)';

  @override
  String photoPreview(int current, int total) {
    return 'फ़ोटो पूर्वावलोकन ($current / $total)';
  }

  @override
  String get closePreview => 'पूर्वावलोकन बंद करें';

  @override
  String routedToDepartment(String department) {
    return 'यह समस्या $department को भेजी जाएगी।';
  }

  @override
  String get markAllAsRead => 'सभी को पढ़ा हुआ चिह्नित करें';

  @override
  String get allNotificationsMarkedRead =>
      'सभी सूचनाएं पढ़ी हुई चिह्नित की गईं।';

  @override
  String get unread => 'अपठित';

  @override
  String get read => 'पठित';

  @override
  String get noUnreadNotifications => 'कोई अपठित सूचना नहीं है';

  @override
  String get noUnreadNotificationsDesc =>
      'आपने अपनी शिकायतों और वार्ड सूचनाओं के सभी अपडेट पढ़ लिए हैं।';

  @override
  String get noNotificationsYet => 'अभी तक कोई सूचना नहीं है।';

  @override
  String get noNotificationsYetDesc =>
      'जब आपकी किसी शिकायत पर कोई अपडेट होगा, तो वह यहाँ दिखाई देगा।';

  @override
  String get citizenProfile => 'नागरिक प्रोफ़ाइल';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get civicContribution => 'नागरिक योगदान';

  @override
  String get viewAchievements => 'उपलब्धियां देखें';

  @override
  String get reports => 'रिपोर्ट्स';

  @override
  String get resolved => 'समाधान';

  @override
  String get civicPoints => 'नागरिक अंक';

  @override
  String get civicEngagement => 'नागरिक सहभाग';

  @override
  String get civicRewardsAndAchievements => 'नागरिक पुरस्कार एवं उपलब्धियां';

  @override
  String get civicAssistant => 'सिविक सहायक';

  @override
  String get assistantSubtitleLong =>
      'अक्सर पूछे जाने वाले प्रश्न, शिकायत नियम और श्रेणी सहायता';

  @override
  String get settingsAndPrivacy => 'सेटिंग्स और गोपनीयता';

  @override
  String get notificationPreferences => 'सूचना प्राथमिकताएं';

  @override
  String get notificationPreferencesSubtitle =>
      'स्थिति अलर्ट, खतरा चेतावनी और ध्वनि';

  @override
  String get privacyAndSafety => 'गोपनीयता और सुरक्षा';

  @override
  String get privacyAndSafetySubtitle => 'गोपनीयता और सार्वजनिक नक्शा नीति';

  @override
  String get aboutCivicFix => 'CivicFix के बारे में';

  @override
  String get aboutCivicFixSubtitle => 'मिशन, प्रशासन मॉडल और तकनीक';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get logoutConfirmTitle => 'लॉग आउट करें?';

  @override
  String get logoutConfirmMessage => 'क्या आप वाकई लॉग आउट करना चाहते हैं?';

  @override
  String get profileUpdatedSuccess => 'प्रोफ़ाइल सफलतापूर्वक अपडेट की गई।';

  @override
  String get profileUpdateFailed =>
      'प्रोफ़ाइल अपडेट नहीं हो सकी। कृपया पुनः प्रयास करें।';

  @override
  String get viewDetails => 'विवरण देखें';

  @override
  String get closeComplaintCard => 'शिकायत कार्ड बंद करें';

  @override
  String get searchHazardsHint => 'खतरे या शिकायतें खोजें...';

  @override
  String get unableToOpenComplaint => 'यह शिकायत खोलने में असमर्थ।';

  @override
  String get complaintBelongsToOther =>
      'यह रिपोर्ट किसी अन्य नागरिक खाते से संबंधित है।';

  @override
  String get backToMyComplaints => 'मेरी शिकायतों पर वापस जाएं';

  @override
  String get complaintNotFound => 'शिकायत नहीं मिली।';

  @override
  String get complaintNotFoundDesc => 'यह शिकायत अब उपलब्ध नहीं हो सकती है।';

  @override
  String get couldNotLoadComplaint => 'यह शिकायत लोड नहीं हो सकी।';

  @override
  String get couldNotLoadNotifications => 'सूचनाएं लोड नहीं हो सकीं।';

  @override
  String get checkConnectionAndRetry =>
      'कृपया अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get pleaseEnterName => 'कृपया अपना नाम दर्ज करें।';

  @override
  String get pleaseEnterValidPhone =>
      'कृपया एक मान्य फ़ोन नंबर दर्ज करें (कम से कम 10 अंक)।';

  @override
  String get passwordMinCharsHint => 'कम से कम 8 अक्षर';

  @override
  String get pleaseConfirmPassword => 'कृपया अपने पासवर्ड की पुष्टि करें।';

  @override
  String get accountCreatedSuccess => 'खाता सफलतापूर्वक बनाया गया।';

  @override
  String get registrationFailed => 'पंजीकरण विफल रहा। कृपया पुनः प्रयास करें।';

  @override
  String get createAccountBtn => 'खाता बनाएं';

  @override
  String get changeAction => 'बदलें';

  @override
  String get verificationCodeHint => '6-अंकीय ओटीपी दर्ज करें';

  @override
  String get pleaseEnterVerificationCode => 'कृपया सत्यापन कोड दर्ज करें।';

  @override
  String get verificationCodeMinLength =>
      'सत्यापन कोड कम से कम 4 अंकों का होना चाहिए।';

  @override
  String get unableToResendCode => 'सत्यापन कोड पुनः भेजने में असमर्थ।';

  @override
  String get enterRegisteredEmail => 'अपना पंजीकृत ईमेल दर्ज करें';

  @override
  String get passwordResetSent => 'पासवर्ड रीसेट निर्देश भेज दिए गए हैं।';

  @override
  String get unableToProcessReset => 'रीसेट अनुरोध संसाधित करने में असमर्थ।';

  @override
  String get navHome => 'होम';

  @override
  String get navComplaints => 'शिकायतें';

  @override
  String get navNotifications => 'सूचनाएं';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get loadingDashboard => 'नागरिक डैशबोर्ड लोड हो रहा है...';

  @override
  String get unableToLoadUpdates =>
      'नागरिक अपडेट लोड करने में असमर्थ। कृपया पुनः प्रयास करें।';

  @override
  String get assistant => 'सहायक';

  @override
  String get reportToGetStarted =>
      'शुरू करने के लिए नागरिक समस्या की शिकायत दर्ज करें।';

  @override
  String get noNearbyHazards =>
      'आपके निकटवर्ती क्षेत्र में कोई तात्कालिक खतरे की शिकायत नहीं है।';

  @override
  String get issueInformationTitle => 'समस्या की जानकारी';

  @override
  String get issueInformationSubtitle =>
      'समस्या को समझने में हमारी सहायता करें ताकि यह सही टीम तक पहुँच सके।';

  @override
  String get issueTitleLabel => 'समस्या का शीर्षक';

  @override
  String get pleaseEnterIssueTitle =>
      'कृपया समस्या के लिए एक शीर्षक दर्ज करें।';

  @override
  String get issueTitleMinLength => 'शीर्षक कम से कम 5 अक्षरों का होना चाहिए।';

  @override
  String get pleaseSelectCategory => 'कृपया एक समस्या श्रेणी चुनें।';

  @override
  String get pleaseDescribeIssue => 'कृपया समस्या का विवरण दें।';

  @override
  String get describeIssueMinLength =>
      'विवरण कम से कम 10 अक्षरों का होना चाहिए।';

  @override
  String get describeIssueHelper =>
      'उपयोगी विवरण शामिल करें जैसे कि क्या क्षतिग्रस्त है, यह कब से हो रहा है, या यह क्षेत्र को कैसे प्रभावित करता है।';

  @override
  String get addLocationSubtitle =>
      'स्थान जोड़ें ताकि जिम्मेदार टीम इसे ढूंढ सके।';

  @override
  String get submitIssue => 'शिकायत दर्ज करें';

  @override
  String get supervisingStatus => 'पर्यवेक्षण';

  @override
  String get routingStatus => 'आवंटित किया जा रहा है...';

  @override
  String get awaitingFieldAllocationNote =>
      'पर्यवेक्षी कनिष्ठ अभियंता द्वारा क्षेत्र अधिकारी आवंटन की प्रतीक्षा है।';

  @override
  String get groundRepairVerified =>
      'जमीनी मरम्मत कार्य पूरा हुआ और सफलतापूर्वक सत्यापित किया गया।';

  @override
  String get executionUnderway => 'साइट पर कार्य वर्तमान में प्रगति पर है।';

  @override
  String get fieldOfficerAllocatedNote =>
      'क्षेत्र अधिकारी आवंटित। जमीनी कार्य निर्धारित।';

  @override
  String get originalSlaPreserved =>
      'प्रस्तुति से मूल एसएलए संरक्षित। प्राथमिकता से जमीनी कार्य प्रगति पर है।';

  @override
  String get resolutionAndWorkVerification => 'समाधान एवं कार्य सत्यापन';

  @override
  String get issueReportedTitle => 'शिकायत दर्ज की गई';

  @override
  String get issueSubmittedSuccess =>
      'आपकी शिकायत सफलतापूर्वक दर्ज कर ली गई है।';

  @override
  String get plusTwentyPoints => '+20 अंक';

  @override
  String get storedLocallyNote =>
      'आपकी शिकायत इस डिवाइस पर सुरक्षित रूप से संग्रहीत है और इंटरनेट कनेक्ट होने पर सिंक हो जाएगी।';

  @override
  String get trackFromMyComplaintsNote =>
      'आप \'मेरी शिकायतें\' से इस समस्या की प्रगति को ट्रैक कर सकते हैं।';

  @override
  String get noComplaintsFoundDesc => 'भिन्न खोज या फ़िल्टर का प्रयास करें।';

  @override
  String get noComplaintsReportedYet => 'अभी तक कोई शिकायत दर्ज नहीं की गई';

  @override
  String get supportedComplaintSuccess => 'शिकायत का समर्थन किया!';

  @override
  String get alreadySupportedComplaint =>
      'आप पहले ही इस शिकायत का समर्थन कर चुके हैं।';

  @override
  String get statusVerified => 'सत्यापित';

  @override
  String get statusRejected => 'अस्वीकृत';

  @override
  String get loadingComplaints => 'आपकी शिकायतें लोड हो रही हैं...';

  @override
  String get failedToLoadComplaints => 'आपकी शिकायतें लोड नहीं की जा सकीं।';

  @override
  String get reportCivicIssueTrackProgress =>
      'नागरिक समस्या दर्ज करें और यहां उसकी प्रगति ट्रैक करें।';

  @override
  String get reportAnIssue => 'शिकायत दर्ज करें';

  @override
  String get trackCivicIssuesReported =>
      'आपके द्वारा दर्ज की गई नागरिक समस्याओं को ट्रैक करें।';

  @override
  String get clearSearch => 'खोज साफ़ करें';

  @override
  String complaintIdCopied(String ticketNumber) {
    return 'शिकायत आईडी $ticketNumber कॉपी की गई।';
  }

  @override
  String get locationSelected => 'स्थान चुना गया';

  @override
  String get supports => 'समर्थन';

  @override
  String get closeFilters => 'फ़िल्टर बंद करें';

  @override
  String get noComplaintSpecified => 'कोई शिकायत निर्दिष्ट नहीं की गई।';

  @override
  String get waitingForConnection => 'इंटरनेट कनेक्शन की प्रतीक्षा';

  @override
  String get complaintStoredSecurelyOffline =>
      'आपकी शिकायत इस डिवाइस पर सुरक्षित रूप से संग्रहीत है और इंटरनेट उपलब्ध होते ही जमा हो जाएगी।';

  @override
  String get synchronizingWithCloud => 'क्लाउड के साथ सिंक्रनाइज़ हो रहा है';

  @override
  String get uploadingComplaintData =>
      'नगरपालिका नेटवर्क पर शिकायत डेटा और साक्ष्य अपलोड हो रहे हैं...';

  @override
  String get synchronizationFailed => 'सिंक्रनाइज़ेशन विफल';

  @override
  String get failedToSyncWithCloud =>
      'क्लाउड बैकएंड के साथ इस रिपोर्ट को सिंक करने में विफल। कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get retrySync => 'पुनः सिंक करें';

  @override
  String get complaintMarkedResolved =>
      'इस शिकायत को समाधानित के रूप में चिह्नित किया गया है।';

  @override
  String reportedOnDate(String date) {
    return '$date को दर्ज की गई';
  }

  @override
  String lastUpdatedTime(String time) {
    return 'अंतिम अपडेट $time';
  }

  @override
  String get wardLabel => 'वार्ड';

  @override
  String get central => 'सेंट्रल';

  @override
  String get groundWorkTemporarilyPaused =>
      'साइट बाधाओं के कारण जमीनी काम अस्थायी रूप से रुका हुआ है।';

  @override
  String commencedTime(String time) {
    return '$time शुरू हुआ।';
  }

  @override
  String get executionUnderwayOnSite => 'साइट पर निष्पादन वर्तमान में जारी है।';

  @override
  String get pendingAllocation => 'आवंटन लंबित';

  @override
  String get defaultReopenReason =>
      'ऑडिट समीक्षा में कार्य की गुणवत्ता नगरपालिका मानकों के अनुरूप नहीं पाई गई। सुधारात्मक कार्रवाई के लिए पुनः सौंपा गया।';

  @override
  String get deptLeadQualityAudit => 'विभाग प्रमुख गुणवत्ता ऑडिट';

  @override
  String get reviewedBy => 'समीक्षक';

  @override
  String get slaPreservedPriorityExecution =>
      'प्रस्तुतीकरण से मूल SLA संरक्षित। प्राथमिकता पर जमीनी निष्पादन जारी।';

  @override
  String get hidePreviousResolutionRecord => 'पिछला समाधान रिकॉर्ड छुपाएं';

  @override
  String get viewPreviousResolutionRecord => 'पिछला समाधान रिकॉर्ड देखें';

  @override
  String get photos => 'तस्वीरें';

  @override
  String get priorResolutionTimestamp => 'पूर्व समाधान समय';

  @override
  String executedBy(String name) {
    return '$name द्वारा निष्पादित';
  }

  @override
  String get progressTracker => 'प्रगति ट्रैकर';

  @override
  String get stage => 'चरण';

  @override
  String get ofFive => '/ 5';

  @override
  String get currentCaps => 'वर्तमान';

  @override
  String get categoryLabel => 'श्रेणी';

  @override
  String get departmentLabel => 'विभाग';

  @override
  String get priorityLabel => 'प्राथमिकता';

  @override
  String get noDescriptionProvided => 'कोई अतिरिक्त विवरण नहीं दिया गया।';

  @override
  String get landmark => 'लैंडमार्क';

  @override
  String get jurisdiction => 'अधिकार क्षेत्र';

  @override
  String get updatesTitle => 'अपडेट';

  @override
  String get entry => 'प्रविष्टि';

  @override
  String get entries => 'प्रविष्टियां';

  @override
  String get hazardMapTitle => 'खतरा मानचित्र';

  @override
  String get couldNotLoadCivicIssues => 'नागरिक समस्याएं लोड नहीं की जा सकीं।';

  @override
  String get checkConnectionRetry =>
      'कृपया अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get loadingHazardMap => 'नागरिक खतरा मानचित्र लोड हो रहा है...';

  @override
  String get offlineCachedHazardsBanner =>
      'ऑफ़लाइन — कैश्ड खतरे दिखाए जा रहे हैं। बेस-मैप टाइल्स के लिए नेटवर्क आवश्यक है।';

  @override
  String get locationServicesDisabled =>
      'आपके डिवाइस पर स्थान सेवाएं अक्षम हैं।';

  @override
  String get locationPermissionRequired =>
      'नक्शे को केंद्रित करने के लिए स्थान अनुमति आवश्यक है।';

  @override
  String centeredOnLocation(String wardText) {
    return 'आपके स्थान$wardText पर केंद्रित';
  }

  @override
  String get unableToDetermineLocation =>
      'आपका स्थान निर्धारित करने में असमर्थ। कृपया पुनः प्रयास करें।';

  @override
  String get gpsTimeoutRetry =>
      'जीपीएस प्राप्ति का समय समाप्त हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get hideHeatmapLayer => 'हीटमैप परत छुपाएं';

  @override
  String get showHeatmapLayer => 'हीटमैप परत दिखाएं';

  @override
  String get toggleMapLegend => 'मानचित्र संकेत टॉगल करें';

  @override
  String get useMyLocation => 'मेरे स्थान का उपयोग करें';

  @override
  String get zoomIn => 'ज़ूम इन';

  @override
  String get zoomOut => 'ज़ूम आउट';

  @override
  String get statusLegend => 'स्थिति संकेत';

  @override
  String get civicIssuesNearYou => 'आपके निकट नागरिक समस्याएं';

  @override
  String get noCivicIssuesFound => 'कोई नागरिक समस्या नहीं मिली।';

  @override
  String get tryChangingFiltersOrSearch =>
      'अपने फ़िल्टर या खोज को बदलने का प्रयास करें।';

  @override
  String get logoutConfirmationTitle => 'लॉग आउट करें?';

  @override
  String get logoutConfirmationDesc =>
      'क्या आप निश्चित रूप से लॉग आउट करना चाहते हैं?';

  @override
  String get viewMilestones => 'माइलस्टोन देखें';

  @override
  String get civicAssistantSubtitle =>
      'अक्सर पूछे जाने वाले प्रश्न, शिकायत नियम और श्रेणी सहायता';

  @override
  String get accountAndPreferences => 'खाता एवं प्राथमिकताएं';

  @override
  String get appearance => 'दिखावट';

  @override
  String get themeMode => 'थीम मोड';

  @override
  String get systemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get lightTheme => 'लाइट थीम';

  @override
  String get darkTheme => 'डार्क थीम';

  @override
  String get appVersion => 'ऐप संस्करण';

  @override
  String get actions => 'कार्य';

  @override
  String get personalInformation => 'व्यक्तिगत जानकारी';

  @override
  String get enterFullName => 'अपना पूरा नाम दर्ज करें';

  @override
  String get emailCannotBeChanged =>
      'नागरिक खाते के लिए ईमेल बदला नहीं जा सकता।';

  @override
  String get phoneHelperText =>
      'तत्काल पड़ोस अलर्ट पर एसएमएस अपडेट के लिए उपयोग किया जाता है।';

  @override
  String get registeredCitizenAccount => 'पंजीकृत नागरिक खाता';

  @override
  String get citizen => 'नागरिक';

  @override
  String get nameTooShort => 'नाम कम से कम 2 अक्षरों का होना चाहिए।';

  @override
  String get nameTooLong => 'नाम 50 अक्षरों से अधिक नहीं हो सकता।';

  @override
  String get phoneInvalid => 'कृपया मान्य 10 अंकों का फोन नंबर दर्ज करें।';

  @override
  String get discardReportDesc => 'आपकी दर्ज की गई जानकारी नष्ट हो जाएगी।';

  @override
  String get filterCivicIssues => 'नागरिक समस्याएं फ़िल्टर करें';

  @override
  String get closeFilter => 'फ़िल्टर बंद करें';

  @override
  String get hazardCategory => 'खतरा श्रेणी';

  @override
  String get issueStatus => 'समस्या की स्थिति';

  @override
  String get reportTimeframe => 'रिपोर्ट समय सीमा';

  @override
  String get civicStanding => 'नागरिक प्रतिष्ठा';

  @override
  String get tierProgress => 'योगदान स्तर प्रगति';

  @override
  String get totalPoints => 'कुल अंक';

  @override
  String get reportsFiled => 'दर्ज शिकायतें';

  @override
  String get resolvedFixes => 'समाधानित सुधार';

  @override
  String get selectCategorySubtitle =>
      'वह श्रेणी चुनें जो समस्या से सबसे अच्छी तरह मेल खाती है।';

  @override
  String get stepInfo => 'जानकारी';

  @override
  String get recentComplaints => 'हाल की शिकायतें';

  @override
  String get rewards => 'इनाम';

  @override
  String resendCodeInSeconds(int seconds) {
    return '$seconds सेकंड में कोड पुनः भेजें';
  }

  @override
  String get immediateSafetyHazardTitle => 'तात्कालिक सुरक्षा खतरा';

  @override
  String get addEvidenceTitle => 'साक्ष्य जोड़ें';

  @override
  String get aiFallbackReviewTitle => 'विभागीय समीक्षा के अधीन';

  @override
  String get aiFallbackReviewMessage =>
      'स्वचालित सत्यापन अस्थायी रूप से अनुपलब्ध है। आपकी शिकायत को विभागीय समीक्षा के लिए भेजा गया है। एसएलए सक्रिय है और निवारण सामान्य रूप से जारी है।';

  @override
  String get aiFallbackConfirmedMessage =>
      'मैनुअल समीक्षा के माध्यम से विभाग की पुष्टि की गई। कनिष्ठ अभियंता को निर्देशित किया गया।';

  @override
  String get aiFallbackTransferredMessage =>
      'मैनुअल समीक्षा के माध्यम से दूसरे बीएमसी विभाग में स्थानांतरित किया गया।';

  @override
  String get useDeviceLocation => 'डिवाइस स्थान का उपयोग करें';

  @override
  String get selectOnMap => 'नक्शे पर चुनें';

  @override
  String get centerOnGps => 'मेरे GPS पर केंद्रित करें';

  @override
  String get verifyBeforeSubmitting =>
      'कृपया अपने वार्ड में जमा करने से पहले सभी जानकारी की पुष्टि करें।';

  @override
  String get markedImmediateSafetyHazard =>
      'तात्कालिक सुरक्षा खतरे के रूप में चिह्नित';

  @override
  String photoEvidenceCount(int count) {
    return 'फ़ोटो साक्ष्य ($count)';
  }

  @override
  String nearLandmark(String landmark) {
    return '$landmark के पास';
  }

  @override
  String landmarkLabel(String landmark) {
    return 'सीमाचिह्न: $landmark';
  }

  @override
  String jurisdictionLabel(String ward) {
    return 'अधिकार क्षेत्र: $ward';
  }

  @override
  String issueRoutedTo(String department) {
    return 'यह समस्या $department को भेजी जाएगी।';
  }

  @override
  String get categoryRoads => 'सड़कें';

  @override
  String get categoryRoadsDesc => 'सड़क क्षति, गड्ढे और असुरक्षित सड़क की सतह।';

  @override
  String get categoryWater => 'जल आपूर्ति';

  @override
  String get categoryWaterDesc =>
      'पानी की आपूर्ति में समस्या, रिसाव या संदूषण।';

  @override
  String get categorySanitation => 'स्वच्छता';

  @override
  String get categorySanitationDesc =>
      'सार्वजनिक स्वच्छता, शौचालय और सड़क सफाई।';

  @override
  String get categoryWaste => 'कचरा प्रबंधन';

  @override
  String get categoryWasteDesc => 'कचरा जमा होना और कचरा संग्रहण की समस्याएं।';

  @override
  String get categoryStreetlights => 'स्ट्रीट लाइट';

  @override
  String get categoryStreetlightsDesc => 'टूटी या खराब स्ट्रीट लाइटें।';

  @override
  String get categoryDrainage => 'जल निकासी';

  @override
  String get categoryDrainageDesc => 'बंद नालियां, जलभराव और खुले मैनहोल।';

  @override
  String get categoryInfrastructure => 'सार्वजनिक अवसंरचना';

  @override
  String get categoryInfrastructureDesc =>
      'क्षतिग्रस्त फुटपाथ, पुल, बस शेल्टर।';

  @override
  String get categoryTraffic => 'यातायात / सड़क सुरक्षा';

  @override
  String get categoryTrafficDesc =>
      'क्षतिग्रस्त संकेत, लापता सिग्नल, खतरनाक चौराहे।';

  @override
  String get categoryOther => 'अन्य';

  @override
  String get categoryOtherDesc =>
      'अन्य सार्वजनिक या नगरपालिका रखरखाव संबंधी समस्याएं।';

  @override
  String get categoryPotholes => 'सड़क के गड्ढे';

  @override
  String get categoryGarbageOverflow => 'कचरे का फैलाव';

  @override
  String get categoryWaterlogging => 'जलभराव';

  @override
  String get categoryWaterLeakage => 'पानी का रिसाव';

  @override
  String get categoryDamagedWater => 'क्षतिग्रस्त जल पाइपलाइन';

  @override
  String get categorySewageOverflow => 'सीवर का ओवरफ्लो';

  @override
  String get categoryManholes => 'खुले मैनहोल';

  @override
  String get categoryFootpaths => 'क्षतिग्रस्त फुटपाथ';

  @override
  String get categoryTrees => 'गिरे या खतरनाक पेड़';

  @override
  String get priorityLow => 'कम';

  @override
  String get priorityMedium => 'मध्यम';

  @override
  String get priorityHigh => 'उच्च';

  @override
  String get priorityEmergency => 'गंभीर';

  @override
  String get deptRoadsTraffic => 'सड़क एवं यातायात विभाग';

  @override
  String get deptSolidWaste => 'ठोस अपशिष्ट प्रबंधन विभाग';

  @override
  String get deptWaterSewerage => 'जल आपूर्ति एवं सीवरेज विभाग';

  @override
  String get deptElectricalStreetlights => 'विद्युत एवं स्ट्रीट लाइट विभाग';

  @override
  String get deptStormDrainage => 'वर्षा जल निकासी विभाग';

  @override
  String get deptPublicHealth => 'सार्वजनिक स्वास्थ्य विभाग';

  @override
  String get deptGardensTrees => 'उद्यान एवं वृक्ष प्राधिकरण';

  @override
  String get deptBuildingInfrastructure => 'भवन एवं अवसंरचना विभाग';

  @override
  String get deptGeneral => 'सामान्य नगरपालिका डेस्क';

  @override
  String get verificationPending => 'सत्यापन लंबित';

  @override
  String get verificationProcessing => 'विश्लेषण एवं सत्यापन जारी...';

  @override
  String get verificationPassed => 'सत्यापन सफल';

  @override
  String get verificationFailed => 'सत्यापन विफल';

  @override
  String get verificationDelayed => 'स्वचालित सत्यापन में देरी';

  @override
  String get verificationOfficerReview => 'विभागीय अधिकारी समीक्षा';

  @override
  String get verificationCompleted => 'सत्यापन पूर्ण';

  @override
  String get routingUnassigned => 'अनावंटित';

  @override
  String get routingAssigned => 'आवंटित';

  @override
  String get routingReassignmentRequested => 'पुनः आवंटन का अनुरोध';

  @override
  String get routingTransferred => 'स्थानांतरित';

  @override
  String get routingInProgress => 'प्रगति पर';

  @override
  String get routingResolved => 'समाधान हुआ';

  @override
  String get assignmentUnassigned => 'अनावंटित';

  @override
  String get assignmentLeadAssigned => 'वार्ड लीड को आवंटित';

  @override
  String get assignmentCrewAssigned => 'ग्राउंड क्रू को आवंटित';

  @override
  String get assignmentFieldOfficerAssigned => 'फील्ड ऑफिसर को आवंटित';

  @override
  String get syncSynced => 'सिंक हुआ';

  @override
  String get syncPending => 'सिंक लंबित';

  @override
  String get syncSyncing => 'सिंक हो रहा है...';

  @override
  String get basemapStyle => 'नक्शा शैली';

  @override
  String get chooseMapViewMode => 'नक्शा दृश्य और उपग्रह मोड चुनें';

  @override
  String get basemapStreets => 'सड़कें';

  @override
  String get basemapStreetsDesc =>
      'विस्तृत सड़क नेटवर्क, वार्ड और नागरिक सुविधाएं';

  @override
  String get basemapSatellite => 'उपग्रह';

  @override
  String get basemapSatelliteDesc =>
      'उच्च-रिज़ॉल्यूशन हवाई और उपग्रह फोटोग्राफिक दृश्य';

  @override
  String get basemapHybrid => 'हाइब्रिड';

  @override
  String get basemapHybridDesc =>
      'सड़कों के नाम, सीमाओं और इलाके के लेबल के साथ उपग्रह दृश्य';

  @override
  String get badgeFirstReport => 'पहली शिकायत';

  @override
  String get badgeFirstReportDesc => 'अपनी पहली नागरिक शिकायत दर्ज की';

  @override
  String get badgeActiveCitizen => 'सक्रिय नागरिक';

  @override
  String get badgeActiveCitizenDesc => '5 या अधिक नागरिक समस्याएं दर्ज कीं';

  @override
  String get badgeNeighborhoodHero => 'मोहल्ला नायक';

  @override
  String get badgeNeighborhoodHeroDesc =>
      'आपके समुदाय में 10 शिकायतों का समाधान हुआ';

  @override
  String get badgeSharpEye => 'सतर्क दृष्टि';

  @override
  String get badgeSharpEyeDesc => 'तात्कालिक सुरक्षा खतरे की रिपोर्ट की';

  @override
  String get badgeCommunityPillar => 'समुदाय का स्तंभ';

  @override
  String get badgeCommunityPillarDesc => '500+ सिविक पॉइंट्स अर्जित किए';

  @override
  String get unlocked => 'अनलॉक किया गया';

  @override
  String get locked => 'लॉक';

  @override
  String get howToUnlock => 'अनलॉक कैसे करें';

  @override
  String get communityPerks => 'सामुदायिक लाभ';

  @override
  String get communityPerksSubtitle =>
      'स्थानीय प्रशासन और सहयोगी सुविधाओं के लिए पॉइंट्स का उपयोग करें';

  @override
  String get claimPerk => 'प्राप्त करें';

  @override
  String get yourContribution => 'आपका योगदान';

  @override
  String get totalReports => 'कुल रिपोर्ट';

  @override
  String get resolvedReports => 'समाधान हुई रिपोर्ट';

  @override
  String get pointsEarned => 'अर्जित पॉइंट्स';

  @override
  String get achievements => 'उपलब्धियां';

  @override
  String get achievementsSubtitle =>
      'सक्रिय नागरिक भागीदारी के लिए बैज अर्जित करें';

  @override
  String get loadingRewards => 'आपके नागरिक मील के पत्थर लोड हो रहे हैं...';

  @override
  String get allNotificationsMarkedAsRead =>
      'सभी सूचनाओं को पढ़ा हुआ चिह्नित किया गया।';

  @override
  String get filterAll => 'सभी';

  @override
  String get filterUnread => 'अपठित';

  @override
  String get filterRead => 'पढ़ा हुआ';

  @override
  String get logOutQuestion => 'लॉग आउट करें?';

  @override
  String get logoutConfirmationMessage =>
      'क्या आप वाकई लॉग आउट करना चाहते हैं?';

  @override
  String get clearChat => 'चैट साफ़ करें';

  @override
  String get assistantThinking => 'सहायक विचार कर रहा है...';

  @override
  String get assistantMessageHint =>
      'शिकायत, ट्रैकिंग या श्रेणियों के बारे में पूछें...';

  @override
  String get resolutionWorkVerification => 'समाधान एवं कार्य सत्यापन';

  @override
  String get groundInspectionSubtitle =>
      'मैदानी निरीक्षण एवं कार्य पूर्णता साक्ष्य';

  @override
  String get govPortalTitle => 'CivicFix सरकारी पोर्टल';

  @override
  String get govLoginTitle => 'सरकारी अधिकारी साइन इन';

  @override
  String get govLoginSubtitle =>
      'बीएमसी नगरपालिका अधिकारियों के लिए सुरक्षित प्रशासनिक पहुंच';

  @override
  String get govEmployeeIdOrEmail => 'कर्मचारी आईडी या आधिकारिक ईमेल';

  @override
  String get govPassword => 'पासवर्ड';

  @override
  String get govSignInButton => 'पोर्टल में साइन इन करें';

  @override
  String get govInvalidCredentials => 'अमान्य कर्मचारी आईडी, ईमेल या पासवर्ड।';

  @override
  String get govAccountDisabled =>
      'खाता निष्क्रिय है। नगरपालिका प्रशासक से संपर्क करें।';

  @override
  String get govSessionExpired =>
      'सत्र समाप्त हो गया है। कृपया पुनः साइन इन करें।';

  @override
  String get govAccessDenied => 'पहुंच अस्वीकृत';

  @override
  String get govAccessDeniedDesc =>
      'आपके पास इस क्षेत्र तक पहुँचने के प्रशासनिक अधिकार नहीं हैं।';

  @override
  String get govReturnToDashboard => 'डैशबोर्ड पर लौटें';

  @override
  String get govAuthenticating =>
      'प्रशासनिक क्रेडेंशियल्स सत्यापित हो रहे हैं...';

  @override
  String get govForgotPassword => 'पासवर्ड भूल गए';

  @override
  String get govResetPasswordInstruction =>
      'पासवर्ड रीसेट निर्देश प्राप्त करने के लिए अपना पंजीकृत आधिकारिक ईमेल दर्ज करें।';

  @override
  String get govSendResetLink => 'रीसेट लिंक भेजें';

  @override
  String get govNavDashboard => 'डैशबोर्ड';

  @override
  String get govNavComplaints => 'शिकायतें';

  @override
  String get govNavHazardMap => 'खतरा मानचित्र';

  @override
  String get govNavAnalytics => 'एनालिटिक्स';

  @override
  String get govNavProfile => 'प्रोफ़ाइल';

  @override
  String get govNavMyWork => 'मेरा कार्य';

  @override
  String get govNavOperations => 'संचालन';

  @override
  String get govNavSla => 'एसएलए मॉनिटर';

  @override
  String get govNavHistory => 'ऑडिट इतिहास';

  @override
  String get govNavVerification => 'सत्यापन कतार';

  @override
  String get govNavAssignments => 'आवंटन';

  @override
  String get govExecutiveDashboard => 'कार्यकारी डैशबोर्ड';

  @override
  String get govGrievanceManagement => 'शिकायत प्रबंधन';

  @override
  String get govLiveHazardGisMap => 'लाइव खतरा जीआईएस मानचित्र';

  @override
  String get govOperationalAnalytics => 'परिचालन विश्लेषण';

  @override
  String get govOfficerProfileSettings => 'अधिकारी प्रोफ़ाइल और सेटिंग्स';

  @override
  String get govCollapseSidebar => 'साइडबार छोटा करें';

  @override
  String get govExpandSidebar => 'साइडबार विस्तार करें';

  @override
  String get govMunicipalCorporation => 'बृहन्मुंबई महानगरपालिका';

  @override
  String get govRoleSuperAdmin => 'महानगरपालिका आयुक्त / सुपर एडमिन';

  @override
  String get govRoleZonalDmc => 'क्षेत्रीय उपायुक्त';

  @override
  String get govRoleCentralHod => 'केंद्रीय विभागाध्यक्ष';

  @override
  String get govRoleWardOfficer => 'सहायक आयुक्त (वार्ड अधिकारी)';

  @override
  String get govRoleWardLead => 'वार्ड विभाग प्रमुख';

  @override
  String get govRoleDepartmentCrew => 'कनिष्ठ अभियंता / फील्ड निष्पादन अधिकारी';

  @override
  String get govRoleAssistantEngineer => 'सहायक अभियंता';

  @override
  String get govRoleExecutiveEngineer => 'कार्यकारी अभियंता';

  @override
  String get govRoleSubEngineer => 'उप-अभियंता';

  @override
  String get govRoleMedicalOfficer => 'स्वास्थ्य चिकित्सा अधिकारी';

  @override
  String get govRoleSuperintendent => 'सहायक अधीक्षक';

  @override
  String get deptMaintenanceRoads => 'सड़क एवं रखरखाव विभाग';

  @override
  String get deptWaterWorks => 'जल कार्य एवं जलापूर्ति विभाग';

  @override
  String get deptSolidWasteManagement => 'ठोस अपशिष्ट प्रबंधन विभाग';

  @override
  String get deptBuildingFactory => 'भवन एवं कारखाना विभाग';

  @override
  String get deptGardenTrees => 'उद्यान एवं वृक्ष प्राधिकरण';

  @override
  String get deptPestControlInsecticide => 'कीट नियंत्रण एवं कीटनाशक विभाग';

  @override
  String get deptEncroachment => 'अतिक्रमण निष्कासन विभाग';

  @override
  String get deptLicence => 'लाइसेंस विभाग';

  @override
  String get deptShopsEstablishments => 'दुकानें एवं स्थापना विभाग';

  @override
  String get deptAssessmentCollection => 'मूल्यांकन एवं कर संग्रह विभाग';

  @override
  String get deptEstate => 'संपदा विभाग';

  @override
  String get deptColonySlum => 'बस्ती एवं स्लम सुधार विभाग';

  @override
  String get deptEducationSchools => 'शिक्षा एवं नगरपालिका स्कूल विभाग';

  @override
  String get deptSecurity => 'सुरक्षा बल विभाग';

  @override
  String get deptLegal => 'विधि / कानूनी विभाग';

  @override
  String get deptAdministrationEstablishment => 'प्रशासन एवं स्थापना विभाग';

  @override
  String get deptTownPlanning => 'नगर नियोजन एवं विकास योजना विभाग';

  @override
  String get govPendingComplaints => 'लंबित शिकायतें';

  @override
  String get govAssignedComplaints => 'आवंटित शिकायतें';

  @override
  String get govInProgressComplaints => 'कार्य प्रगति पर';

  @override
  String get govResolvedComplaints => 'समाधानित शिकायतें';

  @override
  String get govOverdueComplaints => 'समय सीमा पार शिकायतें';

  @override
  String get govSlaBreaches => 'एसएलए उल्लंघन';

  @override
  String get govAwaitingVerification => 'सत्यापन की प्रतीक्षा';

  @override
  String get govReworkRequired => 'पुनर्कार्य आवश्यक';

  @override
  String get govTodayTasks => 'आज के परिचालन कार्य';

  @override
  String get govRecentActivity => 'हाल की विभागीय गतिविधि';

  @override
  String get govWardSummary => 'वार्ड प्रदर्शन सारांश';

  @override
  String get govDepartmentSummary => 'विभागीय परिचालन सारांश';

  @override
  String get govResolutionRate => 'समाधान दर';

  @override
  String get govAvgResolutionTime => 'औसत समाधान समय';

  @override
  String get govTotalGrievances => 'कुल शिकायतें';

  @override
  String get govCriticalHazards => 'गंभीर खतरे';

  @override
  String get govActiveFieldCrew => 'सक्रिय फील्ड क्रू';

  @override
  String get govMyWorkTitle => 'मेरा आवंटित कार्य';

  @override
  String get govStartJob => 'साइट पर कार्य शुरू करें';

  @override
  String get govWorkStarted => 'कार्य प्रारंभ हुआ';

  @override
  String get govUploadBeforeEvidence => 'कार्य-पूर्व साक्ष्य अपलोड करें';

  @override
  String get govUploadAfterEvidence => 'कार्य-पश्चात साक्ष्य अपलोड करें';

  @override
  String get govAddWorkRemarks => 'निष्पादन टिप्पणियां जोड़ें';

  @override
  String get govMarkBlocked => 'कार्य बाधित के रूप में चिह्नित करें';

  @override
  String get govResumeWork => 'कार्य पुनः प्रारंभ करें';

  @override
  String get govSubmitResolution => 'समाधान समीक्षा के लिए जमा करें';

  @override
  String get govBlockedReasonLabel => 'देरी / रुकावट का कारण';

  @override
  String get govWorkInProgressBanner => 'साइट पर निष्पादन प्रगति पर है।';

  @override
  String get govWorkCompletedBanner =>
      'कार्य पूर्ण हुआ और ऑडिट के लिए जमा किया गया।';

  @override
  String get govComplaintDetailsTitle => 'शिकायत निरीक्षण एवं ऑडिट';

  @override
  String get govCitizenDetails => 'नागरिक विवरण';

  @override
  String get govIssueDetails => 'समस्या का विवरण';

  @override
  String get govVerificationResult => 'सत्यापन परिणाम';

  @override
  String get govAiVerification => 'स्वचालित एआई सत्यापन';

  @override
  String get govManualReviewRequired => 'मैनुअल सत्यापन आवश्यक';

  @override
  String get govAiCouldNotVerify =>
      'एआई उच्च विश्वास के साथ विभाग निर्धारित नहीं कर सका।';

  @override
  String get govApproveAndRoute => 'स्वीकृत करें और अग्रेषित करें';

  @override
  String get govRejectGrievance => 'शिकायत अस्वीकार करें';

  @override
  String get govOverrideDepartment => 'विभाग / श्रेणी बदलें';

  @override
  String get govSelectTargetDepartment => 'लक्ष्य विभाग चुनें';

  @override
  String get govReviewNotesLabel => 'अधिकारी समीक्षा टिप्पणियां';

  @override
  String get govConfirmDepartment => 'विभागीय आवंटन की पुष्टि करें';

  @override
  String get govAuditTimeline => 'शिकायत समयरेखा एवं ऑडिट इतिहास';

  @override
  String get govAssignOfficer => 'अधिकारी को सौंपें';

  @override
  String get govAssignedOfficerLabel => 'आवंटित फील्ड अधिकारी';

  @override
  String get govAssignFieldOfficer => 'फील्ड निष्पादन अधिकारी आवंटित करें';

  @override
  String get govReassignOfficer => 'पुनः आवंटित करें';

  @override
  String get govAvailableOfficers => 'उपलब्ध फील्ड अधिकारी';

  @override
  String get govOfficerWorkload => 'सक्रिय कार्यभार';

  @override
  String get govConfirmAssignment => 'आवंटन की पुष्टि करें';

  @override
  String get govCancelAssignment => 'रद्द करें';

  @override
  String govAssignmentSuccess(String officerName) {
    return 'शिकायत सफलतापूर्वक $officerName को आवंटित की गई।';
  }

  @override
  String get govAssignmentFailed =>
      'अधिकारी आवंटित करने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get govSlaStatus => 'एसएलए अनुपालन';

  @override
  String get govWithinSla => 'एसएलए लक्ष्य के भीतर';

  @override
  String get govApproachingSlaDeadline => 'एसएलए समय सीमा निकट';

  @override
  String get govSlaBreached => 'एसएलए उल्लंघन';

  @override
  String govHoursRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे शेष',
      one: '1 घंटा शेष',
    );
    return '$_temp0';
  }

  @override
  String govDaysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन शेष',
      one: '1 दिन शेष',
    );
    return '$_temp0';
  }

  @override
  String govDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन की देरी',
      one: '1 दिन की देरी',
    );
    return '$_temp0';
  }

  @override
  String govHoursOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे की देरी',
      one: '1 घंटे की देरी',
    );
    return '$_temp0';
  }

  @override
  String get govResolutionReview => 'समाधान गुणवत्ता ऑडिट';

  @override
  String get govApproveResolution => 'समाधान स्वीकृत करें एवं बंद करें';

  @override
  String get govSendForRework => 'पुनर्कार्य के लिए भेजें';

  @override
  String get govReworkReasonLabel => 'पुनर्कार्य का कारण';

  @override
  String get govCloseComplaint => 'शिकायत बंद करें';

  @override
  String get govReopenComplaint => 'शिकायत पुनः खोलें';

  @override
  String get govTableHeaderId => 'टिकट संख्या';

  @override
  String get govTableHeaderCategory => 'श्रेणी';

  @override
  String get govTableHeaderWard => 'वार्ड';

  @override
  String get govTableHeaderDepartment => 'विभाग';

  @override
  String get govTableHeaderStatus => 'स्थिति';

  @override
  String get govTableHeaderPriority => 'प्राथमिकता';

  @override
  String get govTableHeaderSla => 'शेष एसएलए';

  @override
  String get govTableHeaderReported => 'दर्ज तिथि';

  @override
  String get govTableHeaderActions => 'कार्य';

  @override
  String get govSearchComplaintsHint =>
      'टिकट संख्या, नागरिक का नाम, स्थान से खोजें...';

  @override
  String get govNoMatchingComplaints => 'कोई मेल खाती शिकायत नहीं मिली।';

  @override
  String get govAllWards => 'सभी वार्ड';

  @override
  String get govAllDepartments => 'सभी विभाग';

  @override
  String get govAllStatuses => 'सभी स्थितियां';

  @override
  String get govRowsPerPage => 'पंक्तियां प्रति पृष्ठ';

  @override
  String get govPreviousPage => 'पिछला';

  @override
  String get govNextPage => 'अगला';

  @override
  String get govOfficerProfile => 'सरकारी अधिकारी प्रोफ़ाइल';

  @override
  String get govOfficerName => 'अधिकारी का नाम';

  @override
  String get govEmployeeId => 'कर्मचारी आईडी';

  @override
  String get govOfficialEmail => 'आधिकारिक ईमेल';

  @override
  String get govDesignation => 'पदनाम';

  @override
  String get govJurisdiction => 'आवंटित अधिकार क्षेत्र';

  @override
  String get govCitywide => 'संपूर्ण शहर (सभी जोन और वार्ड)';

  @override
  String govWardJurisdiction(String wardName) {
    return 'वार्ड $wardName';
  }

  @override
  String govZoneJurisdiction(String zoneName) {
    return 'जोन $zoneName';
  }

  @override
  String get govSignOut => 'सरकारी पोर्टल से साइन आउट करें';

  @override
  String get govSignOutConfirm => 'क्या आप वाकई साइन आउट करना चाहते हैं?';

  @override
  String get govLanguageSettings => 'पोर्टल भाषा';

  @override
  String get govAppearanceSettings => 'थीम एवं दृश्य घनत्व';

  @override
  String get govPrivacyPrinciples => 'शासन एवं डेटा मानक';

  @override
  String get govAboutPortal => 'नगरपालिका पोर्टल के बारे में';

  @override
  String get govVersionInfo => 'CivicFix गवर्नेंस सूट v1.0.0-gov';

  @override
  String get govDashboard => 'नगरपालिका कार्य संचालन अवलोकन';

  @override
  String get govDashboardSubtitle =>
      'वास्तविक समय शिकायत टेलीमेट्री और नोडल विभाग कार्यभार';

  @override
  String get govTotalComplaints => 'कुल शिकायतें';

  @override
  String get govReportedComplaints => 'दर्ज / नई';

  @override
  String get details => 'विवरण';

  @override
  String get unassignedOfficer => 'अनियुक्त';

  @override
  String get govInspectAction => 'विवरण देखें';

  @override
  String get govUpdateStatus => 'स्थिति अपडेट करें';

  @override
  String get executionNotStarted => 'प्रारंभ के लिए तैयार';

  @override
  String get executionInProgress => 'कार्य प्रगति पर है';

  @override
  String get executionBlocked => 'कार्य रुका हुआ है';

  @override
  String get executionAwaitingEvidence => 'जमीनी साक्ष्य की प्रतीक्षा';

  @override
  String get executionCompleted => 'कार्य पूर्ण हुआ';

  @override
  String get resolutionPending => 'समाधान लंबित';

  @override
  String get resolutionSubmitted => 'समाधान प्रस्तुत';

  @override
  String get resolutionApproved => 'समाधान स्वीकृत';

  @override
  String get resolutionRejected => 'समाधान अस्वीकृत';

  @override
  String get resolutionClosed => 'समाधान बंद';

  @override
  String get reworkNotRequired => 'पुनः कार्य की आवश्यकता नहीं';

  @override
  String get reworkRequiredState => 'पुनः कार्य आवश्यक';

  @override
  String get reworkInProgress => 'पुनः कार्य प्रगति पर है';

  @override
  String get reworkSubmitted => 'पुनः कार्य प्रस्तुत';

  @override
  String get reworkApproved => 'पुनः कार्य स्वीकृत';

  @override
  String get syncOffline => 'ऑफ़लाइन कतार';

  @override
  String get syncRetrying => 'सिंक का पुनः प्रयास...';

  @override
  String get notifComplaintSubmitted => 'शिकायत दर्ज की गई';

  @override
  String get notifComplaintVerified => 'शिकायत सत्यापित हुई';

  @override
  String get notifComplaintAssigned => 'शिकायत आवंटित हुई';

  @override
  String get notifComplaintStatusChanged => 'स्थिति अद्यतन';

  @override
  String get notifComplaintResolved => 'शिकायत का समाधान हुआ';

  @override
  String get notifGeneralCivic => 'नागरिक सूचना';

  @override
  String get notifHazardAlert => 'खतरा चेतावनी';

  @override
  String get notifRewardEarned => 'पुरस्कार प्राप्त हुआ';

  @override
  String get notifSlaWarning => 'एसएलए समयसीमा चेतावनी';

  @override
  String get notifReworkRequested => 'पुनः कार्य अनुरोधित';

  @override
  String get badgeGroundReporter => 'ग्राउंड रिपोर्टर';

  @override
  String get badgeGroundReporterDesc =>
      'आवंटित वार्ड से मेल खाते सटीक निर्देशांक प्रदान किए।';

  @override
  String get badgeCommunityVoice => 'सामुदायिक आवाज़';

  @override
  String get badgeCommunityVoiceDesc =>
      'सत्यापित शिकायतों पर नागरिकों का समर्थन प्राप्त किया।';

  @override
  String get badgeResolutionChampion => 'समाधान चैंपियन';

  @override
  String get badgeResolutionChampionDesc =>
      'पात्र शिकायतों को सत्यापित समाधान तक पहुँचाया।';

  @override
  String get civicLevelStarter => 'नागरिक शुरुआत';

  @override
  String get civicLevelContributor => 'नागरिक योगदानकर्ता';

  @override
  String get civicLevelChampion => 'नागरिक चैंपियन';

  @override
  String get civicLevelLeader => 'नागरिक अगुआ';

  @override
  String get civicLevelHero => 'नागरिक नायक';

  @override
  String get jurisdictionZone => 'ज़ोन क्षेत्राधिकार';

  @override
  String get jurisdictionWard => 'वार्ड क्षेत्राधिकार';

  @override
  String get jurisdictionDepartment => 'विभाग क्षेत्राधिकार';

  @override
  String get jurisdictionRole => 'पद कार्यक्षेत्र';

  @override
  String get routingTicketPending => 'वार्ड अधिकारी समीक्षा लंबित';

  @override
  String get routingTicketApproved => 'पुनर्आवंटन स्वीकृत';

  @override
  String get routingTicketRejected => 'पुनर्आवंटन अस्वीकृत';

  @override
  String get routingTicketCancelled => 'टिकट रद्द';

  @override
  String get translatedFromEnglish => 'अंग्रेज़ी से अनुवादित';

  @override
  String get translatedFromHindi => 'हिन्दी से अनुवादित';

  @override
  String get translatedFromMarathi => 'मराठी से अनुवादित';

  @override
  String translatedFromLanguage(String language) {
    return '$language से अनुवादित';
  }

  @override
  String get originalEnglish => 'मूल — अंग्रेज़ी';

  @override
  String get originalHindi => 'मूल — हिन्दी';

  @override
  String get originalMarathi => 'मूल — मराठी';

  @override
  String originalLanguage(String language) {
    return 'मूल — $language';
  }

  @override
  String get viewOriginal => 'मूल देखें';

  @override
  String get viewTranslation => 'अनुवाद देखें';

  @override
  String get translating => 'अनुवाद हो रहा है...';

  @override
  String get translationUnavailable => 'अनुवाद अनुपलब्ध';

  @override
  String get retryTranslation => 'पुनः प्रयास करें';

  @override
  String get translationUnavailableOffline => 'ऑफलाइन अनुवाद अनुपलब्ध';

  @override
  String get complaintRejected => 'शिकायत अस्वीकृत';

  @override
  String get complaintRejectedAuthenticityBody =>
      'इस शिकायत के साथ अपलोड किया गया साक्ष्य CivicFix के प्रमाणिकता सत्यापन में विफल रहा और इसे AI-जनरेटेड या डिजिटल रूप से हेरफेर किया हुआ पाया गया।\n\nनागरिक शिकायतों के लिए, कृपया वास्तविक स्थान से ली गई समस्या की वास्तविक तस्वीर अपलोड करें।';

  @override
  String get reportAgain => 'पुनः रिपोर्ट करें';

  @override
  String get evidenceVerificationFailed => 'साक्ष्य सत्यापन विफल';

  @override
  String get aiGeneratedEvidenceDetected =>
      'AI-जनरेटेड या हेरफेर किया हुआ साक्ष्य पाया गया।';
}
