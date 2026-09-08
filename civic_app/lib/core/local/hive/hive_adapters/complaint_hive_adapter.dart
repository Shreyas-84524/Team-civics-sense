import 'package:hive/hive.dart';
import '../../models/complaint_local_model.dart';
import '../../models/location_local_model.dart';
import '../../models/timeline_event_local_model.dart';

/// Hive TypeAdapter for [ComplaintLocalModel] (typeId: 0).
class ComplaintHiveAdapter extends TypeAdapter<ComplaintLocalModel> {
  @override
  final int typeId = 0;

  @override
  ComplaintLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ComplaintLocalModel(
      id: fields[0] as String? ?? '',
      citizenId: fields[1] as String? ?? 'user_citizen_001',
      ticketNumber: fields[2] as String? ?? '',
      title: fields[3] as String? ?? '',
      description: fields[4] as String? ?? '',
      categoryId: fields[5] as String? ?? 'other',
      categoryName: fields[6] as String? ?? 'Other',
      categoryDescription: fields[7] as String? ?? '',
      status: fields[8] as String? ?? 'reported',
      priority: fields[9] as String? ?? 'medium',
      location: fields[10] as LocationLocalModel? ??
          const LocationLocalModel(latitude: 0, longitude: 0, address: ''),
      imageUrls: (fields[11] as List?)?.cast<String>() ?? const [],
      createdAtEpochMs: fields[12] as int? ?? 0,
      updatedAtEpochMs: fields[13] as int? ?? 0,
      timeline: (fields[14] as List?)?.cast<TimelineEventLocalModel>() ?? const [],
      upvotes: fields[15] as int? ?? 0,
      isHazard: fields[16] as bool? ?? false,
      officerNotes: fields[17] as String?,
      assignedTo: fields[18] as String?,
      departmentName: fields[19] as String?,
      resolvedAtEpochMs: fields[20] as int?,
      syncStatus: fields[21] as String? ?? 'synced',
      localId: fields[22] as String?,
      serverId: fields[23] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ComplaintLocalModel obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.citizenId)
      ..writeByte(2)
      ..write(obj.ticketNumber)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.categoryName)
      ..writeByte(7)
      ..write(obj.categoryDescription)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.priority)
      ..writeByte(10)
      ..write(obj.location)
      ..writeByte(11)
      ..write(obj.imageUrls)
      ..writeByte(12)
      ..write(obj.createdAtEpochMs)
      ..writeByte(13)
      ..write(obj.updatedAtEpochMs)
      ..writeByte(14)
      ..write(obj.timeline)
      ..writeByte(15)
      ..write(obj.upvotes)
      ..writeByte(16)
      ..write(obj.isHazard)
      ..writeByte(17)
      ..write(obj.officerNotes)
      ..writeByte(18)
      ..write(obj.assignedTo)
      ..writeByte(19)
      ..write(obj.departmentName)
      ..writeByte(20)
      ..write(obj.resolvedAtEpochMs)
      ..writeByte(21)
      ..write(obj.syncStatus)
      ..writeByte(22)
      ..write(obj.localId)
      ..writeByte(23)
      ..write(obj.serverId);
  }
}
