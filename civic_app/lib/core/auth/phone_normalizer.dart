/// Utility for validating and normalizing Indian mobile phone numbers.
///
/// Ensures compliance with Indian telecom numbering formats:
/// - 10 digits starting with 6, 7, 8, or 9
/// - E.164 standard format: '+91XXXXXXXXXX' (persisted in user profile)
class PhoneNormalizer {
  PhoneNormalizer._();

  static final RegExp _cleanRegex = RegExp(r'[\s\-\(\)\+]');
  static final RegExp _digitRegex = RegExp(r'^[0-9]+$');
  static final RegExp _validStartRegex = RegExp(r'^[6-9]');

  /// Cleans all formatting characters (spaces, dashes, parentheses, plus).
  static String clean(String input) {
    return input.replaceAll(_cleanRegex, '').trim();
  }

  /// Extracts the raw 10-digit Indian subscriber number if valid, or null.
  static String? extract10Digit(String input) {
    final cleaned = clean(input);
    if (!_digitRegex.hasMatch(cleaned)) return null;

    if (cleaned.length == 10) {
      if (_validStartRegex.hasMatch(cleaned)) return cleaned;
      return null;
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      final sub = cleaned.substring(2);
      if (_validStartRegex.hasMatch(sub)) return sub;
      return null;
    } else if (cleaned.length == 11 && cleaned.startsWith('0')) {
      final sub = cleaned.substring(1);
      if (_validStartRegex.hasMatch(sub)) return sub;
      return null;
    }

    return null;
  }

  /// Validates whether the given string is a valid Indian mobile number.
  static bool isValidIndianMobile(String input) {
    return extract10Digit(input) != null;
  }

  /// Validates and returns a user-friendly error message, or null if valid.
  static String? validate(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Please enter your mobile phone number.';
    }
    final cleaned = clean(input);
    if (cleaned.isEmpty) {
      return 'Please enter your mobile phone number.';
    }
    if (!_digitRegex.hasMatch(cleaned)) {
      return 'Phone number must contain digits only.';
    }
    final tenDigit = extract10Digit(input);
    if (tenDigit == null) {
      if (cleaned.length < 10) {
        return 'Phone number must be 10 digits.';
      } else if (!_validStartRegex.hasMatch(cleaned.length == 10 ? cleaned : cleaned.substring(cleaned.length - 10))) {
        return 'Indian mobile numbers must begin with 6, 7, 8, or 9.';
      }
      return 'Please enter a valid 10-digit Indian mobile number.';
    }
    return null;
  }

  /// Converts the input to standard E.164 format: '+91XXXXXXXXXX'.
  /// Throws [FormatException] if the number is not a valid Indian mobile number.
  static String toE164(String input) {
    final tenDigit = extract10Digit(input);
    if (tenDigit == null) {
      throw FormatException('Invalid Indian mobile phone number: "$input"');
    }
    return '+91$tenDigit';
  }

  /// Formats the input for user display: '+91 XXXXX XXXXX'.
  static String toDisplay(String input) {
    final tenDigit = extract10Digit(input);
    if (tenDigit == null) return input;
    return '+91 ${tenDigit.substring(0, 5)} ${tenDigit.substring(5)}';
  }
}
