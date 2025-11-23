import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../providers/category_provider.dart';

class CategoryChip extends ConsumerWidget {
  final int categoryId;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showIcon;

  const CategoryChip({
    super.key,
    required this.categoryId,
    required this.isSelected,
    required this.onTap,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Handle "All" category
    if (categoryId == -1) {
      return _buildChip(
        context,
        'All',
        AppColors.primaryPurple,
        Icons.grid_view_rounded,
      );
    }

    // Get category from provider
    final categories = ref.watch(categoryNotifierProvider);
    
    if (categoryId >= 0 && categoryId < categories.length) {
      final category = categories[categoryId];
      return _buildChip(
        context,
        category.name,
        category.color,
        category.icon,
      );
    }

    // Fallback to default colors if category not found
    return _buildChip(
      context,
      AppColors.getCategoryName(categoryId),
      AppColors.getCategoryColor(categoryId),
      AppColors.getCategoryIcon(categoryId),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String name,
    Color color,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: AppTheme.spacingXS),
            ],
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
