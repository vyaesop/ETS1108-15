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
  });

  Color get color => Color(colorValue);
  List<String> get attendeeList => attendees
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'start_minutes': start.hour * 60 + start.minute,
      'end_minutes': end.hour * 60 + end.minute,
      'location': location,
      'attendees': attendees,
      'color_value': colorValue,
      'reminder': reminder ? 1 : 0,
    };
  }

  AppEvent copyWith({
    int? id,
    String? title,
    DateTime? date,
    TimeOfDay? start,
    TimeOfDay? end,
    String? location,
    String? attendees,
    int? colorValue,
    bool? reminder,
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
    );
  }

  static AppEvent fromMap(Map<String, Object?> map) {
    final startMinutes = map['start_minutes'] as int;
    final endMinutes = map['end_minutes'] as int;
    return AppEvent(
      id: map['id'] as int,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      start: TimeOfDay(hour: startMinutes ~/ 60, minute: startMinutes % 60),
      end: TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60),
      location: map['location'] as String,
      attendees: map['attendees'] as String,
      colorValue: map['color_value'] as int,
      reminder: (map['reminder'] as int) == 1,
    );
  }
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
