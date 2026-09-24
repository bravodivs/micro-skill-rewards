import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

void main() {
  test('prefetches one remote batch near the end and extends today', () async {
    final appDatabase = await openTestDatabase();
    addTearDown(appDatabase.close);
    final bundled = fakeCatalog(batchCount: 1);
    final remote = fakeCatalog(batchCount: 5, start: 100);
    final repository = testRepository(
      appDatabase: appDatabase,
      bundled: bundled,
      remote: remote,
    );

    final initial = await repository.prepareDailyPack(DateTime(2026, 9, 24));
    expect(initial, hasLength(10));
    expect(remote.fetchedBatchCount, 0);

    final extended = await repository.prefetchNearEnd(
      date: DateTime(2026, 9, 24),
      currentIndex: 8,
    );

    expect(remote.fetchedBatchCount, 1);
    expect(extended, hasLength(20));
    expect(extended.map((entry) => entry.item.id), contains('card-100'));
  });

  test('serves the bundled cache without a network source', () async {
    final appDatabase = await openTestDatabase();
    addTearDown(appDatabase.close);
    final repository = testRepository(
      appDatabase: appDatabase,
      bundled: fakeCatalog(batchCount: 1),
    );

    final pack = await repository.prepareDailyPack(DateTime(2026, 9, 24));

    expect(pack, hasLength(10));
    expect(repository.lastSyncError, isNull);
  });

  test('reuses the same persisted pack and option order on reopen', () async {
    final appDatabase = await openTestDatabase();
    addTearDown(appDatabase.close);
    final repository = testRepository(appDatabase: appDatabase);

    final first = await repository.prepareDailyPack(DateTime(2026, 9, 24));
    final second = await repository.prepareDailyPack(DateTime(2026, 9, 24));

    expect(
      second.map((entry) => entry.item.id),
      first.map((entry) => entry.item.id),
    );
    expect(
      second.map((entry) => entry.optionOrder),
      first.map((entry) => entry.optionOrder),
    );
  });
}
