import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:momentum_learning_feed/features/feed/domain/catalog_manifest.dart';
import 'package:momentum_learning_feed/features/feed/domain/learning_item.dart';

abstract interface class CatalogSource {
  Future<CatalogManifest> fetchManifest();
  Future<List<LearningItem>> fetchBatch(CatalogBatch batch);
}

class BundledCatalogSource implements CatalogSource {
  const BundledCatalogSource({this.assetRoot = 'assets/catalog'});

  final String assetRoot;

  @override
  Future<CatalogManifest> fetchManifest() async {
    final raw = await rootBundle.loadString('$assetRoot/manifest.json');
    return CatalogManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<List<LearningItem>> fetchBatch(CatalogBatch batch) async {
    final raw = await rootBundle.loadString('$assetRoot/${batch.path}');
    return _parseCards(raw, batch);
  }
}

class RemoteCatalogSource implements CatalogSource {
  RemoteCatalogSource({required this.baseUrl, http.Client? client})
    : client = client ?? http.Client();

  final String baseUrl;
  final http.Client client;

  bool get isEnabled => baseUrl.trim().isNotEmpty;

  Uri _uri(String path) {
    final root = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(root).resolve(path);
  }

  @override
  Future<CatalogManifest> fetchManifest() async {
    if (!isEnabled) throw StateError('Remote catalog URL is not configured');
    final response = await client
        .get(_uri('manifest.json'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw HttpException(
        'Catalog manifest returned ${response.statusCode}',
        response.request?.url,
      );
    }
    return CatalogManifest.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<LearningItem>> fetchBatch(CatalogBatch batch) async {
    final response = await client
        .get(_uri(batch.path))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw HttpException(
        'Catalog batch ${batch.id} returned ${response.statusCode}',
        response.request?.url,
      );
    }
    return _parseCards(response.body, batch);
  }
}

class HttpException implements Exception {
  const HttpException(this.message, [this.uri]);

  final String message;
  final Uri? uri;

  @override
  String toString() => uri == null ? message : '$message ($uri)';
}

List<LearningItem> _parseCards(String raw, CatalogBatch batch) {
  final decoded = jsonDecode(raw);
  final cardJson = decoded is List
      ? decoded
      : (decoded as Map<String, dynamic>)['cards'] as List;
  final cards = cardJson
      .map((card) => LearningItem.fromJson(card as Map<String, dynamic>))
      .toList(growable: false);
  if (cards.length != batch.cardCount) {
    throw FormatException(
      'Batch ${batch.id} expected ${batch.cardCount} cards, got ${cards.length}',
    );
  }
  return cards;
}
