import 'package:flutter/material.dart';
import 'package:momentum_learning_feed/core/theme/app_theme.dart';
import 'package:momentum_learning_feed/features/feed/domain/learning_item.dart';

class TopicFilterBar extends StatelessWidget {
  const TopicFilterBar({
    super.key,
    required this.selectedTopic,
    required this.onSelected,
  });

  final LearningTopic? selectedTopic;
  final ValueChanged<LearningTopic?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          _TopicChip(
            label: 'For you',
            selected: selectedTopic == null,
            onTap: () => onSelected(null),
          ),
          ...LearningTopic.values.map(
            (topic) => _TopicChip(
              label: topic.label,
              selected: selectedTopic == topic,
              onTap: () => onSelected(topic),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.ink,
        backgroundColor: AppColors.paper,
        labelStyle: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: selected ? Colors.white : AppColors.ink),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      ),
    );
  }
}
