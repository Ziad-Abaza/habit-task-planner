import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_colors.dart';

class CategoryManagerScreen extends ConsumerStatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  ConsumerState<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> {
  void _showAddCategoryDialog({Category? categoryToEdit}) {
    final isEditing = categoryToEdit != null;
    final nameController = TextEditingController(text: categoryToEdit?.name ?? '');
    Color selectedColor = categoryToEdit?.color ?? AppColors.primaryPurple;
    IconData selectedIcon = categoryToEdit?.icon ?? Icons.category_rounded;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          title: Text(isEditing ? 'Edit Category' : 'New Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Input
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    prefixIcon: const Icon(Icons.label_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Color Picker
                Text(
                  'Color',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Wrap(
                  spacing: AppTheme.spacingS,
                  runSpacing: AppTheme.spacingS,
                  children: [
                    AppColors.primaryPurple,
                    AppColors.categoryWork,
                    AppColors.categoryPersonal,
                    AppColors.categoryHealth,
                    AppColors.categoryFinance,
                    AppColors.categorySocial,
                    AppColors.categoryLearning,
                    AppColors.categoryHobbies,
                    const Color(0xFFE91E63), // Pink
                    const Color(0xFF9C27B0), // Purple
                    const Color(0xFF3F51B5), // Indigo
                    const Color(0xFF2196F3), // Blue
                    const Color(0xFF00BCD4), // Cyan
                    const Color(0xFF009688), // Teal
                    const Color(0xFF4CAF50), // Green
                    const Color(0xFFFF5722), // Deep Orange
                  ].map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Icon Picker
                Text(
                  'Icon',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Wrap(
                  spacing: AppTheme.spacingS,
                  runSpacing: AppTheme.spacingS,
                  children: [
                    Icons.work_rounded,
                    Icons.person_rounded,
                    Icons.favorite_rounded,
                    Icons.account_balance_wallet_rounded,
                    Icons.people_rounded,
                    Icons.school_rounded,
                    Icons.palette_rounded,
                    Icons.category_rounded,
                    Icons.shopping_cart_rounded,
                    Icons.home_rounded,
                    Icons.fitness_center_rounded,
                    Icons.restaurant_rounded,
                    Icons.local_cafe_rounded,
                    Icons.flight_rounded,
                    Icons.music_note_rounded,
                    Icons.sports_esports_rounded,
                    Icons.pets_rounded,
                    Icons.directions_car_rounded,
                    Icons.book_rounded,
                    Icons.computer_rounded,
                  ].map((icon) {
                    final isSelected = selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? selectedColor : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          border: Border.all(
                            color: isSelected ? selectedColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a category name')),
                  );
                  return;
                }

                if (isEditing) {
                  categoryToEdit.name = nameController.text.trim();
                  categoryToEdit.color = selectedColor;
                  categoryToEdit.icon = selectedIcon;
                  ref.read(categoryNotifierProvider.notifier).updateCategory(categoryToEdit);
                } else {
                  final categories = ref.read(categoryNotifierProvider);
                  final newCategory = Category.create(
                    name: nameController.text.trim(),
                    color: selectedColor,
                    icon: selectedIcon,
                    sortOrder: categories.length,
                    isDefault: false,
                  );
                  ref.read(categoryNotifierProvider.notifier).addCategory(newCategory);
                }

                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: selectedColor),
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.priorityHigh),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Try to delete the category
      final errorMessage = await ref.read(categoryNotifierProvider.notifier).deleteCategory(category);
      
      // Dismiss loading indicator
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      // Show error message if any
      if (errorMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.priorityHigh,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
        );
      }
    } catch (e) {
      // Dismiss loading indicator
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete category. Please try again.'),
            backgroundColor: AppColors.priorityHigh,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'No categories yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              itemCount: categories.length,
              onReorder: (oldIndex, newIndex) {
                ref.read(categoryNotifierProvider.notifier).reorderCategories(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final category = categories[index];
                return AnimationConfiguration.staggeredList(
                  key: ValueKey(category.key),
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                          ),
                          boxShadow: AppTheme.softShadow(),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingS,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: category.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                            child: Icon(
                              category.icon,
                              color: category.color,
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: category.isDefault
                              ? const Text('Default category')
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded),
                                onPressed: () => _showAddCategoryDialog(categoryToEdit: category),
                              ),
                              if (!category.isDefault)
                                IconButton(
                                  icon: Icon(Icons.delete_rounded, color: AppColors.priorityHigh),
                                  onPressed: () => _deleteCategory(category),
                                ),
                              const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Category'),
      ),
    );
  }
}
