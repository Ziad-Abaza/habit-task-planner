import 'package:hive/hive.dart';

part 'subtask.g.dart';

@HiveType(typeId: 2)
class Subtask extends HiveObject {
  @HiveField(0)
  late String title;

  @HiveField(1)
  late bool isCompleted;

  @HiveField(2)
  late int order;

  @HiveField(3)
  late String parentTaskKey; // Reference to parent task's key

  @HiveField(4)
  late DateTime createdAt;

  // Default constructor for Hive
  Subtask();

  // Named constructor for creating subtasks
  Subtask.create({
    required this.title,
    required this.parentTaskKey,
    this.isCompleted = false,
    this.order = 0,
  }) {
    createdAt = DateTime.now();
  }
}
