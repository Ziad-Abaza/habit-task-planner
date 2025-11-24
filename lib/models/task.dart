import 'package:hive/hive.dart';

part 'task.g.dart';

typedef Weekday = int; // 1 (Monday) to 7 (Sunday)

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  weekdays,
  custom
}

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  late String title;

  @HiveField(1)
  String? description;

  @HiveField(2)
  late int categoryId;

  @HiveField(3)
  late DateTime scheduledDate; // Initial scheduled date

  @HiveField(4)
  bool isCompleted = false;

  @HiveField(5)
  bool get isCyclic => recurrenceType != RecurrenceType.none;
  
  // For backward compatibility with old tasks
  @HiveField(6)
  set isCyclic(bool value) {
    if (value && recurrenceType == RecurrenceType.none) {
      recurrenceType = RecurrenceType.weekly;
    } else if (!value) {
      recurrenceType = RecurrenceType.none;
    }
  }
  
  @HiveField(6)
  RecurrenceType recurrenceType = RecurrenceType.none;

  @HiveField(7)
  int interval = 1; // Interval for custom recurrence (e.g., every 2 weeks)
  
  // For backward compatibility with old tasks
  @HiveField(17, defaultValue: null)
  int? get cycleInterval => interval ~/ 7; // Convert weeks to days for backward compatibility
  
  set cycleInterval(int? value) {
    if (value != null) {
      interval = value * 7; // Convert days to weeks
    }
  }

  @HiveField(8, defaultValue: false)
  bool autoReschedule = false;

  @HiveField(9, defaultValue: false)
  bool hasReminder = false;

  @HiveField(10)
  DateTime? reminderTime; // Time for notification

  @HiveField(11)
  int? notificationId; // For canceling notifications

  @HiveField(12, defaultValue: <int>[])
  List<int> get weekdays => _scheduledWeekdays;
  set weekdays(List<int> value) => _scheduledWeekdays = value;
  
  List<int> _scheduledWeekdays = []; // 1=Monday to 7=Sunday
  
  // For monthly/yearly recurrence
  @HiveField(13, defaultValue: false)
  bool useDayOfMonth = true; // If false, use week number and day (e.g., 2nd Monday)
  
  @HiveField(14, defaultValue: 1)
  int dayOfMonth = 1; // Day of month for monthly/yearly recurrence
  
  @HiveField(15, defaultValue: 1)
  int weekOfMonth = 1; // 1-5 for 1st-5th week, or -1 for last
  
  @HiveField(16)
  DateTime? endDate; // Optional end date for recurrence
  
  @HiveField(18, defaultValue: 0)
  int maxOccurrences = 0; // Maximum number of occurrences (0 for unlimited)

  // Returns the next occurrence of this task after the given date
  DateTime? getNextOccurrence(DateTime fromDate) {
    if (!isCyclic) {
      return scheduledDate.isAfter(fromDate) ? scheduledDate : null;
    }
    
    // Check if we've reached the maximum number of occurrences
    if (maxOccurrences > 0) {
      final count = _countOccurrencesUpTo(fromDate);
      if (count >= maxOccurrences) {
        return null;
      }
    }
    
    // Check end date if set
    if (endDate != null && fromDate.isAfter(endDate!)) {
      return null;
    }
    
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return _getNextDailyOccurrence(fromDate);
      case RecurrenceType.weekly:
        return _getNextWeeklyOccurrence(fromDate);
      case RecurrenceType.monthly:
        return _getNextMonthlyOccurrence(fromDate);
      case RecurrenceType.yearly:
        return _getNextYearlyOccurrence(fromDate);
      case RecurrenceType.weekdays:
        return _getNextWeekdayOccurrence(fromDate);
      case RecurrenceType.custom:
        return _getNextCustomOccurrence(fromDate);
      case RecurrenceType.none:
      default:
        return scheduledDate.isAfter(fromDate) ? scheduledDate : null;
    }
  }
  
  DateTime? _getNextDailyOccurrence(DateTime fromDate) {
    if (fromDate.isBefore(scheduledDate)) {
      return scheduledDate;
    }
    
    final daysDifference = fromDate.difference(scheduledDate).inDays;
    final daysToAdd = ((daysDifference / interval).floor() + 1) * interval;
    return scheduledDate.add(Duration(days: daysToAdd));
  }
  
  DateTime? _getNextWeeklyOccurrence(DateTime fromDate) {
    if (fromDate.isBefore(scheduledDate)) {
      return scheduledDate;
    }
    
    if (_scheduledWeekdays.isEmpty) {
      // If no specific weekdays, use the original day of week
      return _getNextDayOfWeekOccurrence(fromDate, scheduledDate.weekday);
    }
    
    // Find next occurrence in the next 8 weeks
    for (int i = 0; i < 8 * 7; i++) {
      final date = fromDate.add(Duration(days: i));
      if (_scheduledWeekdays.contains(date.weekday) && 
          (date.isAfter(scheduledDate) || date.isAtSameMomentAs(scheduledDate))) {
        return date;
      }
    }
    return null;
  }
  
  DateTime? _getNextMonthlyOccurrence(DateTime fromDate) {
    if (fromDate.isBefore(scheduledDate)) {
      return scheduledDate;
    }
    
    if (useDayOfMonth) {
      return _getNextDayOfMonthOccurrence(fromDate, dayOfMonth);
    } else {
      return _getNextWeekdayOfMonthOccurrence(fromDate, weekOfMonth, scheduledDate.weekday);
    }
  }
  
  DateTime? _getNextYearlyOccurrence(DateTime fromDate) {
    if (fromDate.isBefore(scheduledDate)) {
      return scheduledDate;
    }
    
    if (useDayOfMonth) {
      return _getNextYearlyDayOccurrence(fromDate, scheduledDate.month, dayOfMonth);
    } else {
      return _getNextYearlyWeekdayOccurrence(fromDate, scheduledDate.month, weekOfMonth, scheduledDate.weekday);
    }
  }
  
  DateTime? _getNextWeekdayOccurrence(DateTime fromDate) {
    if (fromDate.isBefore(scheduledDate)) {
      return scheduledDate;
    }
    
    // Find next weekday (Mon-Fri)
    var nextDate = fromDate.add(Duration(days: 1));
    while (nextDate.weekday > DateTime.friday || nextDate.weekday < DateTime.monday) {
      nextDate = nextDate.add(Duration(days: 1));
    }
    return nextDate;
  }
  
  DateTime? _getNextCustomOccurrence(DateTime fromDate) {
    // Fallback to legacy behavior for custom intervals
    if (_scheduledWeekdays.isNotEmpty) {
      return _getNextWeeklyOccurrence(fromDate);
    }
    
    // Legacy interval-based scheduling (in weeks)
    if (interval > 0) {
      final daysDifference = fromDate.difference(scheduledDate).inDays;
      final weeksDifference = (daysDifference / (interval * 7)).ceil();
      return scheduledDate.add(Duration(days: weeksDifference * interval * 7));
    }
    
    return null;
  }
  
  DateTime? _getNextDayOfWeekOccurrence(DateTime fromDate, int targetWeekday) {
    var nextDate = fromDate.add(Duration(days: 1));
    while (nextDate.weekday != targetWeekday) {
      nextDate = nextDate.add(Duration(days: 1));
    }
    return nextDate;
  }
  
  DateTime? _getNextDayOfMonthOccurrence(DateTime fromDate, int targetDay) {
    var nextDate = DateTime(fromDate.year, fromDate.month, 1);
    
    // If we're past the target day this month, go to next month
    if (fromDate.day >= targetDay) {
      nextDate = DateTime(fromDate.year, fromDate.month + 1, 1);
    }
    
    // Find the last day of the month
    final lastDay = DateTime(nextDate.year, nextDate.month + 1, 0).day;
    final day = targetDay > lastDay ? lastDay : targetDay;
    
    return DateTime(nextDate.year, nextDate.month, day);
  }
  
  DateTime? _getNextWeekdayOfMonthOccurrence(DateTime fromDate, int weekNumber, int targetWeekday) {
    var nextDate = DateTime(fromDate.year, fromDate.month, 1);
    
    // Find the first occurrence of the target weekday in the month
    while (nextDate.weekday != targetWeekday) {
      nextDate = nextDate.add(Duration(days: 1));
    }
    
    // Add the appropriate number of weeks
    if (weekNumber > 1) {
      nextDate = nextDate.add(Duration(days: (weekNumber - 1) * 7));
    }
    
    // If we're still before the fromDate, go to next month
    if (nextDate.isBefore(fromDate)) {
      return _getNextWeekdayOfMonthOccurrence(
        DateTime(fromDate.year, fromDate.month + 1, 1),
        weekNumber,
        targetWeekday
      );
    }
    
    return nextDate;
  }
  
  DateTime? _getNextYearlyDayOccurrence(DateTime fromDate, int month, int day) {
    var nextDate = DateTime(fromDate.year, month, 1);
    
    // If we're past the month or in the same month but past the day, go to next year
    if (fromDate.month > month || (fromDate.month == month && fromDate.day >= day)) {
      nextDate = DateTime(fromDate.year + 1, month, 1);
    }
    
    // Handle invalid days (e.g., February 30)
    final lastDay = DateTime(nextDate.year, nextDate.month + 1, 0).day;
    final actualDay = day > lastDay ? lastDay : day;
    
    return DateTime(nextDate.year, nextDate.month, actualDay);
  }
  
  DateTime? _getNextYearlyWeekdayOccurrence(DateTime fromDate, int month, int weekNumber, int targetWeekday) {
    var nextDate = DateTime(fromDate.year, month, 1);
    
    // If we're past the month, go to next year
    if (fromDate.month > month || 
        (fromDate.month == month && 
         fromDate.isAfter(DateTime(fromDate.year, month, 1).add(Duration(days: 28))))) {
      nextDate = DateTime(fromDate.year + 1, month, 1);
    }
    
    // Find the first occurrence of the target weekday in the month
    while (nextDate.weekday != targetWeekday) {
      nextDate = nextDate.add(Duration(days: 1));
    }
    
    // Add the appropriate number of weeks
    if (weekNumber > 1) {
      nextDate = nextDate.add(Duration(days: (weekNumber - 1) * 7));
    }
    
    // If we're still before the fromDate, go to next year
    if (nextDate.isBefore(fromDate)) {
      return _getNextYearlyWeekdayOccurrence(
        DateTime(fromDate.year + 1, month, 1),
        month,
        weekNumber,
        targetWeekday
      );
    }
    
    return nextDate;
  }

  // Checks if the task occurs on a specific date
  bool occursOnDate(DateTime date) {
    if (!isCyclic) {
      return _isSameDay(date, scheduledDate);
    }
    
    // Check if date is before the first occurrence
    if (date.isBefore(scheduledDate)) {
      return false;
    }
    
    // Check end date if set
    if (endDate != null && date.isAfter(endDate!)) {
      return false;
    }
    
    // Check max occurrences if set
    if (maxOccurrences > 0) {
      final occurrences = _countOccurrencesUpTo(date);
      if (occurrences > maxOccurrences) {
        return false;
      }
    }
    
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return _isDailyOccurrence(date);
      case RecurrenceType.weekly:
        return _isWeeklyOccurrence(date);
      case RecurrenceType.monthly:
        return _isMonthlyOccurrence(date);
      case RecurrenceType.yearly:
        return _isYearlyOccurrence(date);
      case RecurrenceType.weekdays:
        return _isWeekdayOccurrence(date);
      case RecurrenceType.custom:
        return _isCustomOccurrence(date);
      case RecurrenceType.none:
      default:
        return _isSameDay(date, scheduledDate);
    }
  }
  
  bool _isDailyOccurrence(DateTime date) {
    final daysDifference = date.difference(scheduledDate).inDays;
    return daysDifference >= 0 && daysDifference % interval == 0;
  }
  
  bool _isWeeklyOccurrence(DateTime date) {
    if (_scheduledWeekdays.isNotEmpty) {
      return _scheduledWeekdays.contains(date.weekday) &&
             date.weekday == scheduledDate.weekday &&
             date.isAfter(scheduledDate.subtract(const Duration(days: 1)));
    }
    
    // Fallback to interval in weeks
    final weeksDifference = date.difference(scheduledDate).inDays ~/ 7;
    return weeksDifference % interval == 0 && 
           date.weekday == scheduledDate.weekday;
  }
  
  bool _isMonthlyOccurrence(DateTime date) {
    if (useDayOfMonth) {
      return date.day == dayOfMonth &&
             date.isAfter(scheduledDate.subtract(const Duration(days: 1)));
    } else {
      return _isNthWeekdayOfMonth(date, weekOfMonth, scheduledDate.weekday);
    }
  }
  
  bool _isYearlyOccurrence(DateTime date) {
    if (date.month != scheduledDate.month) return false;
    
    if (useDayOfMonth) {
      return date.day == dayOfMonth;
    } else {
      return _isNthWeekdayOfMonth(date, weekOfMonth, scheduledDate.weekday);
    }
  }
  
  bool _isWeekdayOccurrence(DateTime date) {
    return date.weekday >= DateTime.monday && 
           date.weekday <= DateTime.friday;
  }
  
  bool _isCustomOccurrence(DateTime date) {
    // Fallback to legacy behavior for custom intervals
    if (_scheduledWeekdays.isNotEmpty) {
      return _isWeeklyOccurrence(date);
    }
    
    // Legacy interval-based scheduling (in weeks)
    final weeksDifference = date.difference(scheduledDate).inDays ~/ 7;
    return weeksDifference % interval == 0 && 
           date.weekday == scheduledDate.weekday;
  }
  
  bool _isNthWeekdayOfMonth(DateTime date, int weekNumber, int targetWeekday) {
    if (date.weekday != targetWeekday) return false;
    
    final dayOfMonth = date.day;
    final firstDayOfWeek = DateTime(date.year, date.month, 1).weekday;
    
    // Calculate which occurrence of the weekday this is in the month
    int occurrence = ((dayOfMonth + firstDayOfWeek - 1) ~/ 7) + 1;
    
    // Handle 5th weekday (which might be the last one)
    if (weekNumber == 5) {
      // Check if this is the last occurrence of this weekday in the month
      final lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;
      return (dayOfMonth + 7) > lastDayOfMonth;
    }
    
    return occurrence == weekNumber;
  }
  
  int _countOccurrencesUpTo(DateTime endDate) {
    if (!isCyclic || endDate.isBefore(scheduledDate)) {
      return 0;
    }
    
    int count = 0;
    DateTime? current = scheduledDate;
    
    while (current != null && (current.isBefore(endDate) || _isSameDay(current, endDate))) {
      count++;
      current = getNextOccurrence(current.add(const Duration(seconds: 1)));
      
      // Safety check to prevent infinite loops
      if (count > 1000) break;
    }
    
    return count;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  // Helper method to get a human-readable description of the recurrence pattern
  String getRecurrenceDescription() {
    if (!isCyclic) return 'Does not repeat';
    
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return interval == 1 
            ? 'Daily' 
            : 'Every $interval days';
            
      case RecurrenceType.weekly:
        if (_scheduledWeekdays.isNotEmpty) {
          final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final selectedDays = _scheduledWeekdays
              .where((day) => day >= 1 && day <= 7)
              .map((day) => dayNames[day - 1])
              .toList();
              
          if (selectedDays.isEmpty) return 'Weekly';
          
          return 'Weekly on ${selectedDays.join(', ')}';
        }
        return interval == 1 
            ? 'Weekly' 
            : 'Every $interval weeks';
            
      case RecurrenceType.monthly:
        if (useDayOfMonth) {
          return 'Monthly on day $dayOfMonth';
        } else {
          final dayName = _getWeekdayName(scheduledDate.weekday);
          final weekNumberStr = _getWeekNumberString(weekOfMonth);
          return 'Monthly on the $weekNumberStr $dayName';
        }
        
      case RecurrenceType.yearly:
        final monthName = _getMonthName(scheduledDate.month);
        if (useDayOfMonth) {
          return 'Annually on $monthName $dayOfMonth';
        } else {
          final dayName = _getWeekdayName(scheduledDate.weekday);
          final weekNumberStr = _getWeekNumberString(weekOfMonth);
          return 'Annually on the $weekNumberStr $dayName of $monthName';
        }
        
      case RecurrenceType.weekdays:
        return 'Every weekday (Mon-Fri)';
        
      case RecurrenceType.custom:
        return 'Custom recurrence';
        
      case RecurrenceType.none:
      default:
        return 'Does not repeat';
    }
  }
  
  String _getWeekdayName(int weekday) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[weekday - 1];
  }
  
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
  
  String _getWeekNumberString(int weekNumber) {
    switch (weekNumber) {
      case 1: return 'first';
      case 2: return 'second';
      case 3: return 'third';
      case 4: return 'fourth';
      case 5: return 'last';
      default: return '';
    }
  }

  // Helper to get reminder time or default to 9 AM on scheduled date
  DateTime get effectiveReminderTime {
    if (reminderTime != null) {
      return reminderTime!;
    }
    // Default to 9 AM on the scheduled date
    return DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      9,
      0,
    );
  }
}
