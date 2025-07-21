/*
 *  gpt_service.dart  (v5 – Original + GlobalRateLimiter + sendPrompt)
 *  --------------------------------------------------------------
 *  • Vollständige Event-Engine basierend auf YAML-Regeln
 *  • Avatar-Reaktionen, Offline-Modus, GPT-Call per GlobalRateLimiter
 *  • Ergänzt um sendPrompt(String) für direkte manuelle Abfragen
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
import '../network/global_rate_limiter.dart';

class GptService {
  GptService._();
  static final GptService I = GptService._();

  late EventBus _bus;
  late List<_Rule> _rules;
  late String _apiKey;
  late String _model;

  Future<void> init(EventBus bus) async {
    _bus = bus;
    _apiKey = SettingsService.I.gptApiKey;
    _model = 'gpt-4o';
    _rules = await _loadRules();
    _bus.on().listen(_handleEvent);
  }

  Future<List<_Rule>> _loadRules() async {
    final txt = await rootBundle.loadString('assets/config/gpt_rules.yaml');
    final yaml = loadYaml(txt) as YamlList;
    return yaml.map((m) => _Rule.fromYaml(m)).toList();
  }

  Future<void> _handleEvent(dynamic evt) async {
    final trigger = evt.runtimeType.toString();
    final rule = _rules.firstWhere(
          (r) => r.trigger == _camelToSnake(trigger),
      orElse: () => _Rule.empty(),
    );
    if (rule.isEmpty) return;

    _reactAvatar(rule.avatarReact);

    final modeSetting = SettingsService.I.enablePush ? 'online' : 'offline';
    final mode = rule.mode ?? modeSetting;
    if (mode == 'offline') return;

    if (_apiKey.isEmpty) return;

    final result = await _callGpt(_apiKey, rule.prompt ?? '', evt);
    if (result.isNotEmpty) {
      _bus.fire(GptResponseReceived(result));
    }
  }

  /// Öffentliche manuelle Abfrage (z. B. aus Eingabe)
  Future<String?> sendPrompt(String prompt) async {
    if (_apiKey.isEmpty) return null;
    final map = await _callGpt(_apiKey, prompt, {});
    return map['text'];
  }

  Future<Map<String, dynamic>> _callGpt(String key, String prompt, dynamic evt) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final body = {
      "model": _model,
      "temperature": 0,
      "messages": [
        {"role": "system", "content": prompt},
        {"role": "user", "content": jsonEncode(evt)}
      ]
    };

    return GlobalRateLimiter.I.exec('gpt', () async {
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
        final parsed = jsonDecode(content);
        return parsed is Map<String, dynamic> ? parsed : {"text": content};
      } catch (_) {
        return {"text": content};
      }
    });
  }

  void _reactAvatar(String? react) {
    if (react == null || react == 'none') return;
    if (react == 'celebrate') _bus.fire(AvatarCelebrateEvent());
    if (react == 'sad') _bus.fire(AvatarSadEvent());
    if (react.startsWith('speak(')) {
      final text = react.substring(6, react.length - 1);
      _bus.fire(AvatarSpeakEvent(text));
    }
  }

  String _camelToSnake(String s) =>
      s.replaceAllMapped(RegExp('([a-z])([A-Z])'), (m) => '${m[1]}_${m[2]}')
          .toLowerCase();
}

class _Rule {
  final String trigger;
  final String? mode;
  final String? prompt;
  final String? avatarReact;
  final bool empty;
  const _Rule({
    required this.trigger,
    this.mode,
    this.prompt,
    this.avatarReact,
    this.empty = false,
  });

  factory _Rule.empty() => const _Rule(trigger: '', empty: true);

  factory _Rule.fromYaml(YamlMap m) => _Rule(
    trigger: m['trigger'],
    mode: m['mode'],
    prompt: m['prompt'],
    avatarReact: m['avatar_react'],
  );

  bool get isEmpty => empty;
}
