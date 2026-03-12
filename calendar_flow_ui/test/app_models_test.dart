import 'package:calendar_flow_ui/models/app_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppEvent map round-trip preserves key fields', () {
    const event = AppEvent(
      id: 10,
      title: 'Review',
      date: DateTime(2026, 5, 1),
      start: TimeOfDay(hour: 9, minute: 30),
      end: TimeOfDay(hour: 10, minute: 0),
      location: 'HQ',
      attendees: ['AL', 'BO'],
      colorValue: 0xFF000000,
      reminder: true,
    );

    final mapped = event.toMap();
    final decoded = AppEvent.fromMap(mapped, attendees: event.attendees);

    expect(decoded.id, event.id);
    expect(decoded.title, event.title);
    expect(decoded.location, event.location);
    expect(decoded.attendees, event.attendees);
    expect(decoded.reminder, isTrue);
  });
}
