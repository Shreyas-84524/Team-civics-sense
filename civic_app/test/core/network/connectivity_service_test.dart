import 'package:flutter_test/flutter_test.dart';
import 'package:civic_app/core/network/connectivity_service.dart';

void main() {
  group('ConnectivityService Tests', () {
    late AppConnectivityService connectivityService;

    setUp(() {
      connectivityService = AppConnectivityService();
      connectivityService.resetForTesting(initialOnline: true);
    });

    test('Initial state defaults to online', () {
      expect(connectivityService.isOnline, isTrue);
      expect(connectivityService.isOffline, isFalse);
    });

    test('Toggling network state updates isOnline and isOffline', () {
      connectivityService.setOnline(false);
      expect(connectivityService.isOnline, isFalse);
      expect(connectivityService.isOffline, isTrue);

      connectivityService.setOnline(true);
      expect(connectivityService.isOnline, isTrue);
      expect(connectivityService.isOffline, isFalse);
    });

    test('onConnectivityChanged emits updates on state changes', () async {
      final emittedValues = <bool>[];
      final subscription = connectivityService.onConnectivityChanged.listen(emittedValues.add);

      connectivityService.setOnline(false);
      connectivityService.setOnline(true);
      connectivityService.setOnline(false);

      await Future.delayed(const Duration(milliseconds: 20));

      expect(emittedValues, equals([false, true, false]));
      await subscription.cancel();
    });

    test('resetForTesting restores initial requested state', () {
      connectivityService.setOnline(false);
      expect(connectivityService.isOnline, isFalse);

      connectivityService.resetForTesting(initialOnline: true);
      expect(connectivityService.isOnline, isTrue);
    });
  });
}
