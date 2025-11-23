import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  late String title;

  @HiveField(1)
  String? description;

  @HiveField(2)
  late int categoryId;

  @HiveField(3)
  late DateTime scheduledDate;

  @HiveField(4)
  bool isCompleted = false;

  @HiveField(5)
  bool isCyclic = false;

  @HiveField(6)
  int? cycleInterval; // In days

  @HiveField(7)
  bool autoReschedule = false;
}
