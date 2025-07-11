// lib/services/bolus_engine.dart
//
// v5 – BRIDGE READY
// --------------------------------------------------------------
// Berechnet Bolus basierend auf KH, abhängig vom Betriebsmodus:
// • Plugin-Modus: ruft getInsulinRatio() über AAPSBridge
// • Standalone: verwendet SettingsService
// • Liefert BolusCalculatedEvent via EventBus
// • Optionaler Upload ins Nightscout-Treatment
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'package:event_bus/event_bus.dart';
import 'package:flutter/widgets.dart';

import 'package:diabetes_kids_app/l10n/gen_l10n/app_localizations.dart';
import '../core/event_bus.dart';
import '../events/app_events.dart';
import '../services/aaps_bridge.dart';
import '../services/nightscout_service.dart';
import '../services/settings_service.dart';
import '../core/app_context.dart';

class BolusEngine {
  static final BolusEngine I = BolusEngine._();
  BolusEngine._();

  final EventBus _bus = AppEventBus.I.bus;
  final SettingsService _settings = SettingsService.I;
  final NightscoutService _ns = NightscoutService.instance;

  /// Hauptlogik zur Berechnung (aber nicht Ausführung!) eines Bolus
  Future<void> calculateBolus(double carbs, BuildContext context) async {
    final loc = AppLocalizations.of(context);

    double? ratio;
    double units = 0;
    String reason = '';
    bool isSafe = true;

    final isPlugin = _ns.isPlugin;

    if (isPlugin) {
      try {
        ratio = await appCtx.aapsBridge
            .getInsulinRatio(); // z. B. 12g/IE aus Profil
        if (ratio != null && ratio > 0) {
          units = carbs / ratio;
          reason = loc.bolusReasonAaps(ratio.toStringAsFixed(1));
        }
      } catch (_) {
        reason = loc.bolusErrorBridge;
        ratio = null;
      }
    } else {
      ratio = _settings.insulinRatio;
      if (ratio > 0) {
        units = carbs / ratio;
        reason = loc.bolusReasonManual(
          carbs.toStringAsFixed(1),
          ratio.toStringAsFixed(1),
        );
      }
    }

    units = _round(units);
    if (units > 10) isSafe = false;

    _bus.fire(BolusCalculatedEvent(
      source: isPlugin ? 'plugin' : 'standalone',
      insulin: units,
      ratio: ratio ?? 0,
      carbs: carbs,
      units: units,
      reason: reason,
      isSafe: isSafe,
    ));
  }

  /// Optionaler Bolus-Upload (Standalone → NS-Treatment)
  Future<void> deliverBolus(
      double units,
      double carbs,
      BuildContext context,
      ) async {
    final loc = AppLocalizations.of(context);
    final isPlugin = _ns.isPlugin;

    if (isPlugin) {
      try {
        await appCtx.aapsBridge.sendCarbEntry(
          carbs: carbs,
          time: DateTime.now(),
          note: loc.bolusNoteBridge(units.toStringAsFixed(1)),
        );
      } catch (_) {
        // ggf. Logging oder Fallback-Info
      }
    } else {
      final treatment = {
        "eventType": "Meal Bolus",
        "insulin": units,
        "carbs": carbs,
        "enteredBy": "kidsapp",
        "notes": loc.bolusNoteAuto,
      };
      await _ns.uploadTreatment(treatment);
    }
  }

  double _round(double v) => (v * 10).roundToDouble() / 10;
}
