import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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
  static Future<bool> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.local);

      final permissionsGranted = await _requestPermissions();
      return permissionsGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _requestPermissions() async {
    bool permissionsGranted = true;

    // Android 13+ runtime notifications permission
    if (Platform.isAndroid) {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        permissionsGranted = granted ?? false;
      }
    }

    // iOS explicit permission
    if (Platform.isIOS) {
      final iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        permissionsGranted = granted ?? false;
      }
    }

    return permissionsGranted;
  }

  // ---------- Public APIs ----------
  static Future<void> scheduleTaskReminders(Task task) async {
    final due = task.dueDate;
    if (due == null || task.status == 'Done') return;

    // Cancel previous schedules for this task
    await cancelTaskReminders(task);

    final now = DateTime.now();

    if (due.isBefore(now) && !_isSameDay(due, now)) {
      return;
    }

    final baseId = (task.id.hashCode & 0x7fffffff);
    final idMinus1Day = _deriveId(baseId, 1);
    final idDueDay = _deriveId(baseId, 2);

    // Titles/bodies
    const dueTomorrowTitle = 'Due Tomorrow';
    const dueTodayTitle = 'Due TODAY';

    // One day before at 9am local
    final dayBefore = DateTime(due.year, due.month, due.day)
        .subtract(const Duration(days: 1));

    if (_isSameDay(dayBefore, now)) {
      await _zonedAtNineAM(
        idMinus1Day,
        dueTomorrowTitle,
        '${task.title}\nDue: ${_formatDate(due)}',
        dayBefore,
      );
    } else if (dayBefore.isAfter(now)) {
      await _zonedAtNineAM(
        idMinus1Day,
        dueTomorrowTitle,
        '${task.title}\nDue: ${_formatDate(due)}',
        dayBefore,
      );
    }

    // Due day at scheduled time
    await _zonedAtNineAM(
      idDueDay,
      dueTodayTitle,
      '${task.title}\nDue Today!',
      DateTime(due.year, due.month, due.day),
    );
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
    try {
      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _notificationsPlugin.show(id, title, body, _details());
    } catch (e) {
      // ...
    }
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
    try {
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
    } catch (e) {
      // ...
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
