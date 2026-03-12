import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../mock_data.dart';
import '../models/app_models.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const _dbName = 'chrono_ui.db';
  static const _dbVersion = 5;

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (database, version) async {
        await _createSchema(database);
        await _seed(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        await _migrate(database, oldVersion, newVersion);
      },
    );
  }

  Future<void> _createSchema(Database database) async {
    await database.execute('''
      CREATE TABLE app_state(
        id INTEGER PRIMARY KEY,
        onboarded INTEGER NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE profiles(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        city TEXT NOT NULL,
        timezone TEXT NOT NULL,
        goals TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        start_minutes INTEGER NOT NULL,
        end_minutes INTEGER NOT NULL,
        location TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        reminder INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL DEFAULT 30,
        completed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await database.execute('''
      CREATE TABLE event_attendees(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        attendee TEXT NOT NULL,
        FOREIGN KEY(event_id) REFERENCES events(id) ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE focus_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration_minutes INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(event_id) REFERENCES events(id) ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE daily_stats(
        date TEXT PRIMARY KEY,
        tasks_completed INTEGER NOT NULL DEFAULT 0,
        focus_minutes INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _createIndexes(database);
  }

  Future<void> _createIndexes(Database database) async {
    await _createEventIndexes(database);
    await _createAttendeeIndex(database);
  }

  Future<void> _createEventIndexes(DatabaseExecutor database) async {
    await database.execute('CREATE INDEX IF NOT EXISTS idx_events_date ON events(date)');
    await database.execute('CREATE INDEX IF NOT EXISTS idx_events_start_minutes ON events(start_minutes)');
  }

  Future<void> _createAttendeeIndex(DatabaseExecutor database) async {
    await database.execute('CREATE INDEX IF NOT EXISTS idx_event_attendees_event_id ON event_attendees(event_id)');
  }

  Future<void> _seed(Database database) async {
    await database.insert('app_state', {'id': 1, 'onboarded': 0});
    await database.insert('profiles', MockData.defaultProfile.toMap());
    for (final event in MockData.seedEvents()) {
      final eventId = await database.insert('events', event.toMap()..remove('id'));
      for (final attendee in event.attendees) {
        await database.insert('event_attendees', {'event_id': eventId, 'attendee': attendee});
      }
    }
  }

  Future<void> _migrate(Database database, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await _createEventIndexes(database);
    }

    if (oldVersion < 3 && newVersion >= 3) {
      await database.execute('''
        CREATE TABLE IF NOT EXISTS event_attendees(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          attendee TEXT NOT NULL,
          FOREIGN KEY(event_id) REFERENCES events(id) ON DELETE CASCADE
        )
      ''');

      final columns = await database.rawQuery("PRAGMA table_info(events)");
      final hasLegacyAttendees = columns.any((c) => c['name'] == 'attendees');
      if (hasLegacyAttendees) {
        final eventRows = await database.query('events', columns: ['id', 'attendees']);
        for (final row in eventRows) {
          final eventId = row['id'] as int;
          final serialized = (row['attendees'] as String?) ?? '';
          final parsed = serialized
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          for (final attendee in parsed) {
            await database.insert('event_attendees', {'event_id': eventId, 'attendee': attendee});
          }
        }
      }

      await _createAttendeeIndex(database);
    }

    if (oldVersion < 4 && newVersion >= 4) {
      await database.execute('ALTER TABLE events ADD COLUMN duration_minutes INTEGER');
      await database.execute('ALTER TABLE events ADD COLUMN completed INTEGER DEFAULT 0');
      await database.execute('UPDATE events SET duration_minutes = 30 WHERE duration_minutes IS NULL');
      await database.execute('UPDATE events SET completed = 0 WHERE completed IS NULL');
    }

    if (oldVersion < 5 && newVersion >= 5) {
      await database.execute('''
        CREATE TABLE IF NOT EXISTS focus_sessions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          start_time TEXT NOT NULL,
          end_time TEXT,
          duration_minutes INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(event_id) REFERENCES events(id) ON DELETE CASCADE
        )
      ''');

      await database.execute('''
        CREATE TABLE IF NOT EXISTS daily_stats(
          date TEXT PRIMARY KEY,
          tasks_completed INTEGER NOT NULL DEFAULT 0,
          focus_minutes INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
  }

  Future<List<AppEvent>> fetchEvents() async {
    final database = await db;
    final eventMaps = await database.query('events', orderBy: 'date ASC, start_minutes ASC');
    if (eventMaps.isEmpty) return [];

    final attendeeRows = await database.query('event_attendees', orderBy: 'id ASC');
    final byEvent = <int, List<String>>{};
    for (final row in attendeeRows) {
      final eventId = row['event_id'] as int;
      byEvent.putIfAbsent(eventId, () => []).add(row['attendee'] as String);
    }

    return eventMaps
        .map((map) => AppEvent.fromMap(map, attendees: byEvent[(map['id'] as int)] ?? const []))
        .toList();
  }

  Future<int> insertEvent(AppEvent event) async {
    final database = await db;
    return database.transaction((txn) async {
      final id = await txn.insert('events', event.toMap()..remove('id'));
      await _replaceAttendees(txn, id, event.attendees);
      return id;
    });
  }

  Future<void> updateEvent(AppEvent event) async {
    final database = await db;
    await database.transaction((txn) async {
      final before = await txn.query('events', columns: ['completed'], where: 'id = ?', whereArgs: [event.id], limit: 1);
      final previousCompleted = before.isNotEmpty && ((before.first['completed'] ?? 0) as int) == 1;

      await txn.update(
        'events',
        event.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [event.id],
      );
      if (event.id != null) {
        await _replaceAttendees(txn, event.id!, event.attendees);
      }

      if (!previousCompleted && event.completed) {
        await _incrementDailyStats(
          txn,
          DateTime.now(),
          tasksCompletedDelta: 1,
          focusMinutesDelta: 0,
        );
      }
    });
  }

  Future<void> _replaceAttendees(Transaction txn, int eventId, List<String> attendees) async {
    await txn.delete('event_attendees', where: 'event_id = ?', whereArgs: [eventId]);
    for (final attendee in attendees.map((e) => e.trim()).where((e) => e.isNotEmpty)) {
      await txn.insert('event_attendees', {'event_id': eventId, 'attendee': attendee});
    }
  }

  Future<void> deleteEvent(int id) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('event_attendees', where: 'event_id = ?', whereArgs: [id]);
      await txn.delete('events', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> startFocusSession(int eventId) async {
    final database = await db;
    return database.transaction((txn) async {
      final id = await txn.insert('focus_sessions', {
        'event_id': eventId,
        'start_time': DateTime.now().toIso8601String(),
        'end_time': null,
        'duration_minutes': 0,
      });
      return id;
    });
  }

  Future<void> endFocusSession(int sessionId) async {
    final database = await db;
    await database.transaction((txn) async {
      final rows = await txn.query('focus_sessions', where: 'id = ?', whereArgs: [sessionId], limit: 1);
      if (rows.isEmpty) return;

      final row = rows.first;
      final start = DateTime.parse(row['start_time'] as String);
      final end = DateTime.now();
      final duration = end.difference(start).inMinutes <= 0 ? 1 : end.difference(start).inMinutes;

      await txn.update(
        'focus_sessions',
        {
          'end_time': end.toIso8601String(),
          'duration_minutes': duration,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      await _incrementDailyStats(txn, end, tasksCompletedDelta: 0, focusMinutesDelta: duration);
    });
  }

  Future<void> _incrementDailyStats(
    Transaction txn,
    DateTime day, {
    required int tasksCompletedDelta,
    required int focusMinutesDelta,
  }) async {
    final key = DateTime(day.year, day.month, day.day).toIso8601String();
    final rows = await txn.query('daily_stats', where: 'date = ?', whereArgs: [key], limit: 1);

    if (rows.isEmpty) {
      await txn.insert('daily_stats', {
        'date': key,
        'tasks_completed': tasksCompletedDelta,
        'focus_minutes': focusMinutesDelta,
      });
      return;
    }

    final current = rows.first;
    await txn.update(
      'daily_stats',
      {
        'tasks_completed': (current['tasks_completed'] as int) + tasksCompletedDelta,
        'focus_minutes': (current['focus_minutes'] as int) + focusMinutesDelta,
      },
      where: 'date = ?',
      whereArgs: [key],
    );
  }

  Future<DailyProductivityStats> fetchDailyStats(DateTime date) async {
    final database = await db;
    final key = DateTime(date.year, date.month, date.day).toIso8601String();
    final rows = await database.query('daily_stats', where: 'date = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return DailyProductivityStats.empty(date);
    return DailyProductivityStats.fromMap(rows.first);
  }

  Future<void> resetAllData() async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('focus_sessions');
      await txn.delete('daily_stats');
      await txn.delete('event_attendees');
      await txn.delete('events');
      await txn.delete('profiles');
      await txn.delete('app_state');
      await txn.insert('app_state', {'id': 1, 'onboarded': 0});
      await txn.insert('profiles', MockData.defaultProfile.toMap());
      for (final event in MockData.seedEvents()) {
        final eventId = await txn.insert('events', event.toMap()..remove('id'));
        for (final attendee in event.attendees) {
          await txn.insert('event_attendees', {'event_id': eventId, 'attendee': attendee});
        }
      }
    });
  }

  Future<UserProfile> fetchProfile() async {
    final database = await db;
    final maps = await database.query('profiles', where: 'id = 1', limit: 1);
    return UserProfile.fromMap(maps.first);
  }

  Future<void> updateProfile(UserProfile profile) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.update('profiles', profile.toMap(), where: 'id = 1');
    });
  }

  Future<bool> fetchOnboarded() async {
    final database = await db;
    final maps = await database.query('app_state', where: 'id = 1', limit: 1);
    return (maps.first['onboarded'] as int) == 1;
  }

  Future<void> setOnboarded(bool value) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.update('app_state', {'onboarded': value ? 1 : 0}, where: 'id = 1');
    });
  }
}
