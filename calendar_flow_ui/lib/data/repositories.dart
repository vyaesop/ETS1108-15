import '../models/app_models.dart';

abstract class EventRepository {
  Future<List<AppEvent>> fetchEvents();
  Future<void> createEvent(AppEvent event);
  Future<void> updateEvent(AppEvent event);
  Future<void> deleteEvent(int id);
  Future<void> resetAllData();
  Future<int> startFocusSession(int eventId);
  Future<void> endFocusSession(int sessionId);
  Future<DailyProductivityStats> fetchDailyStats(DateTime date);
  Future<List<FocusSession>> fetchActiveFocusSessions();
}

abstract class ProfileRepository {
  Future<UserProfile> fetchProfile();
  Future<void> updateProfile(UserProfile profile);
}

abstract class AppStateRepository {
  Future<bool> fetchOnboarded();
  Future<void> setOnboarded(bool value);
}

abstract class MaintenanceRepository {
  Future<AppDataSnapshot> snapshot();
  Future<void> restore(AppDataSnapshot snapshot);
}
