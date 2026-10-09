import 'phone_normalizer.dart';

/// Authoritative immutable model representing an active phone OTP verification challenge session.
///
/// Encapsulates:
/// - Target phone number in canonical E.164 format
/// - Unique challenge / request identifier
/// - Server-authoritative timestamps (UTC)
/// - Monotonic request generation for race-condition protection
class PhoneVerificationSession {
  final String phoneNumber;
  final String challengeId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime resendAvailableAt;
  final int generation;
  final int maxAttempts;
  final int attemptsUsed;

  const PhoneVerificationSession({
    required this.phoneNumber,
    required this.challengeId,
    required this.createdAt,
    required this.expiresAt,
    required this.resendAvailableAt,
    this.generation = 1,
    this.maxAttempts = 3,
    this.attemptsUsed = 0,
  });

  /// Whether the OTP challenge has passed its validity window.
  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  /// Whether the resend cooldown has elapsed.
  bool get canResend => DateTime.now().toUtc().isAfter(resendAvailableAt);

  /// Remaining seconds before resend is permitted.
  int get secondsUntilResend {
    final now = DateTime.now().toUtc();
    if (now.isAfter(resendAvailableAt)) return 0;
    return resendAvailableAt.difference(now).inSeconds;
  }

  /// Remaining seconds before challenge expiration.
  int get secondsUntilExpiry {
    final now = DateTime.now().toUtc();
    if (now.isAfter(expiresAt)) return 0;
    return expiresAt.difference(now).inSeconds;
  }

  /// Creates a modified copy of the current session.
  PhoneVerificationSession copyWith({
    String? phoneNumber,
    String? challengeId,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? resendAvailableAt,
    int? generation,
    int? maxAttempts,
    int? attemptsUsed,
  }) {
    return PhoneVerificationSession(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      challengeId: challengeId ?? this.challengeId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
      generation: generation ?? this.generation,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      attemptsUsed: attemptsUsed ?? this.attemptsUsed,
    );
  }

  @override
  String toString() {
    final masked = PhoneNormalizer.mask(phoneNumber);
    final truncatedId = challengeId.length > 8
        ? '${challengeId.substring(0, 8)}...'
        : challengeId;
    return 'PhoneVerificationSession(phone: $masked, challengeId: $truncatedId, gen: $generation, expiresAt: $expiresAt)';
  }
}
