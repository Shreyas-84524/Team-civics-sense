import '../../../models/complaint_model.dart';
import '../models/translation_request.dart';
import '../repositories/translation_repository.dart';
import 'historical_language_resolver.dart';

/// Comprehensive Audit and Migration Report for historical data compatibility.
class HistoricalAuditReport {
  final int recordsScanned;
  final int recordsWithMetadata;
  final int recordsMissingMetadata;
  final int recordsConfidentlyDetected;
  final int recordsMixedLanguage;
  final int recordsUncertain;
  final int recordsSkipped;
  final int recordsModified; // Strictly 0 in non-destructive dry-run
  final List<Map<String, dynamic>> sampleAudits;
  final DateTime auditedAt;

  const HistoricalAuditReport({
    required this.recordsScanned,
    required this.recordsWithMetadata,
    required this.recordsMissingMetadata,
    required this.recordsConfidentlyDetected,
    required this.recordsMixedLanguage,
    required this.recordsUncertain,
    required this.recordsSkipped,
    required this.recordsModified,
    required this.sampleAudits,
    required this.auditedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'recordsScanned': recordsScanned,
      'recordsWithMetadata': recordsWithMetadata,
      'recordsMissingMetadata': recordsMissingMetadata,
      'recordsConfidentlyDetected': recordsConfidentlyDetected,
      'recordsMixedLanguage': recordsMixedLanguage,
      'recordsUncertain': recordsUncertain,
      'recordsSkipped': recordsSkipped,
      'recordsModified': recordsModified,
      'sampleCount': sampleAudits.length,
      'auditedAt': auditedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'HistoricalAuditReport(scanned: $recordsScanned, withMetadata: $recordsWithMetadata, '
        'missing: $recordsMissingMetadata, confident: $recordsConfidentlyDetected, '
        'mixed: $recordsMixedLanguage, uncertain: $recordsUncertain, skipped: $recordsSkipped, '
        'modified: $recordsModified)';
  }
}

/// Historical Data Migration and Audit Utility for CivicFix Multilingual Rollout.
///
/// INVARIANTS:
/// 1. Zero destructive mutations: Never modifies original text in Firestore/Hive complaint documents.
/// 2. Dry-run first: Computes compatibility without making external database writes.
/// 3. Sidecar metadata: Derived language metadata is routed exclusively to the translation cache.
/// 4. Optional Warm-up: Pre-caches high-priority active complaints on demand through TranslationRepository.
class HistoricalMigrationUtility {
  HistoricalMigrationUtility._();

  /// Executes a non-destructive dry-run audit across historical complaints.
  static HistoricalAuditReport runAuditDryRun(List<ComplaintModel> complaints) {
    int countScanned = 0;
    int countWithMetadata = 0;
    int countMissingMetadata = 0;
    int countConfident = 0;
    int countMixed = 0;
    int countUncertain = 0;
    int countSkipped = 0;
    const int countModified = 0; // Strictly zero

    final List<Map<String, dynamic>> samples = [];

    for (final complaint in complaints) {
      countScanned++;

      // Audit title
      final titleRes = HistoricalLanguageResolver.resolve(
        text: complaint.title,
        contentId: complaint.id,
        fieldName: 'title',
      );

      // Audit description
      final descRes = HistoricalLanguageResolver.resolve(
        text: complaint.description,
        contentId: complaint.id,
        fieldName: 'description',
      );

      // Check classification
      final primaryCategory = descRes.category != HistoricalDataCategory.emptyOrNull
          ? descRes.category
          : titleRes.category;

      switch (primaryCategory) {
        case HistoricalDataCategory.explicitMetadata:
          countWithMetadata++;
          break;
        case HistoricalDataCategory.confidentDetectable:
          countMissingMetadata++;
          countConfident++;
          break;
        case HistoricalDataCategory.mixedLanguage:
          countMissingMetadata++;
          countMixed++;
          break;
        case HistoricalDataCategory.uncertain:
          countMissingMetadata++;
          countUncertain++;
          break;
        case HistoricalDataCategory.emptyOrNull:
          countMissingMetadata++;
          countSkipped++;
          break;
      }

      if (samples.length < 10) {
        samples.add({
          'id': complaint.id,
          'ticketNumber': complaint.ticketNumber,
          'title': complaint.title,
          'titleCategory': titleRes.category.name,
          'titleLanguage': titleRes.sourceLanguage,
          'descCategory': descRes.category.name,
          'descLanguage': descRes.sourceLanguage,
        });
      }
    }

    return HistoricalAuditReport(
      recordsScanned: countScanned,
      recordsWithMetadata: countWithMetadata,
      recordsMissingMetadata: countMissingMetadata,
      recordsConfidentlyDetected: countConfident,
      recordsMixedLanguage: countMixed,
      recordsUncertain: countUncertain,
      recordsSkipped: countSkipped,
      recordsModified: countModified,
      sampleAudits: samples,
      auditedAt: DateTime.now(),
    );
  }

  /// Controlled warm-up of active/high-priority complaints to pre-populate translation cache
  /// without running a database-wide translation sweep.
  static Future<int> warmUpActiveComplaints({
    required List<ComplaintModel> complaints,
    required TranslationRepository repository,
    required Set<String> targetLanguages,
    int maxWarmUpCount = 20,
  }) async {
    int warmedUpCount = 0;

    // Filter to active high-priority complaints
    final targetComplaints = complaints
        .where((c) =>
            c.status == ComplaintStatus.reported ||
            c.status == ComplaintStatus.underVerification ||
            c.status == ComplaintStatus.verified ||
            c.status == ComplaintStatus.assigned ||
            c.status == ComplaintStatus.inProgress)
        .take(maxWarmUpCount)
        .toList();

    for (final complaint in targetComplaints) {
      final descRes = HistoricalLanguageResolver.resolve(
        text: complaint.description,
        contentId: complaint.id,
        fieldName: 'description',
      );

      for (final targetLang in targetLanguages) {
        if (targetLang != descRes.sourceLanguage) {
          await repository.translate(
            TranslationRequest(
              originalText: complaint.description,
              targetLanguage: targetLang,
              sourceLanguage: descRes.sourceLanguage,
              contentCategory: 'complaint_description',
              contentId: complaint.id,
              fieldName: 'description',
            ),
            useCache: true,
          );
          warmedUpCount++;
        }
      }
    }

    return warmedUpCount;
  }
}
