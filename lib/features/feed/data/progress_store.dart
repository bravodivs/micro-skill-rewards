import 'package:momentum_learning_feed/features/feed/domain/progress_snapshot.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class ProgressStore {
  Future<ProgressSnapshot> load();
  Future<void> save(ProgressSnapshot snapshot);
}

class SqliteProgressStore implements ProgressStore {
  const SqliteProgressStore(this.database);

  final Database database;

  @override
  Future<ProgressSnapshot> load() async {
    final progressRows = await database.query(
      'progress',
      where: 'id = 1',
      limit: 1,
    );
    final savedRows = await database.query('saved_cards');
    final progress = progressRows.isEmpty
        ? const <String, Object?>{}
        : progressRows.single;

    return ProgressSnapshot(
      xp: progress['xp'] as int? ?? 0,
      streak: progress['streak'] as int? ?? 1,
      savedIds: savedRows.map((row) => row['card_id'] as String).toSet(),
      onboardingSeen: (progress['onboarding_seen'] as int? ?? 0) == 1,
      lastActiveDate: progress['last_active_date'] as String?,
    );
  }

  @override
  Future<void> save(ProgressSnapshot snapshot) async {
    await database.transaction((txn) async {
      await txn.insert('progress', {
        'id': 1,
        'xp': snapshot.xp,
        'streak': snapshot.streak,
        'onboarding_seen': snapshot.onboardingSeen ? 1 : 0,
        'last_active_date': snapshot.lastActiveDate,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete('saved_cards');
      for (final cardId in snapshot.savedIds) {
        await txn.insert('saved_cards', {
          'card_id': cardId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }
}

class MemoryProgressStore implements ProgressStore {
  MemoryProgressStore([this.snapshot = const ProgressSnapshot()]);

  ProgressSnapshot snapshot;

  @override
  Future<ProgressSnapshot> load() async => snapshot;

  @override
  Future<void> save(ProgressSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
