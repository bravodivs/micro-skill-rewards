enum LearningTopic {
  dsa('DSA', 'Algorithms & data structures'),
  functional('Functional', 'Functional thinking'),
  codeCraft('Code craft', 'Practical engineering');

  const LearningTopic(this.label, this.description);

  final String label;
  final String description;
}

enum LearningItemType {
  concept('Quick concept'),
  quiz('One-tap quiz'),
  codeTip('Code pattern'),
  bugHunt('Spot the bug');

  const LearningItemType(this.label);

  final String label;
}

class LearningItem {
  const LearningItem({
    required this.id,
    required this.topic,
    required this.type,
    required this.title,
    required this.body,
    required this.takeaway,
    this.code,
    this.options = const [],
    this.correctOptionIndex,
  });

  final String id;
  final LearningTopic topic;
  final LearningItemType type;
  final String title;
  final String body;
  final String takeaway;
  final String? code;
  final List<String> options;
  final int? correctOptionIndex;

  bool get isInteractive => options.isNotEmpty;
}
