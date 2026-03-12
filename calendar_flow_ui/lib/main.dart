import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'mock_data.dart';
import 'models/app_models.dart';
import 'screens/calendar_board_screen.dart';
import 'screens/create_event_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/month_overview_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';

void main() {
  runApp(const PlannerApp());
}

class PlannerApp extends StatelessWidget {
  const PlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chrono UI',
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final events = [...MockData.events];
  int navIndex = 0;
  bool onboarded = false;

  @override
  Widget build(BuildContext context) {
    if (!onboarded) {
      return OnboardingScreen(
        onStart: () => setState(() => onboarded = true),
      );
    }

    final screens = [
      HomeScreen(
        events: events,
        onTapEvent: _openEvent,
        onCreate: _openCreate,
        onOpenSearch: _openSearch,
      ),
      CalendarBoardScreen(events: events, onTapEvent: _openEvent, onCreate: _openCreate),
      MonthOverviewScreen(onMonthTap: (_) => setState(() => navIndex = 1)),
      ProfileScreen(profile: MockData.profile),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(navIndex),
          child: screens[navIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navIndex,
        onDestinationSelected: (v) => setState(() => navIndex = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.view_agenda_outlined), selectedIcon: Icon(Icons.view_agenda), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Months'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _openEvent(AppEvent event) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));
  }

  void _openSearch() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(events: events, onTapEvent: _openEvent)));
  }

  Future<void> _openCreate() async {
    final newEvent = await Navigator.of(context).push<AppEvent>(
      MaterialPageRoute(builder: (_) => const CreateEventScreen()),
    );
    if (newEvent != null) {
      setState(() => events.insert(0, newEvent));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event created (UI demo state).')));
    }
  }
}
