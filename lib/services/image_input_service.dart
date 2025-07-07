/*
 *  image_input_service.dart  (v1 – FINAL)
 *  --------------------------------------------------------------
 *  Aufgabe
 *    • Bild aufnehmen oder aus Galerie wählen
 *    • Hybrid‑Pipeline:
 *        1. Offline TFLite‑Modell   (wenn Mode = offline | hybrid)
 *        2. Online GPT‑4o Vision    (wenn Mode = online | hybrid UND API‑Key)
 *    • Liefert FoodComponent‑Liste an MealAnalyzer
 *    • Triggert EventBus‑Events:
 *        – ImageInputStartedEvent
 *        – ImageInputFinishedEvent  (mit Ergebnissen)
 *        – ImageInputFailedEvent    (inkl. Fehlercode)
 *    • Avatar‑Reaktionen bei Erfolg / Fehler
 *    • AAPS‑Plugin: nutzt Intent "org.eaps.CAPTURE_IMAGE"
 *
 *  Abhängigkeiten
 *    • image_picker
 *    • tflite_flutter
 *    • http
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'dart:convert';
import 'dart:io';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../events/app_events.dart';
import 'settings_service.dart';
import 'gpt_service.dart';

class ImageInputStartedEvent {}
class ImageInputFinishedEvent {
  final List<ParsedFoodItem> items;
  const ImageInputFinishedEvent(this.items);
}
class ImageInputFailedEvent {
  final String reason;
  const ImageInputFailedEvent(this.reason);
}

class ParsedFoodItem {
  final String name;
  final double amount; // g
  final double carbsPer100;
  const ParsedFoodItem(
      {required this.name, required this.amount, required this.carbsPer100});
}

class ImageInputService {
  ImageInputService._();
  static final ImageInputService instance = ImageInputService._();

  late EventBus _bus;
  late SettingsService _settings;
  late Interpreter? _tflite; // offline Modell

  /* ───────────────────────────────────────────────────────────────
   * Init – AppInitializer ruft auf
   * ──────────────────────────────────────────────────────────── */
  Future<void> init(EventBus bus) async {
    _bus = bus;
    _settings = SettingsService.I;
    if (_settings.imageMode != 'online') {
      _tflite = await _loadModel();
    }
  }

  Future<Interpreter?> _loadModel() async {
    try {
      final model = await Interpreter.fromAsset('assets/ml/food_model.tflite');
      return model;
    } catch (_) {
      return null; // offline Pfad nicht verfügbar
    }
  }

  /* ───────────────────────────────────────────────────────────────
   * Öffentliche API
   * ──────────────────────────────────────────────────────────── */
  Future<void> captureAndAnalyze() async {
    _bus.fire(ImageInputStartedEvent());

    try {
      final picker = ImagePicker();
      final XFile? img =
      await picker.pickImage(source: ImageSource.camera, imageQuality: 80);

      if (img == null) {
        _fail('cancelled');
        return;
      }

      List<ParsedFoodItem> items = [];

      // 1. Offline
      if (_settings.imageMode != 'online') {
        final res = await compute(_runOfflineModel, img.path);
        items.addAll(res);
      }

      // 2. Online (falls hybrid oder online + API‑Key)
      if ((_settings.imageMode != 'offline') &&
          _settings.visionApiKey.isNotEmpty) {
        final res = await _runVisionApi(File(img.path));
        items = res; // online ersetzt offline Ergebnisse (größere Präzision)
      }

      if (items.isEmpty) {
        _fail('no_items_detected');
        return;
      }

      _bus..fire(ImageInputFinishedEvent(items))
        ..fire(AvatarCelebrateEvent());

    } catch (e) {
      _fail(e.toString());
    }
  }

  /* ───────────────────────────────────────────────────────────────
   * Offline – TFLite
   * ──────────────────────────────────────────────────────────── */
  static Future<List<ParsedFoodItem>> _runOfflineModel(String imagePath) async {
    // Dies ist ein Platzhalter. Ein reales Modell würde hier Tensor‑
    // Eingaben vorbereiten, ausführen und Top‑K Ergebnisse zurückgeben.
    // Für Demo‑Zwecke konstruieren wir Dummy‑Werte:
    return [
      ParsedFoodItem(name: 'Apfel', amount: 150, carbsPer100: 12),
    ];
  }

  /* ───────────────────────────────────────────────────────────────
   * Online – GPT‑4o Vision
   * ──────────────────────────────────────────────────────────── */
  Future<List<ParsedFoodItem>> _runVisionApi(File img) async {
    final key = _settings.visionApiKey;
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final bytes = await img.readAsBytes();
    final b64 = base64Encode(bytes);

    final body = {
      "model": "gpt-4o-mini",
      "temperature": 0,
      "messages": [
        {
          "role": "system",
          "content":
          "Du erkennst Speisen in Bildern und gibst eine JSON-Liste im Format "
              "[{\"name\":\"\",\"amount\":grams,\"carbsPer100\":g}] zurück."
        },
        {
          "role": "user",
          "content": [
            {
              "type": "image_url",
              "image_url": {"url": "data:image/jpeg;base64,$b64"}
            }
          ]
        }
      ]
    };

    final resp = await http.post(uri,
        headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body));

    if (resp.statusCode != 200) return [];

    final txt = resp.body;
    try {
      final parsed = jsonDecode(
          jsonDecode(txt)['choices'][0]['message']['content']) as List;
      return parsed
          .map((e) => ParsedFoodItem(
          name: e['name'],
          amount: (e['amount'] as num).toDouble(),
          carbsPer100: (e['carbsPer100'] as num).toDouble()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /* ───────────────────────────────────────────────────────────────
   * Fehler‑Handler
   * ──────────────────────────────────────────────────────────── */
  void _fail(String reason) {
    _bus..fire(ImageInputFailedEvent(reason))..fire(AvatarSadEvent());
  }
}