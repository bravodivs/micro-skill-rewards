import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';

class AppDatabase {
  AppDatabase._(this.database);

  final Database database;

  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final selectedFactory = factory ?? databaseFactory;
    final databasePath =
        path ??
        p.join(await selectedFactory.getDatabasesPath(), 'momentum_feed.db');
    final database = await selectedFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createSchema,
        onOpen: (db) async {
          await db.insert('progress', {
            'id': 1,
            'xp': 0,
            'streak': 1,
            'onboarding_seen': 0,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        },
      ),
    );
    return AppDatabase._(database);
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cards (
        id TEXT PRIMARY KEY,
        topic TEXT NOT NULL,
        type TEXT NOT NULL,
        json TEXT NOT NULL,
        imported_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE batches (
        id TEXT PRIMARY KEY,
        path TEXT NOT NULL,
        fetched_at TEXT NOT NULL,
        source TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE progress (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        xp INTEGER NOT NULL DEFAULT 0,
        streak INTEGER NOT NULL DEFAULT 1,
        onboarding_seen INTEGER NOT NULL DEFAULT 0,
        last_active_date TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE saved_cards (
        card_id TEXT PRIMARY KEY REFERENCES cards(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE card_history (
        card_id TEXT PRIMARY KEY REFERENCES cards(id) ON DELETE CASCADE,
        completed_at TEXT NOT NULL,
        correct INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE daily_pack (
        pack_date TEXT NOT NULL,
        position INTEGER NOT NULL,
        card_id TEXT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
        option_order TEXT NOT NULL DEFAULT '[]',
        completed INTEGER NOT NULL DEFAULT 0,
        selected_answer INTEGER,
        PRIMARY KEY (pack_date, position),
        UNIQUE (pack_date, card_id)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_daily_pack_date ON daily_pack(pack_date, position)',
    );
    await db.insert('progress', {
      'id': 1,
      'xp': 0,
      'streak': 1,
      'onboarding_seen': 0,
    });
  }

  Future<void> close() => database.close();
}
