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
    final harness = await createController();
    debugPrint('widget-test: controller ready');
    final controller = harness.controller;
    await tester.pumpWidget(MomentumApp(controller: controller));
    debugPrint('widget-test: onboarding pumped');

    expect(find.text('Scroll less.\nGrow more.'), findsOneWidget);
    expect(find.textContaining('50 cards'), findsOneWidget);
    debugPrint('widget-test: onboarding verified');

    await tester.tap(find.textContaining('Start today'));
    debugPrint('widget-test: start tapped');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    debugPrint('widget-test: feed pumped');
    await controller.onPageViewed(0);
    debugPrint('widget-test: prefetch complete');

    expect(find.text('MOMENTUM'), findsOneWidget);
    expect(controller.allItems, hasLength(50));
    debugPrint('widget-test: feed verified');
    await tester.pumpWidget(const SizedBox.shrink());
    debugPrint('widget-test: app unmounted');
    await harness.appDatabase.close();
    debugPrint('widget-test: database closed');
  });

  testWidgets('learning and bookmarking update the interface', (tester) async {
    final harness = await createController(
      snapshot: const ProgressSnapshot(onboardingSeen: true),
    );
    final controller = harness.controller;
    await tester.pumpWidget(MomentumApp(controller: controller));

    final concept = controller.allItems.firstWhere(
      (item) => !item.isInteractive,
    );
    final conceptIndex = controller.allItems.indexOf(concept);
    final pageView = find.byType(PageView);
    for (var index = 0; index < conceptIndex; index++) {
      await tester.drag(pageView, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 500));
    }

    final completeButton = find.byKey(const Key('complete_item_button'));
    await tester.ensureVisible(completeButton);
    await tester.tap(completeButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Keep the momentum'), findsOneWidget);
    expect(controller.xp, 10);

    final bookmark = find.byTooltip('Save lesson');
    await tester.ensureVisible(bookmark);
    await tester.tap(bookmark);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Saved'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await controller.onPageViewed(conceptIndex);

    expect(find.text('Saved lessons'), findsOneWidget);
    expect(find.text(concept.title), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await harness.appDatabase.close();
  });
}
