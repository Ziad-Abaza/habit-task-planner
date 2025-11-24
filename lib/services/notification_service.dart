import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    final iosSettings = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // You can navigate to specific screens based on the payload
    // For now, we'll just print the payload
    print('Notification tapped: ${response.payload}');
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Schedule a notification for a task
  Future<void> scheduleTaskReminder(Task task) async {
    if (!task.hasReminder || task.isCompleted) {
      return;
    }

    await initialize();
    
    print('Scheduling notification for task: ${task.title}');
    
    // Request permissions first
    final hasPermission = await requestPermissions();
    print('Notification permission status: $hasPermission');
    
    if (!hasPermission) {
      print('Notification permission denied');
      return;
    }

    final reminderTime = task.effectiveReminderTime;
    final now = DateTime.now();
    
    print('Reminder time: $reminderTime, Now: $now');

    // Don't schedule if the reminder time has passed
    if (reminderTime.isBefore(now)) {
      print('Reminder time is in the past, not scheduling');
      return;
    }

    // Generate a unique notification ID if not already set
    final notificationId = task.notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
    // Update task with notification ID
    if (task.notificationId == null) {
      task.notificationId = notificationId;
      await task.save();
    }

    // Convert to timezone-aware datetime
    final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);
    print('Zoned reminder time: $tzReminderTime');

    // Notification details
    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for scheduled tasks',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Schedule the notification
      await _notifications.zonedSchedule(
        notificationId,
        'Task Reminder: ${task.title}',
        task.description ?? 'You have a task scheduled for today',
        tzReminderTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_${task.key}',
      );

      print('Successfully scheduled notification for ${task.title} at $tzReminderTime with ID $notificationId');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // Cancel a task reminder
  Future<void> cancelTaskReminder(Task task) async {
    if (task.notificationId != null) {
      await _notifications.cancel(task.notificationId!);
      print('Cancelled notification for ${task.title}');
    }
  }

  // Schedule daily overview notification
  Future<void> scheduleDailyOverview({int hour = 8, int minute = 0}) async {
    await initialize();
    
    final hasPermission = await requestPermissions();
    if (!hasPermission) return;

    const notificationId = 999999; // Fixed ID for daily overview

    // Schedule for next occurrence of the specified time
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_overview',
      'Daily Overview',
      channelDescription: 'Daily task overview notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      'Good Morning! 🌅',
      'You have tasks scheduled for today. Check your planner!',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );

    print('Scheduled daily overview at $hour:$minute');
  }

  // Cancel daily overview
  Future<void> cancelDailyOverview() async {
    await _notifications.cancel(999999);
  }

  // Show immediate notification (for testing or immediate alerts)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'immediate',
      'Immediate Notifications',
      channelDescription: 'Immediate task notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
