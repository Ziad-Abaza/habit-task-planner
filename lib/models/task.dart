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

  @HiveField(8, defaultValue: false)
  bool hasReminder = false;

  @HiveField(9)
  DateTime? reminderTime; // Time for notification

  @HiveField(10)
  int? notificationId; // For canceling notifications

  // Helper to get reminder time or default to 9 AM on scheduled date
  DateTime get effectiveReminderTime {
    if (reminderTime != null) {
      return reminderTime!;
    }
    // Default to 9 AM on the scheduled date
    return DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      9,
      0,
    );
  }
}
