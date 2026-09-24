import 'package:flutter_test/flutter_test.dart';
import 'package:momentum_learning_feed/features/feed/application/feed_controller.dart';
import 'package:momentum_learning_feed/features/feed/data/progress_store.dart';
import 'package:momentum_learning_feed/features/feed/domain/progress_snapshot.dart';

import 'test_support.dart';

void main() {
  test('draws a finite 50-card daily pack', () async {
    final appDatabase = await openTestDatabase();
    addTearDown(appDatabase.close);
    final controller = FeedController(
      contentRepository: testRepository(appDatabase: appDatabase),
      progressStore: SqliteProgressStore(appDatabase.database),
      now: () => DateTime(2026, 9, 24),
    );

    await controller.initialize();

    expect(controller.allItems, hasLength(50));
    expect(controller.dailyLimit, 50);
    expect(controller.completedCount, 0);
  });

  test('awards XP once and persists shuffled quiz scoring', () async {
    final appDatabase = await openTestDatabase();
    addTearDown(appDatabase.close);
    final controller = FeedController(
      contentRepository: testRepository(appDatabase: appDatabase),
      progressStore: SqliteProgressStore(appDatabase.database),
      now: () => DateTime(2026, 9, 24),
    );
    await controller.initialize();
    final quiz = controller.allItems.firstWhere((item) => item.isInteractive);

    expect(
      await controller.completeItem(
        quiz,
        selectedOption: quiz.correctOptionIndex,
      ),
      20,
    );
    expect(
      await controller.completeItem(
        quiz,
        selectedOption: quiz.correctOptionIndex,
      ),
      0,
    );

    final reloaded = await controller.contentRepository.loadDailyPack(
      '2026-09-24',
    );
    final savedQuiz = reloaded.firstWhere((entry) => entry.item.id == quiz.id);
    expect(savedQuiz.completed, isTrue);
    expect(savedQuiz.selectedAnswer, quiz.correctOptionIndex);
    expect(controller.xp, 20);
  });

  test('a new day resets daily completion but keeps lifetime XP', () async {
    final appDatabase = await openTestDatabase();
    addTearDown(appDatabase.close);
    final repository = testRepository(appDatabase: appDatabase);
    final progressStore = SqliteProgressStore(appDatabase.database);
    final dayOne = FeedController(
      contentRepository: repository,
      progressStore: progressStore,
      now: () => DateTime(2026, 9, 24),
    );
    await dayOne.initialize();
    final concept = dayOne.allItems.firstWhere((item) => !item.isInteractive);
    await dayOne.completeItem(concept);

    final dayTwo = FeedController(
      contentRepository: repository,
      progressStore: progressStore,
      now: () => DateTime(2026, 9, 25),
    );
    await dayTwo.initialize();

    expect(dayTwo.completedCount, 0);
    expect(dayTwo.xp, 10);
    expect(dayTwo.streak, 2);
    expect(dayTwo.allItems, hasLength(50));
  });

  test('loads saved progress from SQLite', () async {
    final appDatabase = await openTestDatabase();
    addTearDown(appDatabase.close);
    final store = SqliteProgressStore(appDatabase.database);
    await store.save(
      const ProgressSnapshot(
        xp: 35,
        streak: 3,
        onboardingSeen: true,
        lastActiveDate: '2026-09-24',
      ),
    );
    final restored = await store.load();

    expect(restored.xp, 35);
    expect(restored.streak, 3);
    expect(restored.onboardingSeen, isTrue);
  });
}
