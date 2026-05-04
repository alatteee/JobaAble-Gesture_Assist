// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogModelAdapter extends TypeAdapter<LogModel> {
  @override
  final int typeId = 0;

  @override
  LogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LogModel(
      title: fields[1] as String,
      description: fields[2] as String,
      date: fields[3] as DateTime,
      category: fields[6] as String,
      authorId: fields[4] as String,
      teamId: fields[5] as String,
      isSynced: fields[7] as bool? ?? false, // Handle null dari data lama
      isPublic: fields[8] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, LogModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.idHex)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.authorId)
      ..writeByte(5)
      ..write(obj.teamId)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
        ..write(obj.isSynced)
        ..writeByte(8)
        ..write(obj.isPublic);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
