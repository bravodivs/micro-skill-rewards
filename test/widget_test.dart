import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momentum_learning_feed/app.dart';
import 'package:momentum_learning_feed/core/storage/app_database.dart';
import 'package:momentum_learning_feed/features/feed/application/feed_controller.dart';
import 'package:momentum_learning_feed/features/feed/data/progress_store.dart';
import 'package:momentum_learning_feed/features/feed/domain/progress_snapshot.dart';

import 'test_support.dart';

Future<({FeedController controller, AppDatabase appDatabase})>
createController({ProgressSnapshot snapshot = const ProgressSnapshot()}) async {
  final appDatabase = await openTestDatabase();
  final controller = FeedController(
    contentRepository: testRepository(appDatabase: appDatabase),
    progressStore: MemoryProgressStore(snapshot),
    now: () => DateTime(2026, 9, 24),
  );
  await controller.initialize();
  return (controller: controller, appDatabase: appDatabase);
}

void main() {
  testWidgets('onboarding opens the finite daily feed', (tester) async {
    final harness = (await tester.runAsync(createController))!;
    final controller = harness.controller;
    await tester.pumpWidget(MomentumApp(controller: controller));

    expect(find.text('Scroll less.\nGrow more.'), findsOneWidget);
    expect(find.textContaining('50 cards'), findsOneWidget);

    await tester.tap(find.textContaining('Start today'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() => controller.onPageViewed(0));

    expect(find.text('MOMENTUM'), findsOneWidget);
    expect(controller.allItems, hasLength(50));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(harness.appDatabase.close);
  });

  testWidgets('learning and bookmarking update the interface', (tester) async {
    final harness = (await tester.runAsync(
      () => createController(
        snapshot: const ProgressSnapshot(onboardingSeen: true),
      ),
    ))!;
    final controller = harness.controller;
    await tester.pumpWidget(MomentumApp(controller: controller));

    final currentItem = controller.allItems.first;
    if (currentItem.isInteractive) {
      final correctAnswer = find.text(
        currentItem.options[currentItem.correctOptionIndex!],
      );
      await tester.ensureVisible(correctAnswer);
      await tester.tap(correctAnswer);
    } else {
      final completeButton = find.byKey(const Key('complete_item_button'));
      await tester.ensureVisible(completeButton);
      await tester.tap(completeButton);
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Keep the momentum'), findsOneWidget);
    expect(controller.xp, currentItem.isInteractive ? 20 : 10);

    final bookmark = find.byTooltip('Save lesson');
    await tester.ensureVisible(bookmark);
    await tester.tap(bookmark);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Saved'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() => controller.onPageViewed(0));

    expect(find.text('Saved lessons'), findsOneWidget);
    expect(find.text(currentItem.title), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(harness.appDatabase.close);
  });
}
