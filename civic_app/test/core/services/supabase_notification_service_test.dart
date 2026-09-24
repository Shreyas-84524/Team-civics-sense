import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:civic_app/core/services/supabase_notification_service.dart';

void main() {
  group('SupabaseNotificationService & HttpSupabaseNotificationService Tests', () {
    test('Successful notification dispatch returns 200 with device counts', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(
          request.url.toString(),
          equals('https://hkgwsqasmboadvpjckbj.supabase.co/functions/v1/civicfix-notification'),
        );
        expect(request.headers['Authorization'], startsWith('Bearer '));
        expect(request.headers['Content-Type'], equals('application/json'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['complaintId'], equals('cmp_101'));
        expect(body['citizenId'], equals('user_citizen_001'));
        expect(body['oldStatus'], equals('assigned'));
        expect(body['newStatus'], equals('inProgress'));
        expect(body['ticketNumber'], equals('CF-2026-000101'));

        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'message': 'Notification dispatched',
            'data': {
              'complaintId': 'cmp_101',
              'newStatus': 'inProgress',
              'devicesAttempted': 2,
              'devicesSucceeded': 2,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = HttpSupabaseNotificationService(client: mockClient);
      final result = await service.triggerStatusNotification(
        complaintId: 'cmp_101',
        citizenId: 'user_citizen_001',
        oldStatus: 'assigned',
        newStatus: 'inProgress',
        ticketNumber: 'CF-2026-000101',
      );

      expect(result.success, isTrue);
      expect(result.statusCode, equals(200));
      expect(result.devicesAttempted, equals(2));
      expect(result.devicesSucceeded, equals(2));
      expect(result.isNoDevice, isFalse);
    });

    test('Returns graceful result when citizen has no registered devices', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'message': 'No registered device',
            'data': {
              'complaintId': 'cmp_102',
              'newStatus': 'resolved',
              'devicesAttempted': 0,
              'devicesSucceeded': 0,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = HttpSupabaseNotificationService(client: mockClient);
      final result = await service.triggerStatusNotification(
        complaintId: 'cmp_102',
        citizenId: 'user_no_device_999',
        oldStatus: 'inProgress',
        newStatus: 'resolved',
      );

      expect(result.success, isTrue);
      expect(result.statusCode, equals(200));
      expect(result.devicesAttempted, equals(0));
      expect(result.isNoDevice, isTrue);
    });

    test('Immediately returns 422 failure without HTTP call when citizenId is empty', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response('ok', 200);
      });

      final service = HttpSupabaseNotificationService(client: mockClient);
      final result = await service.triggerStatusNotification(
        complaintId: 'cmp_103',
        citizenId: '   ',
        oldStatus: 'reported',
        newStatus: 'verified',
      );

      expect(result.success, isFalse);
      expect(result.statusCode, equals(422));
      expect(requestCount, equals(0));
    });

    test('Handles Edge Function 422 Unprocessable Entity error gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 422,
            'error': 'Unprocessable Entity',
            'message': 'Missing required field(s): oldStatus',
          }),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = HttpSupabaseNotificationService(client: mockClient);
      final result = await service.triggerStatusNotification(
        complaintId: 'cmp_104',
        citizenId: 'user_citizen_001',
        oldStatus: '',
        newStatus: 'verified',
      );

      expect(result.success, isFalse);
      expect(result.statusCode, equals(422));
      expect(result.message, contains('Missing required field(s)'));
    });

    test('Handles Edge Function 401 Unauthorized error gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 401,
            'error': 'Unauthorized',
            'message': 'Missing or malformed Authorization header.',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = HttpSupabaseNotificationService(client: mockClient);
      final result = await service.triggerStatusNotification(
        complaintId: 'cmp_105',
        citizenId: 'user_citizen_001',
        oldStatus: 'reported',
        newStatus: 'verified',
      );

      expect(result.success, isFalse);
      expect(result.statusCode, equals(401));
    });

    test('Handles Edge Function 500 Internal Server Error without throwing exceptions', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 500,
            'error': 'Internal Server Error',
            'message': 'Notification dispatch failed.',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = HttpSupabaseNotificationService(client: mockClient);
      final result = await service.triggerStatusNotification(
        complaintId: 'cmp_106',
        citizenId: 'user_citizen_001',
        oldStatus: 'inProgress',
        newStatus: 'resolved',
      );

      expect(result.success, isFalse);
      expect(result.statusCode, equals(500));
      expect(result.message, equals('Notification dispatch failed.'));
    });

    test('Handles Network Exception gracefully without throwing', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused / offline');
      });

      final service = HttpSupabaseNotificationService(client: mockClient);
      final result = await service.triggerStatusNotification(
        complaintId: 'cmp_107',
        citizenId: 'user_citizen_001',
        oldStatus: 'reported',
        newStatus: 'verified',
      );

      expect(result.success, isFalse);
      expect(result.statusCode, equals(500));
      expect(result.message, contains('Network error'));
    });
  });

  group('MockSupabaseNotificationService Tests', () {
    test('Records dispatched events and honors failure flags', () async {
      final mockService = MockSupabaseNotificationService();

      final res1 = await mockService.triggerStatusNotification(
        complaintId: 'cmp_m1',
        citizenId: 'usr_m1',
        oldStatus: 'reported',
        newStatus: 'verified',
        ticketNumber: 'CF-M1',
      );

      expect(res1.success, isTrue);
      expect(mockService.dispatchedEvents.length, equals(1));
      expect(mockService.dispatchedEvents.first['complaintId'], equals('cmp_m1'));

      mockService.shouldSucceed = false;
      final res2 = await mockService.triggerStatusNotification(
        complaintId: 'cmp_m2',
        citizenId: 'usr_m2',
        oldStatus: 'verified',
        newStatus: 'assigned',
      );

      expect(res2.success, isFalse);
      expect(mockService.dispatchedEvents.length, equals(2));
    });
  });
}
