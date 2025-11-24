import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/task_card_widget.dart';
import '../widgets/category_chip.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/app_drawer.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import 'add_task_screen.dart';
import 'calendar_screen.dart';
import 'stats_screen.dart';
import 'category_manager_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _selectedCategoryId;
  bool _isSelectionMode = false;
  final Set<String> _selectedTaskIds = {};

  @override
  void initState() {
    super.initState();
    // Check for auto-reschedule on startup
    Future.microtask(() => ref.read(taskNotifierProvider.notifier).checkAndRescheduleOverdue());
  }

  Future<void> _refreshTasks() async {
    await ref.read(taskNotifierProvider.notifier).checkAndRescheduleOverdue();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedTaskIds.clear();
    });
  }

  void _toggleTaskSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  Future<void> _deleteSelectedTasks() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tasks'),
        content: Text('Delete ${_selectedTaskIds.length} selected tasks?'),
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

    if (shouldDelete == true) {
      final notifier = ref.read(taskNotifierProvider.notifier);
      final tasks = ref.read(tasksStreamProvider).value ?? [];
      
      for (final taskId in _selectedTaskIds) {
        final task = tasks.firstWhere((t) => t.key.toString() == taskId, orElse: () => tasks.first);
        if (task.key.toString() == taskId) {
          await notifier.deleteTask(task);
        }
      }
      _toggleSelectionMode();
    }
  }

  Future<void> _completeSelectedTasks() async {
    final notifier = ref.read(taskNotifierProvider.notifier);
    final tasks = ref.read(tasksStreamProvider).value ?? [];
    
    for (final taskId in _selectedTaskIds) {
      final task = tasks.firstWhere((t) => t.key.toString() == taskId, orElse: () => tasks.first);
      if (task.key.toString() == taskId && !task.isCompleted) {
        await notifier.toggleTaskCompletion(task);
      }
    }
    _toggleSelectionMode();
  }

  Future<void> _shareSelectedTasks() async {
    final tasks = ref.read(tasksStreamProvider).value ?? [];
    final selectedTasks = tasks.where((t) => _selectedTaskIds.contains(t.key.toString())).toList();
    
    if (selectedTasks.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('📋 *My Tasks*');
    buffer.writeln('----------------------------------------');
    
    for (final task in selectedTasks) {
      final status = task.isCompleted ? "✅ Done" : "⭕ Pending";
      final date = DateFormat('MMM d, y').format(task.scheduledDate);
      final category = AppColors.getCategoryName(task.categoryId);
      
      buffer.writeln('$status: *${task.title}*');
      buffer.writeln('   📅 Due: $date');
      buffer.writeln('   🏷️ Category: $category');
      
      if (task.description != null && task.description!.isNotEmpty) {
        buffer.writeln('   📝 Note: ${task.description}');
      }
      
      if (task.isCyclic) {
        buffer.writeln('   🔄 Repeat: ${task.getRecurrenceDescription()}');
      }
      
      buffer.writeln('----------------------------------------');
    }

    await Share.share(buffer.toString());
    _toggleSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateStr = DateFormat('EEEE, d MMMM').format(now);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshTasks,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // App Bar with Greeting or Selection Mode
              SliverAppBar(
                expandedHeight: 100,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primaryPurple,
                leading: _isSelectionMode
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: _toggleSelectionMode,
                      )
                    : null,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    return FlexibleSpaceBar(
                      centerTitle: _isSelectionMode,
                      title: _isSelectionMode
                          ? Text(
                              '${_selectedTaskIds.length} Selected',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            )
                          : null,
                      collapseMode: CollapseMode.pin,
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(AppTheme.radiusXL),
                            bottomRight: Radius.circular(AppTheme.radiusXL),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: _isSelectionMode
                              ? const SizedBox() // Empty background for selection mode
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildAppBar(),
                                    const SizedBox(height: AppTheme.spacingS),
                                    _buildDateHeader(dateStr),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Category Filter Section
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingL,
                        vertical: AppTheme.spacingS,
                      ),
                      child: Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                      ),
                    ),
                    Container(
                      height: 50,
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final categories = ref.watch(categoryNotifierProvider);
                          
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                            itemCount: categories.length + 1, // +1 for 'All' category
                            itemBuilder: (context, index) {
                              // First item is 'All' category
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                                  child: CategoryChip(
                                    categoryId: -1,
                                    isSelected: _selectedCategoryId == null,
                                    onTap: () => setState(() => _selectedCategoryId = null),
                                    showIcon: true,
                                    icon: Icons.grid_view_rounded,
                                  ),
                                );
                              }
                              
                              // Other categories
                              final categoryIndex = index - 1;
                              if (categoryIndex < categories.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                                  child: CategoryChip(
                                    categoryId: categoryIndex,
                                    isSelected: _selectedCategoryId == categoryIndex,
                                    onTap: () => setState(() => _selectedCategoryId = categoryIndex),
                                  ),
                                );
                              }
                              
                              // Add category button
                              return Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: _AddCategoryButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CategoryManagerScreen(),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Tasks List
              tasksAsync.when(
                data: (tasks) {
                  var todaysTasks = tasks.where((t) {
                    final tDate = DateTime(t.scheduledDate.year, t.scheduledDate.month, t.scheduledDate.day);
                    return tDate.isAtSameMomentAs(today);
                  }).toList();

                  // Apply category filter
                  if (_selectedCategoryId != null) {
                    todaysTasks = todaysTasks.where((t) => t.categoryId == _selectedCategoryId).toList();
                  }

                  if (todaysTasks.isEmpty) {
                    return SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.task_alt_rounded,
                        title: _selectedCategoryId == null
                            ? 'No tasks for today!'
                            : 'No ${AppColors.getCategoryName(_selectedCategoryId!).toLowerCase()} tasks',
                        subtitle: 'Create a new task to get started',
                        actionLabel: 'Add Task',
                        onActionPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
                          );
                        },
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: TaskCardWidget(
                                  task: todaysTasks[index],
                                  isSelectionMode: _isSelectionMode,
                                  isSelected: _selectedTaskIds.contains(todaysTasks[index].key.toString()),
                                  onLongPress: () {
                                    if (!_isSelectionMode) {
                                      _toggleSelectionMode();
                                      _toggleTaskSelection(todaysTasks[index].key.toString());
                                    }
                                  },
                                  onSelectionTap: () => _toggleTaskSelection(todaysTasks[index].key.toString()),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: todaysTasks.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: AppTheme.spacingM),
                        Text('Error: $err'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isSelectionMode
          ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBulkActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        color: AppColors.priorityHigh,
                        onTap: _selectedTaskIds.isEmpty ? null : _deleteSelectedTasks,
                      ),
                      _buildBulkActionButton(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Complete',
                        color: AppColors.statusCompleted,
                        onTap: _selectedTaskIds.isEmpty ? null : _completeSelectedTasks,
                      ),
                      _buildBulkActionButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        color: AppColors.primaryPurple,
                        onTap: _selectedTaskIds.isEmpty ? null : _shareSelectedTasks,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTaskScreen()),
                );
              },
              label: const Text('New Task'),
              icon: const Icon(Icons.add_rounded),
            ),
    );
  }

  Widget _buildBulkActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingS,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEnabled ? color : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? color : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CalendarScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          onPressed: () async {
            print('Test Notification button pressed');
            try {
              await ref.read(taskNotifierProvider.notifier).testNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Test notification sent')),
              );
            } catch (e) {
              print('Error sending test notification: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StatsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateHeader(String dateStr) {
    return Text(
      dateStr,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
    );
  }
}

class _AddCategoryButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddCategoryButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Add',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
