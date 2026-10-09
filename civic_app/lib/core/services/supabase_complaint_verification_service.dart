import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Starts the server-side verification pipeline after a complaint is saved.
/// The Edge Function validates this Firebase ID token and the complaint owner.
class SupabaseComplaintVerificationService {
  static const endpoint =
      'https://hkgwsqasmboadvpjckbj.supabase.co/functions/v1/verify-complaint';

  static Future<void> start(String complaintId, String citizenId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != citizenId) return;
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) return;
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'complaintId': complaintId}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 && response.statusCode != 202) {
        debugPrint(
          '[ComplaintVerification] Could not start $complaintId: HTTP ${response.statusCode}',
        );
      }
    } catch (error) {
      debugPrint(
        '[ComplaintVerification] Could not start $complaintId: $error',
      );
    }
  }
}
