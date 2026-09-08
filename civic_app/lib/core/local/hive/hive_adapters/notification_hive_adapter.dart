import 'package:hive/hive.dart';
import '../../models/notification_local_model.dart';

/// Hive TypeAdapter for [NotificationLocalModel] (typeId: 4).
class NotificationHiveAdapter extends TypeAdapter<NotificationLocalModel> {
  @override
  final int typeId = 4;

  @override
  NotificationLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationLocalModel(
      id: fields[0] as String? ?? '',
      userId: fields[1] as String? ?? 'user_citizen_001',
      title: fields[2] as String? ?? '',
      message: fields[3] as String? ?? '',
      type: fields[4] as String? ?? 'generalCivic',
      complaintId: fields[5] as String?,
      isRead: fields[6] as bool? ?? false,
      createdAtEpochMs: fields[7] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationLocalModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.message)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.complaintId)
      ..writeByte(6)
      ..write(obj.isRead)
      ..writeByte(7)
      ..write(obj.createdAtEpochMs);
  }
}
