import 'package:flutter/material.dart';

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
    final today = DateTime.now();
    final shown = mode == 0
        ? widget.events.where((e) => _sameDay(e.date, today)).toList()
        : mode == 1
            ? widget.events.where((e) => e.date.isAfter(today.subtract(const Duration(days: 1)))).toList()
            : widget.events;

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
              const Expanded(
                child: Text('25\nJANUARY', style: TextStyle(fontSize: 54, height: .9, fontWeight: FontWeight.w600)),
              ),
              Container(width: 1, height: 70, color: Colors.black26),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('08.00', style: TextStyle(fontSize: 32)),
                  Text('Indonesia', style: TextStyle(color: Colors.black54)),
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
