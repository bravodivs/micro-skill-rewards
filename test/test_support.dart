import 'package:momentum_learning_feed/core/storage/app_database.dart';
import 'package:momentum_learning_feed/features/feed/data/catalog_source.dart';
import 'package:momentum_learning_feed/features/feed/data/learning_content_repository.dart';
import 'package:momentum_learning_feed/features/feed/domain/catalog_manifest.dart';
import 'package:momentum_learning_feed/features/feed/domain/learning_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeCatalogSource implements CatalogSource {
  FakeCatalogSource({required this.manifest, required this.cardsByBatch});

  final CatalogManifest manifest;
  final Map<String, List<LearningItem>> cardsByBatch;
  int fetchedBatchCount = 0;

  @override
  Future<CatalogManifest> fetchManifest() async => manifest;

  @override
  Future<List<LearningItem>> fetchBatch(CatalogBatch batch) async {
    fetchedBatchCount += 1;
    return cardsByBatch[batch.id]!;
  }
}

FakeCatalogSource fakeCatalog({int batchCount = 5, int start = 0}) {
  final batches = <CatalogBatch>[];
  final cardsByBatch = <String, List<LearningItem>>{};
  for (var batch = 0; batch < batchCount; batch++) {
    final batchId = (batch + 1).toString().padLeft(4, '0');
    batches.add(
      CatalogBatch(id: batchId, path: 'batches/$batchId.json', cardCount: 10),
    );
    cardsByBatch[batchId] = List.generate(10, (offset) {
      final index = start + batch * 10 + offset;
      final isQuiz = index.isOdd;
      return LearningItem(
        id: 'card-$index',
        topic: LearningTopic.values[index % LearningTopic.values.length],
        type: isQuiz ? LearningItemType.quiz : LearningItemType.concept,
        title: index == 0 ? 'Trade memory for speed' : 'Lesson $index',
        body: 'A useful micro lesson number $index.',
        takeaway: 'Remember lesson $index.',
        options: isQuiz ? const ['Wrong A', 'Correct', 'Wrong B'] : const [],
        correctOptionIndex: isQuiz ? 1 : null,
      );
    });
  }
  return FakeCatalogSource(
    manifest: CatalogManifest(
      version: 1,
      generatedAt: '2026-09-24T00:00:00Z',
      batchSize: 10,
      dailyCap: 50,
      minPrefetchUnseen: 20,
      batches: batches,
    ),
    cardsByBatch: cardsByBatch,
  );
}

Future<AppDatabase> openTestDatabase() async {
  sqfliteFfiInit();
  return AppDatabase.open(
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );
}

LearningContentRepository testRepository({
  required AppDatabase appDatabase,
  FakeCatalogSource? bundled,
  CatalogSource? remote,
}) => LearningContentRepository(
  database: appDatabase.database,
  bundledSource: bundled ?? fakeCatalog(),
  remoteSource: remote,
);
