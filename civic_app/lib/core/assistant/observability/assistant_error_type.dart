/// Categorized internal error taxonomy for CivicFix Assistant failures.
enum AssistantErrorType {
  networkFailure,
  providerUnavailable,
  rateLimited,
  retrievalFailure,
  invalidResponse,
  contextUnavailable,
  assistantDisabled,
  unknownFailure,
}

extension AssistantErrorTypeExtension on AssistantErrorType {
  String get name => toString().split('.').last;

  /// User-friendly localized message that never exposes stack traces or provider error details.
  String userFriendlyMessage(String languageCode) {
    switch (languageCode.trim().toLowerCase()) {
      case 'hi':
        switch (this) {
          case AssistantErrorType.assistantDisabled:
            return 'सिविक सहायक अभी रखरखाव के लिए अस्थायी रूप से अनुपलब्ध है।';
          case AssistantErrorType.networkFailure:
            return 'नेटवर्क कनेक्शन में समस्या है। कृपया अपना इंटरनेट जांचें और पुनः प्रयास करें।';
          case AssistantErrorType.rateLimited:
            return 'बहुत अधिक अनुरोध किए गए हैं। कृपया कुछ क्षण प्रतीक्षा करें।';
          default:
            return 'मुझे अभी उत्तर देने में समस्या आ रही है। कृपया पुनः प्रयास करें।';
        }
      case 'mr':
        switch (this) {
          case AssistantErrorType.assistantDisabled:
            return 'सिविक सहाय्यक सध्या देखभालीसाठी तात्पुरता अनुपलब्ध आहे.';
          case AssistantErrorType.networkFailure:
            return 'नेटवर्क कनेक्शनमध्ये अडचण आली आहे. कृपया इंटरनेट तपासा आणि पुन्हा प्रयत्न करा.';
          case AssistantErrorType.rateLimited:
            return 'खूप जास्त विनंत्या पाठवल्या गेल्या आहेत. कृपया थोडा वेळ थांबा.';
          default:
            return 'मला आत्ता उत्तर देण्यात अडचण येत आहे. कृपया पुन्हा प्रयत्न करा.';
        }
      case 'en':
      default:
        switch (this) {
          case AssistantErrorType.assistantDisabled:
            return 'Civic Assistant is temporarily unavailable for scheduled maintenance.';
          case AssistantErrorType.networkFailure:
            return 'Network connection issue. Please check your internet and try again.';
          case AssistantErrorType.rateLimited:
            return 'Too many requests. Please wait a moment before trying again.';
          default:
            return "I'm having trouble responding right now. Please try again.";
        }
    }
  }
}
