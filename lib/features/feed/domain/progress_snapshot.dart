import 'package:momentum_learning_feed/features/feed/domain/learning_item.dart';

class ProgressSnapshot {
  const ProgressSnapshot({
    this.xp = 0,
    this.streak = 1,
    this.completedIds = const {},
    this.savedIds = const {},
    this.answers = const {},
    this.onboardingSeen = false,
    this.lastActiveDate,
  });

  final int xp;
  final int streak;
  final Set<String> completedIds;
  final Set<String> savedIds;
  final Map<String, int> answers;
  final bool onboardingSeen;
  final String? lastActiveDate;
}

abstract final class ProgressScoring {
  static const conceptXp = 10;
  static const correctAnswerXp = 20;
  static const attemptedAnswerXp = 5;

  static int scoreFor(LearningItem item, int? selectedOption) {
    if (!item.isInteractive) return conceptXp;
    if (selectedOption == item.correctOptionIndex) return correctAnswerXp;
    return attemptedAnswerXp;
  }
}
