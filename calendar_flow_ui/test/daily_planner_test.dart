import 'package:calendar_flow_ui/models/app_models.dart';
import 'package:calendar_flow_ui/services/daily_planner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('daily planner sorts and schedules sequentially from 09:00', () {
    final events = [
      const AppEvent(
        id: 2,
        title: 'Later',
        date: DateTime(2026, 1, 2),
        start: TimeOfDay(hour: 9, minute: 0),
        end: TimeOfDay(hour: 10, minute: 0),
        location: 'x',
        attendees: ['A'],
        colorValue: 0xFFFFFFFF,
        reminder: false,
        durationMinutes: 60,
        completed: false,
      ),
      const AppEvent(
        id: 1,
        title: 'Priority',
        date: DateTime(2026, 1, 1),
        start: TimeOfDay(hour: 9, minute: 0),
        end: TimeOfDay(hour: 10, minute: 0),
        location: 'x',
        attendees: ['A'],
        colorValue: 0xFFFFFFFF,
        reminder: true,
        durationMinutes: 30,
        completed: false,
      ),
    ];

    final schedule = generateDailySchedule(DateTime(2026, 1, 3), events);
    expect(schedule.first.event.title, 'Priority');
    expect(schedule.first.start.hour, 9);
    expect(schedule.first.end.minute, 30);
    expect(schedule[1].start.hour, 9);
    expect(schedule[1].start.minute, 30);
    expect(schedule[1].end.hour, 10);
    expect(schedule[1].end.minute, 30);
  });
}
