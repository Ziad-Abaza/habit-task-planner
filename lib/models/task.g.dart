// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task()
      ..title = fields[0] as String
      ..description = fields[1] as String?
      ..categoryId = fields[2] as int
      ..scheduledDate = fields[3] as DateTime
      ..isCompleted = fields[4] as bool
      ..isCyclic = fields[5] as bool
      ..cycleInterval = fields[6] as int?
      ..autoReschedule = fields[7] as bool
      ..hasReminder = fields[8] == null ? false : fields[8] as bool
      ..reminderTime = fields[9] as DateTime?
      ..notificationId = fields[10] as int?;
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.scheduledDate)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.isCyclic)
      ..writeByte(6)
      ..write(obj.cycleInterval)
      ..writeByte(7)
      ..write(obj.autoReschedule)
      ..writeByte(8)
      ..write(obj.hasReminder)
      ..writeByte(9)
      ..write(obj.reminderTime)
      ..writeByte(10)
      ..write(obj.notificationId)
      ..writeByte(11)
      ..write(obj.weekdays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
