import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/category.dart';

class HiveService {
  static const String taskBoxName = 'tasks_v2';
  static const String categoryBoxName = 'categories_v2';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(CategoryAdapter());
    await Hive.openBox<Task>(taskBoxName);
    await Hive.openBox<Category>(categoryBoxName);
  }

  Box<Task> get _taskBox => Hive.box<Task>(taskBoxName);
  Box<Category> get _categoryBox => Hive.box<Category>(categoryBoxName);

  Future<void> saveTask(Task task) async {
    if (task.isInBox) {
      await task.save();
    } else {
      await _taskBox.add(task);
    }
  }

  Future<void> saveCategory(Category category) async {
    if (category.isInBox) {
      await category.save();
    } else {
      await _categoryBox.add(category);
    }
  }

  List<Task> getAllTasks() {
    return _taskBox.values.toList();
  }

  List<Category> getAllCategories() {
    return _categoryBox.values.toList();
  }
  
  Stream<List<Task>> listenToTasks() async* {
    // Yield initial value
    yield _taskBox.values.toList();
    // Yield on changes
    yield* _taskBox.watch().map((event) => _taskBox.values.toList());
  }

  Future<void> deleteTask(Task task) async {
    await task.delete();
  }
  
  Future<void> cleanDb() async {
    await _taskBox.clear();
    await _categoryBox.clear();
  }
}
