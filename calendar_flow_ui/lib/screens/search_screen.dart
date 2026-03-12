import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

import '../models/app_models.dart';

class SearchScreen extends StatefulWidget {
  final List<AppEvent> events;
  final ValueChanged<AppEvent> onTapEvent;
  final ValueChanged<DateTime>? onJumpToDate;
  final ValueChanged<SearchState>? onStateChanged;
  final SearchState? initialState;

  const SearchScreen({
    super.key,
    required this.events,
    required this.onTapEvent,
    this.onJumpToDate,
    this.onStateChanged,
    this.initialState,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ctrl = TextEditingController();
  bool reminderOnly = false;
  bool incompleteOnly = false;
  DateTimeRange? range;
  bool _hydrated = false;
  SearchSort sort = SearchSort.date;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _hydrateInitialState();
    final q = ctrl.text.trim().toLowerCase();
    final results = widget.events.where((e) {
      final textMatch = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.location.toLowerCase().contains(q) ||
          e.attendees.any((a) => a.toLowerCase().contains(q));
      final reminderMatch = !reminderOnly || e.reminder;
      final incompleteMatch = !incompleteOnly || !e.completed;
      final dateMatch = range == null ||
          (!_normalize(e.date).isBefore(_normalize(range!.start)) && !_normalize(e.date).isAfter(_normalize(range!.end)));
      return textMatch && reminderMatch && dateMatch && incompleteMatch;
    }).toList()
      ..sort((a, b) {
        if (sort == SearchSort.title) {
          final t = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          if (t != 0) return t;
        }
        final dateSort = a.date.compareTo(b.date);
        if (dateSort != 0) return dateSort;
        return (a.start.hour * 60 + a.start.minute).compareTo(b.start.hour * 60 + b.start.minute);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Search & Filters')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: 'Meeting, lunch, location, attendee...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () {
                  ctrl.clear();
                  _updateState();
                },
                icon: const Icon(Icons.close),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onChanged: (_) => _updateState(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                selected: reminderOnly,
                label: const Text('Reminders only'),
                onSelected: (v) => _updateState(reminder: v),
              ),
              FilterChip(
                selected: incompleteOnly,
                label: const Text('Incomplete only'),
                onSelected: (v) => _updateState(incomplete: v),
              ),
              FilterChip(
                selected: range != null,
                label: Text(range == null ? 'Date range' : '${range!.start.month}/${range!.start.day} - ${range!.end.month}/${range!.end.day}'),
                onSelected: (_) async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 2),
                    lastDate: DateTime(now.year + 2),
                    initialDateRange: range,
                  );
                  if (picked != null) _updateState(newRange: picked, updateRange: true);
                },
              ),
              ActionChip(
                onPressed: _clearAll,
                label: const Text('Clear all'),
              ),
              ActionChip(
                onPressed: () => _updateSort(),
                label: Text('Sort: ${sort == SearchSort.date ? 'Date' : 'Title'}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Results: ${results.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (results.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No matching events found for the selected filters.'),
              ),
            )
          else
            ...results.map(
              (e) => _SearchResultCard(
                event: e,
                query: q,
                onTap: () => widget.onTapEvent(e),
                onJumpToDate: widget.onJumpToDate,
              ),
            ),
        ],
      ),
    );
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  void _hydrateInitialState() {
    if (_hydrated || widget.initialState == null) return;
    final state = widget.initialState!;
    ctrl.text = state.query;
    reminderOnly = state.reminderOnly;
    incompleteOnly = state.incompleteOnly;
    range = state.range;
    sort = state.sort;
    _hydrated = true;
  }

  void _emitState() {
    widget.onStateChanged?.call(
      SearchState(
        query: ctrl.text.trim(),
        reminderOnly: reminderOnly,
        incompleteOnly: incompleteOnly,
        range: range,
        sort: sort,
      ),
    );
  }

  void _updateState({bool? reminder, bool? incomplete, DateTimeRange? newRange, bool updateRange = false}) {
    setState(() {
      if (reminder != null) reminderOnly = reminder;
      if (incomplete != null) incompleteOnly = incomplete;
      if (updateRange) range = newRange;
    });
    _emitState();
  }

  void _clearAll() {
    setState(() {
      ctrl.clear();
      reminderOnly = false;
      incompleteOnly = false;
      range = null;
    });
    _emitState();
  }

  void _updateSort() {
    setState(() {
      sort = sort == SearchSort.date ? SearchSort.title : SearchSort.date;
    });
    _emitState();
  }
}

class _SearchResultCard extends StatelessWidget {
  final AppEvent event;
  final String query;
  final VoidCallback onTap;
  final ValueChanged<DateTime>? onJumpToDate;

  const _SearchResultCard({
    required this.event,
    required this.query,
    required this.onTap,
    required this.onJumpToDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd().format(event.date);
    final timeLabel = event.allDay ? 'All day' : '${_fmt(event.start)} - ${_fmt(event.end)}';
    return Card(
      child: ListTile(
        onTap: onTap,
        title: _highlightText(event.title, query),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$dateLabel - $timeLabel'),
            _highlightText(event.location, query),
            if (event.attendees.isNotEmpty)
              _highlightText('Attendees: ${event.attendees.join(', ')}', query),
            if (onJumpToDate != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    onJumpToDate!(event.date);
                    Navigator.pop(context);
                  },
                  child: const Text('Open day'),
                ),
              ),
          ],
        ),
        trailing: event.completed ? const Icon(Icons.check_circle, color: Colors.green) : null,
      ),
    );
  }

  String _fmt(TimeOfDay value) {
    final h = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final m = value.minute.toString().padLeft(2, '0');
    final p = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final index = lower.indexOf(q, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + q.length),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      start = index + q.length;
    }
    return RichText(text: TextSpan(style: DefaultTextStyle.of(context as BuildContext).style, children: spans));
  }
}

class SearchState {
  final String query;
  final bool reminderOnly;
  final bool incompleteOnly;
  final DateTimeRange? range;
  final SearchSort sort;

  const SearchState({
    required this.query,
    required this.reminderOnly,
    required this.incompleteOnly,
    required this.range,
    required this.sort,
  });
}

enum SearchSort { date, title }
