import '../../core/location/location_model.dart';
import '../../core/models/category_model.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/evidence_model.dart';

/// Temporary in-memory draft model representing an in-progress citizen civic issue report.
class ComplaintDraft {
  final String title;
  final CivicCategory? category;
  final String description;
  final List<String> imageUrls;
  final List<EvidenceItem> evidence;
  final CivicLocation? location;
  final bool isHazard;

  const ComplaintDraft({
    this.title = '',
    this.category,
    this.description = '',
    this.imageUrls = const [],
    this.evidence = const [],
    this.location,
    this.isHazard = false,
  });

  /// Factory for an empty draft.
  factory ComplaintDraft.empty() => const ComplaintDraft();

  /// Whether the user has entered any data into the draft.
  bool get hasChanges =>
      title.trim().isNotEmpty ||
      category != null ||
      description.trim().isNotEmpty ||
      imageUrls.isNotEmpty ||
      evidence.isNotEmpty ||
      location != null;

  /// Whether Step 1 (Information) requirements are satisfied.
  bool get isValidStep1 =>
      title.trim().isNotEmpty && category != null && description.trim().isNotEmpty;

  /// Whether Step 3 (Location) requirement is satisfied.
  bool get isValidLocation => location != null;

  /// Whether the complete draft is valid and ready for final submission.
  bool get isComplete => isValidStep1 && isValidLocation;

  /// Number of attached photos across URLs and evidence items.
  int get photoCount => evidence.isNotEmpty ? evidence.length : imageUrls.length;

  /// Maps selected category to the appropriate municipal department conceptually.
  String get departmentName {
    if (category == null) return 'General Administration';
    switch (category!.id) {
      case 'roads':
        return 'Roads Department';
      case 'water':
        return 'Water Department';
      case 'sanitation':
        return 'Sanitation Department';
      case 'waste':
        return 'Sanitation / Waste Department';
      case 'streetlights':
        return 'Electrical / Public Works';
      case 'drainage':
        return 'Drainage Department';
      case 'infrastructure':
        return 'Public Works';
      case 'traffic':
        return 'Traffic / Road Safety Department';
      case 'other':
      default:
        return 'Manual Review & Municipal Desk';
    }
  }

  ComplaintDraft copyWith({
    String? title,
    CivicCategory? category,
    String? description,
    List<String>? imageUrls,
    List<EvidenceItem>? evidence,
    CivicLocation? location,
    bool? isHazard,
  }) {
    final updatedEvidence = evidence ?? this.evidence;
    List<String>? updatedUrls = imageUrls;
    if (evidence != null && imageUrls == null) {
      updatedUrls = evidence.map((e) => e.filePath).toList();
    } else if (imageUrls != null && evidence == null) {
      updatedUrls = imageUrls;
    } else {
      updatedUrls = this.imageUrls;
    }

    return ComplaintDraft(
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrls: updatedUrls,
      evidence: updatedEvidence,
      location: location ?? this.location,
      isHazard: isHazard ?? this.isHazard,
    );
  }

  /// Converts a ComplaintModel back to a draft for editing or verification.
  factory ComplaintDraft.fromComplaint(ComplaintModel complaint) {
    return ComplaintDraft(
      title: complaint.title,
      category: complaint.category,
      description: complaint.description,
      imageUrls: List.from(complaint.imageUrls),
      evidence: complaint.imageUrls.map((url) {
        return EvidenceItem(
          id: 'from_model_${url.hashCode}',
          filePath: url,
          fileName: url.split('/').last,
          source: EvidenceSource.gallery,
          capturedAt: complaint.createdAt,
        );
      }).toList(),
      location: complaint.location,
      isHazard: complaint.isHazard,
    );
  }
}
