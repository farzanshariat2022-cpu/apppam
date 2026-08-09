import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int morningNotificationId = 1001;
  static const int eveningNotificationId = 1002;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    await _scheduleDailyNotifications();
    _initialized = true;
  }

  Future<void> _scheduleDailyNotifications() async {
    await _scheduleDaily(
      id: morningNotificationId,
      hour: 7,
      minute: 0,
      title: 'صبح بخیر ☀️',
      body: 'گزارش دیروز و برنامه امروزت آماده‌ست — اپ رو باز کن ببین.',
    );

    await _scheduleDaily(
      id: eveningNotificationId,
      hour: 22,
      minute: 0,
      title: 'وقت جمع‌بندی امروزه 🌙',
      body: 'ژورنالت رو بنویس و ساعت خوابت رو ثبت کن.',
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'architect_daily',
          'یادآورهای روزانه معمار',
          channelDescription: 'خلاصه صبحگاهی و یادآور شبانه',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime scheduledTime,
  }) async {
    final reminderTime = scheduledTime.subtract(const Duration(minutes: 5));
    if (reminderTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(reminderTime, tz.local);

    await _plugin.zonedSchedule(
      _idFromTaskId(taskId),
      'یادآوری تسک ⏰',
      '۵ دقیقه دیگه وقتشه: $taskTitle',
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'architect_task_reminders',
          'یادآور تسک‌ها',
          channelDescription: 'یادآوری ۵ دقیقه قبل از تسک‌های زمان‌بندی‌شده',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await _plugin.cancel(_idFromTaskId(taskId));
  }

  int _idFromTaskId(String taskId) => (taskId.hashCode & 0x7FFFFFFF) % 100000 + 2000;
}
