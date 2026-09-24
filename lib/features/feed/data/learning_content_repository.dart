import 'dart:convert';
import 'dart:math';

import 'package:momentum_learning_feed/features/feed/data/catalog_source.dart';
import 'package:momentum_learning_feed/features/feed/domain/catalog_manifest.dart';
import 'package:momentum_learning_feed/features/feed/domain/daily_pack.dart';
import 'package:momentum_learning_feed/features/feed/domain/learning_item.dart';
import 'package:sqflite/sqflite.dart';

class LearningContentRepository {
  LearningContentRepository({
    required this.database,
    required this.bundledSource,
    this.remoteSource,
  });

  final Database database;
  final CatalogSource bundledSource;
  final CatalogSource? remoteSource;

  CatalogManifest? _manifest;
  String? lastSyncError;

  int get dailyCap => _manifest?.dailyCap ?? 50;

  Future<List<DailyPackEntry>> prepareDailyPack(DateTime date) async {
    await _seedBundledCatalogIfNeeded();
    await _loadStoredManifest();
    await _refreshRemoteCatalog();
    final dateKey = _dateOnly(date);
    final existing = await loadDailyPack(dateKey);
    if (existing.isNotEmpty) return existing;

    if (await _unseenCount() == 0) {
      await _fetchRemoteUntilUnseen(1);
    }
    final hasMoreRemote = await _hasUnfetchedRemoteBatches();
    await _createDailyPack(
      dateKey,
      allowSeenFallback:
          remoteSource == null || !hasMoreRemote || lastSyncError != null,
    );
    return loadDailyPack(dateKey);
  }

  Future<List<DailyPackEntry>> prefetchNearEnd({
    required DateTime date,
    required int currentIndex,
  }) async {
    final dateKey = _dateOnly(date);
    final currentCount = _firstInt(
      await database.rawQuery(
        'SELECT COUNT(*) FROM daily_pack WHERE pack_date = ?',
        [dateKey],
      ),
    );
    final unseen = await _unseenCount();
    final nearEnd = currentCount - currentIndex <= 3;
    final threshold = _manifest?.minPrefetchUnseen ?? 20;

    if (nearEnd || unseen < threshold) {
      await _fetchNextRemoteBatch();
      await _extendDailyPack(dateKey);
    }
    return loadDailyPack(dateKey);
  }

  Future<List<DailyPackEntry>> loadDailyPack(String dateKey) async {
    final rows = await database.rawQuery(
      '''
      SELECT p.position, p.option_order, p.completed, p.selected_answer, c.json
      FROM daily_pack p
      JOIN cards c ON c.id = p.card_id
      WHERE p.pack_date = ?
      ORDER BY p.position
      ''',
      [dateKey],
    );
    return rows
        .map((row) {
          final original = LearningItem.fromJson(
            jsonDecode(row['json'] as String) as Map<String, dynamic>,
          );
          final optionOrder = (jsonDecode(
            row['option_order'] as String,
          ) as List).map((value) => value as int).toList(growable: false);
          final item = optionOrder.isEmpty
              ? original
              : original.withOptionOrder(optionOrder);
          return DailyPackEntry(
            item: item,
            position: row['position'] as int,
            optionOrder: optionOrder,
            completed: (row['completed'] as int) == 1,
            selectedAnswer: row['selected_answer'] as int?,
          );
        })
        .toList(growable: false);
  }

  Future<void> completeCard({
    required String dateKey,
    required LearningItem item,
    required int? selectedAnswer,
  }) async {
    final correct = selectedAnswer == null
        ? null
        : selectedAnswer == item.correctOptionIndex;
    await database.transaction((txn) async {
      await txn.update(
        'daily_pack',
        {'completed': 1, 'selected_answer': selectedAnswer},
        where: 'pack_date = ? AND card_id = ?',
        whereArgs: [dateKey, item.id],
      );
      await txn.insert('card_history', {
        'card_id': item.id,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
        'correct': correct == null ? null : (correct ? 1 : 0),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<LearningItem>> loadCardsByIds(Iterable<String> ids) async {
    final idList = ids.toList(growable: false);
    if (idList.isEmpty) return const [];
    final placeholders = List.filled(idList.length, '?').join(',');
    final rows = await database.rawQuery(
      'SELECT json FROM cards WHERE id IN ($placeholders)',
      idList,
    );
    final byId = <String, LearningItem>{
      for (final row in rows)
        (jsonDecode(row['json'] as String) as Map<String, dynamic>)['id']
            as String: LearningItem.fromJson(
          jsonDecode(row['json'] as String) as Map<String, dynamic>,
        ),
    };
    return [
      for (final id in idList)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Future<void> _seedBundledCatalogIfNeeded() async {
    final cardCount = _firstInt(
      await database.rawQuery('SELECT COUNT(*) FROM cards'),
    );
    if (cardCount > 0) return;

    final manifest = await bundledSource.fetchManifest();
    _manifest = manifest;
    for (final batch in manifest.batches) {
      final cards = await bundledSource.fetchBatch(batch);
      await _storeBatch(batch, cards, source: 'bundle');
    }
    await _storeManifest(manifest);
  }

  Future<void> _loadStoredManifest() async {
    final rows = await database.query(
      'metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['catalog_manifest'],
      limit: 1,
    );
    if (rows.isEmpty) return;
    _manifest = CatalogManifest.fromJson(
      jsonDecode(rows.single['value'] as String) as Map<String, dynamic>,
    );
  }

  Future<void> _refreshRemoteCatalog() async {
    final source = remoteSource;
    if (source == null) return;
    try {
      final remoteManifest = await source.fetchManifest();
      _manifest = remoteManifest;
      lastSyncError = null;
      await _storeManifest(remoteManifest);
    } catch (error) {
      lastSyncError = error.toString();
    }
  }

  Future<void> _fetchRemoteUntilUnseen(int target) async {
    if (remoteSource == null) return;
    while (await _unseenCount() < target) {
      final fetched = await _fetchNextRemoteBatch();
      if (!fetched) break;
    }
  }

  Future<bool> _fetchNextRemoteBatch() async {
    final manifest = _manifest;
    final source = remoteSource;
    if (source == null || manifest == null) return false;
    final fetchedRows = await database.query(
      'batches',
      columns: ['id'],
      where: 'source = ?',
      whereArgs: ['remote'],
    );
    final fetched = fetchedRows.map((row) => row['id'] as String).toSet();
    CatalogBatch? next;
    for (final batch in manifest.batches) {
      if (!fetched.contains('remote:${batch.id}')) {
        next = batch;
        break;
      }
    }
    if (next == null) return false;
    try {
      final cards = await source.fetchBatch(next);
      await _storeBatch(next, cards, source: 'remote');
      lastSyncError = null;
      return true;
    } catch (error) {
      lastSyncError = error.toString();
      return false;
    }
  }

  Future<bool> _hasUnfetchedRemoteBatches() async {
    final manifest = _manifest;
    if (remoteSource == null || manifest == null) return false;
    final fetchedRows = await database.query(
      'batches',
      columns: ['id'],
      where: 'source = ?',
      whereArgs: ['remote'],
    );
    final fetched = fetchedRows.map((row) => row['id'] as String).toSet();
    return manifest.batches.any(
      (batch) => !fetched.contains('remote:${batch.id}'),
    );
  }

  Future<void> _storeBatch(
    CatalogBatch batch,
    List<LearningItem> cards, {
    required String source,
  }) async {
    final importedAt = DateTime.now().toUtc().toIso8601String();
    await database.transaction((txn) async {
      for (final card in cards) {
        await txn.insert('cards', {
          'id': card.id,
          'topic': card.topic.name,
          'type': card.type.name,
          'json': jsonEncode(card.toJson()),
          'imported_at': importedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await txn.insert('batches', {
        'id': '$source:${batch.id}',
        'path': batch.path,
        'fetched_at': importedAt,
        'source': source,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> _storeManifest(CatalogManifest manifest) async {
    await database.insert('metadata', {
      'key': 'catalog_manifest',
      'value': jsonEncode(manifest.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> _unseenCount() async => _firstInt(
    await database.rawQuery('''
      SELECT COUNT(*)
      FROM cards c
      LEFT JOIN card_history h ON h.card_id = c.id
      WHERE h.card_id IS NULL
      '''),
  );

  Future<void> _createDailyPack(
    String dateKey, {
    required bool allowSeenFallback,
  }) async {
    final unseenRows = await database.rawQuery('''
      SELECT c.id
      FROM cards c
      LEFT JOIN card_history h ON h.card_id = c.id
      WHERE h.card_id IS NULL
      ORDER BY c.id
      ''');
    final candidateIds = unseenRows.map((row) => row['id'] as String).toList();
    candidateIds.shuffle(Random(_stableSeed(dateKey)));

    if (allowSeenFallback && candidateIds.length < dailyCap) {
      final allRows = await database.query('cards', columns: ['id']);
      final fallback =
          allRows
              .map((row) => row['id'] as String)
              .where((id) => !candidateIds.contains(id))
              .toList()
            ..shuffle(Random(_stableSeed('$dateKey:fallback')));
      candidateIds.addAll(fallback);
    }
    await _insertPackEntries(
      dateKey,
      candidateIds.take(dailyCap).toList(),
      startPosition: 0,
    );
  }

  Future<void> _extendDailyPack(String dateKey) async {
    final currentRows = await database.query(
      'daily_pack',
      columns: ['card_id'],
      where: 'pack_date = ?',
      whereArgs: [dateKey],
      orderBy: 'position',
    );
    if (currentRows.length >= dailyCap) return;
    final existing = currentRows.map((row) => row['card_id'] as String).toSet();
    final candidates = await database.rawQuery('''
      SELECT c.id
      FROM cards c
      LEFT JOIN card_history h ON h.card_id = c.id
      WHERE h.card_id IS NULL
      ORDER BY c.imported_at, c.id
      ''');
    final additions = candidates
        .map((row) => row['id'] as String)
        .where((id) => !existing.contains(id))
        .take(dailyCap - currentRows.length)
        .toList();
    await _insertPackEntries(
      dateKey,
      additions,
      startPosition: currentRows.length,
    );
  }

  Future<void> _insertPackEntries(
    String dateKey,
    List<String> cardIds, {
    required int startPosition,
  }) async {
    if (cardIds.isEmpty) return;
    final cards = await loadCardsByIds(cardIds);
    final cardsById = {for (final card in cards) card.id: card};
    await database.transaction((txn) async {
      for (var index = 0; index < cardIds.length; index++) {
        final card = cardsById[cardIds[index]]!;
        final optionOrder = List<int>.generate(card.options.length, (i) => i);
        optionOrder.shuffle(Random(_stableSeed('$dateKey:${card.id}:options')));
        await txn.insert('daily_pack', {
          'pack_date': dateKey,
          'position': startPosition + index,
          'card_id': card.id,
          'option_order': jsonEncode(optionOrder),
          'completed': 0,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  int _stableSeed(String value) {
    var hash = 17;
    for (final unit in value.codeUnits) {
      hash = 0x1fffffff & (hash * 31 + unit);
    }
    return hash;
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

int _firstInt(List<Map<String, Object?>> rows) {
  if (rows.isEmpty || rows.first.isEmpty) return 0;
  return rows.first.values.first as int? ?? 0;
}
