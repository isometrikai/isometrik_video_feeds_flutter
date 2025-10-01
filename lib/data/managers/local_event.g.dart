// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalEventAdapter extends TypeAdapter<LocalEvent> {
  @override
  final int typeId = 0;

  @override
  LocalEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalEvent(
      id: fields[0] as String,
      payload: (fields[1] as Map).cast<String, dynamic>(),
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LocalEvent obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.payload)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
