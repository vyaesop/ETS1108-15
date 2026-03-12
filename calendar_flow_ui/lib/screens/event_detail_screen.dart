import 'package:flutter/material.dart';

import '../models/app_models.dart';

class EventDetailScreen extends StatelessWidget {
  final AppEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final txt = event.color.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;
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
              decoration: BoxDecoration(color: event.color, borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(event.title, style: TextStyle(fontSize: 36, height: 1, color: txt, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text('${_fmt(event.start)} - ${_fmt(event.end)}', style: TextStyle(color: txt)),
                const SizedBox(height: 6),
                Text(event.location, style: TextStyle(color: txt.withOpacity(.9))),
              ]),
            ),
            const SizedBox(height: 18),
            const Text('Attendees', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: event.attendees.map((e) => Chip(label: Text(e))).toList(),
            ),
            const SizedBox(height: 20),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Reminder'),
              subtitle: Text('15 minutes before start'),
              trailing: Icon(Icons.notifications_active_outlined),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Meeting Link'),
              subtitle: Text('meet.chrono.app/...'),
              trailing: Icon(Icons.link),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit), label: const Text('Edit')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.done),
                    label: const Text('Done'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _fmt(TimeOfDay value) {
    final h = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final m = value.minute.toString().padLeft(2, '0');
    final p = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }
}
