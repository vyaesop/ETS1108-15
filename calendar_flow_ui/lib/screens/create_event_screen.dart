import 'package:flutter/material.dart';

import '../models/app_models.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key, this.initial});

  final AppEvent? initial;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  late DateTime date;
  late TimeOfDay start;
  late TimeOfDay end;
  late bool reminder;
  late int colorValue;

  final titleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final attendeesCtrl = TextEditingController();

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
    date = initial?.date ?? DateTime.now();
    start = initial?.start ?? const TimeOfDay(hour: 9, minute: 0);
    end = initial?.end ?? const TimeOfDay(hour: 10, minute: 0);
    reminder = initial?.reminder ?? true;
    colorValue = initial?.colorValue ?? const Color(0xFFE8C47D).value;
    titleCtrl.text = initial?.title ?? '';
    locationCtrl.text = initial?.location ?? '';
    attendeesCtrl.text = initial == null ? 'ME' : initial.attendees.join(', ');
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    locationCtrl.dispose();
    attendeesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Event' : 'Create Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
          const SizedBox(height: 10),
          TextField(controller: attendeesCtrl, decoration: const InputDecoration(labelText: 'Attendees (comma separated initials)')),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text('${date.year}-${date.month}-${date.day}'),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
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
            onPick: () async {
              final picked = await showTimePicker(context: context, initialTime: start);
              if (picked != null) setState(() => start = picked);
            },
          ),
          _timeTile(
            label: 'End',
            value: end,
            onPick: () async {
              final picked = await showTimePicker(context: context, initialTime: end);
              if (picked != null) setState(() => end = picked);
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
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required.')));
                return;
              }

              final startMinutes = start.hour * 60 + start.minute;
              final endMinutes = end.hour * 60 + end.minute;
              if (endMinutes <= startMinutes) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('End time must be after start time.')),
                );
                return;
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
                ),
              );
            },
            child: Text(isEdit ? 'Save Changes' : 'Save Event'),
          ),
        ],
      ),
    );
  }

  Widget _timeTile({required String label, required TimeOfDay value, required VoidCallback onPick}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text('${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'),
      trailing: const Icon(Icons.schedule),
      onTap: onPick,
    );
  }
}
