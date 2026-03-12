import 'package:flutter/material.dart';

class AppEvent {
  final int? id;
  final String title;
  final DateTime date;
  final TimeOfDay start;
  final TimeOfDay end;
  final String location;
  final String attendees;
  final int colorValue;
  final bool reminder;
  final bool reminder;

  const AppEvent({
    this.id,
    this.id,
    required this.title,
    required this.date,
    required this.start,
    required this.end,
    required this.location,
    required this.attendees,
    required this.colorValue,
    required this.reminder,
    this.reminder = true,
  });

  factory AppEvent.fromMap(Map<String, Object?> map) {
    return AppEvent(
      id: map['id'] as int?,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      start: _timeFromMinutes(map['start_minutes'] as int),
      end: _timeFromMinutes(map['end_minutes'] as int),
      location: map['location'] as String,
      attendees: ((map['attendees'] as String).split('|')..removeWhere((value) => value.isEmpty)),
      color: Color(map['color_value'] as int),
      reminder: (map['reminder'] as int) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'start_minutes': _toMinutes(start),
      'end_minutes': _toMinutes(end),
      'location': location,
      'attendees': attendees.join('|'),
      'color_value': color.value,
      'reminder': reminder ? 1 : 0,
    };
  }

  static int _toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  static TimeOfDay _timeFromMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

class EventDraft {
  String title = '';
  String location = '';
  DateTime date = DateTime.now();
  TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 10, minute: 0);
  Color color = const Color(0xFFE8C47D);
  bool reminder = true;
}

class UserProfile {
  final int id;
  final String name;
  final String city;
  final String timezone;
  final String goals;

  const UserProfile({
    required this.id,
    required this.name,
    required this.city,
    required this.timezone,
    required this.goals,
  });

  factory UserProfile.fromMap(Map<String, Object?> map) {
    return UserProfile(
      name: map['name'] as String,
      city: map['city'] as String,
      timezone: map['timezone'] as String,
      goals: ((map['goals'] as String).split('|')..removeWhere((value) => value.isEmpty)),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'name': name,
      'city': city,
      'timezone': timezone,
      'goals': goals.join('|'),
    };
  }
}
