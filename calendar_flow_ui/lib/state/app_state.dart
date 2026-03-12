import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../models/app_models.dart';
import '../services/daily_planner.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required EventRepository eventRepository,
    required ProfileRepository profileRepository,
    required AppStateRepository appStateRepository,
    required MaintenanceRepository maintenanceRepository,
  })  : _eventRepository = eventRepository,
        _profileRepository = profileRepository,
        _appStateRepository = appStateRepository,
        _maintenanceRepository = maintenanceRepository;

  final EventRepository _eventRepository;
  final ProfileRepository _profileRepository;
  final AppStateRepository _appStateRepository;
  final MaintenanceRepository _maintenanceRepository;

  bool loading = true;
  bool onboarded = false;
  bool mutating = false;
  String? lastError;
  List<AppEvent> events = [];
  List<AppEvent> baseEvents = [];
  List<AppEvent> rolloverCandidates = [];
  UserProfile? profile;
  DailyProductivityStats todayStats = DailyProductivityStats.empty(DateTime.now());
  final Map<int, _FocusSessionMeta> _activeFocusSessions = {};

  Set<int> get activeFocusEventIds => _activeFocusSessions.keys.toSet();
  Map<int, DateTime> get activeFocusStartTimes => _activeFocusSessions.map((key, value) => MapEntry(key, value.startTime));

  Future<void> initialize() async {
    await _runGuarded(() async {
      loading = true;
      notifyListeners();

      onboarded = await _appStateRepository.fetchOnboarded();
      baseEvents = await _eventRepository.fetchEvents();
      profile = await _profileRepository.fetchProfile();
      events = _expandRecurrences(baseEvents);
      final activeSessions = await _eventRepository.fetchActiveFocusSessions();
      _activeFocusSessions
        ..clear()
        ..addEntries(
          activeSessions.map(
            (s) => MapEntry(
              s.eventId,
              _FocusSessionMeta(sessionId: s.id, startTime: s.startTime),
            ),
          ),
        );

      rolloverCandidates = _findRolloverCandidates(events);
      await _refreshTodayStats();
      await _notificationSync();

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
      baseEvents = await _eventRepository.fetchEvents();
      events = _expandRecurrences(baseEvents);
      await _refreshTodayStats();
      await _notificationSync();
    });
  }

  Future<void> updateEvent(AppEvent event) async {
    await _runGuarded(() async {
      final normalized = event.isOccurrence && event.seriesStartDate != null
          ? event.copyWith(date: event.seriesStartDate)
          : event;
      await _eventRepository.updateEvent(normalized);
      baseEvents = await _eventRepository.fetchEvents();
      events = _expandRecurrences(baseEvents);
      await _refreshTodayStats();
      await _notificationSync();
    });
  }

  Future<void> deleteEvent(int id) async {
    await _runGuarded(() async {
      await _eventRepository.deleteEvent(id);
      baseEvents = await _eventRepository.fetchEvents();
      events = _expandRecurrences(baseEvents);
      await _refreshTodayStats();
      await _notificationSync();
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
      baseEvents = await _eventRepository.fetchEvents();
      events = _expandRecurrences(baseEvents);
      profile = await _profileRepository.fetchProfile();
      _activeFocusSessions.clear();
      rolloverCandidates = _findRolloverCandidates(events);
      await _refreshTodayStats();
      await _notificationSync();
    });
  }

  Future<AppDataSnapshot> resetAppDataWithBackup() async {
    final backup = await _maintenanceRepository.snapshot();
    await _runGuarded(() async {
      await _eventRepository.resetAllData();
      onboarded = await _appStateRepository.fetchOnboarded();
      baseEvents = await _eventRepository.fetchEvents();
      events = _expandRecurrences(baseEvents);
      profile = await _profileRepository.fetchProfile();
      _activeFocusSessions.clear();
      rolloverCandidates = _findRolloverCandidates(events);
      await _refreshTodayStats();
      await _notificationSync();
    });
    return backup;
  }

  Future<void> restoreAppData(AppDataSnapshot snapshot) async {
    await _runGuarded(() async {
      await _maintenanceRepository.restore(snapshot);
      onboarded = await _appStateRepository.fetchOnboarded();
      baseEvents = await _eventRepository.fetchEvents();
      events = _expandRecurrences(baseEvents);
      profile = await _profileRepository.fetchProfile();
      _activeFocusSessions.clear();
      rolloverCandidates = _findRolloverCandidates(events);
      await _refreshTodayStats();
      await _notificationSync();
    });
  }

  Future<String> exportSnapshotJson() async {
    final snapshot = await _maintenanceRepository.snapshot();
    return jsonEncode(snapshot.toJson());
  }

  Future<void> importSnapshotJson(String payload) async {
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final snapshot = AppDataSnapshot.fromJson(decoded.cast<String, Object?>());
    await restoreAppData(snapshot);
  }

  Future<void> rolloverUnfinishedEvents() async {
    await _runGuarded(() async {
      await _rolloverUnfinishedEventsInternal();
      rolloverCandidates = _findRolloverCandidates(events);
      await _notificationSync();
    });
  }

  void dismissRolloverCandidates() {
    rolloverCandidates = [];
    notifyListeners();
  }

  Future<void> toggleEventCompleted(AppEvent event, bool completed) async {
    await updateEvent(event.copyWith(completed: completed));
  }

  Future<void> startFocusForEvent(int eventId) async {
    await _runGuarded(() async {
      final sessionId = await _eventRepository.startFocusSession(eventId);
      _activeFocusSessions[eventId] = _FocusSessionMeta(
        sessionId: sessionId,
        startTime: DateTime.now(),
      );
    });
  }

  Future<void> endFocusForEvent(int eventId) async {
    await _runGuarded(() async {
      final sessionId = _activeFocusSessions[eventId];
      if (sessionId == null) return;
      await _eventRepository.endFocusSession(sessionId.sessionId);
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
    for (final event in baseEvents.where((e) => !e.completed && !e.isRecurring)) {
      final eventDay = DateTime(event.date.year, event.date.month, event.date.day);
      if (eventDay.isBefore(todayDay)) {
        await _eventRepository.updateEvent(event.copyWith(date: todayDay));
      }
    }
    baseEvents = await _eventRepository.fetchEvents();
    events = _expandRecurrences(baseEvents);
  }

  List<AppEvent> _findRolloverCandidates(List<AppEvent> source) {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    return source.where((e) {
      if (e.completed) return false;
      if (e.isRecurring) return false;
      final eventDay = DateTime(e.date.year, e.date.month, e.date.day);
      return eventDay.isBefore(todayDay);
    }).toList();
  }

  Future<void> _refreshTodayStats() async {
    todayStats = await _eventRepository.fetchDailyStats(DateTime.now());
  }

  List<AppEvent> _expandRecurrences(List<AppEvent> source) {
    final now = DateTime.now();
    final rangeStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 90));
    final rangeEnd = DateTime(now.year, now.month, now.day).add(const Duration(days: 365));
    final expanded = <AppEvent>[];
    for (final event in source) {
      if (!event.isRecurring) {
        expanded.add(event);
        continue;
      }
      final until = event.recurrenceUntil != null && event.recurrenceUntil!.isBefore(rangeEnd)
          ? event.recurrenceUntil!
          : rangeEnd;
      final startDate = DateTime(event.date.year, event.date.month, event.date.day);
      var cursor = _firstOccurrenceOnOrAfter(startDate, event.recurrenceRule, rangeStart);
      while (!cursor.isAfter(until)) {
        if (!cursor.isBefore(rangeStart)) {
          expanded.add(
            event.copyWith(
              date: cursor,
              seriesStartDate: startDate,
            ),
          );
        }
        cursor = _nextOccurrence(cursor, event.recurrenceRule);
      }
    }
    return expanded
      ..sort((a, b) {
        final dateSort = a.date.compareTo(b.date);
        if (dateSort != 0) return dateSort;
        final aStart = a.start.hour * 60 + a.start.minute;
        final bStart = b.start.hour * 60 + b.start.minute;
        return aStart.compareTo(bStart);
      });
  }

  DateTime _nextOccurrence(DateTime date, RecurrenceRule rule) {
    return switch (rule) {
      RecurrenceRule.daily => date.add(const Duration(days: 1)),
      RecurrenceRule.weekly => date.add(const Duration(days: 7)),
      RecurrenceRule.monthly => _addMonth(date),
      RecurrenceRule.none => date.add(const Duration(days: 3650)),
    };
  }

  DateTime _addMonth(DateTime date) {
    final year = date.year + (date.month == 12 ? 1 : 0);
    final month = date.month == 12 ? 1 : date.month + 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > daysInMonth ? daysInMonth : date.day;
    return DateTime(year, month, day);
  }

  DateTime _firstOccurrenceOnOrAfter(DateTime startDate, RecurrenceRule rule, DateTime threshold) {
    if (rule == RecurrenceRule.none) return startDate;
    if (!startDate.isBefore(threshold)) return startDate;
    return switch (rule) {
      RecurrenceRule.daily => startDate.add(Duration(days: threshold.difference(startDate).inDays)),
      RecurrenceRule.weekly => startDate.add(Duration(days: (threshold.difference(startDate).inDays ~/ 7) * 7)),
      RecurrenceRule.monthly => _advanceToMonth(startDate, threshold),
      RecurrenceRule.none => startDate,
    };
  }

  DateTime _advanceToMonth(DateTime startDate, DateTime threshold) {
    var cursor = startDate;
    while (cursor.isBefore(threshold)) {
      cursor = _addMonth(cursor);
    }
    return cursor;
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

  Future<void> _notificationSync() async {
    await NotificationService.instance.syncReminders(baseEvents);
  }
}

class _FocusSessionMeta {
  final int sessionId;
  final DateTime startTime;

  const _FocusSessionMeta({
    required this.sessionId,
    required this.startTime,
  });
}
