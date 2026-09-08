import 'package:hive/hive.dart';
import '../../models/settings_local_model.dart';

/// Hive TypeAdapter for [SettingsLocalModel] (typeId: 9).
class SettingsHiveAdapter extends TypeAdapter<SettingsLocalModel> {
  @override
  final int typeId = 9;

  @override
  SettingsLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsLocalModel(
      themeMode: fields[0] as String? ?? 'system',
      languageCode: fields[1] as String? ?? 'en',
      pushNotificationsEnabled: fields[2] as bool? ?? true,
      emailNotificationsEnabled: fields[3] as bool? ?? true,
      soundEnabled: fields[4] as bool? ?? true,
      locationPermissionRequested: fields[5] as bool? ?? false,
      lastSyncEpochMs: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsLocalModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.languageCode)
      ..writeByte(2)
      ..write(obj.pushNotificationsEnabled)
      ..writeByte(3)
      ..write(obj.emailNotificationsEnabled)
      ..writeByte(4)
      ..write(obj.soundEnabled)
      ..writeByte(5)
      ..write(obj.locationPermissionRequested)
      ..writeByte(6)
      ..write(obj.lastSyncEpochMs);
  }
}
