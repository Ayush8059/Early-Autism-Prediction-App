import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const int _dailyReminderId = 1001;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings: initializationSettings);

    _initialized = true;
  }

  static Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
    required List<int> days,
  }) async {
    await initialize();

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final permissionGranted = await androidPlugin?.requestNotificationsPermission() ?? true;
    if (!permissionGranted) return false;

    await cancelDailyReminder();

    for (final day in days) {
      await _notifications.zonedSchedule(
        id: _dailyReminderId + day,
        title: 'Your AutiSense streak needs you',
        body: 'Complete one activity or assessment today so your progress streak does not break.',
        scheduledDate: _nextReminderTime(hour: hour, minute: minute, weekday: day),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminders',
            'Daily reminders',
            channelDescription: 'Scheduled reminders for AutiSense activities and assessments.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }

    return true;
  }

  static Future<void> cancelDailyReminder() async {
    await initialize();
    for (var day = 1; day <= 7; day++) {
      await _notifications.cancel(id: _dailyReminderId + day);
    }
  }

  static tz.TZDateTime _nextReminderTime({required int hour, required int minute, required int weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
