import 'package:flutter/material.dart';

import '../models/app_models.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({
    super.key,
    this.initial,
    this.initialDate,
    required this.existingEvents,
  });

  final AppEvent? initial;
  final DateTime? initialDate;
  final List<AppEvent> existingEvents;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  late DateTime date;
  late TimeOfDay start;
  late TimeOfDay end;
  late bool reminder;
  late int colorValue;
  late bool completed;
  late bool allDay;
  late RecurrenceRule recurrenceRule;
  DateTime? recurrenceUntil;
  late _EventDraft _baseline;
  bool _syncing = false;

  final titleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final attendeesCtrl = TextEditingController();
  final durationCtrl = TextEditingController();

  final colors = const [
    Color(0xFFE8C47D),
    Color(0xFF9A6B72),
    Color(0xFFE16645),
    Color(0xFF8EC9CB),
    Color(0xFFB2AEDF),
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    date = initial?.date ?? widget.initialDate ?? DateTime.now();
    start = initial?.start ?? const TimeOfDay(hour: 9, minute: 0);
    end = initial?.end ?? const TimeOfDay(hour: 10, minute: 0);
    reminder = initial?.reminder ?? true;
    colorValue = initial?.colorValue ?? const Color(0xFFE8C47D).value;
    completed = initial?.completed ?? false;
    allDay = initial?.allDay ?? false;
    recurrenceRule = initial?.recurrenceRule ?? RecurrenceRule.none;
    recurrenceUntil = initial?.recurrenceUntil;
    titleCtrl.text = initial?.title ?? '';
    locationCtrl.text = initial?.location ?? '';
    attendeesCtrl.text = initial == null ? 'ME' : initial.attendees.join(', ');
    durationCtrl.text = (initial?.durationMinutes ?? 30).toString();
    durationCtrl.addListener(_onDurationChanged);
    if (allDay) {
      _applyAllDayDefaults();
    } else {
      _syncDurationFromTime();
    }
    _baseline = _snapshot();
  }

  @override
  void dispose() {
    durationCtrl.removeListener(_onDurationChanged);
    titleCtrl.dispose();
    locationCtrl.dispose();
    attendeesCtrl.dispose();
    durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final isOccurrence = widget.initial?.isOccurrence ?? false;

    return WillPopScope(
      onWillPop: _confirmDiscardIfNeeded,
      child: Scaffold(
        appBar: AppBar(title: Text(isEdit ? 'Edit Event' : 'Create Event')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          if (isOccurrence)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Editing this event will update the whole series.', style: TextStyle(color: Colors.black54)),
            ),
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
          const SizedBox(height: 10),
          TextField(controller: attendeesCtrl, decoration: const InputDecoration(labelText: 'Attendees (comma separated initials)')),
          const SizedBox(height: 10),
          TextField(
            controller: durationCtrl,
            keyboardType: TextInputType.number,
            enabled: !allDay,
            decoration: const InputDecoration(labelText: 'Estimated duration (minutes)'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: allDay,
            onChanged: (v) {
              setState(() {
                allDay = v;
                if (allDay) {
                  _applyAllDayDefaults();
                } else {
                  _syncEndFromDuration();
                }
              });
            },
            title: const Text('All-day'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text('${date.year}-${date.month}-${date.day}'),
            trailing: const Icon(Icons.calendar_month),
            onTap: isOccurrence
                ? null
                : () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                  initialDate: date,
                );
                if (picked != null) setState(() => date = picked);
              },
          ),
          _timeTile(
            label: 'Start',
            value: start,
            onPick: allDay
                ? null
                : () async {
                    final picked = await showTimePicker(context: context, initialTime: start);
                    if (picked != null) {
                      setState(() {
                        start = picked;
                        _syncEndFromDuration();
                      });
                    }
                  },
          ),
          _timeTile(
            label: 'End',
            value: end,
            onPick: allDay
                ? null
                : () async {
                    final picked = await showTimePicker(context: context, initialTime: end);
                    if (picked != null) {
                      setState(() {
                        end = picked;
                        _syncDurationFromTime();
                      });
                    }
                  },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<RecurrenceRule>(
            value: recurrenceRule,
            decoration: const InputDecoration(labelText: 'Repeat'),
            items: RecurrenceRule.values
                .map(
                  (rule) => DropdownMenuItem(
                    value: rule,
                    child: Text(_recurrenceLabel(rule)),
                  ),
                )
                .toList(),
            onChanged: isOccurrence
                ? null
                : (rule) => setState(() {
                      recurrenceRule = rule ?? RecurrenceRule.none;
                      if (recurrenceRule == RecurrenceRule.none) {
                        recurrenceUntil = null;
                      }
                    }),
          ),
          if (recurrenceRule == RecurrenceRule.none) ...[
            const SizedBox(height: 4),
            if (recurrenceUntil != null)
              TextButton(
                onPressed: () => setState(() => recurrenceUntil = null),
                child: const Text('Clear end date'),
              ),
          ],
          if (recurrenceRule != RecurrenceRule.none)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Repeat until'),
              subtitle: Text(recurrenceUntil == null ? 'No end date' : '${recurrenceUntil!.year}-${recurrenceUntil!.month}-${recurrenceUntil!.day}'),
              trailing: const Icon(Icons.event_repeat),
              onTap: isOccurrence
                  ? null
                  : () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: date,
                  lastDate: DateTime(date.year + 5),
                  initialDate: recurrenceUntil ?? date,
                );
                if (picked != null) setState(() => recurrenceUntil = picked);
                },
            ),
          const SizedBox(height: 12),
          const Text('Color'),
          Wrap(
            spacing: 8,
            children: colors
                .map(
                  (c) => InkWell(
                    onTap: () => setState(() => colorValue = c.value),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: c,
                      child: colorValue == c.value ? const Icon(Icons.check, size: 16) : null,
                    ),
                  ),
                )
                .toList(),
          ),
          SwitchListTile(
            value: reminder,
            onChanged: (v) => setState(() => reminder = v),
            title: const Text('Enable reminder'),
          ),
          SwitchListTile(
            value: completed,
            onChanged: (v) => setState(() => completed = v),
            title: const Text('Mark as completed'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required.')));
                return;
              }

              final parsedDuration = allDay ? 24 * 60 : (int.tryParse(durationCtrl.text.trim()) ?? 30);
              if (parsedDuration <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Duration must be a positive number.')),
                );
                return;
              }

              if (!allDay) {
                final startMinutes = start.hour * 60 + start.minute;
                final endMinutes = end.hour * 60 + end.minute;
                if (endMinutes <= startMinutes) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('End time must be after start time.')),
                  );
                  return;
                }
                final expectedDuration = endMinutes - startMinutes;
                if (parsedDuration != expectedDuration) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Duration must match start/end time (${expectedDuration}m).')),
                  );
                  return;
                }
              }

              final conflicts = _findConflicts();
              if (conflicts.isNotEmpty) {
                final proceed = await _confirmConflicts(conflicts);
                if (!proceed) return;
              }

              Navigator.pop(
                context,
                AppEvent(
                  id: widget.initial?.id,
                  title: title,
                  start: start,
                  end: end,
                  location: locationCtrl.text.trim().isEmpty ? 'Unspecified location' : locationCtrl.text.trim(),
                  attendees: attendeesCtrl.text.trim().isEmpty
                      ? const ['ME']
                      : attendeesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  colorValue: colorValue,
                  date: date,
                  reminder: reminder,
                  durationMinutes: parsedDuration,
                  completed: completed,
                  allDay: allDay,
                  recurrenceRule: recurrenceRule,
                  recurrenceUntil: recurrenceUntil,
                ),
              );
            },
            child: Text(isEdit ? 'Save Changes' : 'Save Event'),
          ),
          ],
        ),
      ),
    );
  }

  Widget _timeTile({required String label, required TimeOfDay value, required VoidCallback? onPick}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text('${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'),
      trailing: const Icon(Icons.schedule),
      onTap: onPick,
    );
  }

  void _syncDurationFromTime() {
    if (_syncing) return;
    if (allDay) return;
    _syncing = true;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final duration = endMinutes - startMinutes;
    if (duration > 0) {
      durationCtrl.text = duration.toString();
    }
    _syncing = false;
  }

  void _syncEndFromDuration() {
    if (_syncing) return;
    if (allDay) return;
    final duration = int.tryParse(durationCtrl.text.trim());
    if (duration == null || duration <= 0) return;
    _syncing = true;
    final startMinutes = start.hour * 60 + start.minute;
    var endMinutes = startMinutes + duration;
    if (endMinutes > 23 * 60 + 59) {
      endMinutes = 23 * 60 + 59;
      final clampedDuration = endMinutes - startMinutes;
      if (clampedDuration > 0) {
        durationCtrl.text = clampedDuration.toString();
      }
    }
    end = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
    _syncing = false;
  }

  void _onDurationChanged() {
    if (_syncing) return;
    if (allDay) return;
    final duration = int.tryParse(durationCtrl.text.trim());
    if (duration == null || duration <= 0) return;
    setState(_syncEndFromDuration);
  }

  _EventDraft _snapshot() {
    return _EventDraft(
      title: titleCtrl.text.trim(),
      location: locationCtrl.text.trim(),
      attendees: attendeesCtrl.text.trim(),
      duration: durationCtrl.text.trim(),
      date: DateTime(date.year, date.month, date.day),
      start: start,
      end: end,
      reminder: reminder,
      completed: completed,
      colorValue: colorValue,
      allDay: allDay,
      recurrenceRule: recurrenceRule,
      recurrenceUntil: recurrenceUntil,
    );
  }

  bool get _dirty => _snapshot() != _baseline;

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_dirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved edits. Leave without saving?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
        ],
      ),
    );
    return discard ?? false;
  }

  List<AppEvent> _findConflicts() {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final day = DateTime(date.year, date.month, date.day);
    return widget.existingEvents.where((e) {
      if (widget.initial?.id != null && e.id == widget.initial!.id) return false;
      final sameDay = e.date.year == day.year && e.date.month == day.month && e.date.day == day.day;
      if (!sameDay) return false;
      final eStart = e.start.hour * 60 + e.start.minute;
      final eEnd = e.end.hour * 60 + e.end.minute;
      return startMinutes < eEnd && endMinutes > eStart;
    }).toList();
  }

  Future<bool> _confirmConflicts(List<AppEvent> conflicts) async {
    final names = conflicts.take(3).map((e) => e.title).join(', ');
    final extra = conflicts.length > 3 ? ' +${conflicts.length - 3} more' : '';
    final message = 'Overlaps with ${conflicts.length} event${conflicts.length == 1 ? '' : 's'}: $names$extra.';
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Time conflict'),
        content: Text('$message\nSave anyway?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Review')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save anyway')),
        ],
      ),
    );
    return proceed ?? false;
  }

  void _applyAllDayDefaults() {
    start = const TimeOfDay(hour: 0, minute: 0);
    end = const TimeOfDay(hour: 23, minute: 59);
    durationCtrl.text = (24 * 60).toString();
  }

  String _recurrenceLabel(RecurrenceRule rule) {
    return switch (rule) {
      RecurrenceRule.none => 'Does not repeat',
      RecurrenceRule.daily => 'Daily',
      RecurrenceRule.weekly => 'Weekly',
      RecurrenceRule.monthly => 'Monthly',
    };
  }
}

class _EventDraft {
  final String title;
  final String location;
  final String attendees;
  final String duration;
  final DateTime date;
  final TimeOfDay start;
  final TimeOfDay end;
  final bool reminder;
  final bool completed;
  final int colorValue;
  final bool allDay;
  final RecurrenceRule recurrenceRule;
  final DateTime? recurrenceUntil;

  const _EventDraft({
    required this.title,
    required this.location,
    required this.attendees,
    required this.duration,
    required this.date,
    required this.start,
    required this.end,
    required this.reminder,
    required this.completed,
    required this.colorValue,
    required this.allDay,
    required this.recurrenceRule,
    required this.recurrenceUntil,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _EventDraft &&
        other.title == title &&
        other.location == location &&
        other.attendees == attendees &&
        other.duration == duration &&
        other.date == date &&
        other.start == start &&
        other.end == end &&
        other.reminder == reminder &&
        other.completed == completed &&
        other.colorValue == colorValue &&
        other.allDay == allDay &&
        other.recurrenceRule == recurrenceRule &&
        other.recurrenceUntil == recurrenceUntil;
  }

  @override
  int get hashCode => Object.hash(
        title,
        location,
        attendees,
        duration,
        date,
        start,
        end,
        reminder,
        completed,
        colorValue,
        allDay,
        recurrenceRule,
        recurrenceUntil,
      );
}
