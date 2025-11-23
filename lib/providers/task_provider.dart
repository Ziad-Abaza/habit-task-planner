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
    await _hiveService.saveTask(task);
    // Schedule notification if reminder is set
    if (task.hasReminder) {
      await _notificationService.scheduleTaskReminder(task);
    }
    // Stream will update the UI
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
    final nextDate = completedTask.scheduledDate.add(Duration(days: completedTask.cycleInterval!));
    final newTask = Task()
      ..title = completedTask.title
      ..description = completedTask.description
      ..categoryId = completedTask.categoryId
      ..scheduledDate = nextDate
      ..isCyclic = true
      ..cycleInterval = completedTask.cycleInterval
      ..autoReschedule = completedTask.autoReschedule;
      
    await _hiveService.saveTask(newTask);
  }

  Future<void> checkAndRescheduleOverdue() async {
    final tasks = _hiveService.getAllTasks();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (var task in tasks) {
      if (!task.isCompleted && task.autoReschedule && task.scheduledDate.isBefore(today)) {
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
