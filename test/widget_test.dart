import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momentum_learning_feed/app.dart';
import 'package:momentum_learning_feed/features/feed/application/feed_controller.dart';
import 'package:momentum_learning_feed/features/feed/data/learning_content_repository.dart';
import 'package:momentum_learning_feed/features/feed/data/progress_store.dart';
import 'package:momentum_learning_feed/features/feed/domain/progress_snapshot.dart';

Future<FeedController> createController({
  ProgressSnapshot snapshot = const ProgressSnapshot(),
}) async {
  final controller = FeedController(
    contentRepository: const LearningContentRepository(),
    progressStore: MemoryProgressStore(snapshot),
    now: () => DateTime(2026, 8, 29),
  );
  await controller.initialize();
  return controller;
}

void main() {
  testWidgets('onboarding introduces and opens the finite feed', (
    tester,
  ) async {
    final controller = await createController();
    await tester.pumpWidget(MomentumApp(controller: controller));

    expect(find.text('Scroll less.\nGrow more.'), findsOneWidget);
    expect(find.textContaining('No endless scroll'), findsOneWidget);

    await tester.tap(find.textContaining('Start today'));
    await tester.pumpAndSettle();

    expect(find.text('MOMENTUM'), findsOneWidget);
    expect(find.text('Trade memory for speed'), findsOneWidget);
  });

  testWidgets('learning and bookmarking update the interface', (tester) async {
    final controller = await createController(
      snapshot: const ProgressSnapshot(onboardingSeen: true),
    );
    await tester.pumpWidget(MomentumApp(controller: controller));

    final completeButton = find.byKey(const Key('complete_item_button'));
    await tester.ensureVisible(completeButton);
    await tester.tap(completeButton);
    await tester.pumpAndSettle();

    expect(find.text('Keep the momentum'), findsOneWidget);
    expect(controller.xp, 10);

    final bookmark = find.byTooltip('Save lesson');
    await tester.ensureVisible(bookmark);
    await tester.tap(bookmark);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();

    expect(find.text('Saved lessons'), findsOneWidget);
    expect(find.text('Trade memory for speed'), findsOneWidget);
  });
}
