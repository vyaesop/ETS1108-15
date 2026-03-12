import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import 'create_event_screen.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.event,
    required this.onDelete,
    required this.onSave,
  });

  final AppEvent event;
  final Future<void> Function() onDelete;
  final Future<void> Function(AppEvent event) onSave;

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
                  Text('${_fmt(current.start)} - ${_fmt(current.end)}', style: TextStyle(color: txt)),
                  const SizedBox(height: 6),
                  Text(DateFormat.yMMMMd().format(current.date), style: TextStyle(color: txt.withOpacity(.9))),
                  Text(current.location, style: TextStyle(color: txt.withOpacity(.9))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Attendees', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: current.attendees.map((e) => Chip(label: Text(e))).toList()),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reminder'),
              subtitle: Text(current.reminder ? 'Enabled (15 minutes before)' : 'Disabled'),
              trailing: Icon(current.reminder ? Icons.notifications_active_outlined : Icons.notifications_off_outlined),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Duration'),
              subtitle: Text('${current.effectiveDurationMinutes} minutes'),
              trailing: Icon(current.completed ? Icons.check_circle : Icons.radio_button_unchecked),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Storage'),
              subtitle: Text('Persisted in local SQLite database'),
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
                const SizedBox(width: 12),
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
      MaterialPageRoute(builder: (_) => CreateEventScreen(initial: current)),
    );
    if (edited == null) return;

    await widget.onSave(edited);
    if (!mounted) return;
    setState(() => current = edited);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event updated in SQLite.')));
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
    Navigator.pop(context);
  }

  String _fmt(TimeOfDay value) {
    final h = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final m = value.minute.toString().padLeft(2, '0');
    final p = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }
}
