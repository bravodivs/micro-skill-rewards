import 'package:flutter/material.dart';
import 'package:momentum_learning_feed/app.dart';
import 'package:momentum_learning_feed/features/feed/application/feed_controller.dart';
import 'package:momentum_learning_feed/features/feed/data/learning_content_repository.dart';
import 'package:momentum_learning_feed/features/feed/data/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final controller = FeedController(
    contentRepository: const LearningContentRepository(),
    progressStore: SharedPreferencesProgressStore(preferences),
  );
  await controller.initialize();

  runApp(MomentumApp(controller: controller));
}
