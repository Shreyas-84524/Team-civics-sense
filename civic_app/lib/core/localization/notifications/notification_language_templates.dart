/// Canonical language-aware notification template architecture.
///
/// Converts backend canonical notification event types (e.g. 'complaintReported',
/// 'complaintUnderVerification', 'complaintVerified', 'complaintAssigned',
/// 'complaintStatusChanged', 'complaintResolved', 'complaintClosed', 'slaWarning', 'reworkRequested')
/// into deterministic, localized notification titles and messages for citizens and officers.
class NotificationLanguageTemplates {
  NotificationLanguageTemplates._();

  /// Formats a localized notification title and body based on recipient preferred language.
  static ({String title, String body}) format({
    required String notificationType,
    required String languageCode,
    required String ticketNumber,
    String? complaintTitle,
    String? departmentName,
    String? officerNotes,
  }) {
    final lang = languageCode.trim().toLowerCase();
    final ticket = ticketNumber.trim();
    final titleText = (complaintTitle != null && complaintTitle.trim().isNotEmpty)
        ? complaintTitle.trim()
        : 'Civic Grievance';

    switch (notificationType) {
      case 'complaintUnderVerification':
        return _underVerification(lang, ticket, titleText);
      case 'complaintVerified':
        return _verified(lang, ticket, titleText);
      case 'complaintAssigned':
        return _assigned(lang, ticket, titleText, departmentName);
      case 'complaintStatusChanged':
      case 'inProgress':
        return _inProgress(lang, ticket, titleText);
      case 'complaintResolved':
        return _resolved(lang, ticket, titleText);
      case 'complaintClosed':
        return _closed(lang, ticket, titleText);
      case 'reworkRequested':
      case 'reopened':
        return _rework(lang, ticket, titleText, officerNotes);
      case 'slaWarning':
        return _slaWarning(lang, ticket, titleText);
      case 'complaintReported':
      case 'reported':
      default:
        return _reported(lang, ticket, titleText);
    }
  }

  static ({String title, String body}) _reported(String lang, String ticket, String titleText) {
    switch (lang) {
      case 'hi':
        return (
          title: 'शिकायत दर्ज की गई: $ticket',
          body: 'आपकी नागरिक शिकायत "$titleText" सफलतापूर्वक दर्ज हो गई है।',
        );
      case 'mr':
        return (
          title: 'तक्रार नोंदवली गेली: $ticket',
          body: 'तुमची नागरी तक्रार "$titleText" यशस्वीपणे नोंदवली गेली आहे.',
        );
      case 'en':
      default:
        return (
          title: 'Complaint Reported: $ticket',
          body: 'Your civic grievance "$titleText" has been submitted successfully.',
        );
    }
  }

  static ({String title, String body}) _underVerification(String lang, String ticket, String titleText) {
    switch (lang) {
      case 'hi':
        return (
          title: 'सत्यापन प्रगति पर: $ticket',
          body: 'आपकी शिकायत "$titleText" का सत्यापन किया जा रहा है।',
        );
      case 'mr':
        return (
          title: 'पडताळणी सुरू आहे: $ticket',
          body: 'तुमची तक्रार "$titleText" पडताळणी प्रक्रियेत आहे.',
        );
      case 'en':
      default:
        return (
          title: 'Verification Underway: $ticket',
          body: 'Your grievance "$titleText" is undergoing municipal verification.',
        );
    }
  }

  static ({String title, String body}) _verified(String lang, String ticket, String titleText) {
    switch (lang) {
      case 'hi':
        return (
          title: 'शिकायत सत्यापित: $ticket',
          body: 'आपकी शिकायत "$titleText" को नगरपालिका प्राधिकरण द्वारा सत्यापित किया गया है।',
        );
      case 'mr':
        return (
          title: 'तक्रार पडताळली: $ticket',
          body: 'तुमची तक्रार "$titleText" पालिका अधिकाऱ्यांद्वारे पडताळली गेली आहे.',
        );
      case 'en':
      default:
        return (
          title: 'Complaint Verified: $ticket',
          body: 'Your grievance "$titleText" has been verified by the municipal authority.',
        );
    }
  }

  static ({String title, String body}) _assigned(String lang, String ticket, String titleText, String? dept) {
    switch (lang) {
      case 'hi':
        return (
          title: 'अधिकारी नियुक्त: $ticket',
          body: dept != null
            ? 'आपकी शिकायत "$titleText" को $dept को सौंपा गया है।'
            : 'आपकी शिकायत "$titleText" के समाधान के लिए एक इंजीनियर नियुक्त किया गया है।',
        );
      case 'mr':
        return (
          title: 'अधिकारी नियुक्त: $ticket',
          body: dept != null
            ? 'तुमची तक्रार "$titleText" $dept कडे सोपवण्यात आली आहे.'
            : 'तुमच्या "$titleText" तक्रारीच्या निवारणासाठी अभियंता नियुक्त केला आहे.',
        );
      case 'en':
      default:
        return (
          title: 'Officer Assigned: $ticket',
          body: dept != null
            ? 'Your grievance "$titleText" has been routed to $dept.'
            : 'An engineer has been assigned to address your grievance "$titleText".',
        );
    }
  }

  static ({String title, String body}) _inProgress(String lang, String ticket, String titleText) {
    switch (lang) {
      case 'hi':
        return (
          title: 'कार्य प्रगति पर: $ticket',
          body: 'मैदानी टीम द्वारा "$titleText" पर सक्रिय रूप से कार्य किया जा रहा है।',
        );
      case 'mr':
        return (
          title: 'काम प्रगतीपथावर: $ticket',
          body: 'प्रत्यक्ष पथकाद्वारे "$titleText" वर वेगाने काम सुरू आहे.',
        );
      case 'en':
      default:
        return (
          title: 'Work In Progress: $ticket',
          body: 'Municipal field teams are actively resolving "$titleText".',
        );
    }
  }

  static ({String title, String body}) _resolved(String lang, String ticket, String titleText) {
    switch (lang) {
      case 'hi':
        return (
          title: 'शिकायत का समाधान: $ticket',
          body: '"$titleText" का कार्य पूर्ण हो गया है। फोटो प्रमाण देखने के लिए टैप करें।',
        );
      case 'mr':
        return (
          title: 'तक्रार निवारण पूर्ण: $ticket',
          body: '"$titleText" वरील काम पूर्ण झाले आहे. फोटो पुरावा पाहण्यासाठी टॅप करा.',
        );
      case 'en':
      default:
        return (
          title: 'Grievance Resolved: $ticket',
          body: 'Work on "$titleText" is complete with photo proof. Tap to review.',
        );
    }
  }

  static ({String title, String body}) _closed(String lang, String ticket, String titleText) {
    switch (lang) {
      case 'hi':
        return (
          title: 'शिकायत बंद: $ticket',
          body: '"$titleText" का निवारण सत्यापित करके मामला बंद कर दिया गया है।',
        );
      case 'mr':
        return (
          title: 'तक्रार बंद करण्यात आली: $ticket',
          body: '"$titleText" च्या निवारणाची पुष्टी करून तक्रार बंद करण्यात आली आहे.',
        );
      case 'en':
      default:
        return (
          title: 'Grievance Closed: $ticket',
          body: 'Resolution for "$titleText" has been confirmed and closed.',
        );
    }
  }

  static ({String title, String body}) _rework(String lang, String ticket, String titleText, String? notes) {
    switch (lang) {
      case 'hi':
        return (
          title: 'पुनर्कार्य का अनुरोध: $ticket',
          body: notes != null
            ? 'शिकायत "$titleText" पुनः खोली गई: $notes'
            : 'शिकायत "$titleText" पर पुनः कार्य शुरू किया गया है।',
        );
      case 'mr':
        return (
          title: 'पुनर्कार्याची विनंती: $ticket',
          body: notes != null
            ? 'तक्रार "$titleText" पुन्हा उघडली गेली: $notes'
            : 'तक्रार "$titleText" वर पुनर्कार्य सुरू करण्यात आले आहे.',
        );
      case 'en':
      default:
        return (
          title: 'Rework Requested: $ticket',
          body: notes != null
            ? 'Grievance "$titleText" reopened: $notes'
            : 'Rework requested on grievance "$titleText".',
        );
    }
  }

  static ({String title, String body}) _slaWarning(String lang, String ticket, String titleText) {
    switch (lang) {
      case 'hi':
        return (
          title: 'SLA चेतावनी: $ticket',
          body: 'शिकायत "$titleText" की समाधान समयसीमा नजदीक आ रही है।',
        );
      case 'mr':
        return (
          title: 'SLA चेतावणी: $ticket',
          body: 'तक्रार "$titleText" च्या निवारणाची मुदत संपत आली आहे.',
        );
      case 'en':
      default:
        return (
          title: 'SLA Warning: $ticket',
          body: 'Resolution deadline is approaching for grievance "$titleText".',
        );
    }
  }
}
