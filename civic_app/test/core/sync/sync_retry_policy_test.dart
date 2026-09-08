import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/sync/retry/retry_policy.dart';

void main() {
  group('RetryPolicy Tests', () {
    test('shouldRetry respects maxRetries limit', () {
      final policy = RetryPolicy(maxRetries: 3);

      expect(policy.shouldRetry(0), isTrue);
      expect(policy.shouldRetry(1), isTrue);
      expect(policy.shouldRetry(2), isTrue);
      expect(policy.shouldRetry(3), isFalse);
      expect(policy.shouldRetry(4), isFalse);
    });

    test('getDelay calculates exponential backoff correctly', () {
      // Deterministic Random with 0 jitter
      final policy = RetryPolicy(
        initialDelay: const Duration(seconds: 2),
        multiplier: 2.0,
        maxDelay: const Duration(seconds: 30),
        jitterFactor: 0.0,
      );

      expect(policy.getDelay(0), equals(Duration.zero));
      // Attempt 1: 2 * (2^0) = 2s
      expect(policy.getDelay(1).inSeconds, equals(2));
      // Attempt 2: 2 * (2^1) = 4s
      expect(policy.getDelay(2).inSeconds, equals(4));
      // Attempt 3: 2 * (2^2) = 8s
      expect(policy.getDelay(3).inSeconds, equals(8));
      // Attempt 4: 2 * (2^3) = 16s
      expect(policy.getDelay(4).inSeconds, equals(16));
    });

    test('getDelay caps delay at maxDelay', () {
      final policy = RetryPolicy(
        initialDelay: const Duration(seconds: 10),
        multiplier: 3.0,
        maxDelay: const Duration(seconds: 25),
        jitterFactor: 0.0,
      );

      // Attempt 3: 10 * 9 = 90s -> capped at 25s
      expect(policy.getDelay(3).inSeconds, equals(25));
    });
  });
}
