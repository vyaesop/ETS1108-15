import 'package:flutter/material.dart';

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

void main() {
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

    final screens = [
      HomeScreen(
        events: widget.state.events,
        onTapEvent: _openEvent,
        onCreate: _openCreate,
        onOpenSearch: _openSearch,
        todayPlan: widget.state.buildDailyPlan(today),
        completionProgress: completionProgress,
        tasksCompletedToday: widget.state.todayStats.tasksCompleted,
        focusMinutesToday: widget.state.todayStats.focusMinutes,
        activeFocusEventIds: widget.state.activeFocusEventIds,
        onToggleCompleted: widget.state.toggleEventCompleted,
        onToggleFocus: _toggleFocus,
      ),
      CalendarBoardScreen(
        events: widget.state.events,
        onTapEvent: _openEvent,
        onCreate: _openCreate,
      ),
      MonthOverviewScreen(
        onMonthTap: (_) => setState(() => navIndex = 1),
        onJumpToday: () => setState(() => navIndex = 0),
        events: widget.state.events,
      ),
      ProfileScreen(
        profile: widget.state.profile!,
        onSave: widget.state.saveProfile,
        onResetData: () async {
          await widget.state.resetAppData();
          if (mounted && !widget.state.onboarded) {
            setState(() => navIndex = 0);
          }
        },
      ),
    ];

    return Scaffold(
      body: Column(
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
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(key: ValueKey(navIndex), child: screens[navIndex]),
            ),
          ),
        ],
      ),
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
        builder: (_) => SearchScreen(events: widget.state.events, onTapEvent: _openEvent),
      ),
    );
  }

  Future<void> _openCreate() async {
    final event = await Navigator.of(context).push<AppEvent>(
      MaterialPageRoute(builder: (_) => const CreateEventScreen()),
    );
    if (event == null) return;
    await widget.state.createEvent(event);
    if (!mounted) return;
    if (widget.state.lastError == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to local SQLite database.')),
      );
    }
  }

  Future<void> _openEvent(AppEvent event) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          event: event,
          onDelete: () async {
            if (event.id != null) {
              await widget.state.deleteEvent(event.id!);
            }
          },
          onSave: widget.state.updateEvent,
        ),
      ),
    );
  }

  Future<void> _toggleFocus(AppEvent event) async {
    if (event.id == null) return;
    if (widget.state.activeFocusEventIds.contains(event.id)) {
      await widget.state.endFocusForEvent(event.id!);
    } else {
      await widget.state.startFocusForEvent(event.id!);
    }
  }
}
