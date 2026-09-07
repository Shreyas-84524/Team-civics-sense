import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'category_model.dart';
import 'complaint_model.dart';

/// Severity level for civic hazards
enum HazardSeverity {
  low,
  medium,
  high,
  critical,
}

extension HazardSeverityExt on HazardSeverity {
  String get label {
    switch (this) {
      case HazardSeverity.low:
        return 'Low';
      case HazardSeverity.medium:
        return 'Medium';
      case HazardSeverity.high:
        return 'High';
      case HazardSeverity.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case HazardSeverity.low:
        return CivicFixColors.info;
      case HazardSeverity.medium:
        return CivicFixColors.alertDark;
      case HazardSeverity.high:
        return const Color(0xFFE65100);
      case HazardSeverity.critical:
        return CivicFixColors.error;
    }
  }
}

/// Civic hazard model representing geotagged community issues on the Hazard Map.
class HazardModel {
  final String id;
  final String? complaintId;
  final String? ticketNumber;
  final String title;
  final CivicCategory category;
  final ComplaintStatus status;
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;
  final String? ward;
  final HazardSeverity severity;
  final String? imageUrl;
  final int upvotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HazardModel({
    required this.id,
    this.complaintId,
    this.ticketNumber,
    required this.title,
    required this.category,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
    this.ward,
    this.severity = HazardSeverity.medium,
    this.imageUrl,
    this.upvotes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Derives a HazardModel from an existing ComplaintModel
  factory HazardModel.fromComplaint(ComplaintModel complaint, {HazardSeverity? severity}) {
    return HazardModel(
      id: 'haz_${complaint.id}',
      complaintId: complaint.id,
      ticketNumber: complaint.ticketNumber,
      title: complaint.title,
      category: complaint.category,
      status: complaint.status,
      latitude: complaint.location.latitude,
      longitude: complaint.location.longitude,
      address: complaint.location.address,
      landmark: complaint.location.landmark,
      ward: complaint.location.ward,
      severity: severity ?? (complaint.priority == ComplaintPriority.high ? HazardSeverity.high : HazardSeverity.medium),
      imageUrl: complaint.imageUrls.isNotEmpty ? complaint.imageUrls.first : null,
      upvotes: complaint.upvotes,
      createdAt: complaint.createdAt,
      updatedAt: complaint.updatedAt,
    );
  }

  /// Category icon based on civic hazard category
  IconData get categoryIcon {
    final nameLower = category.name.toLowerCase();
    if (nameLower.contains('road') || nameLower.contains('pothole')) {
      return Icons.edit_road_rounded;
    } else if (nameLower.contains('waterlogging') || nameLower.contains('water')) {
      return Icons.water_drop_rounded;
    } else if (nameLower.contains('manhole')) {
      return Icons.warning_amber_rounded;
    } else if (nameLower.contains('garbage') || nameLower.contains('waste') || nameLower.contains('sanitation')) {
      return Icons.delete_outline_rounded;
    } else if (nameLower.contains('drainage') || nameLower.contains('drain')) {
      return Icons.waves_rounded;
    } else if (nameLower.contains('light') || nameLower.contains('street light')) {
      return Icons.lightbulb_outline_rounded;
    }
    return Icons.report_problem_outlined;
  }

  /// Semantic color based on status
  Color get statusColor => status.badgeColor;

  /// Human-readable status label
  String get statusLabel => status.label;

  HazardModel copyWith({
    String? id,
    String? complaintId,
    String? ticketNumber,
    String? title,
    CivicCategory? category,
    ComplaintStatus? status,
    double? latitude,
    double? longitude,
    String? address,
    String? landmark,
    String? ward,
    HazardSeverity? severity,
    String? imageUrl,
    int? upvotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HazardModel(
      id: id ?? this.id,
      complaintId: complaintId ?? this.complaintId,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      title: title ?? this.title,
      category: category ?? this.category,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      ward: ward ?? this.ward,
      severity: severity ?? this.severity,
      imageUrl: imageUrl ?? this.imageUrl,
      upvotes: upvotes ?? this.upvotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
