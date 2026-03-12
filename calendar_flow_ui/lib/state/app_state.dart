import 'package:flutter/material.dart';

import '../data/local_database.dart';
import '../models/app_models.dart';

class AppState extends ChangeNotifier {
  AppState(this._database);

  final LocalDatabase _database;

  bool loading = true;
  bool onboarded = false;
  List<AppEvent> events = [];
  UserProfile? profile;

  Future<void> initialize() async {
    loading = true;
    notifyListeners();

    onboarded = await _database.fetchOnboarded();
    events = await _database.fetchEvents();
    profile = await _database.fetchProfile();

    loading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboarded = true;
    await _database.setOnboarded(true);
    notifyListeners();
  }

  Future<void> createEvent(AppEvent event) async {
    await _database.insertEvent(event);
    events = await _database.fetchEvents();
    notifyListeners();
  }

  Future<void> updateEvent(AppEvent event) async {
    await _database.updateEvent(event);
    events = await _database.fetchEvents();
    notifyListeners();
  }

  Future<void> deleteEvent(int id) async {
    await _database.deleteEvent(id);
    events = await _database.fetchEvents();
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile next) async {
    await _database.updateProfile(next);
    profile = await _database.fetchProfile();
    notifyListeners();
  }
}
