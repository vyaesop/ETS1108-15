import 'package:flutter/material.dart';

import '../models/app_models.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfile profile;

  const ProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 34)),
          const SizedBox(height: 12),
          Center(child: Text(profile.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700))),
          Center(child: Text('${profile.city} • ${profile.timezone}', style: const TextStyle(color: Colors.black54))),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Planning Goals', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: profile.goals.map((e) => Chip(label: Text(e))).toList()),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: const [
                ListTile(leading: Icon(Icons.notifications_none), title: Text('Notification Settings')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.language), title: Text('Language & Region')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.palette_outlined), title: Text('Theme Customization')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: () {}, child: const Text('Log Out (UI only)')),
        ],
      ),
    );
  }
}
