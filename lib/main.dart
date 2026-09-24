import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:momentum_learning_feed/app.dart';
import 'package:momentum_learning_feed/core/storage/app_database.dart';
import 'package:momentum_learning_feed/features/feed/application/feed_controller.dart';
import 'package:momentum_learning_feed/features/feed/data/catalog_source.dart';
import 'package:momentum_learning_feed/features/feed/data/learning_content_repository.dart';
import 'package:momentum_learning_feed/features/feed/data/progress_store.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const contentBaseUrl = String.fromEnvironment(
    'CONTENT_BASE_URL',
    defaultValue: '',
  );
  final appDatabase = kIsWeb
      ? await AppDatabase.open(
          factory: databaseFactoryFfiWeb,
          path: 'momentum_feed.db',
        )
      : await AppDatabase.open();
  final contentRepository = LearningContentRepository(
    database: appDatabase.database,
    bundledSource: const BundledCatalogSource(),
    remoteSource: contentBaseUrl.isEmpty
        ? null
        : RemoteCatalogSource(baseUrl: contentBaseUrl),
  );
  final controller = FeedController(
    contentRepository: contentRepository,
    progressStore: SqliteProgressStore(appDatabase.database),
  );
  await controller.initialize();

  runApp(MomentumApp(controller: controller));
}
