import 'package:flutter/material.dart';

import '../models/app_models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.profile, required this.onSave});

  final UserProfile profile;
  final Future<void> Function(UserProfile) onSave;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController nameCtrl;
  late final TextEditingController cityCtrl;
  late final TextEditingController tzCtrl;
  late final TextEditingController goalsCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.profile.name);
    cityCtrl = TextEditingController(text: widget.profile.city);
    tzCtrl = TextEditingController(text: widget.profile.timezone);
    goalsCtrl = TextEditingController(text: widget.profile.goals.replaceAll('|', ', '));
  }


  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      nameCtrl.text = widget.profile.name;
      cityCtrl.text = widget.profile.city;
      tzCtrl.text = widget.profile.timezone;
      goalsCtrl.text = widget.profile.goals.replaceAll('|', ', ');
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
          Center(child: Text('${widget.profile.city} • ${widget.profile.timezone}', style: const TextStyle(color: Colors.black54))),
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
                  TextField(controller: tzCtrl, decoration: const InputDecoration(labelText: 'Timezone')),
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
        ],
      ),
    );
  }

  Future<void> _save() async {
    final updated = widget.profile.copyWith(
      name: nameCtrl.text.trim(),
      city: cityCtrl.text.trim(),
      timezone: tzCtrl.text.trim(),
      goals: goalsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .join('|'),
    );
    await widget.onSave(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved locally.')));
  }
}
