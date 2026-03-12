import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import 'create_event_screen.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.event,
    required this.existingEvents,
    required this.onDelete,
    required this.onSave,
    required this.onToggleCompleted,
  });

  final AppEvent event;
  final List<AppEvent> existingEvents;
  final Future<void> Function() onDelete;
  final Future<void> Function(AppEvent event) onSave;
  final Future<void> Function(AppEvent event, bool completed) onToggleCompleted;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late AppEvent current;

  @override
  void initState() {
    super.initState();
    current = widget.event;
  }

  @override
  Widget build(BuildContext context) {
    final txt = current.color.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: current.color, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(current.title, style: TextStyle(fontSize: 36, height: 1, color: txt, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Text(current.allDay ? 'All day' : '${_fmt(current.start)} - ${_fmt(current.end)}', style: TextStyle(color: txt)),
                  const SizedBox(height: 6),
                  Text(DateFormat.yMMMMd().format(current.date), style: TextStyle(color: txt.withOpacity(.9))),
                  Text(current.location, style: TextStyle(color: txt.withOpacity(.9))),
                  if (current.isOccurrence) ...[
                    const SizedBox(height: 8),
                    Text('Part of a repeating series', style: TextStyle(color: txt.withOpacity(.9), fontSize: 12)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Attendees', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: current.attendees.map((e) => Chip(label: Text(e))).toList()),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reminder'),
              subtitle: Text(current.reminder ? 'Enabled (15 minutes before)' : 'Disabled'),
              value: current.reminder,
              onChanged: (value) => _toggleReminder(value),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Repeat'),
              subtitle: Text(_recurrenceLabel(current.recurrenceRule, current.recurrenceUntil)),
              trailing: Icon(current.recurrenceRule == RecurrenceRule.none ? Icons.repeat : Icons.repeat_on),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Duration'),
              subtitle: Text(current.allDay ? 'All day' : '${current.effectiveDurationMinutes} minutes'),
              trailing: Icon(current.completed ? Icons.check_circle : Icons.radio_button_unchecked),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Storage'),
              subtitle: Text('Stored locally on this device'),
              trailing: Icon(Icons.storage_outlined),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _editEvent,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _toggleCompleted,
                    icon: Icon(current.completed ? Icons.undo : Icons.check),
                    label: Text(current.completed ? 'Undo' : 'Complete'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                    onPressed: _deleteEvent,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _editEvent() async {
    final edited = await Navigator.of(context).push<AppEvent>(
      MaterialPageRoute(builder: (_) => CreateEventScreen(initial: current, existingEvents: widget.existingEvents)),
    );
    if (edited == null) return;

    await widget.onSave(edited);
    if (!mounted) return;
    setState(() => current = edited);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event updated.')));
  }


  Future<void> _toggleReminder(bool value) async {
    final updated = current.copyWith(reminder: value);
    await widget.onSave(updated);
    if (!mounted) return;
    setState(() => current = updated);
  }

  Future<void> _toggleCompleted() async {
    final next = !current.completed;
    await widget.onToggleCompleted(current, next);
    if (!mounted) return;
    setState(() => current = current.copyWith(completed: next));
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this event?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;
    await widget.onDelete();
    if (!mounted) return;
    Navigator.pop(context, EventDetailResult.deleted(current.copyWith(id: null)));
  }

  String _fmt(TimeOfDay value) {
    final h = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final m = value.minute.toString().padLeft(2, '0');
    final p = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  String _recurrenceLabel(RecurrenceRule rule, DateTime? until) {
    final base = switch (rule) {
      RecurrenceRule.none => 'Does not repeat',
      RecurrenceRule.daily => 'Daily',
      RecurrenceRule.weekly => 'Weekly',
      RecurrenceRule.monthly => 'Monthly',
    };
    if (rule == RecurrenceRule.none) return base;
    if (until == null) return '$base, no end date';
    return '$base until ${DateFormat.yMMMd().format(until)}';
  }
}

class EventDetailResult {
  final AppEvent? deletedEvent;

  const EventDetailResult._({this.deletedEvent});

  factory EventDetailResult.deleted(AppEvent event) => EventDetailResult._(deletedEvent: event);
}
