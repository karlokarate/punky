/*
 *  meal_review_screen.dart  (v3 – i18n)
 *  --------------------------------------------------------------
 *  Bewertungs-Screen nach Analyse: KH-Komponenten, Bolus-Empfehlung,
 *  Interaktion mit AAPS (manuell bestätigt), visuell optimiert.
 */

import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/meal_analyzer.dart'
    show MealReviewComponent, BolusCalculatedEvent;
import '../events/app_events.dart';

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

class MealReviewScreen extends StatefulWidget {
  final EventBus eventBus;
  const MealReviewScreen({super.key, required this.eventBus});

  @override
  State<MealReviewScreen> createState() => _MealReviewScreenState();
}

class _MealReviewScreenState extends State<MealReviewScreen> {
  List<MealReviewComponent> _components = const [];
  double _totalCarbs = 0.0;
  BolusCalculatedEvent? _bolusRec;

  late final StreamSubscription _subAnalysis;
  late final StreamSubscription _subBolus;

  @override
  void initState() {
    super.initState();

    _subAnalysis = widget.eventBus.on<MealAnalyzedEvent>().listen((e) {
      setState(() {
        _components = e.components;
        _totalCarbs = e.totalCarbs;
      });
    });

    _subBolus = widget.eventBus.on<BolusCalculatedEvent>().listen((e) {
      setState(() => _bolusRec = e);
      _showBolusDialog(e);
    });
  }

  @override
  void dispose() {
    _subAnalysis.cancel();
    _subBolus.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.decimalPattern();
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.mealReviewTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.mealRevTotalLabel,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (_totalCarbs / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text('${nf.format(_totalCarbs)} g ${l.mealRevSectionGrams}',
                    style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _components.length,
              itemBuilder: (context, i) {
                final c = _components[i];
                return Card(
                  shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(
                      c.isNewlyAdded ? Icons.new_releases : Icons.fastfood,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(c.name),
                    subtitle: Text(
                        '${nf.format(c.grams)} g  •  ${nf.format(c.carbsTotal)} g ${l.mealRevSectionGrams}'),
                  ),
                );
              },
            ),
          ),
          if (_bolusRec != null) _buildBolusBanner(_bolusRec!, context),
        ],
      ),
    );
  }

  Widget _buildBolusBanner(BolusCalculatedEvent e, BuildContext ctx) {
    final l = AppLocalizations.of(ctx)!;
    return Material(
      color: e.isSafe ? Colors.teal : Colors.red.shade700,
      child: ListTile(
        leading: const Icon(Icons.medical_services, color: Colors.white),
        title: Text(
          '${l.mealRevRecommendation}: ${e.units.toStringAsFixed(1)} IE',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          e.reason.isEmpty ? l.mealRevRecommendedBy : e.reason,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: TextButton(
          onPressed: () => _showBolusDialog(e),
          child: Text(l.commonDetails,
              style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Future<void> _showBolusDialog(BolusCalculatedEvent e) async {
    final l = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.mealRevDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l.mealRevDialogCarbs}: ${e.carbs.toStringAsFixed(1)} g'),
            const SizedBox(height: 4),
            Text('IE: ${e.units.toStringAsFixed(1)}'),
            const SizedBox(height: 4),
            Text(
              e.reason.isEmpty ? l.mealRevDialogNone : e.reason,
              style: TextStyle(
                color: e.isSafe ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.commonCancel),
          ),
          if (e.isSafe)
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(l.mealRevDialogConfirm),
              onPressed: () {
                // TODO: Bolus senden
                Navigator.of(ctx).pop();
              },
            ),
        ],
      ),
    );
  }
}