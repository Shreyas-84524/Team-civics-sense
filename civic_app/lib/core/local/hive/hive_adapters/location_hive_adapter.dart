import 'package:hive/hive.dart';
import '../../models/location_local_model.dart';

/// Hive TypeAdapter for [LocationLocalModel] (typeId: 1).
class LocationHiveAdapter extends TypeAdapter<LocationLocalModel> {
  @override
  final int typeId = 1;

  @override
  LocationLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationLocalModel(
      latitude: fields[0] as double? ?? 0.0,
      longitude: fields[1] as double? ?? 0.0,
      address: fields[2] as String? ?? '',
      landmark: fields[3] as String?,
      ward: fields[4] as String?,
      city: fields[5] as String?,
      pincode: fields[6] as String?,
      source: fields[7] as String? ?? 'manual',
      accuracyMeters: fields[8] as double?,
      timestampEpochMs: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, LocationLocalModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.landmark)
      ..writeByte(4)
      ..write(obj.ward)
      ..writeByte(5)
      ..write(obj.city)
      ..writeByte(6)
      ..write(obj.pincode)
      ..writeByte(7)
      ..write(obj.source)
      ..writeByte(8)
      ..write(obj.accuracyMeters)
      ..writeByte(9)
      ..write(obj.timestampEpochMs);
  }
}
