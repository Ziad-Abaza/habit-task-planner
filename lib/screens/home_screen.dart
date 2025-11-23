import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../models/task.dart';
import '../widgets/task_card_widget.dart';
import '../widgets/category_chip.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/stats_card.dart';
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

  @override
  void initState() {
    super.initState();
    // Check for auto-reschedule on startup
    Future.microtask(() => ref.read(taskNotifierProvider.notifier).checkAndRescheduleOverdue());
  }

  Future<void> _refreshTasks() async {
    await ref.read(taskNotifierProvider.notifier).checkAndRescheduleOverdue();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateStr = DateFormat('EEEE, d MMMM').format(now);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshTasks,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Custom App Bar
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppTheme.radiusXL),
                      bottomRight: Radius.circular(AppTheme.radiusXL),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Day',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateStr,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.category_rounded, color: Colors.white),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CategoryManagerScreen()),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.insights_rounded, color: Colors.white),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const StatsScreen()),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        // Quick Stats
                        tasksAsync.when(
                          data: (allTasks) {
                            final todaysTasks = allTasks.where((t) {
                              final tDate = DateTime(t.scheduledDate.year, t.scheduledDate.month, t.scheduledDate.day);
                              return tDate.isAtSameMomentAs(today);
                            }).toList();

                            final completedToday = todaysTasks.where((t) => t.isCompleted).length;
                            final totalToday = todaysTasks.length;
                            final completionRate = totalToday > 0 ? (completedToday / totalToday * 100).toInt() : 0;

                            return Row(
                              children: [
                                Expanded(
                                  child: _QuickStatCard(
                                    icon: Icons.check_circle_rounded,
                                    value: '$completedToday/$totalToday',
                                    label: 'Completed',
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingM),
                                Expanded(
                                  child: _QuickStatCard(
                                    icon: Icons.trending_up_rounded,
                                    value: '$completionRate%',
                                    label: 'Rate',
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Category Filter
              SliverToBoxAdapter(
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.only(top: AppTheme.spacingL),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final categories = ref.watch(categoryNotifierProvider);
                      
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: AppTheme.spacingS),
                            child: CategoryChip(
                              categoryId: -1,
                              isSelected: _selectedCategoryId == null,
                              onTap: () => setState(() => _selectedCategoryId = null),
                              showIcon: false,
                            ),
                          ),
                          ...categories.asMap().entries.map((entry) {
                            final index = entry.key;
                            return Padding(
                              padding: const EdgeInsets.only(right: AppTheme.spacingS),
                              child: CategoryChip(
                                categoryId: index,
                                isSelected: _selectedCategoryId == index,
                                onTap: () => setState(() => _selectedCategoryId = index),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
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
                                child: TaskCardWidget(task: todaysTasks[index]),
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
      floatingActionButton: FloatingActionButton.extended(
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
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _QuickStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: AppTheme.spacingS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
