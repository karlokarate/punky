// -----------------------------------------------------------------------------
//  avatar_service.dart  (v6 – state‑of‑the‑art)
//  -----------------------------------------------------------------------------
//  • SQL‑Lite‑Persistenz für Auswahl, Unlocks & Custom‑Uploads
//  • Volles AvatarItem‑Datenmodell inklusive UnlockCondition
//  • Unlock‑Engine mit Rückgabe neu freigeschalteter Items
//  • EventBus‑Integration (Celebrate, Sad, Preview)
//  • Custom‑Uploads (PNG) via Settings‑Screen → werden live geladen
//  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../core/event_bus.dart';
import '../events/app_events.dart';
import '../services/settings_service.dart';

/* ═════════════════════════════════════════ MODEL ═══════════════════════════ */

@immutable
class UnlockCondition {
  const UnlockCondition({this.minPoints, this.minLevel});

  final int? minPoints;
  final int? minLevel;

  bool evaluate(int points, int level) =>
      (minPoints == null || points >= minPoints!) &&
          (minLevel == null || level >= minLevel!);

  Map<String, dynamic> toJson() =>
      {'minPoints': minPoints, 'minLevel': minLevel};

  factory UnlockCondition.fromJson(Map<String, dynamic> j) =>
      UnlockCondition(minPoints: j['minPoints'], minLevel: j['minLevel']);
}

@immutable
class AvatarItem {
  const AvatarItem({
    required this.key,
    required this.name,
    required this.layer,
    required this.assetPath,
    this.isCustom = false,
    this.unlock,
  });

  final String key;
  final String name;
  final String layer;
  final String assetPath;
  final bool isCustom;
  final UnlockCondition? unlock;

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'layer': layer,
    'assetPath': assetPath,
    'isCustom': isCustom ? 1 : 0,
    'unlock': unlock?.toJson()
  };

  factory AvatarItem.fromJson(Map<String, dynamic> j) => AvatarItem(
    key: j['key'],
    name: j['name'],
    layer: j['layer'],
    assetPath: j['assetPath'],
    isCustom: (j['isCustom'] ?? 0) == 1,
    unlock: j['unlock'] == null
        ? null
        : UnlockCondition.fromJson(Map<String, dynamic>.from(j['unlock'])),
  );
}

/* ═════════════════════════════════════════ DB‑LAYER ═════════════════════════ */

class _AvatarDB {
  static const _dbName = 'avatar.db';
  static const _dbVersion = 1;

  late final Database _db;

  Future<void> open() async {
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      p.join(dir.path, _dbName),
      version: _dbVersion,
      onCreate: (db, _) async {
        await db.execute(
            'CREATE TABLE selections(layer TEXT PRIMARY KEY, item TEXT)');
        await db.execute(
            'CREATE TABLE unlocks(item TEXT PRIMARY KEY) WITHOUT ROWID');
        await db.execute(
            'CREATE TABLE items(key TEXT PRIMARY KEY, json TEXT) WITHOUT ROWID');
      },
    );
  }

  /* ---------------- CRUD ---------------- */

  Future<Map<String, String?>> loadSelections() async {
    final rows = await _db.query('selections');
    return {for (var r in rows) r['layer'] as String: r['item'] as String?};
  }

  Future<void> saveSelection(String layer, String? item) async =>
      await _db.insert('selections', {'layer': layer, 'item': item},
          conflictAlgorithm: ConflictAlgorithm.replace);

  Future<Set<String>> loadUnlocks() async {
    final rows = await _db.query('unlocks');
    return rows.map((r) => r['item'] as String).toSet();
  }

  Future<void> addUnlock(String key) async =>
      await _db.insert('unlocks', {'item': key},
          conflictAlgorithm: ConflictAlgorithm.ignore);

  Future<void> storeItem(AvatarItem i) async => await _db.insert(
    'items',
    {'key': i.key, 'json': jsonEncode(i.toJson())},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<List<AvatarItem>> loadCustomItems() async {
    final rows = await _db.query('items');
    return rows
        .map((r) =>
        AvatarItem.fromJson(jsonDecode(r['json'] as String) as Map<String, dynamic>))
        .toList();
  }
}

/* ═════════════════════════════════════ SERVICE (Singleton) ══════════════════ */

class AvatarService extends ChangeNotifier {
  AvatarService._internal();
  static final AvatarService I = AvatarService._internal();

  /* ---------------- Runtime State ---------------- */

  final _db = _AvatarDB();
  late EventBus _bus;
  StreamSubscription? _sub;

  final Map<String, String?> _selected = {
    'background': null,
    'wing': null,
    'body': null,
    'head': null,
    'accessory': null,
    'weapon': null,
  };
  final Set<String> _unlocked = {
    // Basis‑Starter‑Pack
    'bg_blue',
    'body_default',
    'head_cap',
  };

  final List<AvatarItem> _catalog = [];
  String? _previewItem;

  /* ---------------- Public API ---------------- */

  String? get previewItem => _previewItem;

  List<AvatarItem> get catalog => List.unmodifiable(_catalog);

  List<AvatarItem> itemsForLayer(String layer) =>
      _catalog.where((e) => e.layer == layer).toList();

  String? selectedItem(String layer) => _selected[layer];

  bool itemUnlocked(String key) => _unlocked.contains(key);

  Map<String, UnlockCondition?> get unlockRules => {
    for (final i in _catalog) i.key: i.unlock,
  };

  /* ---------------- Lifecycle ---------------- */

  Future<AvatarService> init(EventBus bus) async {
    _bus = bus;
    _sub = _bus.on().listen(_onEvent);
    await _db.open();
    await _loadState();
    await _buildCatalog();
    return this;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /* ---------------- State Management ---------------- */

  Future<void> equip(String layer, String key) async {
    if (!itemUnlocked(key)) return;
    _selected[layer] = key;
    await _db.saveSelection(layer, key);
    notifyListeners();
  }

  Future<void> unlock(String key) async {
    if (_unlocked.add(key)) {
      await _db.addUnlock(key);
      notifyListeners();
    }
  }

  /// Prüft Regeln & gibt neu freigeschaltete Items zurück
  Future<List<AvatarItem>> checkUnlocks() async {
    final points = SettingsService.I.childPoints;
    final level = SettingsService.I.childLevel;

    final List<AvatarItem> newly = [];
    for (final i in _catalog) {
      if (!_unlocked.contains(i.key) &&
          (i.unlock?.evaluate(points, level) ?? false)) {
        await unlock(i.key);
        newly.add(i);
      }
    }
    return newly;
  }

  /* ---------------- Custom Uploads ---------------- */

  Future<void> addCustomItem(String layer, String filePath) async {
    final fileName = p.basenameWithoutExtension(filePath);
    final key = 'c_${layer}_$fileName';

    final item = AvatarItem(
      key: key,
      name: fileName,
      layer: layer,
      assetPath: filePath,
      isCustom: true,
    );
    _catalog.add(item);
    await _db.storeItem(item);
    notifyListeners();
  }

  /* ---------------- Helpers ---------------- */

  List<String> getImagePaths() {
    final order = ['background', 'wing', 'body', 'head', 'accessory', 'weapon'];
    return order
        .map((l) => _selected[l])
        .where((k) => k != null && itemUnlocked(k))
        .map((k) => _catalog.firstWhere((e) => e.key == k!).assetPath)
        .toList();
  }

  /* ---------------- Private ---------------- */

  Future<void> _loadState() async {
    _selected.addAll(await _db.loadSelections());
    _unlocked.addAll(await _db.loadUnlocks());
  }

  Future<void> _buildCatalog() async {
    /* Built‑in Assets */
    const builtIn = [
      AvatarItem(
          key: 'bg_blue',
          name: 'Blue',
          layer: 'background',
          assetPath: 'assets/avatar/background/bg_blue.png'),
      AvatarItem(
          key: 'bg_forest',
          name: 'Forest',
          layer: 'background',
          assetPath: 'assets/avatar/background/bg_forest.png',
          unlock: UnlockCondition(minPoints: 100)),
      AvatarItem(
          key: 'wing_angel',
          name: 'Angel Wings',
          layer: 'wing',
          assetPath: 'assets/avatar/wing/wing_angel.png',
          unlock: UnlockCondition(minLevel: 3)),
      AvatarItem(
          key: 'wing_fire',
          name: 'Fire Wings',
          layer: 'wing',
          assetPath: 'assets/avatar/wing/wing_fire.png',
          unlock: UnlockCondition(minLevel: 5)),
      AvatarItem(
          key: 'body_default',
          name: 'Default Body',
          layer: 'body',
          assetPath: 'assets/avatar/body/body_default.png'),
      AvatarItem(
          key: 'head_cap',
          name: 'Cap',
          layer: 'head',
          assetPath: 'assets/avatar/head/head_cap.png'),
      AvatarItem(
          key: 'head_helmet',
          name: 'Helmet',
          layer: 'head',
          assetPath: 'assets/avatar/head/head_helmet.png',
          unlock: UnlockCondition(minPoints: 200)),
      AvatarItem(
          key: 'acc_glasses',
          name: 'Glasses',
          layer: 'accessory',
          assetPath: 'assets/avatar/accessory/acc_glasses.png'),
      AvatarItem(
          key: 'acc_flower',
          name: 'Flower',
          layer: 'accessory',
          assetPath: 'assets/avatar/accessory/acc_flower.png',
          unlock: UnlockCondition(minPoints: 150)),
      AvatarItem(
          key: 'wp_sword',
          name: 'Sword',
          layer: 'weapon',
          assetPath: 'assets/avatar/weapon/wp_sword.png',
          unlock: UnlockCondition(minLevel: 5)),
      AvatarItem(
          key: 'wp_wand',
          name: 'Magic Wand',
          layer: 'weapon',
          assetPath: 'assets/avatar/weapon/wp_wand.png',
          unlock: UnlockCondition(minLevel: 2)),
    ];
    _catalog..clear()..addAll(builtIn);

    /* Custom Assets stored in DB */
    _catalog.addAll(await _db.loadCustomItems());

    /* Remote‑uploaded Assets (if not yet in DB) */
    final dir = await getApplicationDocumentsDirectory();
    final remote = Directory(dir.path)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith('remote_'))
        .toList();

    for (final f in remote) {
      final fn = p.basenameWithoutExtension(f.path);
      final parts = fn.split('_');
      if (parts.length < 3) continue; // remote_<layer>_<name>.png
      final layer = parts[1];
      final key = 'c_${layer}_${parts.skip(2).join('_')}';
      if (_catalog.any((e) => e.key == key)) continue;
      final item = AvatarItem(
        key: key,
        name: parts.skip(2).join('_'),
        layer: layer,
        assetPath: f.path,
        isCustom: true,
      );
      _catalog.add(item);
      await _db.storeItem(item);
    }
  }

  void _onEvent(dynamic e) {
    switch (e) {
      case AvatarCelebrateEvent():
      // TODO – Callback für Animation
        break;
      case AvatarSadEvent():
      // TODO – Callback für Traurig‑Animation
        break;
      case AvatarItemPreviewEvent():
        _previewItem = e.itemKey;
        notifyListeners();
        break;
    }
  }
}
