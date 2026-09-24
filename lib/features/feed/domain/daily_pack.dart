import 'package:momentum_learning_feed/features/feed/domain/learning_item.dart';

class DailyPackEntry {
  const DailyPackEntry({
    required this.item,
    required this.position,
    required this.optionOrder,
    required this.completed,
    this.selectedAnswer,
  });

  final LearningItem item;
  final int position;
  final List<int> optionOrder;
  final bool completed;
  final int? selectedAnswer;
}
