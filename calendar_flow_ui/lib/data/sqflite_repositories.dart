import '../models/app_models.dart';
import 'local_database.dart';
import 'repositories.dart';

class SqfliteEventRepository implements EventRepository {
  SqfliteEventRepository(this._db);

  final LocalDatabase _db;

  @override
  Future<void> createEvent(AppEvent event) async {
    await _db.insertEvent(event);
  }

  @override
  Future<void> deleteEvent(int id) async {
    await _db.deleteEvent(id);
  }

  @override
  Future<List<AppEvent>> fetchEvents() async {
    return _db.fetchEvents();
  }

  @override
  Future<void> updateEvent(AppEvent event) async {
    await _db.updateEvent(event);
  }

  @override
  Future<void> resetAllData() async {
    await _db.resetAllData();
  }

  @override
  Future<int> startFocusSession(int eventId) async {
    return _db.startFocusSession(eventId);
  }

  @override
  Future<void> endFocusSession(int sessionId) async {
    await _db.endFocusSession(sessionId);
  }

  @override
  Future<DailyProductivityStats> fetchDailyStats(DateTime date) async {
    return _db.fetchDailyStats(date);
  }

  @override
  Future<List<FocusSession>> fetchActiveFocusSessions() async {
    return _db.fetchActiveFocusSessions();
  }
}

class SqfliteProfileRepository implements ProfileRepository {
  SqfliteProfileRepository(this._db);

  final LocalDatabase _db;

  @override
  Future<UserProfile> fetchProfile() async {
    return _db.fetchProfile();
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await _db.updateProfile(profile);
  }
}

class SqfliteAppStateRepository implements AppStateRepository {
  SqfliteAppStateRepository(this._db);

  final LocalDatabase _db;

  @override
  Future<bool> fetchOnboarded() async {
    return _db.fetchOnboarded();
  }

  @override
  Future<void> setOnboarded(bool value) async {
    await _db.setOnboarded(value);
  }
}

class SqfliteMaintenanceRepository implements MaintenanceRepository {
  SqfliteMaintenanceRepository(this._db);

  final LocalDatabase _db;

  @override
  Future<AppDataSnapshot> snapshot() async {
    return _db.snapshot();
  }

  @override
  Future<void> restore(AppDataSnapshot snapshot) async {
    await _db.restoreSnapshot(snapshot);
  }
}
