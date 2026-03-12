import 'package:flutter/material.dart';

import '../models/app_models.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final draft = EventDraft();
  final titleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  final colors = const [
    Color(0xFFE8C47D),
    Color(0xFF9A6B72),
    Color(0xFFE16645),
    Color(0xFF8EC9CB),
    Color(0xFFB2AEDF),
  ];

  @override
  void dispose() {
    titleCtrl.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text('${draft.date.year}-${draft.date.month}-${draft.date.day}'),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
                initialDate: draft.date,
              );
              if (picked != null) setState(() => draft.date = picked);
            },
          ),
          _timeTile(
            label: 'Start',
            value: draft.start,
            onPick: () async {
              final picked = await showTimePicker(context: context, initialTime: draft.start);
              if (picked != null) setState(() => draft.start = picked);
            },
          ),
          _timeTile(
            label: 'End',
            value: draft.end,
            onPick: () async {
              final picked = await showTimePicker(context: context, initialTime: draft.end);
              if (picked != null) setState(() => draft.end = picked);
            },
          ),
          const SizedBox(height: 12),
          const Text('Color'),
          Wrap(
            spacing: 8,
            children: colors
                .map((c) => InkWell(
                      onTap: () => setState(() => draft.color = c),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: c,
                        child: draft.color == c ? const Icon(Icons.check, size: 16) : null,
                      ),
                    ))
                .toList(),
          ),
          SwitchListTile(
            value: draft.reminder,
            onChanged: (v) => setState(() => draft.reminder = v),
            title: const Text('Enable reminder'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(
                context,
                AppEvent(
                  title: title,
                  start: draft.start,
                  end: draft.end,
                  location: locationCtrl.text.trim().isEmpty ? 'Unspecified location' : locationCtrl.text.trim(),
                  attendees: const ['ME'],
                  color: draft.color,
                  date: draft.date,
                ),
              );
            },
            child: const Text('Save Event'),
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
