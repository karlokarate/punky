// lib/services/recommendation_history_service.dart
//
// v2 – Therapie‑Empfehlungs‑Archiv (Hive‑basiert)
//
// ▸ Aufgaben
//   • Persistiert alle GPT‑/Nightscout‑Empfehlungen lokal in Hive.
//   • Kapselt CRUD‑Methoden + Export/Import + Auto‑Pruning.
//   • ChangeNotifier → Widgets können `context.watch<RecommendationHistoryService>()`
//     nutzen, um sofortige UI‑Aktualisierungen zu erhalten.
//   • Höchst‑Performance: Lazy‑Load in Memory‑Cache; Box wird nur bei
//     Schreib‑Operationen berührt.
//
// ---------------------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class RecommendationHistoryService extends ChangeNotifier {
  RecommendationHistoryService._();
  static final RecommendationHistoryService i =
      RecommendationHistoryService._();

  static const _boxName = 'recommendation_history';
  static const _maxEntries = 200;       // Auto‑Pruning‑Limit

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

    // Cache aufbauen (ältest → neu)
    _cache
      ..clear()
      ..addAll(_box.values.cast<Map>().toList());
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

    // Auto‑Pruning
    if (_cache.length > _maxEntries) {
      final overflow = _cache.length - _maxEntries;
      _cache.removeRange(0, overflow);
      await _box.deleteAt(0); // nur 1 Item pro Aufruf entfernen
    }

    notifyListeners();
  }

  /// Gibt das komplette Archiv zurück (älteste → neueste).
  List<Map<String, dynamic>> getHistory() => List.unmodifiable(_cache);

  /// Neueste Empfehlung (oder null)
  Map<String, dynamic>? get latest =>
      _cache.isNotEmpty ? _cache.last : null;

  /// Löscht das komplette Archiv.
  Future<void> clear() async {
    await _box.clear();
    _cache.clear();
    notifyListeners();
  }

  /* ───────────────────────── Export / Import ───────────────────────── */

  /// Exportiert als JSON‑String.
  String exportJson() => jsonEncode(_cache);

  /// Importiert (überschreibt) aus JSON‑String.
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
