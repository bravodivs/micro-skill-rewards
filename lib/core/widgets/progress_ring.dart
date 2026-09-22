import 'package:flutter/material.dart';
import 'package:momentum_learning_feed/core/theme/app_theme.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.label,
    this.size = 48,
  });

  final double progress;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0, 1),
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.ink.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.ink),
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
