import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../providers/category_provider.dart';

class CategoryChip extends ConsumerStatefulWidget {
  final int categoryId;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showIcon;
  final IconData? icon;

  const CategoryChip({
    super.key,
    required this.categoryId,
    required this.isSelected,
    required this.onTap,
    this.showIcon = true,
    this.icon,
  });

  @override
  ConsumerState<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends ConsumerState<CategoryChip> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Handle "All" category
    if (widget.categoryId == -1) {
      return _buildChip(
        context,
        'All',
        AppColors.primaryPurple,
        widget.icon ?? Icons.grid_view_rounded,
      );
    }

    // Get category from provider
    final categories = ref.watch(categoryNotifierProvider);
    
    if (widget.categoryId >= 0 && widget.categoryId < categories.length) {
      final category = categories[widget.categoryId];
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
      AppColors.getCategoryName(widget.categoryId),
      AppColors.getCategoryColor(widget.categoryId),
      AppColors.getCategoryIcon(widget.categoryId),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String name,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Calculate text color based on background brightness
    final textColor = widget.isSelected 
        ? Colors.white 
        : color.computeLuminance() > 0.5 
            ? Colors.black87 
            : color;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isSelected 
                    ? color 
                    : color.withOpacity(isDarkMode ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected 
                      ? color 
                      : color.withOpacity(0.4),
                  width: 1.2,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(20),
                  splashColor: color.withOpacity(0.2),
                  highlightColor: color.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.showIcon) ...[
                          Icon(
                            icon,
                            size: 18,
                            color: widget.isSelected ? Colors.white : color,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            fontWeight: widget.isSelected 
                                ? FontWeight.w600 
                                : FontWeight.w500,
                            fontSize: 13.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
