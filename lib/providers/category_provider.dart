import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../services/hive_service.dart';
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

  // Delete category
  Future<void> deleteCategory(Category category) async {
    if (!category.isDefault) {
      await category.delete();
      _loadCategories();
    }
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

  // Initialize default categories if none exist
  Future<void> initializeDefaultCategories() async {
    if (categoryBox.isEmpty) {
      final defaultCategories = Category.getDefaultCategories();
      for (var category in defaultCategories) {
        await categoryBox.add(category);
      }
      _loadCategories();
    }
  }

  // Get category by index (for backward compatibility with categoryId)
  Category? getCategoryByIndex(int index) {
    if (index >= 0 && index < state.length) {
      return state[index];
    }
    return null;
  }
}

// Category Provider
final categoryNotifierProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  final categoryBox = Hive.box<Category>('categories');
  final notifier = CategoryNotifier(categoryBox);
  
  // Initialize default categories on first run
  notifier.initializeDefaultCategories();
  
  return notifier;
});

// Stream provider for categories
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final categoryBox = Hive.box<Category>('categories');
  
  return Stream.periodic(const Duration(milliseconds: 100), (_) {
    final categories = categoryBox.values.toList();
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return categories;
  }).distinct();
});
