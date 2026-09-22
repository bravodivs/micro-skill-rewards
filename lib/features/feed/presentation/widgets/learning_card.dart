import 'package:flutter/material.dart';
import 'package:momentum_learning_feed/core/theme/app_theme.dart';
import 'package:momentum_learning_feed/features/feed/domain/learning_item.dart';

class LearningCard extends StatelessWidget {
  const LearningCard({
    super.key,
    required this.item,
    required this.isSaved,
    required this.isCompleted,
    required this.selectedAnswer,
    required this.onSaved,
    required this.onAnswer,
    required this.onComplete,
    required this.onNext,
  });

  final LearningItem item;
  final bool isSaved;
  final bool isCompleted;
  final int? selectedAnswer;
  final VoidCallback onSaved;
  final ValueChanged<int> onAnswer;
  final VoidCallback onComplete;
  final VoidCallback onNext;

  Color get _accent => switch (item.topic) {
    LearningTopic.dsa => AppColors.mint,
    LearningTopic.functional => AppColors.lilac,
    LearningTopic.codeCraft => AppColors.peach,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            item.type.label.toUpperCase(),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontSize: 11, letterSpacing: 0.7),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: onSaved,
                          tooltip: isSaved ? 'Remove bookmark' : 'Save lesson',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.canvas,
                          ),
                          icon: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.body,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (item.code != null) ...[
                      const SizedBox(height: 14),
                      _CodeBlock(code: item.code!),
                    ],
                    if (item.options.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ...List.generate(
                        item.options.length,
                        (index) => _AnswerOption(
                          label: item.options[index],
                          index: index,
                          isComplete: isCompleted,
                          isSelected: selectedAnswer == index,
                          isCorrect: item.correctOptionIndex == index,
                          onTap: () => onAnswer(index),
                        ),
                      ),
                    ],
                    if (isCompleted || !item.isInteractive) ...[
                      const SizedBox(height: 14),
                      _Takeaway(
                        text: item.takeaway,
                        revealed: isCompleted || !item.isInteractive,
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (!isCompleted && !item.isInteractive)
                      FilledButton.icon(
                        key: const Key('complete_item_button'),
                        onPressed: onComplete,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Got it  ·  +10 XP'),
                      )
                    else if (isCompleted)
                      FilledButton.icon(
                        key: const Key('next_item_button'),
                        onPressed: onNext,
                        icon: const Icon(Icons.arrow_upward_rounded),
                        label: const Text('Keep the momentum'),
                      ),
                    if (!isCompleted && item.isInteractive)
                      Center(
                        child: Text(
                          'Choose one answer',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        code,
        style: const TextStyle(
          color: Color(0xFFF2F7E8),
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.45,
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.index,
    required this.isComplete,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
  });

  final String label;
  final int index;
  final bool isComplete;
  final bool isSelected;
  final bool isCorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color background = AppColors.canvas;
    Color border = Colors.transparent;
    IconData? trailingIcon;

    if (isComplete && isCorrect) {
      background = AppColors.mint;
      border = AppColors.ink;
      trailingIcon = Icons.check_circle_rounded;
    } else if (isComplete && isSelected) {
      background = const Color(0xFFFFE0DB);
      border = AppColors.coral;
      trailingIcon = Icons.cancel_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: 'Answer ${index + 1}: $label',
        child: InkWell(
          onTap: isComplete ? null : onTap,
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontSize: 14),
                  ),
                ),
                if (trailingIcon != null) Icon(trailingIcon, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Takeaway extends StatelessWidget {
  const _Takeaway({required this.text, required this.revealed});

  final String text;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: revealed ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.lime.withValues(alpha: 0.44),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_rounded, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
