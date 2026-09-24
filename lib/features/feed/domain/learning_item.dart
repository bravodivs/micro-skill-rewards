enum LearningTopic {
  dsa('DSA', 'Algorithms & data structures'),
  functional('Functional', 'Functional thinking'),
  codeCraft('Code craft', 'Practical engineering');

  const LearningTopic(this.label, this.description);

  final String label;
  final String description;

  static LearningTopic fromJson(String value) =>
      LearningTopic.values.firstWhere(
        (topic) => topic.name == value,
        orElse: () => throw FormatException('Unknown learning topic: $value'),
      );
}

enum LearningItemType {
  concept('Quick concept'),
  quiz('One-tap quiz'),
  codeTip('Code pattern'),
  bugHunt('Spot the bug');

  const LearningItemType(this.label);

  final String label;

  static LearningItemType fromJson(String value) =>
      LearningItemType.values.firstWhere(
        (type) => type.name == value,
        orElse: () =>
            throw FormatException('Unknown learning item type: $value'),
      );
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
    this.difficulty = 'beginner',
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
  final String difficulty;

  bool get isInteractive => options.isNotEmpty;

  factory LearningItem.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List? ?? const [])
        .map((option) => option as String)
        .toList(growable: false);
    final correctOptionIndex = json['correctOptionIndex'] as int?;
    if (options.isNotEmpty &&
        (correctOptionIndex == null ||
            correctOptionIndex < 0 ||
            correctOptionIndex >= options.length)) {
      throw FormatException('Invalid correct option for ${json['id']}');
    }

    return LearningItem(
      id: json['id'] as String,
      topic: LearningTopic.fromJson(json['topic'] as String),
      type: LearningItemType.fromJson(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      takeaway: json['takeaway'] as String,
      code: json['code'] as String?,
      options: options,
      correctOptionIndex: correctOptionIndex,
      difficulty: json['difficulty'] as String? ?? 'beginner',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'topic': topic.name,
    'type': type.name,
    'title': title,
    'body': body,
    'takeaway': takeaway,
    if (code != null) 'code': code,
    if (options.isNotEmpty) 'options': options,
    if (correctOptionIndex != null) 'correctOptionIndex': correctOptionIndex,
    'difficulty': difficulty,
  };

  LearningItem withOptionOrder(List<int> order) {
    if (!isInteractive) return this;
    if (order.length != options.length) {
      throw ArgumentError('Option order does not match option count');
    }
    final shuffledOptions = order.map((index) => options[index]).toList();
    final shuffledCorrect = order.indexOf(correctOptionIndex!);
    return LearningItem(
      id: id,
      topic: topic,
      type: type,
      title: title,
      body: body,
      takeaway: takeaway,
      code: code,
      options: shuffledOptions,
      correctOptionIndex: shuffledCorrect,
      difficulty: difficulty,
    );
  }
}
