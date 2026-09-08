import '../../models/category_model.dart';
import '../../models/complaint_model.dart';
import 'location_local_model.dart';
import 'timeline_event_local_model.dart';

/// Local persistence model for civic complaints stored in Hive.
class ComplaintLocalModel {
  final String id;
  final String citizenId;
  final String ticketNumber;
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final String categoryDescription;
  final String status;
  final String priority;
  final LocationLocalModel location;
  final List<String> imageUrls;
  final int createdAtEpochMs;
  final int updatedAtEpochMs;
  final List<TimelineEventLocalModel> timeline;
  final int upvotes;
  final bool isHazard;
  final String? officerNotes;
  final String? assignedTo;
  final String? departmentName;
  final int? resolvedAtEpochMs;
  final String syncStatus;
  final String? localId;
  final String? serverId;

  const ComplaintLocalModel({
    required this.id,
    required this.citizenId,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.categoryDescription,
    required this.status,
    required this.priority,
    required this.location,
    this.imageUrls = const [],
    required this.createdAtEpochMs,
    required this.updatedAtEpochMs,
    this.timeline = const [],
    this.upvotes = 0,
    this.isHazard = false,
    this.officerNotes,
    this.assignedTo,
    this.departmentName,
    this.resolvedAtEpochMs,
    this.syncStatus = 'synced',
    this.localId,
    this.serverId,
  });

  /// Map from Domain Model [ComplaintModel] -> [ComplaintLocalModel]
  factory ComplaintLocalModel.fromDomain(ComplaintModel complaint) {
    return ComplaintLocalModel(
      id: complaint.id,
      citizenId: complaint.citizenId,
      ticketNumber: complaint.ticketNumber,
      title: complaint.title,
      description: complaint.description,
      categoryId: complaint.category.id,
      categoryName: complaint.category.name,
      categoryDescription: complaint.category.description,
      status: complaint.status.name,
      priority: complaint.priority.name,
      location: LocationLocalModel.fromDomain(complaint.location),
      imageUrls: List.unmodifiable(complaint.imageUrls),
      createdAtEpochMs: complaint.createdAt.millisecondsSinceEpoch,
      updatedAtEpochMs: complaint.updatedAt.millisecondsSinceEpoch,
      timeline: complaint.timeline.map(TimelineEventLocalModel.fromDomain).toList(),
      upvotes: complaint.upvotes,
      isHazard: complaint.isHazard,
      officerNotes: complaint.officerNotes,
      assignedTo: complaint.assignedTo,
      departmentName: complaint.departmentName,
      resolvedAtEpochMs: complaint.resolvedAt?.millisecondsSinceEpoch,
      syncStatus: complaint.syncStatus.name,
      localId: complaint.localId,
      serverId: complaint.serverId,
    );
  }

  /// Map from [ComplaintLocalModel] -> Domain Model [ComplaintModel]
  ComplaintModel toDomain() {
    ComplaintStatus parsedStatus;
    try {
      parsedStatus = ComplaintStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == status.toLowerCase(),
        orElse: () => ComplaintStatus.reported,
      );
    } catch (_) {
      parsedStatus = ComplaintStatus.reported;
    }

    ComplaintPriority parsedPriority;
    try {
      parsedPriority = ComplaintPriority.values.firstWhere(
        (p) => p.name.toLowerCase() == priority.toLowerCase(),
        orElse: () => ComplaintPriority.medium,
      );
    } catch (_) {
      parsedPriority = ComplaintPriority.medium;
    }

    SyncStatus parsedSyncStatus;
    try {
      parsedSyncStatus = SyncStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == syncStatus.toLowerCase(),
        orElse: () => SyncStatus.synced,
      );
    } catch (_) {
      parsedSyncStatus = SyncStatus.synced;
    }

    // Resolve category from default categories or create an instance
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

    return ComplaintModel(
      id: id,
      citizenId: citizenId,
      ticketNumber: ticketNumber,
      title: title,
      description: description,
      category: resolvedCategory,
      status: parsedStatus,
      priority: parsedPriority,
      location: location.toDomain(),
      imageUrls: imageUrls,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtEpochMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtEpochMs),
      timeline: timeline.map((e) => e.toDomain()).toList(),
      upvotes: upvotes,
      isHazard: isHazard,
      officerNotes: officerNotes,
      assignedTo: assignedTo,
      departmentName: departmentName,
      resolvedAt: resolvedAtEpochMs != null
          ? DateTime.fromMillisecondsSinceEpoch(resolvedAtEpochMs!)
          : null,
      syncStatus: parsedSyncStatus,
      localId: localId,
      serverId: serverId,
    );
  }

  ComplaintLocalModel copyWith({
    String? id,
    String? citizenId,
    String? ticketNumber,
    String? title,
    String? description,
    String? categoryId,
    String? categoryName,
    String? categoryDescription,
    String? status,
    String? priority,
    LocationLocalModel? location,
    List<String>? imageUrls,
    int? createdAtEpochMs,
    int? updatedAtEpochMs,
    List<TimelineEventLocalModel>? timeline,
    int? upvotes,
    bool? isHazard,
    String? officerNotes,
    String? assignedTo,
    String? departmentName,
    int? resolvedAtEpochMs,
    String? syncStatus,
    String? localId,
    String? serverId,
  }) {
    return ComplaintLocalModel(
      id: id ?? this.id,
      citizenId: citizenId ?? this.citizenId,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryDescription: categoryDescription ?? this.categoryDescription,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
      timeline: timeline ?? this.timeline,
      upvotes: upvotes ?? this.upvotes,
      isHazard: isHazard ?? this.isHazard,
      officerNotes: officerNotes ?? this.officerNotes,
      assignedTo: assignedTo ?? this.assignedTo,
      departmentName: departmentName ?? this.departmentName,
      resolvedAtEpochMs: resolvedAtEpochMs ?? this.resolvedAtEpochMs,
      syncStatus: syncStatus ?? this.syncStatus,
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
    );
  }
}
