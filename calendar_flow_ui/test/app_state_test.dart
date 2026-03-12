import 'package:calendar_flow_ui/data/repositories.dart';
import 'package:calendar_flow_ui/models/app_models.dart';
import 'package:calendar_flow_ui/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEventRepository implements EventRepository {
  List<AppEvent> _events = [
    const AppEvent(
      id: 1,
      title: 'A',
      date: DateTime(2026, 1, 1),
      start: TimeOfDay(hour: 9, minute: 0),
      end: TimeOfDay(hour: 10, minute: 0),
      location: 'Room',
      attendees: ['AA'],
      colorValue: 0xFFFFFFFF,
      reminder: true,
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
}

class _FakeProfileRepository implements ProfileRepository {
  UserProfile profile = const UserProfile(
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

void main() {
  test('initialize + completeOnboarding updates state', () async {
    final appState = AppState(
      eventRepository: _FakeEventRepository(),
      profileRepository: _FakeProfileRepository(),
      appStateRepository: _FakeAppStateRepository(),
    );

    await appState.initialize();
    expect(appState.loading, isFalse);
    expect(appState.events, isNotEmpty);

    await appState.completeOnboarding();
    expect(appState.onboarded, isTrue);
  });
}
