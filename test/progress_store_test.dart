import 'package:flutter_test/flutter_test.dart';
import 'package:momentum_learning_feed/features/feed/data/progress_store.dart';
import 'package:momentum_learning_feed/features/feed/domain/progress_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('progress survives a SharedPreferences round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesProgressStore(preferences);
    const expected = ProgressSnapshot(
      xp: 35,
      streak: 3,
      completedIds: {'lesson-1'},
      savedIds: {'lesson-2'},
      answers: {'lesson-1': 2},
      onboardingSeen: true,
      lastActiveDate: '2026-08-29',
    );

    await store.save(expected);
    final restored = await store.load();

    expect(restored.xp, 35);
    expect(restored.streak, 3);
    expect(restored.completedIds, {'lesson-1'});
    expect(restored.savedIds, {'lesson-2'});
    expect(restored.answers, {'lesson-1': 2});
    expect(restored.onboardingSeen, isTrue);
    expect(restored.lastActiveDate, '2026-08-29');
  });
}
