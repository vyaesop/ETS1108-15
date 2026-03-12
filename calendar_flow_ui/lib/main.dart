import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'data/local_database.dart';
import 'data/sqflite_repositories.dart';
import 'models/app_models.dart';
import 'screens/calendar_board_screen.dart';
import 'screens/create_event_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/month_overview_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'state/app_state.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const PlannerApp());
}

class PlannerApp extends StatefulWidget {
  const PlannerApp({super.key});

  @override
  State<PlannerApp> createState() => _PlannerAppState();
}

class _PlannerAppState extends State<PlannerApp> {
  late final AppState appState;

  @override
  void initState() {
    super.initState();
    final db = LocalDatabase.instance;
    appState = AppState(
      eventRepository: SqfliteEventRepository(db),
      profileRepository: SqfliteProfileRepository(db),
      appStateRepository: SqfliteAppStateRepository(db),
      maintenanceRepository: SqfliteMaintenanceRepository(db),
    )..initialize();
  }

  @override
  void dispose() {
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Chrono UI',
          theme: AppTheme.light(),
          home: appState.loading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : AppShell(state: appState),
        );
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});

  final AppState state;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int navIndex = 0;
  bool rolloverPrompted = false;
  DateTime? calendarFocusDate;
  SearchState searchState = const SearchState(
    query: '',
    reminderOnly: false,
    incompleteOnly: false,
    range: null,
    sort: SearchSort.date,
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.state.onboarded) {
      return OnboardingScreen(onStart: widget.state.completeOnboarding);
    }

    final today = DateTime.now();
    final todayEvents = widget.state.events
        .where((e) => e.date.year == today.year && e.date.month == today.month && e.date.day == today.day)
        .toList();
    final completedCount = todayEvents.where((e) => e.completed).length;
    final completionProgress = todayEvents.isEmpty ? 0.0 : completedCount / todayEvents.length;

    final focusMonthOffset = calendarFocusDate == null
        ? 0
        : (calendarFocusDate!.year - today.year) * 12 + (calendarFocusDate!.month - today.month);

    final screens = [
      HomeScreen(
        events: widget.state.events,
        profile: widget.state.profile,
        onTapEvent: _openEvent,
        todayPlan: widget.state.buildDailyPlan(today),
        completionProgress: completionProgress,
        tasksCompletedToday: widget.state.todayStats.tasksCompleted,
        focusMinutesToday: widget.state.todayStats.focusMinutes,
        activeFocusEventIds: widget.state.activeFocusEventIds,
        activeFocusStartTimes: widget.state.activeFocusStartTimes,
        onToggleFocus: _toggleFocus,
        onAddEvent: _openCreate,
        onOpenCalendar: () => setState(() => navIndex = 1),
      ),
      CalendarBoardScreen(
        key: ValueKey('calendar-$focusMonthOffset'),
        events: widget.state.events,
        onTapEvent: _openEvent,
        onCreateForDate: _openCreateForDate,
        initialMode: 1,
        initialMonthOffset: focusMonthOffset,
      ),
      MonthOverviewScreen(
        onMonthTap: _openMonth,
        onJumpToday: () => setState(() => navIndex = 0),
        events: widget.state.events,
      ),
      ProfileScreen(
        profile: widget.state.profile!,
        onSave: widget.state.saveProfile,
        onResetData: () async {
          final backup = await widget.state.resetAppDataWithBackup();
          if (mounted && !widget.state.onboarded) {
            setState(() => navIndex = 0);
          }
          return backup;
        },
        onRestoreData: widget.state.restoreAppData,
        onExportData: widget.state.exportSnapshotJson,
        onImportData: widget.state.importSnapshotJson,
      ),
    ];

    if (!rolloverPrompted && widget.state.rolloverCandidates.isNotEmpty) {
      rolloverPrompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _promptRollover(widget.state.rolloverCandidates.length));
    }

    final showAppBar = navIndex != 0;
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(_navTitle(navIndex)),
              actions: [
                IconButton(
                  tooltip: 'Search',
                  onPressed: _openSearch,
                  icon: const Icon(Icons.search),
                ),
              ],
            )
          : null,
      body: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const _OpenSearchIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const _OpenCreateIntent(),
        },
        child: Actions(
          actions: {
            _OpenSearchIntent: CallbackAction<_OpenSearchIntent>(onInvoke: (_) => _openSearch()),
            _OpenCreateIntent: CallbackAction<_OpenCreateIntent>(onInvoke: (_) => _openCreate()),
          },
          child: Focus(
            autofocus: true,
            child: Column(
              children: [
          if (widget.state.lastError != null)
            Material(
              color: Colors.red.shade100,
              child: SafeArea(
                bottom: false,
                child: ListTile(
                  dense: true,
                  title: Text(widget.state.lastError!, style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.state.clearError,
                  ),
                ),
              ),
            ),
          if (widget.state.mutating) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: IndexedStack(
              index: navIndex,
              children: screens,
            ),
          ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: showAppBar
          ? FloatingActionButton(
              onPressed: _openCreate,
              tooltip: 'Create event',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navIndex,
        onDestinationSelected: (value) => setState(() => navIndex = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.view_agenda_outlined), selectedIcon: Icon(Icons.view_agenda), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Months'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          events: widget.state.events,
          onTapEvent: _openEvent,
          onJumpToDate: _focusCalendarDate,
          onStateChanged: (state) => searchState = state,
          initialState: searchState,
        ),
      ),
    );
  }

  Future<void> _openCreate() async {
    final event = await Navigator.of(context).push<AppEvent>(
      MaterialPageRoute(builder: (_) => CreateEventScreen(existingEvents: widget.state.events)),
    );
    if (event == null) return;
    await widget.state.createEvent(event);
    if (!mounted) return;
    if (widget.state.lastError == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event saved.')),
      );
    }
  }

  Future<void> _openCreateForDate(DateTime date) async {
    final event = await Navigator.of(context).push<AppEvent>(
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(
          existingEvents: widget.state.events,
          initialDate: date,
        ),
      ),
    );
    if (event == null) return;
    await widget.state.createEvent(event);
    if (!mounted) return;
    if (widget.state.lastError == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event saved.')),
      );
    }
  }

  Future<void> _openEvent(AppEvent event) async {
    final result = await Navigator.of(context).push<EventDetailResult>(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          event: event,
          existingEvents: widget.state.events,
          onDelete: () async {
            if (event.id != null) {
              await widget.state.deleteEvent(event.id!);
            }
          },
          onSave: widget.state.updateEvent,
          onToggleCompleted: widget.state.toggleEventCompleted,
        ),
      ),
    );
    if (!mounted) return;
    final deleted = result?.deletedEvent;
    if (deleted != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Event deleted.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await widget.state.createEvent(deleted);
            },
          ),
        ),
      );
    }
  }

  Future<void> _toggleFocus(AppEvent event) async {
    if (event.id == null) return;
    if (widget.state.activeFocusEventIds.contains(event.id)) {
      await widget.state.endFocusForEvent(event.id!);
    } else {
      await widget.state.startFocusForEvent(event.id!);
    }
  }

  void _focusCalendarDate(DateTime date) {
    setState(() {
      calendarFocusDate = DateTime(date.year, date.month, 1);
      navIndex = 1;
    });
  }

  void _openMonth(int monthIndex) {
    final now = DateTime.now();
    final target = DateTime(now.year, monthIndex + 1, 1);
    _focusCalendarDate(target);
  }

  Future<void> _promptRollover(int count) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Move unfinished tasks?'),
        content: Text('$count incomplete task${count == 1 ? '' : 's'} are from previous days. Move them to today?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep dates'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Move to today'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.state.rolloverUnfinishedEvents();
    } else {
      widget.state.dismissRolloverCandidates();
    }
  }

  String _navTitle(int index) {
    return switch (index) {
      0 => 'Today',
      1 => 'Calendar',
      2 => 'Months',
      3 => 'Profile',
      _ => 'Chrono',
    };
  }
}

class _OpenSearchIntent extends Intent {
  const _OpenSearchIntent();
}

class _OpenCreateIntent extends Intent {
  const _OpenCreateIntent();
}
