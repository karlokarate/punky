// lib/services/gpt_analysis_service.dart
//
// ▸ Original­funktionen (analyseNightscout) bleiben **unverändert bestehen**.
// ▸ Erweitert um:
//   • 20‑Min‑Datenselektion & Filter (SGV + Treatments)
//   • Automatische Ausführung alle 10 Tage (Timer über SharedPrefs)
//   • Strukturierte JSON‑Antwort (Empfehlungen) inkl. Begründung
//   • Persistente Verlaufs­ablage (RecommendationHistoryService)
//   • Push‑Benachrichtigung an Eltern‑Topic (CommunicationService)
//   • Event‑Dispatch NightscoutAnalysisAvailableEvent
//   • Öffentliche Methode  [maybeAnalyze]  als neuer Einstiegspunkt
//
// ------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:event_bus/event_bus.dart';

import 'settings_service.dart';
import '../events/app_events.dart';
import 'communication_service.dart';
import 'recommendation_history_service.dart';

/// Ursprüngliches Ergebnis­objekt – bleibt erhalten.
class GPTAnalysisResult {
  GPTAnalysisResult({required this.suggestion, this.raw});
  final String suggestion;
  final Map<String, dynamic>? raw;

  /// Kurzzusammenfassung für Push/Snackbar (neu).
  String summary() => suggestion.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Bindet einen GPT‑/LLM‑Endpoint an und erstellt Empfehlungen zur Profil‑Optimierung.
/// -----------------------------------------------------------------------------
/// *Neu* (v2):
///   – [maybeAnalyze] führt automatische Analyse alle 10 Tage durch  
///   – strukturierte JSON‑Antwort (Empfehlungen) wird verarbeitet  
///   – Verlauf wird geloggt, Push versendet, Event gefeuert
class GptAnalysisService {
  GptAnalysisService(this._settings, {EventBus? bus})
      : _bus = bus ?? EventBus();

  final SettingsService _settings;
  final EventBus _bus;

  /* ════════════════════════════  PUBLIC  ════════════════════════════ */

  /// 🔹 Automatische Analyse (alle 10 Tage) mit 20‑Min‑Sampling.
  ///
  /// * [sgvRaw]        – Nightscout `entries` (mind. _date_ & _sgv_)
  /// * [treatmentsRaw] – Nightscout `treatments`
  Future<void> maybeAnalyze(
    List<Map<String, dynamic>> sgvRaw,
    List<Map<String, dynamic>> treatmentsRaw,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final last  = prefs.getInt('last_nightscout_analysis') ?? 0;
    final now   = DateTime.now().millisecondsSinceEpoch;
    const interval = Duration(days: 10);

    if (now - last < interval.inMilliseconds) return; // noch nicht dran

    final sgv        = _reduce20Min(sgvRaw);
    final treatments = _filterTreatments(treatmentsRaw);
    final gpt        = await _callGptStructured(sgv, treatments);

    if (gpt == null) return;

    // Verlauf speichern
    await RecommendationHistoryService.i
        .addEntry(DateTime.now(), gpt['recommendations']);

    // Push an Eltern
    CommunicationService.I.sendPush(
      title  : 'Neue Therapie‑Empfehlung',
      body   : gpt['summary'] as String,
      payload: {
        'type'           : 'profile_suggestion',
        'recommendations': gpt['recommendations'],
      },
      target : 'parent',
    );

    // Event für UI
    _bus.fire(
      NightscoutAnalysisAvailableEvent(
        List<Map<String, dynamic>>.from(gpt['recommendations']),
      ),
    );

    await prefs.setInt('last_nightscout_analysis', now);
  }

  /// 🔹 *Unveränderte* ursprüngliche 1‑Shot‑Analyse – bleibt für API‑Kompatibilität.
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

  /* ═══════════════════════════  INTERNALS  ══════════════════════════ */

  // --- 20‑Minuten‑Sampling (SGV) ------------------------------------
  List<Map<String, dynamic>> _reduce20Min(List<Map<String, dynamic>> raw) {
    raw.sort((a, b) => (a['date'] as int).compareTo(b['date'] as int));
    final out = <Map<String, dynamic>>[];
    int last  = 0;
    for (final e in raw) {
      final ts = e['date'] as int? ?? 0;
      if (ts - last >= 20 * 60 * 1000) {
        out.add({'sgv': e['sgv'], 'date': ts});
        last = ts;
      }
    }
    return out;
  }

  // --- Only relevant treatment types -------------------------------
  List<Map<String, dynamic>> _filterTreatments(List<Map<String, dynamic>> raw) {
    const keep = {
      'Meal Bolus',
      'Correction Bolus',
      'Carb Correction',
      'Temp Basal'
    };
    return raw
        .where((t) => keep.contains(t['eventType']))
        .map((t) => {
              'eventType' : t['eventType'],
              'carbs'     : t['carbs'],
              'insulin'   : t['insulin'],
              'created_at': t['created_at'],
            })
        .toList();
  }

  // --- GPT‑Call (strukturierte JSON‑Antwort) -----------------------
  Future<Map<String, dynamic>?> _callGptStructured(
    List<Map<String, dynamic>> sgv,
    List<Map<String, dynamic>> treatments,
  ) async {
    if (_settings.gptEndpoint.isEmpty || _settings.gptApiKey.isEmpty) {
      return null;
    }

    const sysPrompt = '''
Du bist ein erfahrener Kinder‑Diabetes‑Coach.
Analysiere die SGV‑ und Therapie‑Daten (JSON) und gib höchstens drei Empfehlungen.
Antwortformat:
{
  "recommendations":[
    {
      "type":"ICR|ISF|Basal",
      "change":"kurze Beschreibung",
      "reason":"kurze Begründung",
      "profile_patch":{...}
    }
  ]
}''';

    final payload = {
      'model': 'gpt-4o-mini',
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': sysPrompt},
        {
          'role': 'user',
          'content': jsonEncode({'sgv': sgv, 'treatments': treatments}),
        }
      ]
    };

    try {
      final resp = await http
          .post(Uri.parse(_settings.gptEndpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${_settings.gptApiKey}',
              },
              body: jsonEncode(payload))
          .timeout(Duration(seconds: 30 + (sgv.length + treatments.length) ~/ 10));

      if (resp.statusCode != 200) return null;

      final root   = jsonDecode(resp.body) as Map<String, dynamic>;
      final rawMsg = root['choices'][0]['message']['content'] as String;
      final clean  = rawMsg.replaceAll(RegExp(r'```json|```', multiLine: true), '');
      final parsed = jsonDecode(clean) as Map<String, dynamic>;
      final recs   = List<Map<String, dynamic>>.from(parsed['recommendations'] ?? []);

      // Zusammenfassung für Push
      final summary = recs.map((r) => '• ${r['change']} (${r['reason']})').join('\n');

      return {
        'recommendations': recs,
        'summary'        : summary,
        'raw'            : root,
      };
    } catch (_) {
      return null;
    }
  }
}
