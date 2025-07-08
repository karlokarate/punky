import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'package:event_bus/event_bus.dart';

import '../l10n/app_localizations.dart';
import '../core/event_bus.dart';
import '../events/app_events.dart';
final EventBus eventBus = AppEventBus.I.bus;

class ParsedItem {
  final double amount;
  final String unitId;
  final String term;
  final String? category;
  final bool hasConcreteQuantity;

  ParsedItem({
    required this.amount,
    required this.unitId,
    required this.term,
    this.category,
    this.hasConcreteQuantity = true,
  });
}

class TextParser {
  static final Map<String, Map<String, String>> _unitIndex = {};
  static bool _loaded = false;

  static Future<void> loadUnitsFromYaml(String path) async {
    final yamlString = await rootBundle.loadString(path);
    final yamlMap = loadYaml(yamlString) as YamlMap;
    final einheiten = yamlMap['einheiten'] as YamlList;
    _unitIndex.clear();

    for (final einheit in einheiten) {
      final id = einheit['id']?.toString();
      final category = einheit['category']?.toString();
      final synonyms = (einheit['synonyms'] as YamlList).cast<String>();
      if (id != null && category != null) {
        for (final s in synonyms) {
          _unitIndex[s.toLowerCase()] = {'id': id, 'category': category};
        }
      }
    }
    _loaded = true;
  }

  static List<ParsedItem> parse(String input) {
    final loc = lookupAppLocalizations(const Locale('en'));
    if (!_loaded) {
      throw Exception(loc.parserErrorNotLoaded);
    }

    final List<ParsedItem> result = [];
    final tokens = input.toLowerCase().split(RegExp(r'\s+'));

    for (int i = 0; i < tokens.length; i++) {
      final amount = _parseAmount(tokens[i]);
      if (amount == null || i + 1 >= tokens.length) continue;

      final unitToken = tokens[i + 1];
      final unitData = _unitIndex[unitToken];
      if (unitData == null) continue;

      final term = (i + 2 < tokens.length) ? tokens[i + 2] : unitToken;

      result.add(ParsedItem(
        amount: amount,
        unitId: unitData['id']!,
        category: unitData['category'],
        term: term,
        hasConcreteQuantity: true,
      ));
    }

    if (result.isEmpty) {
      for (int i = 0; i < tokens.length - 1; i++) {
        final unitData = _unitIndex[tokens[i]];
        if (unitData != null) {
          final term = tokens[i + 1];
          result.add(ParsedItem(
            amount: 1,
            unitId: unitData['id']!,
            category: unitData['category'],
            term: term,
            hasConcreteQuantity: false,
          ));
        }
      }
    }

    eventBus.fire(NewMealDetectedEvent(source: 'text'));
    return result;
  }

  static double? _parseAmount(String input) {
    input = input.replaceAll(',', '.');
    final lower = input.toLowerCase();

    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(lower)) {
      return double.tryParse(lower);
    }

    const numbers = {
      'null': 0,
      'eins': 1,
      'ein': 1,
      'eine': 1,
      'zwei': 2,
      'drei': 3,
      'vier': 4,
      'fünf': 5,
      'sechs': 6,
      'sieben': 7,
      'acht': 8,
      'neun': 9,
      'zehn': 10,
      'elf': 11,
      'zwölf': 12,
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
      'eleven': 11,
      'twelve': 12,
    };

    return numbers[lower]?.toDouble();

  }
}
