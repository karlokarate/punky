// lib/services/aaps_carb_sync_service.dart
//
// v2 – FINAL mit AAPSBridge-Integration
// --------------------------------------------------------------
// Persistiert analysierte KH‑Mahlzeiten in AAPS über appCtx.aapsBridge
// • Stand‑alone:   kein Effekt
// • Plugin‑Modus:  Übergibt carbs + Komponenten + Timestamp via Bridge
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import '../core/app_flavor.dart';
import '../core/app_context.dart';

class AapsCarbSyncService {
  AapsCarbSyncService._(this._flavor);
  static late AapsCarbSyncService I;
  final AppFlavor _flavor;

  static Future<void> init(AppFlavor flavor) async {
    I = AapsCarbSyncService._(flavor);
  }

  Future<void> persistMeal(
      double carbs,
      List<Map<String, dynamic>> components,
      ) async {
    if (_flavor != AppFlavor.plugin) return;

    try {
      await appCtx.aapsBridge.sendCarbEntry(
        carbs: carbs,
        time: DateTime.now(),
        note: _buildNote(components),
      );
    } catch (e) {
      // Optional: Logging oder Fehlerweiterleitung
    }
  }

  /// Erstellt eine Kurzbeschreibung für den Bolus-Notiz-Eintrag
  String _buildNote(List<Map<String, dynamic>> components) {
    if (components.isEmpty) return 'KH aus KidsApp';
    return components.map((e) => e['label'] ?? '').where((s) => s != '').join(', ');
  }
}
