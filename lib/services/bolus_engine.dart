/*
 *  bolus_engine.dart  (v4 – fixed)
 *  --------------------------------------------------------------
 *  Berechnet Bolus auf Basis KH, abhängig vom Betriebsmodus (AAPS/Standalone)
 *  Nutzt AapsLogicPort → getInsulinRatio(), recommendBolus()
 *  Nutzt NightscoutService → fetchTreatments(), uploadTreatment()
 *  Gibt Event: BolusCalculatedEvent
 *
 *  © 2025 Kids Diabetes Companion – GPL​-3.0​-or​later
 */

import 'package:event_bus/event_bus.dart';
import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../core/event_bus.dart';
import '../events/app_events.dart';
import 'aaps_logic_port.dart';
import 'nightscout_service.dart';
import 'settings_service.dart';

class BolusEngine {
  static final BolusEngine I = BolusEngine._();
  BolusEngine._();

  final EventBus _bus = AppEventBus.I.bus;
  final SettingsService _settings = SettingsService.I;
  final NightscoutService _ns = NightscoutService.instance;

  /// Hauptlogik zur Berechnung (aber nicht Ausführung!) eines Bolus
  Future<void> calculateBolus(double carbs, BuildContext context) async {
    final loc = AppLocalizations.of(context)!;

    double? ratio;
    double units = 0;
    String reason = '';
    bool isSafe = true;

    final isPlugin = _ns.isPlugin;

    if (isPlugin) {
      ratio = await AapsLogicPort.getInsulinRatio();
      if (ratio != null && ratio > 0) {
        units = carbs / ratio;
        reason = loc.bolusReasonAaps(ratio.toStringAsFixed(1));
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
    ));
  }

  /// Optionaler Bolus​-Upload (Standalone → NS-Treatment)
  Future<void> deliverBolus(double units, double carbs, BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final isPlugin = _ns.isPlugin;

    if (isPlugin) {
      // TODO: Optionaler Trigger für AAPS-Execution
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
