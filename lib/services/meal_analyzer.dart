// lib/services/meal_analyzer.dart
//
// v8 – BRIDGE READY + VALIDIERT
// --------------------------------------------------------------
// • Text → FoodItems → ProductMatch → KH-Berechnung
// • berücksichtigt Portionen + Plausibilität
// • sendet MealAnalyzedEvent, MealWarningEvent, BolusCalculatedEvent
// • persistiert Mahlzeit: Plugin → AAPSBridge, Standalone → NS via AapsCarbSyncService
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'dart:ui';
import 'package:event_bus/event_bus.dart';
import 'package:sqflite/sqflite.dart';
import '../core/event_bus.dart';
import '../core/app_initializer.dart';
import '../events/app_events.dart';
import '../services/settings_service.dart';
import '../services/product_matcher.dart';
import '../services/aaps_carb_sync_service.dart';
import '../services/aaps_bridge.dart';
import '../services/text_parser.dart';
import 'package:diabetes_kids_app/l10n/gen_l10n/app_localizations.dart';

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

  factory MealReviewComponent.fromJson(Map<String, dynamic> json) {
    return MealReviewComponent(
      name: json['name'] ?? '',
      grams: (json['grams'] as num).toDouble(),
      carbsPer100g: (json['carbsPer100g'] as num).toDouble(),
      carbsTotal: (json['carbsTotal'] as num).toDouble(),
      isNewlyAdded: json['isNewlyAdded'] == true,
    );
  }
}

class MealAnalyzer {
  MealAnalyzer._(Database db)
      : _matcher = ProductMatcher(db),
        _bus = AppEventBus.I.bus,
        _settings = SettingsService.I,
        _sync = AapsCarbSyncService.I;

  static late MealAnalyzer I;

  static Future<void> init(Database db) async {
    I = MealAnalyzer._(db);
  }

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

    final jsonResults =
    List<Map<String, dynamic>>.from(results.map((e) => e.toJson()));

    _bus.fire(MealAnalyzedEvent(
      totalCarbs: totalCarbs,
      components: jsonResults,
    ));

    _processWarnings(totalCarbs, fuzzyHitOccurred, loc);

    // Plugin-Modus → direkt an Bridge senden
    if (appCtx.flavor == AppFlavor.plugin) {
      try {
        await appCtx.aapsBridge.sendCarbEntry(
          carbs: totalCarbs,
          time: DateTime.now(),
          note: loc.mealCarbNoteShort(totalCarbs.toStringAsFixed(1)),
        );
      } catch (_) {/* Fallback ignorieren */}
    } else {
      await _sync.persistMeal(totalCarbs, jsonResults);
    }

    // Bolus-Empfehlung
    double? ratio;
    if (appCtx.flavor == AppFlavor.plugin) {
      try {
        ratio = await appCtx.aapsBridge.getInsulinRatio();
      } catch (_) {}
    } else {
      ratio = _settings.insulinRatio;
    }

    if (ratio != null && ratio > 0) {
      final units = _round(totalCarbs / ratio);
      _bus.fire(BolusCalculatedEvent(
        carbs: totalCarbs,
        units: units,
        reason: loc.carbAnalysisReasonDefault(
          _round(totalCarbs).toString(),
          ratio.toString(),
        ),
        isSafe: units < 10,
        insulin: units,
        ratio: ratio,
        source: 'analyzer',
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
