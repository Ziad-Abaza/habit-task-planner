import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../services/hive_service.dart';

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

  TaskNotifier(this._hiveService) : super(const AsyncValue.loading()) {
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => _hiveService.getAllTasks());
  }

  Future<void> addTask(Task task) async {
    await _hiveService.saveTask(task);
    // Stream will update the UI
  }

  Future<void> updateTask(Task task) async {
    await _hiveService.saveTask(task);
    // Stream will update the UI
  }

  Future<void> deleteTask(Task task) async {
    await _hiveService.deleteTask(task);
    // Stream will update the UI
  }

  Future<void> toggleTaskCompletion(Task task) async {
    task.isCompleted = !task.isCompleted;
    await _hiveService.saveTask(task);
    
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
