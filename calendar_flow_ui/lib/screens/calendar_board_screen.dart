import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/common_widgets.dart';

class CalendarBoardScreen extends StatefulWidget {
  final List<AppEvent> events;
  final ValueChanged<AppEvent> onTapEvent;
  final VoidCallback onCreate;

  const CalendarBoardScreen({
    super.key,
    required this.events,
    required this.onTapEvent,
    required this.onCreate,
  });

  @override
  State<CalendarBoardScreen> createState() => _CalendarBoardScreenState();
}

class _CalendarBoardScreenState extends State<CalendarBoardScreen> {
  int mode = 1;

  @override
  Widget build(BuildContext context) {
    final grouped = <DateTime, List<AppEvent>>{};
    for (final e in widget.events) {
      final k = DateTime(e.date.year, e.date.month, e.date.day);
      grouped.putIfAbsent(k, () => []).add(e);
    }
    final days = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ModeSwitch(
                  labels: const ['Today', 'Calendar', 'All'],
                  selected: mode,
                  onSelected: (v) => setState(() => mode = v),
                ),
              ),
              IconButton.filledTonal(onPressed: widget.onCreate, icon: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text('DEC   <  JAN  >  FEB', style: TextStyle(fontSize: 30, color: Colors.black45, letterSpacing: 1.1)),
          ),
          const SizedBox(height: 8),
          ...days.map((day) {
            final dayEvents = grouped[day]!;
            final firstColor = dayEvents.first.color.withOpacity(.9);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: firstColor, borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_weekday(day), style: const TextStyle(color: Colors.white)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${day.day}\n${_month(day)}', style: const TextStyle(color: Colors.white, fontSize: 44, height: .86)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          runSpacing: 8,
                          spacing: 8,
                          children: dayEvents
                              .map(
                                (e) => ActionChip(
                                  onPressed: () => widget.onTapEvent(e),
                                  backgroundColor: Colors.black26,
                                  side: BorderSide.none,
                                  label: Text('${_fmt(e.start)}  ${e.title}', style: const TextStyle(color: Colors.white)),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onCreate,
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _weekday(DateTime d) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
  String _month(DateTime d) => ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][d.month - 1];
  String _fmt(TimeOfDay t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
}
