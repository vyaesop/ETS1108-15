import 'package:flutter/material.dart';

import '../mock_data.dart';
import '../models/app_models.dart';

class MonthOverviewScreen extends StatefulWidget {
  final ValueChanged<int> onMonthTap;
  final VoidCallback onJumpToday;
  final List<AppEvent> events;

  const MonthOverviewScreen({
    super.key,
    required this.onMonthTap,
    required this.onJumpToday,
    required this.events,
  });

  @override
  State<MonthOverviewScreen> createState() => _MonthOverviewScreenState();
}

class _MonthOverviewScreenState extends State<MonthOverviewScreen> {
  final ctrl = TextEditingController();

  static const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = ctrl.text.trim().toLowerCase();
    final monthIndexes = List<int>.generate(12, (i) => i).where((i) {
      if (q.isEmpty) return true;
      final monthMatch = months[i].toLowerCase().contains(q);
      final eventMatch = widget.events.any(
        (e) => e.date.month == i + 1 && e.title.toLowerCase().contains(q),
      );
      return monthMatch || eventMatch;
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Tooltip(
                  message: 'Jump to today view',
                  child: IconButton.filledTonal(onPressed: widget.onJumpToday, icon: const Icon(Icons.today)),
                ),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search month or event',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: ctrl.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => setState(ctrl.clear),
                              icon: const Icon(Icons.close),
                            ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: monthIndexes.isEmpty
                  ? const Center(child: Text('No months match your search.'))
                  : GridView.builder(
                      itemCount: monthIndexes.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.08,
                      ),
                      itemBuilder: (context, idx) {
                        final index = monthIndexes[idx];
                        final color = MockData.monthPalette[index];
                        final count = widget.events.where((e) => e.date.month == index + 1).length;
                        final year = DateTime.now().year;
                        return InkWell(
                          onTap: () => widget.onMonthTap(index),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(months[index], style: TextStyle(color: Colors.white.withOpacity(.95), fontWeight: FontWeight.w600)),
                                          Text('$year', style: TextStyle(color: Colors.white.withOpacity(.8), fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    if (count > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _MiniCalendar(
                                  color: Colors.white.withOpacity(.85),
                                  highlightDensity: count,
                                  monthIndex: index,
                                  year: year,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCalendar extends StatelessWidget {
  final Color color;
  final int highlightDensity;
  final int monthIndex;
  final int year;

  const _MiniCalendar({
    required this.color,
    required this.highlightDensity,
    required this.monthIndex,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final month = monthIndex + 1;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startIndex = firstDay.weekday % 7;
    final highlightedDays = highlightDensity.clamp(0, daysInMonth);
    return Expanded(
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: 'SMTWTFS'.split('').map((e) => Text(e, style: TextStyle(color: color, fontSize: 9))).toList()),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemBuilder: (_, index) {
                final dayNumber = index - startIndex + 1;
                final validDay = dayNumber >= 1 && dayNumber <= daysInMonth;
                final day = validDay ? '$dayNumber' : '';
                final highlighted = validDay && dayNumber <= highlightedDays;
                return Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: highlighted ? Colors.white.withOpacity(0.35) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      day,
                      style: TextStyle(fontSize: 8, color: color),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
