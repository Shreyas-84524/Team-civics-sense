import 'package:hive/hive.dart';
import '../../models/hazard_local_model.dart';

/// Hive TypeAdapter for [HazardLocalModel] (typeId: 3).
class HazardHiveAdapter extends TypeAdapter<HazardLocalModel> {
  @override
  final int typeId = 3;

  @override
  HazardLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HazardLocalModel(
      id: fields[0] as String? ?? '',
      complaintId: fields[1] as String?,
      ticketNumber: fields[2] as String?,
      title: fields[3] as String? ?? '',
      categoryId: fields[4] as String? ?? 'other',
      categoryName: fields[5] as String? ?? 'Other',
      categoryDescription: fields[6] as String? ?? '',
      status: fields[7] as String? ?? 'reported',
      latitude: fields[8] as double? ?? 0.0,
      longitude: fields[9] as double? ?? 0.0,
      address: fields[10] as String? ?? '',
      landmark: fields[11] as String?,
      ward: fields[12] as String?,
      severity: fields[13] as String? ?? 'medium',
      imageUrl: fields[14] as String?,
      upvotes: fields[15] as int? ?? 0,
      createdAtEpochMs: fields[16] as int? ?? 0,
      updatedAtEpochMs: fields[17] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, HazardLocalModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.complaintId)
      ..writeByte(2)
      ..write(obj.ticketNumber)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.categoryId)
      ..writeByte(5)
      ..write(obj.categoryName)
      ..writeByte(6)
      ..write(obj.categoryDescription)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.latitude)
      ..writeByte(9)
      ..write(obj.longitude)
      ..writeByte(10)
      ..write(obj.address)
      ..writeByte(11)
      ..write(obj.landmark)
      ..writeByte(12)
      ..write(obj.ward)
      ..writeByte(13)
      ..write(obj.severity)
      ..writeByte(14)
      ..write(obj.imageUrl)
      ..writeByte(15)
      ..write(obj.upvotes)
      ..writeByte(16)
      ..write(obj.createdAtEpochMs)
      ..writeByte(17)
      ..write(obj.updatedAtEpochMs);
  }
}
