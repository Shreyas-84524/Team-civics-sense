import 'dart:math';

/// Exponential backoff retry policy with jitter support for synchronization operations.
class RetryPolicy {
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final double multiplier;
  final double jitterFactor;
  final Random _random;

  RetryPolicy({
    this.maxRetries = 5,
    this.initialDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(seconds: 60),
    this.multiplier = 2.0,
    this.jitterFactor = 0.1,
    Random? random,
  }) : _random = random ?? Random();

  /// Determine if an operation should be retried given the current attempt count.
  bool shouldRetry(int attemptCount) {
    return attemptCount < maxRetries;
  }

  /// Calculate the delay before the next retry attempt based on exponential backoff and jitter.
  Duration getDelay(int attemptCount) {
    if (attemptCount <= 0) return Duration.zero;

    // Exponential calculation: initialDelay * (multiplier ^ (attemptCount - 1))
    final double calculatedSeconds =
        initialDelay.inMilliseconds / 1000.0 * pow(multiplier, attemptCount - 1);
    final double clampedSeconds = min(calculatedSeconds, maxDelay.inMilliseconds / 1000.0);

    // Apply jitter: +/- (jitterFactor * clampedSeconds)
    double jitter = 0.0;
    if (jitterFactor > 0) {
      final double delta = clampedSeconds * jitterFactor;
      jitter = (_random.nextDouble() * 2 * delta) - delta;
    }

    final double totalSeconds = max(0.1, clampedSeconds + jitter);
    return Duration(milliseconds: (totalSeconds * 1000).round());
  }
}
