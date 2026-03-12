import 'package:calendar_flow_ui/data/repositories.dart';
import 'package:calendar_flow_ui/models/app_models.dart';
import 'package:calendar_flow_ui/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEventRepository implements EventRepository {
  List<AppEvent> _events = [
    AppEvent(
      id: 1,
      title: 'A',
      date: DateTime(2026, 1, 1),
      start: TimeOfDay(hour: 9, minute: 0),
      end: TimeOfDay(hour: 10, minute: 0),
      location: 'Room',
      attendees: ['AA'],
      colorValue: 0xFFFFFFFF,
      reminder: true,
      durationMinutes: 30,
      completed: false,
    ),
  ];

  @override
  Future<void> createEvent(AppEvent event) async {
    _events = [..._events, event.copyWith(id: _events.length + 1)];
  }

  @override
  Future<void> deleteEvent(int id) async {
    _events = _events.where((e) => e.id != id).toList();
  }

  @override
  Future<List<AppEvent>> fetchEvents() async => _events;

  @override
  Future<void> updateEvent(AppEvent event) async {
    _events = _events.map((e) => e.id == event.id ? event : e).toList();
  }

  @override
  Future<void> resetAllData() async {
    _events = [];
  }

  @override
  Future<int> startFocusSession(int eventId) async => 99;

  @override
  Future<void> endFocusSession(int sessionId) async {}

  @override
  Future<DailyProductivityStats> fetchDailyStats(DateTime date) async {
    return DailyProductivityStats.empty(date);
  }

  @override
  Future<List<FocusSession>> fetchActiveFocusSessions() async {
    return [];
  }
}

class _FakeProfileRepository implements ProfileRepository {
  UserProfile profile = UserProfile(
    id: 1,
    name: 'A',
    city: 'X',
    timezone: 'GMT+7',
    goals: 'One|Two',
  );

  @override
  Future<UserProfile> fetchProfile() async => profile;

  @override
  Future<void> updateProfile(UserProfile profile) async {
    this.profile = profile;
  }
}

class _FakeAppStateRepository implements AppStateRepository {
  bool onboarded = false;

  @override
  Future<bool> fetchOnboarded() async => onboarded;

  @override
  Future<void> setOnboarded(bool value) async {
    onboarded = value;
  }
}

class _FakeMaintenanceRepository implements MaintenanceRepository {
  AppDataSnapshot? snapshotValue;

  @override
  Future<AppDataSnapshot> snapshot() async {
    return snapshotValue ??
        AppDataSnapshot(
          onboarded: false,
          profile: UserProfile(id: 1, name: 'A', city: 'X', timezone: 'GMT+7', goals: 'One|Two'),
          events: [],
          focusSessions: [],
          dailyStats: [],
        );
  }

  @override
  Future<void> restore(AppDataSnapshot snapshot) async {
    snapshotValue = snapshot;
  }
}

void main() {
  test('initialize + completeOnboarding updates state', () async {
    final appState = AppState(
      eventRepository: _FakeEventRepository(),
      profileRepository: _FakeProfileRepository(),
      appStateRepository: _FakeAppStateRepository(),
      maintenanceRepository: _FakeMaintenanceRepository(),
    );

    await appState.initialize();
    expect(appState.loading, isFalse);
    expect(appState.events, isNotEmpty);

    await appState.completeOnboarding();
    expect(appState.onboarded, isTrue);
  });

  test('rollover moves old unfinished events to today', () async {
    final old = DateTime.now().subtract(const Duration(days: 2));
    final repo = _FakeEventRepository()
      .._events = [
        AppEvent(
          id: 3,
          title: 'Old',
          date: old,
          start: const TimeOfDay(hour: 9, minute: 0),
          end: const TimeOfDay(hour: 10, minute: 0),
          location: 'X',
          attendees: const ['AA'],
          colorValue: 0xFFFFFFFF,
          reminder: false,
          durationMinutes: 30,
          completed: false,
        )
      ];

    final appState = AppState(
      eventRepository: repo,
      profileRepository: _FakeProfileRepository(),
      appStateRepository: _FakeAppStateRepository(),
      maintenanceRepository: _FakeMaintenanceRepository(),
    );

    await appState.initialize();
    expect(appState.rolloverCandidates, isNotEmpty);
    await appState.rolloverUnfinishedEvents();
    final today = DateTime.now();
    final rolled = appState.events.first;
    expect(rolled.date.year, today.year);
    expect(rolled.date.month, today.month);
    expect(rolled.date.day, today.day);
  });
}
