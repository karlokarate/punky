/*
 *  gpt_service.dart
 *  --------------------------------------------------------------
 *  Zentrales Gateway zu GPT‑4o (o3pro) inkl. Offline‑Fallback und
 *  Event‑basierter Regel‑Engine.
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'dart:convert';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

import '../events/app_events.dart';
import 'settings_service.dart';

class GptService {
  GptService._();
  static final GptService I = GptService._();

  late EventBus _bus;
  late List<_Rule> _rules;

  Future<void> init(EventBus bus) async {
    _bus = bus;
    _rules = await _loadRules();

    // Event‑Abo
    _bus.on().listen(_handleEvent);
  }

  /* *********************************************************************
   *  Regel‑Loader
   * *********************************************************************/

  Future<List<_Rule>> _loadRules() async {
    final txt = await rootBundle.loadString('assets/config/gpt_rules.yaml');
    final yaml = loadYaml(txt) as YamlList;
    return yaml.map((m) => _Rule.fromYaml(m)).toList();
  }

  /* *********************************************************************
   *  Event‑Router
   * *********************************************************************/

  Future<void> _handleEvent(dynamic evt) async {
    final trigger = evt.runtimeType.toString(); // z. B. MealAnalyzedEvent
    final rule = _rules.firstWhere(
          (r) => r.trigger == _camelToSnake(trigger),
      orElse: () => _Rule.empty(),
    );
    if (rule.isEmpty) return;

    // Avatar‑Reaktion (auch ohne GPT möglich)
    _reactAvatar(rule.avatarReact);

    // Modus checken
    final modeSetting = SettingsService.I.enablePush
        ? 'online'
        : 'offline'; // Simpl. – könnte komplexer sein
    final mode = rule.mode ?? modeSetting;

    if (mode == 'offline') return; // keine GPT‑Abfrage nötig

    // Online oder hybrid
    final apiKey = SettingsService.I.gptApiKey;
    if (apiKey.isEmpty) return; // kein Key → skip

    await _callGpt(apiKey, rule, evt);
    // TODO: Ergebnis weiterverarbeiten
  }

  /* *********************************************************************
   *  GPT‑Call
   * *********************************************************************/

  Future<Map<String, dynamic>> _callGpt(
      String key, _Rule rule, dynamic evt) async {
    final prompt = rule.prompt ?? '';
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final body = {
      "model": "gpt-4o-mini",
      "temperature": 0,
      "messages": [
        {"role": "system", "content": prompt},
        {"role": "user", "content": jsonEncode(evt)}
      ]
    };
    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) return {};
    final data = jsonDecode(resp.body);
    final content = data['choices'][0]['message']['content'];
    try {
      return jsonDecode(content);
    } catch (_) {
      return {};
    }
  }

  /* *********************************************************************
   *  Avatar‑Reaktionen
   * *********************************************************************/

  void _reactAvatar(String? react) {
    if (react == null || react == 'none') return;
    if (react == 'celebrate') _bus.fire(AvatarCelebrateEvent());
    if (react == 'sad') _bus.fire(AvatarSadEvent());
    if (react.startsWith('speak(')) {
      final text = react.substring(6, react.length - 1);
      _bus.fire(AvatarSadEvent()); // Dummy: eigene Eventklasse denkbar
      // TODO: SpeechService.tts(text);
    }
  }

  String _camelToSnake(String s) =>
      s.replaceAllMapped(RegExp('([a-z])([A-Z])'), (m) => '${m[1]}_${m[2]}')
          .toLowerCase();
}

/* ***********************************************************************
 *  Hilfs‑Klasse Regel
 * *********************************************************************/

class _Rule {
  final String trigger;
  final String? mode;
  final String? prompt;
  final String? avatarReact;
  final bool empty;
  const _Rule(
      {required this.trigger,
        this.mode,
        this.prompt,
        this.avatarReact,
        this.empty = false});

  factory _Rule.empty() => const _Rule(trigger: '', empty: true);

  factory _Rule.fromYaml(YamlMap m) => _Rule(
    trigger: m['trigger'],
    mode: m['mode'],
    prompt: m['prompt'],
    avatarReact: m['avatar_react'],
  );

  bool get isEmpty => empty;
}