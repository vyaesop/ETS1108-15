import 'package:flutter/material.dart';

class AppEvent {
  final String title;
  final TimeOfDay start;
  final TimeOfDay end;
  final String location;
  final List<String> attendees;
  final Color color;
  final DateTime date;

  const AppEvent({
    required this.title,
    required this.start,
    required this.end,
    required this.location,
    required this.attendees,
    required this.color,
    required this.date,
  });
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
  final String name;
  final String city;
  final String timezone;
  final List<String> goals;

  const UserProfile({
    required this.name,
    required this.city,
    required this.timezone,
    required this.goals,
  });
}
