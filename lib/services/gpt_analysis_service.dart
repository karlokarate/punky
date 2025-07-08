import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';
import '../events/app_events.dart';

class GPTAnalysisResult {
  GPTAnalysisResult({required this.suggestion, this.raw});
  final String suggestion;
  final Map<String, dynamic>? raw;
}

/// Bindet einen GPT‑/LLM‑Endpoint an und erstellt Empfehlungen zur Profil‑Optimierung.
class GptAnalysisService {
  GptAnalysisService(this._settings);
  final SettingsService _settings;

  Future<GPTAnalysisResult?> analyzeNightscout(
      List<dynamic> nightscoutHistory) async {
    if (_settings.gptEndpoint.isEmpty || _settings.gptApiKey.isEmpty) {
      return null;
    }

    final payload = {
      'model': 'gpt‑4o‑mini',
      'messages': [
        {
          'role': 'system',
          'content':
          'Du bist ein erfahrener Kinder‑Diabetes‑Coach. Analysiere die Nightscout‑Daten und gib konkrete, kurze Empfehlungen zur Basalrate/ISF/ICR‑Anpassung.'
        },
        {
          'role': 'user',
          'content': jsonEncode(nightscoutHistory),
        }
      ]
    };

    final resp = await http
        .post(Uri.parse(_settings.gptEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_settings.gptApiKey}',
        },
        body: jsonEncode(payload))
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final content = data['choices'][0]['message']['content'] as String;
      return GPTAnalysisResult(suggestion: content, raw: data);
    }
    return null;
  }
}
