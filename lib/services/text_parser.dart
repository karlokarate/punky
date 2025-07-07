import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'package:diabetes_kids_app/utils/localization_helper.dart';
import '../core/event_bus.dart';
import '../events/app_events.dart';

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
    if (!_loaded) {
      throw Exception(LocalizationHelper.get('text_parser.error.not_loaded'));
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

    if (RegExp(r'^\d+(\.\d+)?\$').hasMatch(lower)) {
      return double.tryParse(lower);
    }

    final numbers = Map<String, double>.from(LocalizationHelper.getMap('text_parser.numbers'));

    return numbers[lower];
  }
}
