/*
 *  avatar_service.dart  (v5 – final)
 *  --------------------------------------------------------------
 *  Zentraler Avatar-Service:
 *    – Singleton-Zugriff (AvatarService.I)
 *    – Initialisierung & EventBus-Anbindung (via attachEventBus)
 *    – ChangeNotifier für UI-Reaktionen
 *    – Auswahl und Freischaltungen für Avatar-Layer (z. B. Kopf, Körper)
 *    – Verarbeitung von AvatarEvents (Celebrate, Sad, Preview)
 *
 *  © 2025 Kids Diabetes Companion – GPL-3.0-or-later
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:event_bus/event_bus.dart';

import '../core/event_bus.dart';
import '../events/app_events.dart';

class AvatarService extends ChangeNotifier {
  AvatarService._();
  static final AvatarService I = AvatarService._();

  late EventBus _bus;
  StreamSubscription? _eventSub;

  final Map<String, String?> _selectedItems = {
    'background': null,
    'wing': null,
    'body': null,
    'head': null,
    'accessory': null,
    'weapon': null,
  };

  final Set<String> _unlockedItems = {
    'bg_blue', 'body_default', 'head_cap',
  };

  final Map<String, List<String>> _itemsPerLayer = {
    'background': ['bg_blue', 'bg_forest'],
    'wing': ['wing_angel', 'wing_fire'],
    'body': ['body_default'],
    'head': ['head_cap', 'head_helmet'],
    'accessory': ['acc_glasses', 'acc_flower'],
    'weapon': ['wp_sword', 'wp_wand'],
  };

  String? _previewItem;
  String? get previewItem => _previewItem;

  /// Initialisierung des Dienstes (z. B. aus Datenbank)
  Future<AvatarService> init() async {
    // TODO: Auswahl und Freischaltungen aus lokaler DB laden
    return this;
  }

  /// Anbindung an globalen EventBus
  AvatarService attachEventBus(EventBus bus) {
    _bus = bus;
    _eventSub?.cancel();
    _eventSub = _bus.on().listen(_onEvent);
    return this;
  }

  void _onEvent(dynamic event) {
    if (event is AvatarCelebrateEvent) {
      // TODO: Avatar feiert (Animation etc.)
    } else if (event is AvatarSadEvent) {
      // TODO: Avatar zeigt Traurigkeit
    } else if (event is AvatarItemPreviewEvent) {
      _previewItem = event.itemKey;
      notifyListeners();
    }
  }

  List<String> getItems(String layer) => _itemsPerLayer[layer] ?? [];

  String? getSelected(String layer) => _selectedItems[layer];

  void selectItem(String layer, String item) {
    if (!_itemsPerLayer[layer]!.contains(item)) return;
    _selectedItems[layer] = item;
    notifyListeners();
  }

  bool isUnlocked(String itemId) => _unlockedItems.contains(itemId);

  void unlockItem(String itemId) {
    _unlockedItems.add(itemId);
    notifyListeners();
  }

  /// Unlock-Regeln basierend auf Punkten & Level (Dummy-Implementierung)
  Future<void> checkUnlocks(int points, int level) async {
    if (points >= 100 && !_unlockedItems.contains('bg_forest')) {
      _unlockedItems.add('bg_forest');
    }
    if (level >= 3 && !_unlockedItems.contains('wing_angel')) {
      _unlockedItems.add('wing_angel');
    }
    if (level >= 5 && !_unlockedItems.contains('wp_sword')) {
      _unlockedItems.add('wp_sword');
    }
    notifyListeners();
  }

  /// Liefert alle aktiv gewählten Bildelemente mit Pfaden für die UI
  List<String> getImagePaths() {
    final paths = <String>[];
    for (final entry in _selectedItems.entries) {
      final item = entry.value;
      if (item != null) {
        paths.add('assets/avatar/${entry.key}/$item.png');
      }
    }
    return paths;
  }

  Map<String, String?> get allSelected => Map.unmodifiable(_selectedItems);
  Set<String> get unlockedItems => Set.unmodifiable(_unlockedItems);

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }
}
