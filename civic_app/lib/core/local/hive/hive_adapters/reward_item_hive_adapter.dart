import 'package:hive/hive.dart';
import '../../models/reward_local_model.dart';

/// Hive TypeAdapter for [RewardItemLocalModel] (typeId: 7).
class RewardItemHiveAdapter extends TypeAdapter<RewardItemLocalModel> {
  @override
  final int typeId = 7;

  @override
  RewardItemLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RewardItemLocalModel(
      id: fields[0] as String? ?? '',
      title: fields[1] as String? ?? '',
      partner: fields[2] as String? ?? '',
      description: fields[3] as String? ?? '',
      pointsCost: fields[4] as int? ?? 0,
      expiryDate: fields[5] as String? ?? '',
      iconCodePoint: fields[6] as int? ?? 0,
      iconFontFamily: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RewardItemLocalModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.partner)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.pointsCost)
      ..writeByte(5)
      ..write(obj.expiryDate)
      ..writeByte(6)
      ..write(obj.iconCodePoint)
      ..writeByte(7)
      ..write(obj.iconFontFamily);
  }
}
