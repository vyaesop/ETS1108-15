import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';

class ModeSwitch extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  const ModeSwitch({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index == selected;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: active ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onSelected(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final AppEvent event;
  final VoidCallback? onTap;
  final bool showConflict;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.showConflict = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = event.color.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;
    final startLabel = event.allDay
        ? 'All day'
        : DateFormat.jm().format(DateTime(0, 1, 1, event.start.hour, event.start.minute));
    final endLabel = event.allDay
        ? ''
        : DateFormat.jm().format(DateTime(0, 1, 1, event.end.hour, event.end.minute));
    final durationLabel = event.allDay ? 'All day' : '${event.effectiveDurationMinutes} Min';
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: event.color,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(fontSize: 28, height: 1, color: textColor, fontWeight: FontWeight.w700),
                  ),
                ),
                if (event.attendees.isNotEmpty)
                  Row(
                    children: event.attendees.take(2).map((a) {
                      return Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.5)),
                        ),
                        alignment: Alignment.center,
                        child: Text(a, style: TextStyle(fontSize: 9, color: textColor)),
                      );
                    }).toList(),
                  ),
              ],
            ),
            if (event.location.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(event.location, style: TextStyle(color: textColor.withOpacity(0.85), fontSize: 12)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _timeColumn(label: 'Start', time: startLabel, textColor: textColor),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(durationLabel, style: TextStyle(color: textColor, fontSize: 11)),
                ),
                const Spacer(),
                _timeColumn(label: 'End', time: endLabel, textColor: textColor, hideTime: event.allDay),
              ],
            ),
            if (event.completed || showConflict || event.isRecurring) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (event.completed) _statusPill('Done', textColor),
                  if (showConflict) _statusPill('Conflict', textColor),
                  if (event.isRecurring) _statusPill('Repeats', textColor),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timeColumn({
    required String label,
    required String time,
    required Color textColor,
    bool hideTime = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          hideTime ? '-' : time,
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _statusPill(String label, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 11)),
    );
  }
}
