class CatalogBatch {
  const CatalogBatch({
    required this.id,
    required this.path,
    required this.cardCount,
  });

  final String id;
  final String path;
  final int cardCount;

  factory CatalogBatch.fromJson(Map<String, dynamic> json) => CatalogBatch(
    id: json['id'] as String,
    path: json['path'] as String,
    cardCount: json['cardCount'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'cardCount': cardCount,
  };
}

class CatalogManifest {
  const CatalogManifest({
    required this.version,
    required this.generatedAt,
    required this.batchSize,
    required this.dailyCap,
    required this.minPrefetchUnseen,
    required this.batches,
  });

  final int version;
  final String generatedAt;
  final int batchSize;
  final int dailyCap;
  final int minPrefetchUnseen;
  final List<CatalogBatch> batches;

  factory CatalogManifest.fromJson(Map<String, dynamic> json) {
    final batchSize = json['batchSize'] as int? ?? 10;
    final dailyCap = json['dailyCap'] as int? ?? 50;
    if (batchSize <= 0 || dailyCap <= 0) {
      throw const FormatException('Catalog limits must be positive');
    }
    return CatalogManifest(
      version: json['version'] as int,
      generatedAt: json['generatedAt'] as String,
      batchSize: batchSize,
      dailyCap: dailyCap,
      minPrefetchUnseen: json['minPrefetchUnseen'] as int? ?? 20,
      batches: (json['batches'] as List)
          .map((batch) => CatalogBatch.fromJson(batch as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'generatedAt': generatedAt,
    'batchSize': batchSize,
    'dailyCap': dailyCap,
    'minPrefetchUnseen': minPrefetchUnseen,
    'batches': batches.map((batch) => batch.toJson()).toList(),
  };
}
