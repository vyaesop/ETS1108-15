import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import '../services/daily_planner.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  final List<AppEvent> events;
  final ValueChanged<AppEvent> onTapEvent;
  final VoidCallback onCreate;
  final VoidCallback onOpenSearch;
  final List<ScheduledEvent> todayPlan;
  final double completionProgress;
  final int tasksCompletedToday;
  final int focusMinutesToday;
  final Set<int> activeFocusEventIds;
  final Future<void> Function(AppEvent event, bool completed) onToggleCompleted;
  final Future<void> Function(AppEvent event) onToggleFocus;

  const HomeScreen({
    super.key,
    required this.events,
    required this.onTapEvent,
    required this.onCreate,
    required this.onOpenSearch,
    required this.todayPlan,
    required this.completionProgress,
    required this.tasksCompletedToday,
    required this.focusMinutesToday,
    required this.activeFocusEventIds,
    required this.onToggleCompleted,
    required this.onToggleFocus,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int mode = 0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final shown = switch (mode) {
      0 => widget.events.where((e) => _sameDay(e.date, today)).toList(),
      1 => widget.events.where((e) => _sameDay(e.date, tomorrow)).toList(),
      _ => widget.events,
    };

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good Morning, Aditya 👋', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Have a great day!', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              IconButton(onPressed: widget.onOpenSearch, icon: const Icon(Icons.search)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ModeSwitch(
                  labels: const ['Today', 'Tomorrow', 'All'],
                  selected: mode,
                  onSelected: (v) => setState(() => mode = v),
                ),
              ),
              IconButton.filledTonal(onPressed: widget.onCreate, icon: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${DateFormat.d().format(today)}\n${DateFormat.MMMM().format(today).toUpperCase()}',
                  style: const TextStyle(fontSize: 54, height: .9, fontWeight: FontWeight.w600),
                ),
              ),
              Container(width: 1, height: 70, color: Colors.black26),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat.Hm().format(now), style: const TextStyle(fontSize: 32)),
                  const Text('Local time', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Text('No tasks for this filter. Tap + to create one.'),
            )
          else
            ...shown.map((e) => EventCard(event: e, onTap: () => widget.onTapEvent(e))),
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
                    'Completed: ${widget.tasksCompletedToday} • Focus: ${widget.focusMinutesToday} mins',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
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
                  leading: Checkbox(
                    value: event.completed,
                    onChanged: (v) {
                      if (v == null) return;
                      widget.onToggleCompleted(event, v);
                    },
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    '${DateFormat.Hm().format(entry.start)} - ${DateFormat.Hm().format(entry.end)}  (${event.effectiveDurationMinutes}m)',
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: event.id == null ? null : () => widget.onToggleFocus(event),
                    child: Text(active ? 'Stop' : 'Focus'),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
