import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/task.dart';
import 'task_provider.dart';

// Category Notifier
class CategoryNotifier extends StateNotifier<List<Category>> {
  final Box<Category> categoryBox;

  CategoryNotifier(this.categoryBox) : super([]) {
    _loadCategories();
  }

  void _loadCategories() {
    final categories = categoryBox.values.toList();
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    state = categories;
  }

  // Add category
  Future<void> addCategory(Category category) async {
    await categoryBox.add(category);
    _loadCategories();
  }

  // Update category
  Future<void> updateCategory(Category category) async {
    await category.save();
    _loadCategories();
  }

  // Check if category is being used by any tasks
  Future<bool> isCategoryInUse(Category category) async {
    final taskBox = Hive.box<Task>('tasks_v2');
    final tasks = taskBox.values.toList();
    return tasks.any((task) => task.categoryId == category.key);
  }

  // Delete category
  Future<String?> deleteCategory(Category category) async {
    if (category.isDefault) {
      return 'Default categories cannot be deleted';
    }
    
    final inUse = await isCategoryInUse(category);
    if (inUse) {
      return 'This category is being used by one or more tasks. Please reassign or delete those tasks first.';
    }
    
    await category.delete();
    _loadCategories();
    return null; // No error
  }

  // Reorder categories
  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final categories = List<Category>.from(state);
    final item = categories.removeAt(oldIndex);
    categories.insert(newIndex, item);

    // Update sort order
    for (int i = 0; i < categories.length; i++) {
      categories[i].sortOrder = i;
      await categories[i].save();
    }
    _loadCategories();
  }


  // Get category by index (for backward compatibility with categoryId)
  Category? getCategoryByIndex(int index) {
    if (index >= 0 && index < state.length) {
      return state[index];
    }
    return null;
  }

  // Initialize with a single default category if no categories exist
  Future<void> initializeDefaultCategory() async {
    if (categoryBox.isEmpty) {
      final defaultCategory = Category.getDefaultCategory();
      await categoryBox.add(defaultCategory);
      _loadCategories();
    }
  }
}

// Category Provider
final categoryNotifierProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  final categoryBox = Hive.box<Category>('categories_v2');
  final notifier = CategoryNotifier(categoryBox);
  
  // Initialize default category on first run
  notifier.initializeDefaultCategory();
  
  return notifier;
});

// Stream provider for categories
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final categoryBox = Hive.box<Category>('categories_v2');
  
  return Stream.periodic(const Duration(milliseconds: 100), (_) {
    final categories = categoryBox.values.toList();
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return categories;
  }).distinct();
});
