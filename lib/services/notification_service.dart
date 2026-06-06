import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/task_model.dart';

class NotificationService {
  NotificationService._();

  static const _channelId = 'focus_task_reminders';
  static const _channelName = 'Focus Task Reminders';
  static const _channelDescription =
      'Reminders for upcoming Focus task deadlines';

  static const _reminderHour = 9;
  static const _slotDayBefore = 1;
  static const _slotDueDay = 2;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialised = false;

  // ---------- Init ----------

  static Future<void> init() async {
    if (_initialised) return;

    await _configureLocalTimeZone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _createAndroidChannel();
    _initialised = true;

    await requestPermission();
  }

  static Future<void> _configureLocalTimeZone() async {
    tzdata.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }
  }

  static Future<void> _createAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );
  }

  // ---------- Permissions ----------

  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return (await android?.requestNotificationsPermission()) ?? false;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return (await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )) ??
          false;
    }
    return true;
  }

  // ---------- Scheduling ----------

  static Future<void> scheduleTaskReminders(
    Task task, {
    bool allowImmediate = false,
  }) async {
    await cancelTaskReminders(task);

    final due = task.dueDate;
    if (due == null || task.status == 'Done' || task.isArchived) return;

    final dueDay = DateTime(due.year, due.month, due.day);
    final dayBefore = dueDay.subtract(const Duration(days: 1));

    await _scheduleAt(
      id: _stableId(task.id, _slotDayBefore),
      day: dayBefore,
      title: 'Due tomorrow',
      body: task.title,
      payload: task.id,
      allowImmediate: false,
    );
    await _scheduleAt(
      id: _stableId(task.id, _slotDueDay),
      day: dueDay,
      title: 'Due today',
      body: task.title,
      payload: task.id,
      allowImmediate: allowImmediate,
    );
  }

  static Future<void> cancelTaskReminders(Task task) async {
    await _plugin.cancel(_stableId(task.id, _slotDayBefore));
    await _plugin.cancel(_stableId(task.id, _slotDueDay));
  }

  static Future<void> reconcileAll(List<Task> tasks) async {
    await _plugin.cancelAll();
    for (final task in tasks) {
      await scheduleTaskReminders(task);
    }
  }

  // ---------- Internals ----------

  static Future<void> _scheduleAt({
    required int id,
    required DateTime day,
    required String title,
    required String body,
    required String payload,
    required bool allowImmediate,
  }) async {
    final when = resolveFireTime(
      day,
      tz.TZDateTime.now(tz.local),
      allowImmediate: allowImmediate,
    );
    if (when == null) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  @visibleForTesting
  static tz.TZDateTime? resolveFireTime(
    DateTime day,
    tz.TZDateTime now, {
    required bool allowImmediate,
  }) {
    final scheduled = tz.TZDateTime(
      tz.local,
      day.year,
      day.month,
      day.day,
      _reminderHour,
    );
    if (scheduled.isAfter(now)) return scheduled;

    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    if (!isToday || !allowImmediate) return null;
    return now.add(const Duration(minutes: 1));
  }

  static NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  static int _stableId(String taskId, int slot) {
    var hash = 0x811c9dc5;
    for (final unit in taskId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    hash ^= slot;
    hash = (hash * 0x01000193) & 0xffffffff;
    return hash & 0x7fffffff;
  }

  @visibleForTesting
  static int stableId(String taskId, int slot) => _stableId(taskId, slot);

  static void _onNotificationResponse(NotificationResponse response) {}
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {}
