/*
 *  nightscout_service.dart (v4 – MERGED)
 *  --------------------------------------------------------------------------
 *  • Vereint die Funktionsvielfalt des bisherigen „v3 – FINAL“ (Standalone /
 *    Plugin‑Bridge, Upload‑Routinen, AAPS‑Channel) mit den Live‑Cache‑,
 *    Polling‑ und Provider‑Features des neuen Parent‑Screens (Trend‑Cache,
 *    ChangeNotifier, EventBus‑Log, Bolus‑Freigabe).
 *  • Bewahrt 100 % Rückwärtskompatibilität: alle älteren Aufrufe bleiben
 *    unverändert nutzbar, zusätzliche Reaktivität wird on‑top bereitgestellt.
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../core/app_initializer.dart';
import 'settings_service.dart';
import '../services/nightscout_models.dart';
import '../events/app_events.dart';
import '../core/event_bus.dart';

/// ---------------------------------------------------------------------------
/// Hilfs‑Extension: hübsches Trend‑Symbol
/// ---------------------------------------------------------------------------
extension GlucoseTrendArrow on GlucoseEntry {
  String get trendArrow {
    const map = {
      0: '⇼', // none
      1: '↓', // double down
      2: '↘',
      3: '→',
      4: '↗',
      5: '↑',
      6: '↑↑',
      7: '✶',
      8: '↜',
      9: '↝',
    };
    return map[trend] ?? '';
  }
}

/// ---------------------------------------------------------------------------
/// Nightscout‑Service (Singleton + ChangeNotifier + Event‑Log)
/// ---------------------------------------------------------------------------
class NightscoutService extends ChangeNotifier {
  // ---------------------- Singleton & Factory --------------------------------
  NightscoutService._();
  static final NightscoutService instance = NightscoutService._();

  /// Erlaubt die gewohnte Provider‑Syntax:
  /// `ChangeNotifierProvider(create: (_) => NightscoutService(settings))`
  factory NightscoutService(SettingsService settings) {
    instance._init(settings);
    return instance;
  }

  // ---------------------- generelle Konfiguration ----------------------------
  late final SettingsService _settings;
  late final AppFlavor _flavor; // Standalone ↔︎ Plugin
  static const MethodChannel _nsBridge =
  MethodChannel('kidsapp/ns_bridge');

  // ---------------------- Live‑Cache / State ---------------------------------
  GlucoseEntry? currentEntry;
  List<GlucoseEntry> cachedEntries = <GlucoseEntry>[];
  final List<ParentLogEvent> parentLog = [];

  Timer? _pollTimer;

  // ---------------------- Initialisierung ------------------------------------
  Future<void> _init(SettingsService settings) async {
    if (_pollTimer != null) return; // bereits initialisiert
    _settings = settings;
    _flavor = const String.fromEnvironment(
      'INTEGRATION_MODE',
      defaultValue: 'sa',
    ).toLowerCase().startsWith('p')
        ? AppFlavor.plugin
        : AppFlavor.standalone;

    _startPolling();
  }

  bool get isPlugin => _flavor == AppFlavor.plugin;

  // ---------------------- Öffentliche API (Bestand) --------------------------
  Future<List<GlucoseEntry>> fetchGlucose({int count = 12}) async {
    if (isPlugin) {
      final List<dynamic> list =
      await _nsBridge.invokeMethod('getEntries', {'count': count});
      return list
          .map((e) => GlucoseEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      final uri = Uri.parse(
          '${_baseUrl()}/api/v1/entries.json?count=$count&find[device]=Dexcom');
      final resp = await http.get(uri, headers: _headers());
      if (resp.statusCode != 200) {
        throw Exception('Nightscout ${resp.statusCode}');
      }
      final list = jsonDecode(resp.body);
      return list
          .map<GlucoseEntry>(
              (e) => GlucoseEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<List<Treatment>> fetchTreatments({int count = 10}) async {
    if (isPlugin) {
      final List<dynamic> list =
      await _nsBridge.invokeMethod('getTreatments', {'count': count});
      return list
          .map((e) => Treatment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      final uri = Uri.parse('${_baseUrl()}/api/v1/treatments.json?count=$count');
      final resp = await http.get(uri, headers: _headers());
      if (resp.statusCode != 200) {
        throw Exception('Nightscout ${resp.statusCode}');
      }
      final list = jsonDecode(resp.body);
      return list
          .map<Treatment>(
              (e) => Treatment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<DeviceStatus?> fetchDeviceStatus() async {
    if (isPlugin) {
      final Map? map = await _nsBridge.invokeMethod('getDeviceStatus');
      return map != null
          ? DeviceStatus.fromJson(Map<String, dynamic>.from(map))
          : null;
    } else {
      final uri =
      Uri.parse('${_baseUrl()}/api/v1/devicestatus.json?count=1');
      final resp = await http.get(uri, headers: _headers());
      if (resp.statusCode != 200) return null;
      final List list = jsonDecode(resp.body);
      if (list.isEmpty) return null;
      return DeviceStatus.fromJson(Map<String, dynamic>.from(list.first));
    }
  }

  Future<DeviceStatus?> fetchLoopStatus() => fetchDeviceStatus();

  Future<void> uploadTreatment(Map<String, dynamic> payload) async {
    if (isPlugin) {
      await _nsBridge.invokeMethod('uploadTreatment', payload);
    } else {
      final uri = Uri.parse('${_baseUrl()}/api/v1/treatments.json');
      final resp = await http.post(
        uri,
        headers: _headers(contentType: true),
        body: jsonEncode(payload),
      );
      if (resp.statusCode >= 400) {
        throw Exception(
            'Upload failed: ${resp.statusCode} ${resp.body}');
      }
    }
  }

  // ---------------------- Öffentliche API (NEU) ------------------------------
  /// Manuelles Refresh (Glukose + Treatments) und Notifikation.
  Future<void> refresh() async {
    await Future.wait([_updateGlucose(), _updateTreatments()]);
  }

  /// Liefert letzten `limit`‑SGV‑Einträge (Cache wird aktualisiert).
  Future<List<GlucoseEntry>> getRecentEntries({int limit = 96}) async {
    await _updateGlucose(limit: limit);
    return cachedEntries;
  }

  /// Autorisiert den letzten angeforderten Bolus (falls vorhanden).
  Future<bool> authorizePendingBolus() async {
    if (isPlugin) {
      final bool ok =
          await _nsBridge.invokeMethod('authorizeBolus') ?? false;
      if (ok) _log('Bolus freigegeben (Plugin)');
      return ok;
    }

    if (_settings.nightscoutUrl.isEmpty) return false;
    final uri =
    Uri.parse('${_baseUrl()}/api/v1/treatments'); // Beispiel‑Endpoint
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'approve-last-bolus'}),
    );
    final ok = resp.statusCode == 200;
    if (ok) _log('Bolus freigegeben');
    return ok;
  }

  // ---------------------- Polling / Cache‑Updates ---------------------------
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => refresh());
    unawaited(refresh()); // sofort ­(ignore lint)
  }

  Future<void> _updateGlucose({int limit = 96}) async {
    try {
      final entries = await fetchGlucose(count: limit);
      // Chronologisch sortieren (ältest → neu)
      cachedEntries = entries.reversed.toList();
      currentEntry = cachedEntries.isNotEmpty ? cachedEntries.last : null;
      notifyListeners();
    } catch (_) {
      // leise ignorieren
    }
  }

  Future<void> _updateTreatments() async {
    try {
      final list = await fetchTreatments(count: 50);
      parentLog
        ..clear()
        ..addAll(list
            .map((t) => ParentLogEvent.fromTreatment(t.toJson()))); // toJson() vorhanden
      notifyListeners();
    } catch (_) {
      // leise ignorieren
    }
  }

  void _log(String msg) {
    final evt = ParentLogEvent(
      message: msg,
      timestamp: DateTime.now(),
    );
    parentLog.add(evt);
    eventBus.fire(evt);
    notifyListeners();
  }

  // ---------------------- Helper --------------------------------------------
  String _baseUrl() =>
      _settings.nightscoutUrl.trim().replaceAll(RegExp(r'/$'), '');

  Map<String, String> _headers({bool contentType = false}) {
    final h = <String, String>{
      'API-SECRET': _settings.nightscoutSecretSHA1,
    };
    if (contentType) h['Content-Type'] = 'application/json';
    return h;
  }

  // ---------------------- Lebenszyklus --------------------------------------
  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
