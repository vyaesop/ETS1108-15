import 'package:flutter/material.dart';

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
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(labels[index]),
            selected: active,
            showCheckmark: false,
            side: BorderSide(color: active ? Colors.transparent : Colors.grey.shade300),
            selectedColor: Colors.black,
            labelStyle: TextStyle(color: active ? Colors.white : Colors.black87),
            onSelected: (_) => onSelected(index),
          ),
        );
      }),
    );
  }
}

class EventCard extends StatelessWidget {
  final AppEvent event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = event.color.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: event.color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(fontSize: 32, height: 1, color: textColor, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(_fmtTime(event.start), style: TextStyle(color: textColor.withOpacity(0.85))),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: textColor.withOpacity(0.9)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(event.location, style: TextStyle(color: textColor.withOpacity(0.9))),
                ),
                ...event.attendees.take(3).map((a) => Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.5)),
                      ),
                      alignment: Alignment.center,
                      child: Text(a, style: TextStyle(fontSize: 9, color: textColor)),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(TimeOfDay value) {
    final h = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final m = value.minute.toString().padLeft(2, '0');
    final p = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }
}
