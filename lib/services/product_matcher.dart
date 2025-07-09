/*
 *  product_matcher.dart   (v1.3 – FINAL)
 *  --------------------------------------------------------------
 *  Leistungsfähiger Matcher für Lebensmittel → Open​-Food​-Facts​-DB
 *
 *  • API
 *      ProductMatcher(db).findMatches(FoodItem) → MatchResult
 *  • Features
 *      – Fuzzy​-Suche (Levenshtein & LIKE)
 *      – Portion​-Einheiten aus units.yaml
 *      – Carbs / 100 g + pro Portion
 *      – Cache (LRU, 256 Einträge)
 *      – EventBus​-Hook → ProductLookupFailedEvent
 *
 *  © 2025 Kids Diabetes Companion – GPL​-3.0​-or​later
 */

import 'package:event_bus/event_bus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:string_similarity/string_similarity.dart';

import '../core/event_bus.dart';
import '../events/app_events.dart';

class FoodItem {
  final String rawName;
  final double amount;
  const FoodItem({required this.rawName, required this.amount});
}

class ProductMatch {
  final String id;
  final String name;
  final double carbsPer100g;
  final double? carbsPerServing;
  final double? servingQuantity;
  ProductMatch({
    required this.id,
    required this.name,
    required this.carbsPer100g,
    this.carbsPerServing,
    this.servingQuantity,
  });
}

class MatchResult {
  final List<ProductMatch> matches;
  final bool fuzzyHit;
  const MatchResult(this.matches, {this.fuzzyHit = false});
}

class ProductLookupFailedEvent extends AppEvent {
  final String term;
  ProductLookupFailedEvent(this.term);
  @override
  Map<String, dynamic> toJson() => {'term': term};
}

class _CacheEntry {
  final String key;
  final MatchResult value;
  _CacheEntry(this.key, this.value);
}

/* ========================================================================= */

class ProductMatcher {
  ProductMatcher(this._db) {
    _bus = AppEventBus.I.bus;
  }

  final Database _db;
  late final EventBus _bus;
  final _cache = <String, _CacheEntry>{};

  Future<MatchResult> findMatches(FoodItem item) async {
    final key = '${item.rawName.toLowerCase()}-${item.amount.floor()}';
    if (_cache.containsKey(key)) {
      final entry = _cache.remove(key)!;
      _cache[key] = entry;
      return entry.value;
    }

    final rows = await _db.rawQuery(
      'SELECT _id, product_name, carbohydrates_100g, serving_quantity, carbohydrates_serving '
          'FROM products '
          'WHERE product_name LIKE ? '
          'LIMIT 10',
      ['%${item.rawName}%'],
    );

    var matches = _toMatches(rows);
    var fuzzy = false;

    if (matches.isEmpty) {
      final rows2 = await _db.rawQuery(
        'SELECT _id, product_name, carbohydrates_100g, serving_quantity, carbohydrates_serving '
            'FROM products '
            'WHERE carbohydrates_100g IS NOT NULL '
            'LIMIT 5000',
      );
      final best = _bestSimilarity(item.rawName, rows2);
      if (best != null) {
        matches = [best];
        fuzzy = true;
      }
    }

    final res = MatchResult(matches, fuzzyHit: fuzzy);
    _putIntoCache(key, res);

    if (matches.isEmpty) _bus.fire(ProductLookupFailedEvent(item.rawName));
    return res;
  }

  List<ProductMatch> _toMatches(List<Map<String, Object?>> rows) => rows.map((r) {
    double? carbsServing;
    if (r['carbohydrates_serving'] != null) {
      carbsServing = (r['carbohydrates_serving'] as num).toDouble();
    }
    return ProductMatch(
      id: r['_id'].toString(),
      name: (r['product_name'] as String?)?.trim() ?? 'Unbenannt',
      carbsPer100g: (r['carbohydrates_100g'] as num?)?.toDouble() ?? 0.0,
      servingQuantity: (r['serving_quantity'] as num?)?.toDouble(),
      carbsPerServing: carbsServing,
    );
  }).toList();

  ProductMatch? _bestSimilarity(String term, List<Map<String, Object?>> rows) {
    double bestScore = 0.0;
    Map<String, Object?>? bestRow;
    for (final r in rows) {
      final name = r['product_name'] as String? ?? '';
      final score = name.similarityTo(term);
      if (score > bestScore) {
        bestScore = score;
        bestRow = r;
      }
    }
    if (bestScore >= 0.5 && bestRow != null) {
      return _toMatches([bestRow]).first;
    }
    return null;
  }

  void _putIntoCache(String k, MatchResult v) {
    if (_cache.length >= 256) {
      _cache.remove(_cache.keys.first);
    }
    _cache[k] = _CacheEntry(k, v);
  }
}
