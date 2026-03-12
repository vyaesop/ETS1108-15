import '../models/app_models.dart';

class ScheduledEvent {
  final AppEvent event;
  final DateTime start;
  final DateTime end;

  const ScheduledEvent({
    required this.event,
    required this.start,
    required this.end,
  });
}

List<ScheduledEvent> generateDailySchedule(DateTime date, List<AppEvent> events) {
  final day = DateTime(date.year, date.month, date.day);
  final incomplete = events.where((e) => !e.completed && !e.allDay).toList();

  incomplete.sort((a, b) {
    final reminderSort = (b.reminder ? 1 : 0).compareTo(a.reminder ? 1 : 0);
    if (reminderSort != 0) return reminderSort;

    final dateSort = DateTime(a.date.year, a.date.month, a.date.day)
        .compareTo(DateTime(b.date.year, b.date.month, b.date.day));
    if (dateSort != 0) return dateSort;

    return (a.id ?? 1 << 30).compareTo(b.id ?? 1 << 30);
  });

  var current = DateTime(day.year, day.month, day.day, 9, 0);
  final scheduled = <ScheduledEvent>[];

  for (final event in incomplete) {
    final duration = event.durationMinutes ?? 30;
    final end = current.add(Duration(minutes: duration));
    scheduled.add(ScheduledEvent(event: event, start: current, end: end));
    current = end;
  }

  return scheduled;
}
