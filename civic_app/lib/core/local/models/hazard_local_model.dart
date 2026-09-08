import '../../models/category_model.dart';
import '../../models/complaint_model.dart';
import '../../models/hazard_model.dart';

/// Local persistence model for civic hazards stored in Hive.
class HazardLocalModel {
  final String id;
  final String? complaintId;
  final String? ticketNumber;
  final String title;
  final String categoryId;
  final String categoryName;
  final String categoryDescription;
  final String status;
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;
  final String? ward;
  final String severity;
  final String? imageUrl;
  final int upvotes;
  final int createdAtEpochMs;
  final int updatedAtEpochMs;

  const HazardLocalModel({
    required this.id,
    this.complaintId,
    this.ticketNumber,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.categoryDescription,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
    this.ward,
    this.severity = 'medium',
    this.imageUrl,
    this.upvotes = 0,
    required this.createdAtEpochMs,
    required this.updatedAtEpochMs,
  });

  /// Map from Domain Model [HazardModel] -> [HazardLocalModel]
  factory HazardLocalModel.fromDomain(HazardModel hazard) {
    return HazardLocalModel(
      id: hazard.id,
      complaintId: hazard.complaintId,
      ticketNumber: hazard.ticketNumber,
      title: hazard.title,
      categoryId: hazard.category.id,
      categoryName: hazard.category.name,
      categoryDescription: hazard.category.description,
      status: hazard.status.name,
      latitude: hazard.latitude,
      longitude: hazard.longitude,
      address: hazard.address,
      landmark: hazard.landmark,
      ward: hazard.ward,
      severity: hazard.severity.name,
      imageUrl: hazard.imageUrl,
      upvotes: hazard.upvotes,
      createdAtEpochMs: hazard.createdAt.millisecondsSinceEpoch,
      updatedAtEpochMs: hazard.updatedAt.millisecondsSinceEpoch,
    );
  }

  /// Map from [HazardLocalModel] -> Domain Model [HazardModel]
  HazardModel toDomain() {
    ComplaintStatus parsedStatus;
    try {
      parsedStatus = ComplaintStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == status.toLowerCase(),
        orElse: () => ComplaintStatus.reported,
      );
    } catch (_) {
      parsedStatus = ComplaintStatus.reported;
    }

    HazardSeverity parsedSeverity;
    try {
      parsedSeverity = HazardSeverity.values.firstWhere(
        (s) => s.name.toLowerCase() == severity.toLowerCase(),
        orElse: () => HazardSeverity.medium,
      );
    } catch (_) {
      parsedSeverity = HazardSeverity.medium;
    }

    CivicCategory resolvedCategory;
    try {
      resolvedCategory = CivicCategory.defaultCategories.firstWhere(
        (c) => c.id.toLowerCase() == categoryId.toLowerCase(),
        orElse: () => CivicCategory(
          id: categoryId,
          name: categoryName,
          description: categoryDescription,
          icon: CivicCategory.defaultCategories.first.icon,
        ),
      );
    } catch (_) {
      resolvedCategory = CivicCategory.defaultCategories.first;
    }

    return HazardModel(
      id: id,
      complaintId: complaintId,
      ticketNumber: ticketNumber,
      title: title,
      category: resolvedCategory,
      status: parsedStatus,
      latitude: latitude,
      longitude: longitude,
      address: address,
      landmark: landmark,
      ward: ward,
      severity: parsedSeverity,
      imageUrl: imageUrl,
      upvotes: upvotes,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtEpochMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtEpochMs),
    );
  }

  HazardLocalModel copyWith({
    String? id,
    String? complaintId,
    String? ticketNumber,
    String? title,
    String? categoryId,
    String? categoryName,
    String? categoryDescription,
    String? status,
    double? latitude,
    double? longitude,
    String? address,
    String? landmark,
    String? ward,
    String? severity,
    String? imageUrl,
    int? upvotes,
    int? createdAtEpochMs,
    int? updatedAtEpochMs,
  }) {
    return HazardLocalModel(
      id: id ?? this.id,
      complaintId: complaintId ?? this.complaintId,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryDescription: categoryDescription ?? this.categoryDescription,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      ward: ward ?? this.ward,
      severity: severity ?? this.severity,
      imageUrl: imageUrl ?? this.imageUrl,
      upvotes: upvotes ?? this.upvotes,
      createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
    );
  }
}
