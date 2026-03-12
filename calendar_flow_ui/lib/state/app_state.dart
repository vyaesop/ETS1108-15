import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../models/app_models.dart';
import '../services/daily_planner.dart';

class AppState extends ChangeNotifier {
  AppState({
    required EventRepository eventRepository,
    required ProfileRepository profileRepository,
    required AppStateRepository appStateRepository,
  })  : _eventRepository = eventRepository,
        _profileRepository = profileRepository,
        _appStateRepository = appStateRepository;

  final EventRepository _eventRepository;
  final ProfileRepository _profileRepository;
  final AppStateRepository _appStateRepository;

  bool loading = true;
  bool onboarded = false;
  bool mutating = false;
  String? lastError;
  List<AppEvent> events = [];
  UserProfile? profile;
  DailyProductivityStats todayStats = DailyProductivityStats.empty(DateTime.now());
  final Map<int, int> _activeFocusSessions = {};

  Set<int> get activeFocusEventIds => _activeFocusSessions.keys.toSet();

  Future<void> initialize() async {
    await _runGuarded(() async {
      loading = true;
      notifyListeners();

      onboarded = await _appStateRepository.fetchOnboarded();
      events = await _eventRepository.fetchEvents();
      profile = await _profileRepository.fetchProfile();

      await _rolloverUnfinishedEventsInternal();
      await _refreshTodayStats();

      loading = false;
    }, isBoot: true);
  }

  Future<void> completeOnboarding() async {
    await _runGuarded(() async {
      onboarded = true;
      await _appStateRepository.setOnboarded(true);
    });
  }

  Future<void> createEvent(AppEvent event) async {
    await _runGuarded(() async {
      await _eventRepository.createEvent(event);
      events = await _eventRepository.fetchEvents();
      await _refreshTodayStats();
    });
  }

  Future<void> updateEvent(AppEvent event) async {
    await _runGuarded(() async {
      await _eventRepository.updateEvent(event);
      events = await _eventRepository.fetchEvents();
      await _refreshTodayStats();
    });
  }

  Future<void> deleteEvent(int id) async {
    await _runGuarded(() async {
      await _eventRepository.deleteEvent(id);
      events = await _eventRepository.fetchEvents();
      await _refreshTodayStats();
    });
  }

  Future<void> saveProfile(UserProfile next) async {
    await _runGuarded(() async {
      await _profileRepository.updateProfile(next);
      profile = await _profileRepository.fetchProfile();
    });
  }

  Future<void> resetAppData() async {
    await _runGuarded(() async {
      await _eventRepository.resetAllData();
      onboarded = await _appStateRepository.fetchOnboarded();
      events = await _eventRepository.fetchEvents();
      profile = await _profileRepository.fetchProfile();
      _activeFocusSessions.clear();
      await _refreshTodayStats();
    });
  }

  Future<void> rolloverUnfinishedEvents() async {
    await _runGuarded(() async {
      await _rolloverUnfinishedEventsInternal();
    });
  }

  Future<void> toggleEventCompleted(AppEvent event, bool completed) async {
    await updateEvent(event.copyWith(completed: completed));
  }

  Future<void> startFocusForEvent(int eventId) async {
    await _runGuarded(() async {
      final sessionId = await _eventRepository.startFocusSession(eventId);
      _activeFocusSessions[eventId] = sessionId;
    });
  }

  Future<void> endFocusForEvent(int eventId) async {
    await _runGuarded(() async {
      final sessionId = _activeFocusSessions[eventId];
      if (sessionId == null) return;
      await _eventRepository.endFocusSession(sessionId);
      _activeFocusSessions.remove(eventId);
      await _refreshTodayStats();
    });
  }

  List<ScheduledEvent> buildDailyPlan(DateTime date) => generateDailySchedule(date, events);

  void clearError() {
    lastError = null;
    notifyListeners();
  }

  Future<void> _rolloverUnfinishedEventsInternal() async {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    for (final event in events.where((e) => !e.completed)) {
      final eventDay = DateTime(event.date.year, event.date.month, event.date.day);
      if (eventDay.isBefore(todayDay)) {
        await _eventRepository.updateEvent(event.copyWith(date: todayDay));
      }
    }
    events = await _eventRepository.fetchEvents();
  }

  Future<void> _refreshTodayStats() async {
    todayStats = await _eventRepository.fetchDailyStats(DateTime.now());
  }

  Future<void> _runGuarded(Future<void> Function() task, {bool isBoot = false}) async {
    try {
      lastError = null;
      if (!isBoot) {
        mutating = true;
      }
      await task();
    } catch (error) {
      lastError = 'Operation failed: $error';
      if (isBoot) {
        loading = false;
      }
    } finally {
      mutating = false;
      notifyListeners();
    }
  }
}
