import 'package:flutter/material.dart';
import 'package:momentum_learning_feed/core/theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.dailyCardCount,
    required this.onStart,
  });

  final int dailyCardCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: _Blob(size: 250, color: AppColors.lime),
          ),
          Positioned(
            bottom: 110,
            left: -90,
            child: _Blob(size: 220, color: AppColors.lilac),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: AppColors.lime,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'MOMENTUM',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(letterSpacing: 1.6),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.peach,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'A BETTER 5-MINUTE BREAK',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Scroll less.\nGrow more.',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tiny coding wins that feel easy to start—and useful to remember.',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: AppColors.mutedInk),
                      ),
                      const SizedBox(height: 28),
                      const Row(
                        children: [
                          Expanded(
                            child: _FeaturePill(
                              icon: Icons.swipe_vertical_rounded,
                              label: 'Swipe-sized',
                              color: AppColors.mint,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _FeaturePill(
                              icon: Icons.emoji_events_rounded,
                              label: 'Earn XP',
                              color: AppColors.yellow,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _FeaturePill(
                              icon: Icons.timer_outlined,
                              label: 'Finite feed',
                              color: AppColors.lilac,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: onStart,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text('Start today’s $dailyCardCount cards'),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'No account. No endless scroll.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.62),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
