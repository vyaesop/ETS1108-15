import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../models/app_models.dart';

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

  Future<void> initialize() async {
    await _runGuarded(() async {
      loading = true;
      notifyListeners();

      onboarded = await _appStateRepository.fetchOnboarded();
      events = await _eventRepository.fetchEvents();
      profile = await _profileRepository.fetchProfile();

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
    });
  }

  Future<void> updateEvent(AppEvent event) async {
    await _runGuarded(() async {
      await _eventRepository.updateEvent(event);
      events = await _eventRepository.fetchEvents();
    });
  }

  Future<void> deleteEvent(int id) async {
    await _runGuarded(() async {
      await _eventRepository.deleteEvent(id);
      events = await _eventRepository.fetchEvents();
    });
  }

  Future<void> saveProfile(UserProfile next) async {
    await _runGuarded(() async {
      await _profileRepository.updateProfile(next);
      profile = await _profileRepository.fetchProfile();
    });
  }

  void clearError() {
    lastError = null;
    notifyListeners();
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
