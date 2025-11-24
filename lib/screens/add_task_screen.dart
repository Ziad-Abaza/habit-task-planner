import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  final Task? taskToEdit;

  const AddTaskScreen({super.key, this.taskToEdit});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  late DateTime _selectedDate;
  late RecurrenceType _recurrenceType;
  late int _interval;
  late bool _autoReschedule;
  late int _selectedCategoryId;
  late bool _hasReminder;
  late TimeOfDay _reminderTime;
  late List<int> _selectedWeekdays;
  late bool _useDayOfMonth;
  late int _dayOfMonth;
  late int _weekOfMonth;
  late DateTime? _endDate;
  late int _maxOccurrences;
  bool _isCyclic = false;

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildRecurrenceSettings() {
    return DropdownButtonFormField<RecurrenceType>(
      initialValue: _recurrenceType,
      decoration: InputDecoration(
        labelText: 'Repeat',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: RecurrenceType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(
            type.toString().split('.').last,
            style: const TextStyle(fontSize: 16),
          ),
        );
      }).toList(),
      onChanged: (RecurrenceType? newValue) {
        if (newValue != null) {
          setState(() {
            _recurrenceType = newValue;
          });
        }
      },
    );
  }

  Widget _buildAutoReschedule() {
    return SwitchListTile(
      title: const Text('Auto-reschedule'),
      subtitle: const Text('Automatically reschedule if not completed on time'),
      value: _autoReschedule,
      onChanged: (value) {
        setState(() {
          _autoReschedule = value;
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize with existing task data or defaults
    if (widget.taskToEdit != null) {
      final task = widget.taskToEdit!;
      _titleController.text = task.title;
      _descController.text = task.description ?? '';
      _selectedDate = task.scheduledDate;
      _recurrenceType = task.recurrenceType;
      _interval = task.interval;
      _autoReschedule = task.autoReschedule;
      _selectedCategoryId = task.categoryId;
      _hasReminder = task.hasReminder;
      _isCyclic = task.recurrenceType != RecurrenceType.none;
      _selectedWeekdays = List.from(task.weekdays);
      _useDayOfMonth = task.useDayOfMonth;
      _dayOfMonth = task.dayOfMonth;
      _weekOfMonth = task.weekOfMonth;
      _endDate = task.endDate;
      _maxOccurrences = task.maxOccurrences;
      
      if (task.reminderTime != null) {
        final time = task.reminderTime!;
        _reminderTime = TimeOfDay(hour: time.hour, minute: time.minute);
      } else {
        _reminderTime = const TimeOfDay(hour: 9, minute: 0);
      }
    } else {
      _selectedDate = DateTime.now();
      _recurrenceType = RecurrenceType.none;
      _interval = 1;
      _autoReschedule = false;
      _selectedCategoryId = 0;
      _hasReminder = false;
      _reminderTime = const TimeOfDay(hour: 9, minute: 0);
      _selectedWeekdays = [];
      _useDayOfMonth = true;
      _isCyclic = false;
      _dayOfMonth = _selectedDate.day;
      _weekOfMonth = ((_selectedDate.day - 1) ~/ 7) + 1;
      _endDate = null;
      _maxOccurrences = 0;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryPurple,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryPurple,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      if (widget.taskToEdit != null) {
        // Update existing task
        final task = widget.taskToEdit!;
        task.title = _titleController.text;
        task.description = _descController.text.isEmpty ? null : _descController.text;
        task.categoryId = _selectedCategoryId;
        task.scheduledDate = _selectedDate;
        task.recurrenceType = _recurrenceType;
        task.interval = _interval;
        task.autoReschedule = _autoReschedule;
        task.hasReminder = _hasReminder;
        task.weekdays = _selectedWeekdays;
        task.useDayOfMonth = _useDayOfMonth;
        task.dayOfMonth = _dayOfMonth;
        task.weekOfMonth = _weekOfMonth;
        task.endDate = _endDate;
        task.maxOccurrences = _maxOccurrences;
        
        if (_hasReminder) {
          task.reminderTime = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _reminderTime.hour,
            _reminderTime.minute,
          );
        } else {
          task.reminderTime = null;
        }

        ref.read(taskNotifierProvider.notifier).updateTask(widget.taskToEdit!);
      } else {
        // Create new task
        final newTask = Task()
          ..title = _titleController.text
          ..description = _descController.text.isEmpty ? null : _descController.text
          ..categoryId = _selectedCategoryId
          ..scheduledDate = _selectedDate
          ..recurrenceType = _recurrenceType
          ..interval = _interval
          ..autoReschedule = _autoReschedule
          ..hasReminder = _hasReminder
          ..reminderTime = _hasReminder
              ? DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _reminderTime.hour,
                  _reminderTime.minute,
                )
              : null
          ..weekdays = _selectedWeekdays
          ..useDayOfMonth = _useDayOfMonth
          ..dayOfMonth = _dayOfMonth
          ..weekOfMonth = _weekOfMonth
          ..endDate = _endDate
          ..maxOccurrences = _maxOccurrences;

        ref.read(taskNotifierProvider.notifier).addTask(newTask);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppColors.getCategoryColor(_selectedCategoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit != null ? 'Edit Task' : 'New Task'),
        actions: [
          if (widget.taskToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete_rounded),
              color: AppColors.priorityHigh,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    ),
                    title: const Text('Delete Task'),
                    content: const Text('Are you sure you want to delete this task?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          ref.read(taskNotifierProvider.notifier).deleteTask(widget.taskToEdit!);
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.priorityHigh,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'What do you need to do?',
                  prefixIcon: const Icon(Icons.title_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Description
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add more details...',
                  prefixIcon: const Icon(Icons.description_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Category Selection
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Consumer(
                builder: (context, ref, child) {
                  final categories = ref.watch(categoryNotifierProvider);
                  
                  return Wrap(
                    spacing: AppTheme.spacingS,
                    runSpacing: AppTheme.spacingS,
                    children: categories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      final isSelected = _selectedCategoryId == index;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategoryId = index),
                        child: AnimatedContainer(
                          duration: AppTheme.durationFast,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingS,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? category.color : category.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(
                              color: isSelected ? category.color : category.color.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category.icon,
                                size: 20,
                                color: isSelected ? Colors.white : category.color,
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              Text(
                                category.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : category.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Date Selection
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                child: ListTile(
                  leading: Icon(Icons.calendar_today_rounded, color: categoryColor),
                  title: const Text('Scheduled Date'),
                  subtitle: Text(DateFormat('EEEE, MMMM d, y').format(_selectedDate)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => _selectDate(context),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Cyclic Task Settings
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(Icons.loop_rounded, color: categoryColor),
                      title: const Text('Cyclic Task'),
                      subtitle: const Text('Repeats automatically after completion'),
                      value: _isCyclic,
                      activeThumbColor: categoryColor,
                      onChanged: (val) {
                        setState(() {
                          _isCyclic = val;
                        });
                      },
                    ),
                    if (_isCyclic) ...[
                      const Divider(height: 1),
                      _buildSectionTitle('Recurrence'),
                      _buildRecurrenceSettings(),
                      if (_recurrenceType != RecurrenceType.none) ...[
                        const SizedBox(height: 8),
                        _buildAutoReschedule(),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Reminder Settings
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(Icons.notifications_rounded, color: categoryColor),
                      title: const Text('Set Reminder'),
                      subtitle: const Text('Get notified about this task'),
                      value: _hasReminder,
                      activeThumbColor: categoryColor,
                      onChanged: (val) {
                        setState(() {
                          _hasReminder = val;
                        });
                      },
                    ),
                    if (_hasReminder) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const SizedBox(width: 56),
                        title: const Text('Reminder Time'),
                        subtitle: Text(_reminderTime.format(context)),
                        trailing: const Icon(Icons.access_time_rounded, size: 20),
                        onTap: () => _selectTime(context),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _saveTask,
                  style: FilledButton.styleFrom(
                    backgroundColor: categoryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    widget.taskToEdit != null ? 'Update Task' : 'Create Task',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
