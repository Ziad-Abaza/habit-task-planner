import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/task_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../widgets/stats_card.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics & Insights'),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          // Calculate stats
          final totalTasks = tasks.length;
          final completedTasks = tasks.where((t) => t.isCompleted).length;
          final cyclicTasks = tasks.where((t) => t.isCyclic).length;
          
          final todaysTasks = tasks.where((t) {
            final tDate = DateTime(t.scheduledDate.year, t.scheduledDate.month, t.scheduledDate.day);
            return tDate.isAtSameMomentAs(today);
          }).toList();
          
          final completedToday = todaysTasks.where((t) => t.isCompleted).length;
          final totalToday = todaysTasks.length;
          
          // Category distribution
          final categoryCount = <int, int>{};
          for (var task in tasks) {
            categoryCount[task.categoryId] = (categoryCount[task.categoryId] ?? 0) + 1;
          }
          
          // Weekly completion
          final weeklyData = <int, int>{};
          for (int i = 6; i >= 0; i--) {
            final day = today.subtract(Duration(days: i));
            final dayTasks = tasks.where((t) {
              final tDate = DateTime(t.scheduledDate.year, t.scheduledDate.month, t.scheduledDate.day);
              return tDate.isAtSameMomentAs(day);
            });
            weeklyData[6 - i] = dayTasks.where((t) => t.isCompleted).length;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Stats
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Total Tasks',
                        value: '$totalTasks',
                        icon: Icons.task_alt_rounded,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: StatsCard(
                        title: 'Completed',
                        value: '$completedTasks',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.statusCompleted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Today',
                        value: '$completedToday/$totalToday',
                        icon: Icons.today_rounded,
                        color: AppColors.statusToday,
                        subtitle: totalToday > 0 
                            ? '${(completedToday / totalToday * 100).toInt()}% complete'
                            : 'No tasks',
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: StatsCard(
                        title: 'Cyclic',
                        value: '$cyclicTasks',
                        icon: Icons.loop_rounded,
                        color: AppColors.categoryLearning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXL),
                
                // Weekly Completion Chart
                Text(
                  'Weekly Completion',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (weeklyData.values.isEmpty ? 5 : weeklyData.values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (value.toInt() >= 0 && value.toInt() < days.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    days[value.toInt()],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: weeklyData.entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              gradient: AppColors.primaryGradient,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                
                // Category Distribution
                if (categoryCount.isNotEmpty) ...[
                  Text(
                    'Category Distribution',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: categoryCount.entries.map((entry) {
                          final color = AppColors.getCategoryColor(entry.key);
                          final percentage = (entry.value / totalTasks * 100).toInt();
                          return PieChartSectionData(
                            color: color,
                            value: entry.value.toDouble(),
                            title: '$percentage%',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  // Legend
                  Wrap(
                    spacing: AppTheme.spacingM,
                    runSpacing: AppTheme.spacingS,
                    children: categoryCount.entries.map((entry) {
                      final color = AppColors.getCategoryColor(entry.key);
                      final name = AppColors.getCategoryName(entry.key);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$name (${entry.value})',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
