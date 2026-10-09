import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/certificate_model.dart';
import 'certificate_repository.dart';

/// Firebase Firestore implementation for Civic Certificates (`certificates` collection).
class FirebaseCertificateRepository implements CertificateRepository {
  final FirebaseFirestore? _firestore;

  FirebaseCertificateRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore? get _db {
    if (_firestore != null) return _firestore;
    try {
      if (FirebaseFirestore.instance.app.name.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  static const String collectionName = 'certificates';

  @override
  Future<List<CivicCertificate>> getCertificatesForUser(String recipientUid) async {
    final db = _db;
    if (db == null) return [];

    try {
      final query = await db
          .collection(collectionName)
          .where('recipientUid', isEqualTo: recipientUid)
          .orderBy('issuedAt', descending: true)
          .get();

      return query.docs.map((d) => CivicCertificate.fromJson({'certificateId': d.id, ...d.data()})).toList();
    } catch (e) {
      debugPrint('[FirebaseCertificateRepository] getCertificatesForUser error: $e');
      return [];
    }
  }

  @override
  Future<CivicCertificate?> getCertificateById(String certificateId) async {
    final db = _db;
    if (db == null) return null;

    try {
      final doc = await db.collection(collectionName).doc(certificateId).get();
      if (doc.exists && doc.data() != null) {
        return CivicCertificate.fromJson({'certificateId': doc.id, ...doc.data()!});
      }
    } catch (e) {
      debugPrint('[FirebaseCertificateRepository] getCertificateById error: $e');
    }
    return null;
  }

  @override
  Future<CivicCertificate?> getCertificateByVerificationSlug(String slug) async {
    final db = _db;
    if (db == null) return null;

    try {
      final query = await db.collection(collectionName).where('verificationSlug', isEqualTo: slug).limit(1).get();
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return CivicCertificate.fromJson({'certificateId': doc.id, ...doc.data()});
      }
    } catch (e) {
      debugPrint('[FirebaseCertificateRepository] getCertificateByVerificationSlug error: $e');
    }
    return null;
  }

  @override
  Future<CivicCertificate> saveCertificate(CivicCertificate certificate) async {
    final db = _db;
    if (db != null) {
      try {
        await db.collection(collectionName).doc(certificate.certificateId).set({
          ...certificate.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[FirebaseCertificateRepository] saveCertificate error: $e');
      }
    }
    return certificate;
  }

  @override
  Future<void> updateCertificateStatus(
    String certificateId, {
    required String status,
    String? reason,
  }) async {
    final db = _db;
    if (db != null) {
      try {
        await db.collection(collectionName).doc(certificateId).update({
          'status': status,
          'revocationReason': ?reason,
          if (status.toLowerCase() == 'revoked') 'revokedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('[FirebaseCertificateRepository] updateCertificateStatus error: $e');
      }
    }
  }
}
