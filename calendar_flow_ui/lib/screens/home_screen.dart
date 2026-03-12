import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  final List<AppEvent> events;
  final ValueChanged<AppEvent> onTapEvent;
  final VoidCallback onCreate;
  final VoidCallback onOpenSearch;

  const HomeScreen({
    super.key,
    required this.events,
    required this.onTapEvent,
    required this.onCreate,
    required this.onOpenSearch,
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
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
