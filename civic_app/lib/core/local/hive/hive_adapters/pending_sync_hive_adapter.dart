import 'package:hive/hive.dart';
import '../../models/pending_sync_local_model.dart';

/// Hive TypeAdapter for [PendingSyncLocalModel] (typeId: 8).
class PendingSyncHiveAdapter extends TypeAdapter<PendingSyncLocalModel> {
  @override
  final int typeId = 8;

  @override
  PendingSyncLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingSyncLocalModel(
      id: fields[0] as String? ?? '',
      entityType: fields[1] as String? ?? 'complaint',
      action: fields[2] as String? ?? 'create',
      payloadJson: fields[3] as String? ?? '{}',
      createdAtEpochMs: fields[4] as int? ?? 0,
      retryCount: fields[5] as int? ?? 0,
      lastError: fields[6] as String?,
      syncStatus: fields[7] as String? ?? 'pending',
      entityId: fields[8] as String? ?? '',
      lastAttemptAtEpochMs: fields[9] as int?,
      idempotencyKey: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingSyncLocalModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entityType)
      ..writeByte(2)
      ..write(obj.action)
      ..writeByte(3)
      ..write(obj.payloadJson)
      ..writeByte(4)
      ..write(obj.createdAtEpochMs)
      ..writeByte(5)
      ..write(obj.retryCount)
      ..writeByte(6)
      ..write(obj.lastError)
      ..writeByte(7)
      ..write(obj.syncStatus)
      ..writeByte(8)
      ..write(obj.entityId)
      ..writeByte(9)
      ..write(obj.lastAttemptAtEpochMs)
      ..writeByte(10)
      ..write(obj.idempotencyKey);
  }
}
