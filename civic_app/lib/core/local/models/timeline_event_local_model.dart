import '../../models/complaint_model.dart';

/// Local persistence model for complaint lifecycle audit events.
class TimelineEventLocalModel {
  final String title;
  final String description;
  final int timestampEpochMs;
  final String status;
  final String? updatedBy;

  const TimelineEventLocalModel({
    required this.title,
    required this.description,
    required this.timestampEpochMs,
    required this.status,
    this.updatedBy,
  });

  /// Map from Domain Model [TimelineEvent] -> [TimelineEventLocalModel]
  factory TimelineEventLocalModel.fromDomain(TimelineEvent event) {
    return TimelineEventLocalModel(
      title: event.title,
      description: event.description,
      timestampEpochMs: event.timestamp.millisecondsSinceEpoch,
      status: event.status.name,
      updatedBy: event.updatedBy,
    );
  }

  /// Map from [TimelineEventLocalModel] -> Domain Model [TimelineEvent]
  TimelineEvent toDomain() {
    ComplaintStatus parsedStatus;
    try {
      parsedStatus = ComplaintStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == status.toLowerCase(),
        orElse: () => ComplaintStatus.reported,
      );
    } catch (_) {
      parsedStatus = ComplaintStatus.reported;
    }

    return TimelineEvent(
      title: title,
      description: description,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampEpochMs),
      status: parsedStatus,
      updatedBy: updatedBy,
    );
  }

  TimelineEventLocalModel copyWith({
    String? title,
    String? description,
    int? timestampEpochMs,
    String? status,
    String? updatedBy,
  }) {
    return TimelineEventLocalModel(
      title: title ?? this.title,
      description: description ?? this.description,
      timestampEpochMs: timestampEpochMs ?? this.timestampEpochMs,
      status: status ?? this.status,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
