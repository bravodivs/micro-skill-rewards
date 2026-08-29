import 'package:flutter/material.dart';
import 'package:momentum_learning_feed/core/theme/app_theme.dart';

class CompletionCard extends StatelessWidget {
  const CompletionCard({
    super.key,
    required this.completedCount,
    required this.totalCount,
    required this.xp,
    required this.onReview,
    required this.onSaved,
  });

  final int completedCount;
  final int totalCount;
  final int xp;
  final VoidCallback onReview;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final finished = completedCount == totalCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: AppColors.lime,
                shape: BoxShape.circle,
              ),
              child: Icon(
                finished ? Icons.emoji_events_rounded : Icons.flag_rounded,
                color: AppColors.ink,
                size: 38,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              finished ? 'Daily feed complete' : 'You reached the end',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              finished
                  ? 'You turned a quick break into something that moves your career forward.'
                  : '$completedCount of $totalCount cards learned. Review the feed whenever you’re ready.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _Stat(label: 'LEARNED', value: '$completedCount/$totalCount'),
                _Stat(label: 'TOTAL XP', value: '$xp'),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onReview,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: AppColors.ink,
              ),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Review today’s cards'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onSaved,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.bookmark_rounded),
              label: const Text('Open saved lessons'),
            ),
            const SizedBox(height: 18),
            Text(
              'Come back tomorrow for a fresh set.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
