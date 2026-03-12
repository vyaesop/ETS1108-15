import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/common_widgets.dart';

class CalendarBoardScreen extends StatefulWidget {
  final List<AppEvent> events;
  final ValueChanged<AppEvent> onTapEvent;
  final ValueChanged<DateTime>? onCreateForDate;
  final int initialMode;
  final int initialMonthOffset;

  const CalendarBoardScreen({
    super.key,
    required this.events,
    required this.onTapEvent,
    this.onCreateForDate,
    this.initialMode = 1,
    this.initialMonthOffset = 0,
  });

  @override
  State<CalendarBoardScreen> createState() => _CalendarBoardScreenState();
}

class _CalendarBoardScreenState extends State<CalendarBoardScreen> {
  late int mode;
  late int monthOffset;

  @override
  void initState() {
    super.initState();
    mode = widget.initialMode;
    monthOffset = widget.initialMonthOffset;
  }

  @override
  void didUpdateWidget(covariant CalendarBoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMonthOffset != widget.initialMonthOffset) {
      monthOffset = widget.initialMonthOffset;
    }
    if (oldWidget.initialMode != widget.initialMode) {
      mode = widget.initialMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedMonth = DateTime(now.year, now.month + monthOffset, 1);

    final filtered = switch (mode) {
      0 => widget.events.where((e) => _sameDay(e.date, today)).toList(),
      1 => widget.events.where((e) => e.date.year == selectedMonth.year && e.date.month == selectedMonth.month).toList(),
      _ => widget.events,
    };

    final grouped = <DateTime, List<AppEvent>>{};
    for (final e in filtered) {
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
            ],
          ),
          const SizedBox(height: 14),
          if (mode == 1)
            Row(
              children: [
                IconButton(onPressed: () => setState(() => monthOffset -= 1), icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Center(
                    child: Text(
                      _monthLabel(selectedMonth),
                      style: const TextStyle(fontSize: 30, color: Colors.black54, letterSpacing: 1.1),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Jump to today',
                  onPressed: () => setState(() => monthOffset = 0),
                  icon: const Icon(Icons.today),
                ),
                IconButton(onPressed: () => setState(() => monthOffset += 1), icon: const Icon(Icons.chevron_right)),
              ],
            )
          else
            const Center(
              child: Text('Agenda', style: TextStyle(fontSize: 30, color: Colors.black45, letterSpacing: 1.1)),
            ),
          const SizedBox(height: 8),
          if (days.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(mode == 1 ? 'No events in this month.' : 'No events in this time window.'),
              ),
            )
          else
            ...days.map((day) {
              final dayEvents = grouped[day]!;
              final firstColor = dayEvents.first.color.withOpacity(.9);
              return InkWell(
                onTap: () => _openDaySheet(day, dayEvents),
                borderRadius: BorderRadius.circular(22),
                child: Container(
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
                                    label: Text('${_timeLabel(e)}  ${e.title}', style: const TextStyle(color: Colors.white)),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _weekday(DateTime d) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
  String _month(DateTime d) => ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][d.month - 1];
  String _fmt(TimeOfDay t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
  String _monthLabel(DateTime d) => '${_month(d)} ${d.year}';
  String _timeLabel(AppEvent event) => event.allDay ? 'ALL DAY' : _fmt(event.start);

  Future<void> _openDaySheet(DateTime day, List<AppEvent> dayEvents) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${day.day} ${_month(day)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (dayEvents.isEmpty)
                const Text('No events for this day.')
              else
                ...dayEvents.map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.title),
                    subtitle: Text(e.allDay ? 'All day' : '${_fmt(e.start)} - ${_fmt(e.end)}'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onTapEvent(e);
                    },
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: widget.onCreateForDate == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          widget.onCreateForDate!(day);
                        },
                  child: const Text('Create event on this day'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
