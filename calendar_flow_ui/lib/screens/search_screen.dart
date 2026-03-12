import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/common_widgets.dart';

class SearchScreen extends StatefulWidget {
  final List<AppEvent> events;
  final ValueChanged<AppEvent> onTapEvent;

  const SearchScreen({super.key, required this.events, required this.onTapEvent});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ctrl = TextEditingController();
  bool reminderOnly = false;
  bool incompleteOnly = false;
  DateTimeRange? range;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = ctrl.text.trim().toLowerCase();
    final results = widget.events.where((e) {
      final textMatch = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.location.toLowerCase().contains(q) ||
          e.attendees.any((a) => a.toLowerCase().contains(q));
      final reminderMatch = !reminderOnly || e.reminder;
      final incompleteMatch = !incompleteOnly || !e.completed;
      final dateMatch = range == null ||
          (!_normalize(e.date).isBefore(_normalize(range!.start)) && !_normalize(e.date).isAfter(_normalize(range!.end)));
      return textMatch && reminderMatch && dateMatch && incompleteMatch;
    }).toList()
      ..sort((a, b) {
        final dateSort = a.date.compareTo(b.date);
        if (dateSort != 0) return dateSort;
        return (a.start.hour * 60 + a.start.minute).compareTo(b.start.hour * 60 + b.start.minute);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Search & Filters')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: 'Meeting, lunch, location, attendee...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(onPressed: () => setState(ctrl.clear), icon: const Icon(Icons.close)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                selected: reminderOnly,
                label: const Text('Reminders only'),
                onSelected: (v) => setState(() => reminderOnly = v),
              ),
              FilterChip(
                selected: incompleteOnly,
                label: const Text('Incomplete only'),
                onSelected: (v) => setState(() => incompleteOnly = v),
              ),
              FilterChip(
                selected: range != null,
                label: Text(range == null ? 'Date range' : '${range!.start.month}/${range!.start.day} - ${range!.end.month}/${range!.end.day}'),
                onSelected: (_) async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 2),
                    lastDate: DateTime(now.year + 2),
                    initialDateRange: range,
                  );
                  if (picked != null) setState(() => range = picked);
                },
              ),
              ActionChip(
                onPressed: () => setState(() {
                  ctrl.clear();
                  reminderOnly = false;
                  incompleteOnly = false;
                  range = null;
                }),
                label: const Text('Clear all'),
              ),
              if (range != null)
                ActionChip(
                  onPressed: () => setState(() => range = null),
                  label: const Text('Clear range'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (results.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No matching events found for the selected filters.'),
              ),
            )
          else
            ...results.map((e) => EventCard(event: e, onTap: () => widget.onTapEvent(e))),
        ],
      ),
    );
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}
