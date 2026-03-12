import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_models.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(settings);

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    _initialized = true;
  }

  Future<void> syncReminders(List<AppEvent> baseEvents) async {
    if (!_initialized) return;
    await _plugin.cancelAll();
    final now = DateTime.now();
    for (final event in baseEvents) {
      if (!event.reminder || event.completed) continue;
      final next = _nextOccurrenceDate(event, now);
      if (next == null) continue;
      final scheduleTime = _notificationTime(event, next);
      if (scheduleTime.isBefore(now)) continue;
      await _plugin.zonedSchedule(
        _notificationId(event),
        event.title,
        event.allDay ? 'All day event' : 'Starts at ${_fmt(event.start)}',
        tz.TZDateTime.from(scheduleTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chrono_events',
            'Event reminders',
            channelDescription: 'Event reminder notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  int _notificationId(AppEvent event) => event.id ?? event.hashCode;

  DateTime _notificationTime(AppEvent event, DateTime date) {
    if (event.allDay) {
      return DateTime(date.year, date.month, date.day, 9, 0);
    }
    final start = DateTime(date.year, date.month, date.day, event.start.hour, event.start.minute);
    return start.subtract(const Duration(minutes: 15));
  }

  DateTime? _nextOccurrenceDate(AppEvent event, DateTime now) {
    final startDate = DateTime(event.date.year, event.date.month, event.date.day);
    if (!event.isRecurring) {
      return startDate.isBefore(_startOfDay(now)) ? null : startDate;
    }
    final until = event.recurrenceUntil;
    var cursor = startDate;
    while (cursor.isBefore(_startOfDay(now))) {
      cursor = _next(cursor, event.recurrenceRule);
      if (until != null && cursor.isAfter(until)) return null;
    }
    return cursor;
  }

  DateTime _next(DateTime date, RecurrenceRule rule) {
    return switch (rule) {
      RecurrenceRule.daily => date.add(const Duration(days: 1)),
      RecurrenceRule.weekly => date.add(const Duration(days: 7)),
      RecurrenceRule.monthly => _addMonth(date),
      RecurrenceRule.none => date.add(const Duration(days: 3650)),
    };
  }

  DateTime _addMonth(DateTime date) {
    final year = date.year + (date.month == 12 ? 1 : 0);
    final month = date.month == 12 ? 1 : date.month + 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > daysInMonth ? daysInMonth : date.day;
    return DateTime(year, month, day);
  }

  DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  String _fmt(TimeOfDay value) {
    final h = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final m = value.minute.toString().padLeft(2, '0');
    final p = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }
}
