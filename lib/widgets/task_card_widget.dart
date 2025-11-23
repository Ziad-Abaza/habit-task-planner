import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../screens/add_task_screen.dart';

class TaskCardWidget extends ConsumerStatefulWidget {
  final Task task;
  final VoidCallback? onDelete;

  const TaskCardWidget({
    super.key,
    required this.task,
    this.onDelete,
  });

  @override
  ConsumerState<TaskCardWidget> createState() => _TaskCardWidgetState();
}

class _TaskCardWidgetState extends ConsumerState<TaskCardWidget> {
  bool _isPressed = false;

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${widget.task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.priorityHigh,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Color _getTaskStatusColor() {
    if (widget.task.isCompleted) {
      return AppColors.statusCompleted;
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(
      widget.task.scheduledDate.year,
      widget.task.scheduledDate.month,
      widget.task.scheduledDate.day,
    );
    
    if (taskDate.isBefore(today)) {
      return AppColors.statusOverdue;
    } else if (taskDate.isAtSameMomentAs(today)) {
      return AppColors.statusToday;
    } else {
      return AppColors.statusUpcoming;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppColors.getCategoryColor(widget.task.categoryId);
    final statusColor = _getTaskStatusColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey(widget.task.key),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _confirmDelete(context),
      onDismissed: (direction) {
        ref.read(taskNotifierProvider.notifier).deleteTask(widget.task);
        widget.onDelete?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.task.title} deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppColors.priorityHigh,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 32),
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTaskScreen(taskToEdit: widget.task),
            ),
          );
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: AppTheme.durationFast,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                width: 1,
              ),
              boxShadow: AppTheme.softShadow(),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              child: Row(
                children: [
                  // Category Color Indicator
                  Container(
                    width: 4,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          categoryColor,
                          categoryColor.withOpacity(0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Main Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      child: Row(
                        children: [
                          // Checkbox
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.task.isCompleted
                                    ? AppColors.statusCompleted
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                              color: widget.task.isCompleted
                                  ? AppColors.statusCompleted
                                  : Colors.transparent,
                            ),
                            child: InkWell(
                              onTap: () {
                                ref.read(taskNotifierProvider.notifier)
                                    .toggleTaskCompletion(widget.task);
                              },
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: widget.task.isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        size: 20,
                                        color: Colors.white,
                                      )
                                    : const SizedBox(width: 20, height: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          // Task Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.task.title,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          decoration: widget.task.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: widget.task.isCompleted
                                              ? Colors.grey
                                              : null,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.task.description != null &&
                                    widget.task.description!.isNotEmpty) ...[
                                  const SizedBox(height: AppTheme.spacingXS),
                                  Text(
                                    widget.task.description!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: AppTheme.spacingS),
                                Row(
                                  children: [
                                    // Category Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingS,
                                        vertical: AppTheme.spacingXS,
                                      ),
                                      decoration: BoxDecoration(
                                        color: categoryColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            AppColors.getCategoryIcon(widget.task.categoryId),
                                            size: 14,
                                            color: categoryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            AppColors.getCategoryName(widget.task.categoryId),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: categoryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spacingS),
                                    // Cyclic Indicator
                                    if (widget.task.isCyclic)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacingS,
                                          vertical: AppTheme.spacingXS,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryPurple.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.loop_rounded,
                                              size: 14,
                                              color: AppColors.primaryPurple,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Every ${widget.task.cycleInterval ?? 1}d',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.primaryPurple,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    // Reminder Indicator
                                    if (widget.task.hasReminder && !widget.task.isCompleted)
                                      Container(
                                        margin: const EdgeInsets.only(left: AppTheme.spacingS),
                                        padding: const EdgeInsets.all(AppTheme.spacingXS),
                                        decoration: BoxDecoration(
                                          color: AppColors.statusToday.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                        ),
                                        child: Icon(
                                          Icons.notifications_active_rounded,
                                          size: 14,
                                          color: AppColors.statusToday,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Status Indicator
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }
}
