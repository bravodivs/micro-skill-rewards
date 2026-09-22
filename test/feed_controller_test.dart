import 'package:flutter_test/flutter_test.dart';
import 'package:momentum_learning_feed/features/feed/application/feed_controller.dart';
import 'package:momentum_learning_feed/features/feed/data/learning_content_repository.dart';
import 'package:momentum_learning_feed/features/feed/data/progress_store.dart';
import 'package:momentum_learning_feed/features/feed/domain/learning_item.dart';
import 'package:momentum_learning_feed/features/feed/domain/progress_snapshot.dart';

Future<FeedController> buildController({
  ProgressSnapshot snapshot = const ProgressSnapshot(),
  DateTime? now,
}) async {
  final controller = FeedController(
    contentRepository: const LearningContentRepository(),
    progressStore: MemoryProgressStore(snapshot),
    now: () => now ?? DateTime(2026, 8, 29),
  );
  await controller.initialize();
  return controller;
}

void main() {
  group('FeedController', () {
    test('awards XP once for a completed concept', () async {
      final controller = await buildController();
      final concept = controller.allItems.first;

      expect(await controller.completeItem(concept), 10);
      expect(await controller.completeItem(concept), 0);
      expect(controller.xp, 10);
      expect(controller.completedCount, 1);
    });

    test('scores correct and incorrect answers deterministically', () async {
      final controller = await buildController();
      final quizzes = controller.allItems.where((item) => item.isInteractive);

      final correct = quizzes.first;
      final incorrect = quizzes.skip(1).first;
      expect(
        await controller.completeItem(
          correct,
          selectedOption: correct.correctOptionIndex,
        ),
        20,
      );
      expect(
        await controller.completeItem(
          incorrect,
          selectedOption:
              (incorrect.correctOptionIndex! + 1) % incorrect.options.length,
        ),
        5,
      );
      expect(controller.xp, 25);
    });

    test('filters items without discarding progress', () async {
      final controller = await buildController();
      final first = controller.allItems.first;
      await controller.completeItem(first);

      controller.selectTopic(LearningTopic.functional);

      expect(
        controller.visibleItems.every(
          (item) => item.topic == LearningTopic.functional,
        ),
        isTrue,
      );
      expect(controller.isCompleted(first.id), isTrue);
    });

    test('increments a consecutive daily streak', () async {
      final controller = await buildController(
        snapshot: const ProgressSnapshot(
          streak: 4,
          lastActiveDate: '2026-08-28',
        ),
        now: DateTime(2026, 8, 29),
      );

      expect(controller.streak, 5);
      expect(controller.snapshot.lastActiveDate, '2026-08-29');
    });
  });
}
