import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import '../services/daily_planner.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  final List<AppEvent> events;
  final UserProfile? profile;
  final ValueChanged<AppEvent> onTapEvent;
  final List<ScheduledEvent> todayPlan;
  final double completionProgress;
  final int tasksCompletedToday;
  final int focusMinutesToday;
  final Set<int> activeFocusEventIds;
  final Map<int, DateTime> activeFocusStartTimes;
  final Future<void> Function(AppEvent event) onToggleFocus;
  final VoidCallback onAddEvent;
  final VoidCallback onOpenCalendar;

  const HomeScreen({
    super.key,
    required this.events,
    required this.profile,
    required this.onTapEvent,
    required this.todayPlan,
    required this.completionProgress,
    required this.tasksCompletedToday,
    required this.focusMinutesToday,
    required this.activeFocusEventIds,
    required this.activeFocusStartTimes,
    required this.onToggleFocus,
    required this.onAddEvent,
    required this.onOpenCalendar,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeFocusEventIds.length != widget.activeFocusEventIds.length) {
      _syncTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEvents = widget.events.where((e) => _sameDay(e.date, today)).toList();
    final conflictKeys = _findConflicts(todayEvents);
    final reminderCount = todayEvents.where((e) => e.reminder && !e.completed).length;
    final profileTime = _profileTime(now);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ModeSwitch(
                  labels: const ['Today', 'Calendar'],
                  selected: 0,
                  onSelected: (v) {
                    if (v == 1) {
                      widget.onOpenCalendar();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              InkResponse(
                onTap: widget.onAddEvent,
                radius: 24,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat.EEEE().format(today), style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormat('d.MM').format(today)}\n${DateFormat.MMM().format(today).toUpperCase()}',
                      style: const TextStyle(fontSize: 56, height: .85, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _timeTile(DateFormat.jm().format(now), 'Local time'),
                  if (profileTime != null) ...[
                    const SizedBox(height: 8),
                    _timeTile(
                      DateFormat.jm().format(profileTime),
                      widget.profile?.city.isNotEmpty == true ? widget.profile!.city : 'Profile time',
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text('Today\'s tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  reminderCount == 0 ? 'Reminders' : 'Reminders $reminderCount',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (todayEvents.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Text('No tasks for today. Tap + to create one.'),
            )
          else
            ...todayEvents
                .map((e) => EventCard(event: e, onTap: () => widget.onTapEvent(e), showConflict: conflictKeys.contains(e.instanceKey))),
          const SizedBox(height: 16),
          const Text('Today\'s Plan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: widget.completionProgress),
                  const SizedBox(height: 8),
                  Text(
                    'Completed: ${widget.tasksCompletedToday} - Focus: ${widget.focusMinutesToday} mins',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          if (widget.activeFocusStartTimes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Active Focus', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ..._activeFocusTiles(now),
                  ],
                ),
              ),
            ),
          ],
          if (widget.todayPlan.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No incomplete tasks to auto-plan today.'),
            )
          else
            ...widget.todayPlan.map((entry) {
              final event = entry.event;
              final active = event.id != null && widget.activeFocusEventIds.contains(event.id);
              return Card(
                child: ListTile(
                  title: Text(event.title),
                  subtitle: Text(
                    '${DateFormat.Hm().format(entry.start)} - ${DateFormat.Hm().format(entry.end)}  (${event.effectiveDurationMinutes}m)',
                  ),
                  trailing: event.completed
                      ? const Chip(label: Text('Done'))
                      : active
                          ? const Chip(label: Text('Focusing'))
                          : FilledButton.tonal(
                              onPressed: event.id == null ? null : () => widget.onToggleFocus(event),
                              child: const Text('Focus'),
                            ),
                ),
              );
            }),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Set<String> _findConflicts(List<AppEvent> events) {
    final conflicts = <String>{};
    final byDay = <String, List<AppEvent>>{};
    for (final e in events) {
      final key = '${e.date.year}-${e.date.month}-${e.date.day}';
      byDay.putIfAbsent(key, () => []).add(e);
    }
    for (final dayEvents in byDay.values) {
      dayEvents.sort((a, b) {
        final am = a.start.hour * 60 + a.start.minute;
        final bm = b.start.hour * 60 + b.start.minute;
        return am.compareTo(bm);
      });
      for (var i = 0; i < dayEvents.length; i++) {
        final a = dayEvents[i];
        final aStart = a.start.hour * 60 + a.start.minute;
        final aEnd = a.end.hour * 60 + a.end.minute;
        for (var j = i + 1; j < dayEvents.length; j++) {
          final b = dayEvents[j];
          final bStart = b.start.hour * 60 + b.start.minute;
          if (bStart >= aEnd) break;
          final bEnd = b.end.hour * 60 + b.end.minute;
          if (aStart < bEnd && aEnd > bStart) {
            conflicts.add(a.instanceKey);
            conflicts.add(b.instanceKey);
          }
        }
      }
    }
    return conflicts;
  }

  void _syncTicker() {
    if (widget.activeFocusStartTimes.isEmpty) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  DateTime? _profileTime(DateTime now) {
    final profile = widget.profile;
    if (profile == null) return null;
    final offset = _parseGmtOffset(profile.timezone);
    if (offset == null) return null;
    final deviceOffset = now.timeZoneOffset.inHours;
    if (deviceOffset == offset) return null;
    return now.toUtc().add(Duration(hours: offset));
  }

  int? _parseGmtOffset(String tz) {
    final match = RegExp(r'^GMT([+-])(\d{1,2})$').firstMatch(tz.trim());
    if (match == null) return null;
    final sign = match.group(1) == '-' ? -1 : 1;
    final hours = int.tryParse(match.group(2) ?? '');
    if (hours == null || hours > 14) return null;
    return sign * hours;
  }

  Widget _timeTile(String time, String label) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  List<Widget> _activeFocusTiles(DateTime now) {
    final activeIds = widget.activeFocusStartTimes.keys.toList();
    return activeIds.map((eventId) {
      final event = widget.events.firstWhere(
        (e) => e.id == eventId,
        orElse: () => AppEvent(
          id: eventId,
          title: 'Focus Session',
          date: DateTime.now(),
          start: const TimeOfDay(hour: 9, minute: 0),
          end: const TimeOfDay(hour: 10, minute: 0),
          location: 'Unspecified location',
          attendees: const ['ME'],
          colorValue: Colors.black.value,
          reminder: false,
          durationMinutes: 30,
        ),
      );
      final start = widget.activeFocusStartTimes[eventId] ?? now;
      final elapsed = now.difference(start).inMinutes <= 0 ? 1 : now.difference(start).inMinutes;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(event.title),
        subtitle: Text('Focus running for ${elapsed}m'),
        trailing: FilledButton.tonal(
          onPressed: () => widget.onToggleFocus(event),
          child: const Text('Stop'),
        ),
      );
    }).toList();
  }
}


