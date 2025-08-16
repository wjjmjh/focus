import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/task_model.dart';

class NotificationService {
  static const _channelId = 'focus_task_reminders';
  static const _channelName = 'Focus Task Reminders';
  static const _channelDescription =
      'Notifications for upcoming Focus task deadlines';

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const MethodChannel _alarmChannel =
      MethodChannel('com.example.focus/alarm');

  static bool _isAppInForeground = true;

  // ---------- Init ----------
  static Future<void> init() async {
    // Timezone (required for zonedSchedule & DST correctness)
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _notificationsPlugin.initialize(initSettings);
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    // Android 13+ runtime notifications permission
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // IOS explicit permission (no-op on Android)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ---------- Public APIs ----------
  static Future<void> scheduleTaskReminders(Task task) async {
    final due = task.dueDate;
    if (due == null || task.status == 'Done') return;

    // Cancel previous schedules for this task
    await cancelTaskReminders(task);

    final now = DateTime.now();
    if (due.isBefore(now)) return; // nothing to schedule in the past

    final baseId = (task.id.hashCode & 0x7fffffff);
    final idMinus1Day = _deriveId(baseId, 1);
    final idDueDay = _deriveId(baseId, 2);

    // Titles/bodies
    const dueTomorrowTitle = 'Due Tomorrow';
    const dueTodayTitle = 'Due TODAY';

    // One day before at 9am local
    final dayBefore = DateTime(due.year, due.month, due.day)
        .subtract(const Duration(days: 1));
    if (!_isSameDay(due, now)) {
      // show immediate if today is the day-before
      if (_isSameDay(dayBefore, now)) {
        await showImmediateNotification(
            'Task Due Tomorrow', '${task.title}\nDue: ${_formatDate(due)}');
      } else if (dayBefore.isAfter(now)) {
        await _zonedAtNineAM(
          idMinus1Day,
          dueTomorrowTitle,
          '${task.title}\nDue: ${_formatDate(due)}',
          dayBefore,
        );
      }
    }

    // Due day at 9am local
    if (_isSameDay(due, now)) {
      await showImmediateNotification(
          dueTodayTitle, '${task.title}\nDue Today!');
    } else {
      await _zonedAtNineAM(
        idDueDay,
        dueTodayTitle,
        '${task.title}\nDue Today!',
        DateTime(due.year, due.month, due.day),
      );
    }
  }

  static Future<void> scheduleAllTaskReminders(List<Task> tasks) async {
    await _notificationsPlugin.cancelAll();
    for (final t in tasks) {
      if (t.dueDate != null && t.status != 'Done') {
        await scheduleTaskReminders(t);
      }
    }
  }

  static Future<void> cancelTaskReminders(Task task) async {
    final baseId = (task.id.hashCode & 0x7fffffff);
    final idMinus1Day = _deriveId(baseId, 1);
    final idDueDay = _deriveId(baseId, 2);

    // Cancel flutter notifications
    await _notificationsPlugin.cancel(idMinus1Day);
    await _notificationsPlugin.cancel(idDueDay);

    // Cancel native alarms only on Android
    if (Platform.isAndroid) {
      await _alarmChannel
          .invokeMethod('cancelAlarm', {'notificationId': idMinus1Day});
      await _alarmChannel
          .invokeMethod('cancelAlarm', {'notificationId': idDueDay});
    }
  }

  static Future<void> showImmediateNotification(
      String title, String body) async {
    // No immediate notifications when app is in foreground
    if (_isAppInForeground) return;

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await _notificationsPlugin.show(id, title, body, _details());
  }

  static void setAppLifecycleState(bool isInForeground) {
    _isAppInForeground = isInForeground;
  }

  static int _deriveId(int base, int salt) {
    return (base ^ (salt * 0x9e3779b9)) & 0x7fffffff;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static Future<void> _zonedAtNineAM(
    int id,
    String title,
    String body,
    DateTime dayLocal,
  ) async {
    final scheduledLocal =
        DateTime(dayLocal.year, dayLocal.month, dayLocal.day, 9, 0);
    final now = DateTime.now();
    if (!scheduledLocal.isAfter(now)) return;

    if (Platform.isAndroid) {
      // Use native AlarmManager for Android
      await _alarmChannel.invokeMethod('scheduleAlarm', {
        'title': title,
        'body': body,
        'timestamp': scheduledLocal.millisecondsSinceEpoch,
        'notificationId': id,
      });
    } else {
      // Use flutter_local_notifications for iOS
      final tzTime = tz.TZDateTime.from(scheduledLocal, tz.local);
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (_isSameDay(target, today)) return 'Today';
    if (_isSameDay(target, today.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
