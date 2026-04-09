import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notifications;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart' as model;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final notifications.FlutterLocalNotificationsPlugin _notificationsPlugin =
      notifications.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const notifications.AndroidInitializationSettings androidSettings =
        notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
    const notifications.InitializationSettings initializationSettings =
        notifications.InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initializationSettings);

    // Request permissions for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            notifications.AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            notifications.AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  Future<void> scheduleNotification(model.Task task) async {
    if (task.dueDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      task.id ?? 0,
      'Task Reminder',
      task.title,
      tz.TZDateTime.from(task.dueDate, tz.local),
      const notifications.NotificationDetails(
        android: notifications.AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          importance: notifications.Importance.max,
          priority: notifications.Priority.high,
        ),
      ),
      androidScheduleMode: notifications.AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          notifications.UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
