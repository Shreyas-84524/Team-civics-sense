import 'package:hive/hive.dart';
import '../../models/reward_local_model.dart';

/// Hive TypeAdapter for [AchievementLocalModel] (typeId: 6).
class AchievementHiveAdapter extends TypeAdapter<AchievementLocalModel> {
  @override
  final int typeId = 6;

  @override
  AchievementLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AchievementLocalModel(
      id: fields[0] as String? ?? '',
      title: fields[1] as String? ?? '',
      description: fields[2] as String? ?? '',
      howToUnlock: fields[3] as String? ?? '',
      iconCodePoint: fields[4] as int? ?? 0,
      iconFontFamily: fields[5] as String?,
      isUnlocked: fields[6] as bool? ?? false,
      pointsRequired: fields[7] as int? ?? 0,
      unlockedAtEpochMs: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, AchievementLocalModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.howToUnlock)
      ..writeByte(4)
      ..write(obj.iconCodePoint)
      ..writeByte(5)
      ..write(obj.iconFontFamily)
      ..writeByte(6)
      ..write(obj.isUnlocked)
      ..writeByte(7)
      ..write(obj.pointsRequired)
      ..writeByte(8)
      ..write(obj.unlockedAtEpochMs);
  }
}
