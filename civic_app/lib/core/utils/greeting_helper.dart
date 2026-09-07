/// Time-based greeting helper for CivicFix application.
class GreetingHelper {
  GreetingHelper._();

  /// Returns localized greeting string based on the provided time (or DateTime.now()).
  /// - Morning: 05:00 - 11:59
  /// - Afternoon: 12:00 - 16:59
  /// - Evening: 17:00 - 04:59
  static String getGreeting([DateTime? time]) {
    final now = time ?? DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Returns full greeting phrase with user name (e.g. "Good morning, Rahul").
  static String formatUserGreeting(String? fullName, [DateTime? time]) {
    final greeting = getGreeting(time);
    if (fullName == null || fullName.trim().isEmpty) {
      return '$greeting, Citizen';
    }
    final firstName = fullName.trim().split(' ').first;
    return '$greeting, $firstName';
  }
}
