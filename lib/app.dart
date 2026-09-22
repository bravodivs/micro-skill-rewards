import 'package:flutter/material.dart';
import 'package:momentum_learning_feed/core/theme/app_theme.dart';
import 'package:momentum_learning_feed/features/feed/application/feed_controller.dart';
import 'package:momentum_learning_feed/features/feed/presentation/feed_screen.dart';
import 'package:momentum_learning_feed/features/feed/presentation/onboarding_screen.dart';

class MomentumApp extends StatelessWidget {
  const MomentumApp({super.key, required this.controller});

  final FeedController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Momentum',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (!controller.onboardingSeen) {
            return OnboardingScreen(
              dailyCardCount: controller.allItems.length,
              onStart: controller.completeOnboarding,
            );
          }
          return FeedScreen(controller: controller);
        },
      ),
    );
  }
}
