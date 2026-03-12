import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../mock_data.dart';
import '../models/app_models.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const _dbName = 'chrono_ui.db';
  static const _dbVersion = 2;

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
        attendees TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        reminder INTEGER NOT NULL
      )
    ''');

    await _createIndexes(database);
  }

  Future<void> _createIndexes(Database database) async {
    await database.execute('CREATE INDEX IF NOT EXISTS idx_events_date ON events(date)');
    await database.execute('CREATE INDEX IF NOT EXISTS idx_events_start_minutes ON events(start_minutes)');
  }

  Future<void> _seed(Database database) async {
    await database.insert('app_state', {'id': 1, 'onboarded': 0});
    await database.insert('profiles', MockData.defaultProfile.toMap());
    for (final event in MockData.seedEvents()) {
      await database.insert('events', event.toMap()..remove('id'));
    }
  }

  Future<void> _migrate(Database database, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await _createIndexes(database);
    }
  }

  Future<List<AppEvent>> fetchEvents() async {
    final database = await db;
    final maps = await database.query('events', orderBy: 'date ASC, start_minutes ASC');
    return maps.map(AppEvent.fromMap).toList();
  }

  Future<int> insertEvent(AppEvent event) async {
    final database = await db;
    return database.transaction(
      (txn) => txn.insert('events', event.toMap()..remove('id')),
    );
  }

  Future<void> updateEvent(AppEvent event) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.update(
        'events',
        event.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [event.id],
      );
    });
  }

  Future<void> deleteEvent(int id) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('events', where: 'id = ?', whereArgs: [id]);
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
