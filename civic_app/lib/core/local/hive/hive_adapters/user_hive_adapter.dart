import 'package:hive/hive.dart';
import '../../models/user_local_model.dart';

/// Hive TypeAdapter for [UserLocalModel] (typeId: 5).
class UserHiveAdapter extends TypeAdapter<UserLocalModel> {
  @override
  final int typeId = 5;

  @override
  UserLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserLocalModel(
      id: fields[0] as String? ?? '',
      fullName: fields[1] as String? ?? '',
      email: fields[2] as String? ?? '',
      phone: fields[3] as String? ?? '',
      avatarUrl: fields[4] as String?,
      civicPoints: fields[5] as int? ?? 0,
      reportsSubmitted: fields[6] as int? ?? 0,
      reportsResolved: fields[7] as int? ?? 0,
      badges: (fields[8] as List?)?.cast<String>() ?? const [],
      languageCode: fields[9] as String? ?? 'en',
      wardNumber: fields[10] as String? ?? 'Ward 14 (Central)',
      role: fields[11] as String? ?? 'citizen',
    );
  }

  @override
  void write(BinaryWriter writer, UserLocalModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.avatarUrl)
      ..writeByte(5)
      ..write(obj.civicPoints)
      ..writeByte(6)
      ..write(obj.reportsSubmitted)
      ..writeByte(7)
      ..write(obj.reportsResolved)
      ..writeByte(8)
      ..write(obj.badges)
      ..writeByte(9)
      ..write(obj.languageCode)
      ..writeByte(10)
      ..write(obj.wardNumber)
      ..writeByte(11)
      ..write(obj.role);
  }
}
