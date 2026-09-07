import '../../core/models/category_model.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/hazard_model.dart';
import '../../core/models/user_model.dart';

/// Compact model representing a nearby civic hazard preview on the Home screen.
class NearbyHazardModel {
  final String id;
  final String ticketNumber;
  final String title;
  final CivicCategory category;
  final int distanceMeters;
  final String distanceText;
  final ComplaintStatus status;
  final String locality;

  const NearbyHazardModel({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.category,
    required this.distanceMeters,
    required this.distanceText,
    required this.status,
    required this.locality,
  });

  /// Converts a ComplaintModel to a NearbyHazardModel with estimated distance.
  factory NearbyHazardModel.fromComplaint(ComplaintModel complaint, {int distanceMeters = 350, String locality = 'Ward 14'}) {
    final distanceDisplay = distanceMeters < 1000
        ? '$distanceMeters m away'
        : '${(distanceMeters / 1000).toStringAsFixed(1)} km away';

    return NearbyHazardModel(
      id: complaint.id,
      ticketNumber: complaint.ticketNumber,
      title: complaint.title,
      category: complaint.category,
      distanceMeters: distanceMeters,
      distanceText: distanceDisplay,
      status: complaint.status,
      locality: complaint.location.landmark ?? complaint.location.ward ?? locality,
    );
  }

  /// Converts a HazardModel to a NearbyHazardModel with estimated distance.
  factory NearbyHazardModel.fromHazard(HazardModel hazard, {int distanceMeters = 350, String locality = 'Ward 14'}) {
    final distanceDisplay = distanceMeters < 1000
        ? '$distanceMeters m away'
        : '${(distanceMeters / 1000).toStringAsFixed(1)} km away';

    return NearbyHazardModel(
      id: hazard.complaintId ?? hazard.id,
      ticketNumber: hazard.ticketNumber ?? 'CF-2026-000000',
      title: hazard.title,
      category: hazard.category,
      distanceMeters: distanceMeters,
      distanceText: distanceDisplay,
      status: hazard.status,
      locality: hazard.landmark ?? hazard.ward ?? locality,
    );
  }
}

/// Civic participation and progress stats displayed on Home.
class CivicProgressSummary {
  final int points;
  final int reportsSubmitted;
  final int reportsResolved;
  final String levelName;
  final double progressPercent;
  final int nextLevelTarget;

  const CivicProgressSummary({
    required this.points,
    required this.reportsSubmitted,
    required this.reportsResolved,
    this.levelName = 'Civic Contributor',
    this.progressPercent = 0.80,
    this.nextLevelTarget = 600,
  });

  factory CivicProgressSummary.fromUser(UserModel? user) {
    final points = user?.civicPoints ?? 120;
    final submitted = user?.reportsSubmitted ?? 5;
    final resolved = user?.reportsResolved ?? 3;

    String level;
    double percent;
    int target;

    if (points < 200) {
      level = 'Active Citizen';
      percent = points / 200;
      target = 200;
    } else if (points < 500) {
      level = 'Civic Contributor';
      percent = (points - 200) / 300;
      target = 500;
    } else {
      level = 'Community Guardian';
      percent = 1.0;
      target = 1000;
    }

    return CivicProgressSummary(
      points: points,
      reportsSubmitted: submitted,
      reportsResolved: resolved,
      levelName: level,
      progressPercent: percent.clamp(0.0, 1.0),
      nextLevelTarget: target,
    );
  }
}

/// Aggregated data payload for the Citizen Home Dashboard.
class HomeDataModel {
  final UserModel? user;
  final String greeting;
  final String welcomeMessage;
  final int unreadNotificationsCount;
  final List<ComplaintModel> recentComplaints;
  final List<NearbyHazardModel> nearbyHazards;
  final CivicProgressSummary progress;

  const HomeDataModel({
    required this.user,
    required this.greeting,
    required this.welcomeMessage,
    required this.unreadNotificationsCount,
    required this.recentComplaints,
    required this.nearbyHazards,
    required this.progress,
  });
}
