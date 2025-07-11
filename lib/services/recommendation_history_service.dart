// lib/services/recommendation_history_service.dart
//
// v3 – FINAL BRIDGE READY
// --------------------------------------------------------------
// GPT- & Nightscout-Empfehlungsarchiv (lokal, Hive-basiert)
// • CRUD-API für Empfehlungen (Datum + Liste)
// • Auto-Pruning auf max. 200 Einträge
// • JSON-Export + Import
// • Kompatibel mit Provider & ChangeNotifier
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class RecommendationHistoryService extends ChangeNotifier {
  RecommendationHistoryService._();
  static final RecommendationHistoryService i = RecommendationHistoryService._();

  static const _boxName = 'recommendation_history';
  static const _maxEntries = 200;

  late Box _box;
  final List<Map<String, dynamic>> _cache = [];

  bool _ready = false;
  bool get isReady => _ready;

  /* ───────────────────────── Init / Teardown ────────────────────────── */

  Future<void> init() async {
    if (_ready) return;
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    _box = await Hive.openBox(_boxName);

    _cache
      ..clear()
      ..addAll(
        _box.values
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );
    _ready = true;
    notifyListeners();
  }

  Future<void> disposeService() async {
    await _box.close();
    _ready = false;
  }

  /* ───────────────────────── CRUD‑API ──────────────────────────────── */

  Future<void> addEntry(DateTime ts, List<Map<String, dynamic>> recs) async {
    final entry = {
      'ts': ts.toIso8601String(),
      'recs': recs,
    };
    _cache.add(entry);
    await _box.add(entry);

    if (_cache.length > _maxEntries) {
      final overflow = _cache.length - _maxEntries;
      _cache.removeRange(0, overflow);
      for (int i = 0; i < overflow; i++) {
        if (_box.length > i) await _box.deleteAt(i);
      }
    }

    notifyListeners();
  }

  List<Map<String, dynamic>> getHistory() => List.unmodifiable(_cache);

  Map<String, dynamic>? get latest => _cache.isNotEmpty ? _cache.last : null;

  Future<void> clear() async {
    await _box.clear();
    _cache.clear();
    notifyListeners();
  }

  /* ───────────────────────── Export / Import ───────────────────────── */

  String exportJson() => jsonEncode(_cache);

  Future<void> importJson(String json) async {
    final List list = jsonDecode(json);
    await _box.clear();
    _cache
      ..clear()
      ..addAll(list.cast<Map<String, dynamic>>());
    await _box.addAll(_cache);
    notifyListeners();
  }
}
