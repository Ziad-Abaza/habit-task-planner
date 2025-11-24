import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

final tasksStreamProvider = StreamProvider<List<Task>>((ref) async* {
  final hiveService = ref.watch(hiveServiceProvider);
  yield* hiveService.listenToTasks();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final hiveService = ref.watch(hiveServiceProvider);
  return hiveService.getAllCategories();
});

class TaskNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final HiveService _hiveService;
  final NotificationService _notificationService = NotificationService();

  TaskNotifier(this._hiveService) : super(const AsyncValue.loading()) {
    _fetchTasks();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    // Schedule daily overview at 8 AM
    await _notificationService.scheduleDailyOverview(hour: 8, minute: 0);
  }

  Future<void> _fetchTasks() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => _hiveService.getAllTasks());
  }

  Future<void> addTask(Task task) async {
    if (task.isCyclic && task.recurrenceType == RecurrenceType.weekly && task.weekdays.isNotEmpty) {
      // For tasks with specific weekdays, ensure the scheduled date is one of the selected days
      if (!task.weekdays.contains(task.scheduledDate.weekday)) {
        // Find the next occurrence from today
        final now = DateTime.now();
        for (int i = 0; i < 7; i++) {
          final date = now.add(Duration(days: i));
          if (task.weekdays.contains(date.weekday)) {
            task.scheduledDate = DateTime(
              date.year,
              date.month,
              date.day,
              task.scheduledDate.hour,
              task.scheduledDate.minute,
            );
            break;
          }
        }
      }
    }
    
    await _hiveService.saveTask(task);
    // Schedule notification if reminder is set
    if (task.hasReminder) {
      await _notificationService.scheduleTaskReminder(task);
      
      // Schedule future occurrences if it's a recurring task with specific weekdays
      if (task.isCyclic && task.recurrenceType == RecurrenceType.weekly && task.weekdays.isNotEmpty) {
        await _scheduleFutureTaskOccurrences(task);
      }
    }
  }
  
  Future<void> _scheduleFutureTaskOccurrences(Task task) async {
    if (!task.isCyclic || task.weekdays.isEmpty) return;
    
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, now.day);
    
    // Schedule for the next 30 days
    for (int i = 1; i <= 30; i++) {
      final date = now.add(Duration(days: i));
      if (task.weekdays.contains(date.weekday)) {
        final occurrence = Task()
          ..title = task.title
          ..description = task.description
          ..categoryId = task.categoryId
          ..scheduledDate = DateTime(
            date.year,
            date.month,
            date.day,
            task.scheduledDate.hour,
            task.scheduledDate.minute,
          )
          ..isCyclic = false // This is a specific occurrence
          ..hasReminder = task.hasReminder
          ..reminderTime = task.reminderTime != null
              ? DateTime(
                  date.year,
                  date.month,
                  date.day,
                  task.reminderTime!.hour,
                  task.reminderTime!.minute,
                )
              : null;
              
        await _hiveService.saveTask(occurrence);
        if (occurrence.hasReminder) {
          await _notificationService.scheduleTaskReminder(occurrence);
        }
      }
    }
  }

  Future<void> updateTask(Task task) async {
    await _hiveService.saveTask(task);
    // Cancel old notification and schedule new one if needed
    await _notificationService.cancelTaskReminder(task);
    if (task.hasReminder && !task.isCompleted) {
      await _notificationService.scheduleTaskReminder(task);
    }
    // Stream will update the UI
  }

  Future<void> deleteTask(Task task) async {
    // Cancel notification before deleting
    await _notificationService.cancelTaskReminder(task);
    await _hiveService.deleteTask(task);
    // Stream will update the UI
  }

  Future<void> toggleTaskCompletion(Task task) async {
    task.isCompleted = !task.isCompleted;
    await _hiveService.saveTask(task);
    
    // Cancel notification when task is completed
    if (task.isCompleted) {
      await _notificationService.cancelTaskReminder(task);
    } else if (task.hasReminder) {
      // Reschedule if uncompleted and has reminder
      await _notificationService.scheduleTaskReminder(task);
    }
    
    if (task.isCompleted && task.isCyclic && task.cycleInterval != null) {
      _createNextCycleTask(task);
    }
  }

  Future<void> _createNextCycleTask(Task completedTask) async {
    if (!completedTask.isCyclic) return;
    
    final nextDate = completedTask.getNextOccurrence(completedTask.scheduledDate.add(const Duration(seconds: 1)));
    if (nextDate == null) return;
    
    final newTask = Task()
      ..title = completedTask.title
      ..description = completedTask.description
      ..categoryId = completedTask.categoryId
      ..scheduledDate = nextDate
      ..recurrenceType = completedTask.recurrenceType
      ..interval = completedTask.interval
      ..autoReschedule = completedTask.autoReschedule
      ..hasReminder = completedTask.hasReminder
      ..reminderTime = completedTask.reminderTime
      ..weekdays = List.from(completedTask.weekdays)
      ..useDayOfMonth = completedTask.useDayOfMonth
      ..dayOfMonth = completedTask.dayOfMonth
      ..weekOfMonth = completedTask.weekOfMonth
      ..endDate = completedTask.endDate
      ..maxOccurrences = completedTask.maxOccurrences;
      
    await _hiveService.saveTask(newTask);
    
    // Schedule notification for the new task if needed
    if (newTask.hasReminder) {
      await _notificationService.scheduleTaskReminder(newTask);
    }
  }

  Future<List<Task>> getTasksForDate(DateTime date) async {
    final tasks = _hiveService.getAllTasks();
    return tasks.where((task) => task.occursOnDate(date)).toList();
  }

  Future<void> testNotification() async {
    await _notificationService.showImmediateNotification(
      title: 'Test Notification',
      body: 'This is a test notification to verify the system works.',
    );
  }

  Future<void> checkAndRescheduleOverdue() async {
    final tasks = _hiveService.getAllTasks();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (var task in tasks) {
      if (task.isCompleted || !task.autoReschedule) continue;
      
      if (task.isCyclic) {
        // For recurring tasks, find the next occurrence
        final nextOccurrence = task.getNextOccurrence(today.subtract(const Duration(days: 1)));
        if (nextOccurrence != null && 
            (task.scheduledDate.isBefore(today) || 
             nextOccurrence.isAfter(task.scheduledDate))) {
          task.scheduledDate = nextOccurrence;
          await _hiveService.saveTask(task);
        }
      } else if (task.scheduledDate.isBefore(today)) {
        // For one-time tasks, reschedule to today
        task.scheduledDate = today;
        await _hiveService.saveTask(task);
      }
    }
  }
}

final taskNotifierProvider = StateNotifierProvider<TaskNotifier, AsyncValue<List<Task>>>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return TaskNotifier(hiveService);
});
