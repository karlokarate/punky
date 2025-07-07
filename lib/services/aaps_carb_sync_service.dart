/*
 *  aaps_carb_sync_service.dart  (v1 – FINAL)
 *  --------------------------------------------------------------
 *  Persistiert analysierte KH‑Mahlzeiten in die AAPS‑Carb‑DB.
 *  • Stand‑alone  :   no‑op
 *  • Plugin       :   MethodChannel → ContentProvider‑Insert
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'package:flutter/services.dart';

import '../core/app_initializer.dart';

class AapsCarbSyncService {
  AapsCarbSyncService._(this._flavor);
  static late AapsCarbSyncService I;
  final AppFlavor _flavor;
  static const _ch = MethodChannel('kidsapp/carb_sync');

  static Future<void> init(AppFlavor flavor) async {
    I = AapsCarbSyncService._(flavor);
  }

  Future<void> persistMeal(
      double carbs, List<Map<String, dynamic>> components) async {
    if (_flavor != AppFlavor.plugin) return;
    try {
      await _ch.invokeMethod('addMeal', {
        'carbs': carbs,
        'components': components,
        'timestamp': DateTime.now().millisecondsSinceEpoch
      });
    } catch (_) {/* ignore */}
  }
}