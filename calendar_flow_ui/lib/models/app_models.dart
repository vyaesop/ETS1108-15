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
  final bool allDay;
  final RecurrenceRule recurrenceRule;
  final DateTime? recurrenceUntil;
  final DateTime? seriesStartDate;

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
    this.allDay = false,
    this.recurrenceRule = RecurrenceRule.none,
    this.recurrenceUntil,
    this.seriesStartDate,
  });

  int get effectiveDurationMinutes => durationMinutes ?? 30;

  Color get color => Color(colorValue);

  bool get isRecurring => recurrenceRule != RecurrenceRule.none;

  bool get isOccurrence => seriesStartDate != null && !_sameDay(seriesStartDate!, date);

  String get instanceKey => '${id ?? 'x'}-${date.year}-${date.month}-${date.day}-${start.hour}-${start.minute}';

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
      'all_day': allDay ? 1 : 0,
      'recurrence_rule': recurrenceRule.storageValue,
      'recurrence_until': recurrenceUntil?.toIso8601String(),
    };
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'start_minutes': start.hour * 60 + start.minute,
      'end_minutes': end.hour * 60 + end.minute,
      'location': location,
      'attendees': attendees,
      'color_value': colorValue,
      'reminder': reminder,
      'duration_minutes': effectiveDurationMinutes,
      'completed': completed,
      'all_day': allDay,
      'recurrence_rule': recurrenceRule.storageValue,
      'recurrence_until': recurrenceUntil?.toIso8601String(),
      'series_start_date': seriesStartDate?.toIso8601String(),
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
    bool? allDay,
    RecurrenceRule? recurrenceRule,
    DateTime? recurrenceUntil,
    DateTime? seriesStartDate,
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
      allDay: allDay ?? this.allDay,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceUntil: recurrenceUntil ?? this.recurrenceUntil,
      seriesStartDate: seriesStartDate ?? this.seriesStartDate,
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
      allDay: ((map['all_day'] ?? 0) as int) == 1,
      recurrenceRule: recurrenceRuleFromStorage(map['recurrence_rule'] as String?),
      recurrenceUntil: map['recurrence_until'] == null ? null : DateTime.parse(map['recurrence_until'] as String),
    );
  }

  static AppEvent fromJson(Map<String, Object?> map) {
    final startMinutes = map['start_minutes'] as int;
    final endMinutes = map['end_minutes'] as int;
    final rawDuration = map['duration_minutes'] as int?;
    final attendees = (map['attendees'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    return AppEvent(
      id: map['id'] as int?,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      start: TimeOfDay(hour: startMinutes ~/ 60, minute: startMinutes % 60),
      end: TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60),
      location: map['location'] as String,
      attendees: attendees,
      colorValue: map['color_value'] as int,
      reminder: map['reminder'] as bool,
      durationMinutes: rawDuration ?? 30,
      completed: map['completed'] as bool? ?? false,
      allDay: map['all_day'] as bool? ?? false,
      recurrenceRule: recurrenceRuleFromStorage(map['recurrence_rule'] as String?),
      recurrenceUntil: map['recurrence_until'] == null ? null : DateTime.parse(map['recurrence_until'] as String),
      seriesStartDate: map['series_start_date'] == null ? null : DateTime.parse(map['series_start_date'] as String),
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

enum RecurrenceRule { none, daily, weekly, monthly }

extension RecurrenceRuleStorage on RecurrenceRule {
  String get storageValue => switch (this) {
        RecurrenceRule.none => 'none',
        RecurrenceRule.daily => 'daily',
        RecurrenceRule.weekly => 'weekly',
        RecurrenceRule.monthly => 'monthly',
      };
}

RecurrenceRule recurrenceRuleFromStorage(String? value) => switch (value) {
      'daily' => RecurrenceRule.daily,
      'weekly' => RecurrenceRule.weekly,
      'monthly' => RecurrenceRule.monthly,
      _ => RecurrenceRule.none,
    };

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

  Map<String, Object?> toJson() => {
        'id': id,
        'event_id': eventId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'duration_minutes': durationMinutes,
      };

  static FocusSession fromJson(Map<String, Object?> map) => FocusSession(
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

  Map<String, Object?> toJson() => {
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'tasks_completed': tasksCompleted,
        'focus_minutes': focusMinutes,
      };

  static DailyProductivityStats fromJson(Map<String, Object?> map) => DailyProductivityStats(
        date: DateTime.parse(map['date'] as String),
        tasksCompleted: map['tasks_completed'] as int,
        focusMinutes: map['focus_minutes'] as int,
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

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'timezone': timezone,
        'goals': goals,
      };

  static UserProfile fromJson(Map<String, Object?> map) => UserProfile(
        id: map['id'] as int,
        name: map['name'] as String,
        city: map['city'] as String,
        timezone: map['timezone'] as String,
        goals: map['goals'] as String,
      );
}

class AppDataSnapshot {
  final bool onboarded;
  final UserProfile profile;
  final List<AppEvent> events;
  final List<FocusSession> focusSessions;
  final List<DailyProductivityStats> dailyStats;

  const AppDataSnapshot({
    required this.onboarded,
    required this.profile,
    required this.events,
    required this.focusSessions,
    required this.dailyStats,
  });

  Map<String, Object?> toJson() => {
        'onboarded': onboarded,
        'profile': profile.toJson(),
        'events': events.map((e) => e.toJson()).toList(),
        'focus_sessions': focusSessions.map((s) => s.toJson()).toList(),
        'daily_stats': dailyStats.map((s) => s.toJson()).toList(),
      };

  static AppDataSnapshot fromJson(Map<String, Object?> map) {
    final profile = UserProfile.fromJson(map['profile'] as Map<String, Object?>);
    final events = (map['events'] as List<dynamic>? ?? const [])
        .map((e) => AppEvent.fromJson((e as Map).cast<String, Object?>()))
        .toList();
    final focusSessions = (map['focus_sessions'] as List<dynamic>? ?? const [])
        .map((e) => FocusSession.fromJson((e as Map).cast<String, Object?>()))
        .toList();
    final stats = (map['daily_stats'] as List<dynamic>? ?? const [])
        .map((e) => DailyProductivityStats.fromJson((e as Map).cast<String, Object?>()))
        .toList();
    return AppDataSnapshot(
      onboarded: map['onboarded'] as bool,
      profile: profile,
      events: events,
      focusSessions: focusSessions,
      dailyStats: stats,
    );
  }
}
