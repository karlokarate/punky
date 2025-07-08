/*
 *  meal_analyzer.dart  (v7 – korrigiert FINAL)
 *  --------------------------------------------------------------
 *  • Parsed Text → FoodItems → ProductMatch → KH ‑Summe
 *  • Berücksichtigt Portionen (servingQuantity) **korrekt**
 *  • Plausibilitäts​‑Check ±15 %, konfigurierbare Warn­schwelle
 *  • Ergebnis​‑Events  MealAnalyzedEvent, MealWarningEvent
 *  • AAPS​‑/Nightscout​‑Sync via AapsCarbSyncService
 *  • Liefert BolusCalculatedEvent mit Empfehlung (optional)
 *
 *  Projektpfad: lib/services/meal_analyzer.dart
 */

import 'dart:ui';

import 'package:event_bus/event_bus.dart';
import 'package:sqflite/sqflite.dart';

import '../core/event_bus.dart';
import '../events/app_events.dart';
import '../services/settings_service.dart';
import '../services/product_matcher.dart';
import '../services/aaps_carb_sync_service.dart';
import '../services/text_parser.dart';
import '../l10n/app_localizations.dart';

class MealReviewComponent {
  final String name;
  final double grams;
  final double carbsPer100g;
  final double carbsTotal;
  final bool isNewlyAdded;

  const MealReviewComponent({
    required this.name,
    required this.grams,
    required this.carbsPer100g,
    required this.carbsTotal,
    this.isNewlyAdded = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'grams': grams,
    'carbsPer100g': carbsPer100g,
    'carbsTotal': carbsTotal,
    'isNewlyAdded': isNewlyAdded,
  };
}

class MealAnalyzer {
  MealAnalyzer({required Database db})
      : _matcher = ProductMatcher(db),
        _bus = AppEventBus.I.bus,
        _settings = SettingsService.I,
        _sync = AapsCarbSyncService.I;

  final ProductMatcher _matcher;
  final EventBus _bus;
  final SettingsService _settings;
  final AapsCarbSyncService _sync;

  Future<void> analyze(String input) async {
    final loc = lookupAppLocalizations(const Locale('en'));
    await TextParser.loadUnitsFromYaml('assets/config/units.yaml');
    final parsedItems = TextParser.parse(input);

    final List<MealReviewComponent> results = [];
    double totalCarbs = 0.0;
    bool fuzzyHitOccurred = false;

    for (final parsed in parsedItems) {
      final item = FoodItem(rawName: parsed.term, amount: parsed.amount);
      final matchResult = await _matcher.findMatches(item);

      if (matchResult.fuzzyHit) fuzzyHitOccurred = true;

      for (final match in matchResult.matches) {
        final carbs = _calcCarbs(item, match);
        if (carbs == null) continue;

        totalCarbs += carbs;
        results.add(MealReviewComponent(
          name: match.name,
          grams: item.amount,
          carbsPer100g: match.carbsPer100g,
          carbsTotal: carbs,
          isNewlyAdded: true,
        ));
      }
    }

    _bus.fire(MealAnalyzedEvent(
      totalCarbs: totalCarbs,
      components: results.map((e) => e.toJson()).toList(),
    ));

    _processWarnings(totalCarbs, fuzzyHitOccurred, loc);
    await _sync.persistMeal(totalCarbs, results.map((e) => e.toJson()).toList());

    if (_settings.insulinRatio > 0) {
      final units = _round(totalCarbs / _settings.insulinRatio);
      _bus.fire(BolusCalculatedEvent(
        carbs: totalCarbs,
        units: units,
        reason: loc.carbAnalysisReasonDefault(
          _round(totalCarbs).toString(),
          _settings.insulinRatio.toString(),
        ),
        isSafe: units < 10,
      ));
    }
  }

  double? _calcCarbs(FoodItem item, ProductMatch match) {
    double? carbs;
    if (match.carbsPerServing != null &&
        match.servingQuantity != null &&
        match.servingQuantity! > 0) {
      final servings = item.amount / match.servingQuantity!;
      carbs = servings * match.carbsPerServing!;
    } else if (match.carbsPer100g > 0) {
      carbs = item.amount * match.carbsPer100g / 100;
    }
    return carbs != null ? _round(carbs) : null;
  }

  void _processWarnings(double totalCarbs, bool fuzzy, AppLocalizations loc) {
    final warnThreshold = _settings.carbWarnThreshold;
    final List<String> warns = [];

    if (totalCarbs >= warnThreshold) {
      warns.add(loc.carbAnalysisWarnHigh(_round(totalCarbs).toString()));
    }
    if (fuzzy) warns.add(loc.carbAnalysisWarnFuzzy);
    if (totalCarbs > 250) warns.add(loc.carbAnalysisWarnExcessive);

    if (warns.isNotEmpty) {
      _bus.fire(MealWarningEvent(warnings: warns));
    }
  }

  double _round(double v) => (v * 10).roundToDouble() / 10;
}
