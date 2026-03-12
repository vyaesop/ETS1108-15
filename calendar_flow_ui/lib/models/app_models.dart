import 'package:flutter/material.dart';

class AppEvent {
  final int? id;
  final String title;
  final DateTime date;
  final TimeOfDay start;
  final TimeOfDay end;
  final String location;
  final List<String> attendees;
  final int colorValue;
  final bool reminder;
  final int? durationMinutes;
  final bool completed;

  const AppEvent({
    this.id,
    required this.title,
    required this.date,
    required this.start,
    required this.end,
    required this.location,
    required this.attendees,
    required this.colorValue,
    required this.reminder,
    this.durationMinutes,
    this.completed = false,
  });

  int get effectiveDurationMinutes => durationMinutes ?? 30;

  Color get color => Color(colorValue);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'start_minutes': start.hour * 60 + start.minute,
      'end_minutes': end.hour * 60 + end.minute,
      'location': location,
      'color_value': colorValue,
      'reminder': reminder ? 1 : 0,
      'duration_minutes': effectiveDurationMinutes,
      'completed': completed ? 1 : 0,
    };
  }

  AppEvent copyWith({
    int? id,
    String? title,
    DateTime? date,
    TimeOfDay? start,
    TimeOfDay? end,
    String? location,
    List<String>? attendees,
    int? colorValue,
    bool? reminder,
    int? durationMinutes,
    bool? completed,
  }) {
    return AppEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      start: start ?? this.start,
      end: end ?? this.end,
      location: location ?? this.location,
      attendees: attendees ?? this.attendees,
      colorValue: colorValue ?? this.colorValue,
      reminder: reminder ?? this.reminder,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      completed: completed ?? this.completed,
    );
  }

  static AppEvent fromMap(Map<String, Object?> map, {List<String> attendees = const []}) {
    final startMinutes = map['start_minutes'] as int;
    final endMinutes = map['end_minutes'] as int;
    final rawDuration = map['duration_minutes'];

    return AppEvent(
      id: map['id'] as int,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      start: TimeOfDay(hour: startMinutes ~/ 60, minute: startMinutes % 60),
      end: TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60),
      location: map['location'] as String,
      attendees: attendees,
      colorValue: map['color_value'] as int,
      reminder: (map['reminder'] as int) == 1,
      durationMinutes: rawDuration == null ? 30 : rawDuration as int,
      completed: ((map['completed'] ?? 0) as int) == 1,
    );
  }
}

class FocusSession {
  final int id;
  final int eventId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;

  const FocusSession({
    required this.id,
    required this.eventId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  });

  static FocusSession fromMap(Map<String, Object?> map) => FocusSession(
        id: map['id'] as int,
        eventId: map['event_id'] as int,
        startTime: DateTime.parse(map['start_time'] as String),
        endTime: map['end_time'] == null ? null : DateTime.parse(map['end_time'] as String),
        durationMinutes: map['duration_minutes'] as int,
      );
}

class DailyProductivityStats {
  final DateTime date;
  final int tasksCompleted;
  final int focusMinutes;

  const DailyProductivityStats({
    required this.date,
    required this.tasksCompleted,
    required this.focusMinutes,
  });

  static DailyProductivityStats fromMap(Map<String, Object?> map) => DailyProductivityStats(
        date: DateTime.parse(map['date'] as String),
        tasksCompleted: map['tasks_completed'] as int,
        focusMinutes: map['focus_minutes'] as int,
      );

  static DailyProductivityStats empty(DateTime date) => DailyProductivityStats(
        date: DateTime(date.year, date.month, date.day),
        tasksCompleted: 0,
        focusMinutes: 0,
      );
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

  List<String> get goalList => goals.split('|').where((e) => e.isNotEmpty).toList();

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'city': city,
        'timezone': timezone,
        'goals': goals,
      };

  UserProfile copyWith({
    String? name,
    String? city,
    String? timezone,
    String? goals,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      timezone: timezone ?? this.timezone,
      goals: goals ?? this.goals,
    );
  }

  static UserProfile fromMap(Map<String, Object?> map) => UserProfile(
        id: map['id'] as int,
        name: map['name'] as String,
        city: map['city'] as String,
        timezone: map['timezone'] as String,
        goals: map['goals'] as String,
      );
}
