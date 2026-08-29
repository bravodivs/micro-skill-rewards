import 'dart:convert';

import 'package:momentum_learning_feed/features/feed/domain/progress_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ProgressStore {
  Future<ProgressSnapshot> load();
  Future<void> save(ProgressSnapshot snapshot);
}

class SharedPreferencesProgressStore implements ProgressStore {
  const SharedPreferencesProgressStore(this.preferences);

  static const _storageKey = 'momentum_progress_v1';

  final SharedPreferences preferences;

  @override
  Future<ProgressSnapshot> load() async {
    final raw = preferences.getString(_storageKey);
    if (raw == null) return const ProgressSnapshot();

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final answerJson = (json['answers'] as Map<String, dynamic>?) ?? {};
      return ProgressSnapshot(
        xp: json['xp'] as int? ?? 0,
        streak: json['streak'] as int? ?? 1,
        completedIds: Set<String>.from(
          json['completedIds'] as List? ?? const [],
        ),
        savedIds: Set<String>.from(json['savedIds'] as List? ?? const []),
        answers: answerJson.map((key, value) => MapEntry(key, value as int)),
        onboardingSeen: json['onboardingSeen'] as bool? ?? false,
        lastActiveDate: json['lastActiveDate'] as String?,
      );
    } on FormatException {
      return const ProgressSnapshot();
    } on TypeError {
      return const ProgressSnapshot();
    }
  }

  @override
  Future<void> save(ProgressSnapshot snapshot) async {
    final json = jsonEncode({
      'xp': snapshot.xp,
      'streak': snapshot.streak,
      'completedIds': snapshot.completedIds.toList(),
      'savedIds': snapshot.savedIds.toList(),
      'answers': snapshot.answers,
      'onboardingSeen': snapshot.onboardingSeen,
      'lastActiveDate': snapshot.lastActiveDate,
    });
    await preferences.setString(_storageKey, json);
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
