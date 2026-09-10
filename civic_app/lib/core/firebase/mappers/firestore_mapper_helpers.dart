import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../location/location_model.dart';
import '../../models/category_model.dart';
import '../../models/complaint_model.dart';
import '../../models/hazard_model.dart';
import '../../models/notification_model.dart';

/// Reusable utility conversions for Firestore field types, enums, timestamps, and locations.
class FirestoreMapperHelpers {
  FirestoreMapperHelpers._();

  // ===========================================================================
  // TIMESTAMPS
  // ===========================================================================

  /// Safely converts Firestore [Timestamp], [String], or [int] milliseconds into Dart [DateTime].
  static DateTime? timestampToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Converts Dart [DateTime] to Firestore [Timestamp].
  static Timestamp? dateTimeToTimestamp(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }

  // ===========================================================================
  // LOCATION
  // ===========================================================================

  /// Serializes [CivicLocation] into a structured Firestore map.
  static Map<String, dynamic> locationToMap(CivicLocation loc) {
    return {
      'latitude': loc.latitude,
      'longitude': loc.longitude,
      'address': loc.address,
      'landmark': loc.landmark,
      'ward': loc.ward,
      'city': loc.city,
    };
  }

  /// Safely reconstructs [CivicLocation] from Firestore map or data object.
  static CivicLocation locationFromMap(dynamic map) {
    if (map is! Map) {
      return const CivicLocation(
        latitude: 0.0,
        longitude: 0.0,
        address: 'Unknown Location',
      );
    }

    final double lat = (map['latitude'] as num?)?.toDouble() ?? 0.0;
    final double lng = (map['longitude'] as num?)?.toDouble() ?? 0.0;
    final String address = map['address'] as String? ?? 'Unknown Location';
    final String? landmark = map['landmark'] as String?;
    final String? ward = map['ward'] as String?;
    final String? city = map['city'] as String?;

    return CivicLocation(
      latitude: lat,
      longitude: lng,
      address: address,
      landmark: landmark,
      ward: ward,
      city: city,
    );
  }

  // ===========================================================================
  // CATEGORY
  // ===========================================================================

  /// Serializes [CivicCategory] into a Firestore map.
  static Map<String, dynamic> categoryToMap(CivicCategory category) {
    return {
      'id': category.id,
      'name': category.name,
      'description': category.description,
    };
  }

  /// Safely resolves [CivicCategory] from a Firestore map or category ID.
  static CivicCategory categoryFromMap(dynamic val) {
    if (val is Map) {
      final id = val['id'] as String? ?? 'cat_roads';
      final name = val['name'] as String? ?? 'Roads & Potholes';
      final desc = val['description'] as String? ?? 'Road and pavement issues';
      return CivicCategory.defaultCategories.firstWhere(
        (c) => c.id == id,
        orElse: () => CivicCategory(
          id: id,
          name: name,
          description: desc,
          icon: Icons.report_problem_outlined,
        ),
      );
    } else if (val is String) {
      return CivicCategory.defaultCategories.firstWhere(
        (c) => c.id == val || c.name.toLowerCase() == val.toLowerCase(),
        orElse: () => CivicCategory.defaultCategories[0],
      );
    }
    return CivicCategory.defaultCategories[0];
  }

  // ===========================================================================
  // ENUMS
  // ===========================================================================

  /// Deserializes Firestore status string to [ComplaintStatus] safely.
  static ComplaintStatus parseComplaintStatus(String? value) {
    if (value == null) return ComplaintStatus.reported;
    switch (value.toLowerCase()) {
      case 'reported':
      case 'submitted':
        return ComplaintStatus.reported;
      case 'verified':
      case 'underreview':
      case 'under_review':
        return ComplaintStatus.verified;
      case 'assigned':
        return ComplaintStatus.assigned;
      case 'inprogress':
      case 'in_progress':
        return ComplaintStatus.inProgress;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'rejected':
        return ComplaintStatus.rejected;
      default:
        return ComplaintStatus.reported;
    }
  }

  /// Deserializes Firestore priority string to [ComplaintPriority] safely.
  static ComplaintPriority parseComplaintPriority(String? value) {
    if (value == null) return ComplaintPriority.medium;
    switch (value.toLowerCase()) {
      case 'low':
        return ComplaintPriority.low;
      case 'medium':
        return ComplaintPriority.medium;
      case 'high':
        return ComplaintPriority.high;
      case 'emergency':
      case 'critical':
        return ComplaintPriority.emergency;
      default:
        return ComplaintPriority.medium;
    }
  }

  /// Deserializes Firestore hazard severity string to [HazardSeverity] safely.
  static HazardSeverity parseHazardSeverity(String? value) {
    if (value == null) return HazardSeverity.medium;
    switch (value.toLowerCase()) {
      case 'low':
        return HazardSeverity.low;
      case 'medium':
        return HazardSeverity.medium;
      case 'high':
        return HazardSeverity.high;
      case 'critical':
      case 'emergency':
        return HazardSeverity.critical;
      default:
        return HazardSeverity.medium;
    }
  }

  /// Deserializes Firestore notification type string to [NotificationType] safely.
  static NotificationType parseNotificationType(String? value) {
    if (value == null) return NotificationType.generalCivic;
    switch (value) {
      case 'complaintSubmitted':
        return NotificationType.complaintSubmitted;
      case 'complaintVerified':
        return NotificationType.complaintVerified;
      case 'complaintAssigned':
        return NotificationType.complaintAssigned;
      case 'complaintStatusChanged':
        return NotificationType.complaintStatusChanged;
      case 'complaintResolved':
        return NotificationType.complaintResolved;
      case 'generalCivic':
      case 'civicBroadcast':
        return NotificationType.generalCivic;
      case 'hazardAlert':
        return NotificationType.hazardAlert;
      case 'rewardEarned':
        return NotificationType.rewardEarned;
      default:
        return NotificationType.generalCivic;
    }
  }
}
