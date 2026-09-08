import 'package:hive/hive.dart';
import '../../models/timeline_event_local_model.dart';

/// Hive TypeAdapter for [TimelineEventLocalModel] (typeId: 2).
class TimelineEventHiveAdapter extends TypeAdapter<TimelineEventLocalModel> {
  @override
  final int typeId = 2;

  @override
  TimelineEventLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimelineEventLocalModel(
      title: fields[0] as String? ?? '',
      description: fields[1] as String? ?? '',
      timestampEpochMs: fields[2] as int? ?? 0,
      status: fields[3] as String? ?? 'reported',
      updatedBy: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TimelineEventLocalModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.timestampEpochMs)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.updatedBy);
  }
}
