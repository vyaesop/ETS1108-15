import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onSave,
    required this.onResetData,
    required this.onRestoreData,
    required this.onExportData,
    required this.onImportData,
  });

  final UserProfile profile;
  final Future<void> Function(UserProfile) onSave;
  final Future<AppDataSnapshot> Function() onResetData;
  final Future<void> Function(AppDataSnapshot snapshot) onRestoreData;
  final Future<String> Function() onExportData;
  final Future<void> Function(String payload) onImportData;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController nameCtrl;
  late final TextEditingController cityCtrl;
  late final TextEditingController tzCtrl;
  late final TextEditingController goalsCtrl;
  final List<String> tzOptions = [
    'GMT-12',
    'GMT-11',
    'GMT-10',
    'GMT-9',
    'GMT-8',
    'GMT-7',
    'GMT-6',
    'GMT-5',
    'GMT-4',
    'GMT-3',
    'GMT-2',
    'GMT-1',
    'GMT+0',
    'GMT+1',
    'GMT+2',
    'GMT+3',
    'GMT+4',
    'GMT+5',
    'GMT+6',
    'GMT+7',
    'GMT+8',
    'GMT+9',
    'GMT+10',
    'GMT+11',
    'GMT+12',
    'GMT+13',
    'GMT+14',
  ];

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.profile.name);
    cityCtrl = TextEditingController(text: widget.profile.city);
    tzCtrl = TextEditingController(text: widget.profile.timezone);
    goalsCtrl = TextEditingController(text: widget.profile.goals.replaceAll('|', ', '));
    if (!tzOptions.contains(tzCtrl.text)) {
      tzCtrl.text = 'GMT+0';
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      nameCtrl.text = widget.profile.name;
      cityCtrl.text = widget.profile.city;
      tzCtrl.text = widget.profile.timezone;
      goalsCtrl.text = widget.profile.goals.replaceAll('|', ', ');
      if (!tzOptions.contains(tzCtrl.text)) {
        tzCtrl.text = 'GMT+0';
      }
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    cityCtrl.dispose();
    tzCtrl.dispose();
    goalsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 34)),
          const SizedBox(height: 12),
          Center(child: Text(widget.profile.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700))),
          Center(child: Text('${widget.profile.city} - ${widget.profile.timezone}', style: const TextStyle(color: Colors.black54))),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Planning Goals', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: widget.profile.goalList.map((e) => Chip(label: Text(e))).toList()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
                  DropdownButtonFormField<String>(
                    value: tzOptions.contains(tzCtrl.text) ? tzCtrl.text : 'GMT+0',
                    decoration: const InputDecoration(labelText: 'Timezone (GMT offset)'),
                    items: tzOptions.map((tz) => DropdownMenuItem(value: tz, child: Text(tz))).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => tzCtrl.text = value);
                    },
                  ),
                  TextField(controller: goalsCtrl, decoration: const InputDecoration(labelText: 'Goals (comma separated)')),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                    child: const Text('Save Profile to SQLite'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Danger Zone', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Reset all local data (events, profile edits, onboarding state).'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _confirmReset,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset App Data'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data Tools', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Export or import your local data snapshot.'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exportData,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Export'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _importData,
                          icon: const Icon(Icons.download),
                          label: const Text('Import'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final tz = tzCtrl.text.trim();
    final tzValid = RegExp(r'^GMT[+-](?:0?[0-9]|1[0-4])$').hasMatch(tz);
    if (!tzValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timezone must be in format GMT+7 or GMT-5.')),
      );
      return;
    }

    final updated = widget.profile.copyWith(
      name: nameCtrl.text.trim(),
      city: cityCtrl.text.trim(),
      timezone: tz,
      goals: goalsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .join('|'),
    );
    await widget.onSave(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved.')));
  }

  Future<void> _confirmReset() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset local data?'),
        content: const Text('This will restore seeded profile/events and show onboarding again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );

    if (sure != true) return;
    final backup = await widget.onResetData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data reset complete.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await widget.onRestoreData(backup);
          },
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    final payload = await widget.onExportData();
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported to clipboard.')));
  }

  Future<void> _importData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import data?'),
        content: const Text('This will replace your current local data with the clipboard snapshot. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Import')),
        ],
      ),
    );
    if (confirm != true) return;
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clipboard is empty.')));
      return;
    }
    await widget.onImportData(text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import complete.')));
  }
}

