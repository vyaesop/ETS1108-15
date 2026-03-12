import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/common_widgets.dart';

class SearchScreen extends StatefulWidget {
  final List<AppEvent> events;
  final ValueChanged<AppEvent> onTapEvent;

  const SearchScreen({super.key, required this.events, required this.onTapEvent});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = ctrl.text.trim().toLowerCase();
    final results = q.isEmpty
        ? widget.events
        : widget.events.where((e) => e.title.toLowerCase().contains(q) || e.location.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Search & Filters')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: 'Meeting, lunch, location...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(onPressed: () => setState(ctrl.clear), icon: const Icon(Icons.close)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (results.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No matching events found.'),
              ),
            )
          else
            ...results.map((e) => EventCard(event: e, onTap: () => widget.onTapEvent(e))),
        ],
      ),
    );
  }
}
