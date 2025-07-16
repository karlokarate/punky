// lib/services/nightscout_service.dart
//
// v8 – BRIDGE COMPLETE & VALIDATED
// --------------------------------------------------------------
// • ersetzt alle channel-Zugriffe durch AAPSBridge-Methoden
// • Plugin-Modus nutzt Flutter <-> AAPSBridge vollständig
// • Standalone-Modus nutzt Nightscout REST + GlobalRateLimiter
// • persistente Logik, Profilpatch, Glukose-Cache, Bolus-Approval
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:synchronized/synchronized.dart';
import '../core/app_flavor.dart';
import 'settings_service.dart';
import 'nightscout_models.dart';
import '../events/app_events.dart';
import '../core/event_bus.dart';
import '../network/global_rate_limiter.dart';
import '../core/global.dart';

extension GlucoseTrendArrow on GlucoseEntry {
  String get trendArrow {
    const map = {
      0: '⇼',
      1: '↓↓',
      2: '↘',
      3: '→',
      4: '↗',
      5: '↑',
      6: '↑↑',
      7: '✶',
      8: '↜',
      9: '↝'
    };
    return map[trend] ?? '';
  }
}

class NightscoutService extends ChangeNotifier {
  NightscoutService._();
  static final NightscoutService instance = NightscoutService._();

  late final SettingsService _settings;
  late final AppFlavor _flavor;
  GlucoseEntry? currentEntry;
  List<GlucoseEntry> cachedEntries = <GlucoseEntry>[];
  final List<ParentLogEvent> parentLog = [];

  Timer? _pollTimer;
  final Lock _uploadLock = Lock();
  final _pendingTreatments = <Map<String, dynamic>>[];
  Timer? _flushTimer;

  Future<void> init(SettingsService settings) async {
    if (_pollTimer != null) return;
    _settings = settings;
    _flavor = appCtx.flavor;

    _startPolling();
    _flushTimer ??= Timer.periodic(const Duration(seconds: 30), (_) => _flushTreatments());
  }

  bool get isPlugin => _flavor == AppFlavor.plugin;

  Future<List<GlucoseEntry>> fetchGlucose({int count = 12}) async {
    if (isPlugin) {
      final raw = await appCtx.aapsBridge.getEntries(count);
      return raw.map(GlucoseEntry.fromJson).toList();
    }

    return GlobalRateLimiter.I.exec('nightscout', () async {
      final resp = await http.get(
        Uri.parse('${_baseUrl()}/api/v1/entries.json?count=$count&find[device]=Dexcom'),
        headers: _headers(),
      );
      if (resp.statusCode != 200) throw Exception('Nightscout ${resp.statusCode}');
      return (jsonDecode(resp.body) as List)
          .map((e) => GlucoseEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  Future<List<Treatment>> fetchTreatments({int count = 10}) async {
    if (isPlugin) {
      final raw = await appCtx.aapsBridge.getTreatments(count);
      return raw.map(Treatment.fromJson).toList();
    }

    return GlobalRateLimiter.I.exec('nightscout', () async {
      final resp = await http.get(
        Uri.parse('${_baseUrl()}/api/v1/treatments.json?count=$count'),
        headers: _headers(),
      );
      if (resp.statusCode != 200) throw Exception('Nightscout ${resp.statusCode}');
      return (jsonDecode(resp.body) as List)
          .map((e) => Treatment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  Future<DeviceStatus?> fetchDeviceStatus() async {
    if (isPlugin) {
      final raw = await appCtx.aapsBridge.getDeviceStatus();
      return raw != null ? DeviceStatus.fromJson(raw) : null;
    }

    return GlobalRateLimiter.I.exec('nightscout', () async {
      final uri = Uri.parse('${_baseUrl()}/api/v1/devicestatus.json?count=1');
      final resp = await http.get(uri, headers: _headers());
      if (resp.statusCode != 200) return null;
      final List list = jsonDecode(resp.body);
      if (list.isEmpty) return null;
      return DeviceStatus.fromJson(Map<String, dynamic>.from(list.first));
    });
  }

  Future<DeviceStatus?> fetchLoopStatus() => fetchDeviceStatus();

  Future<void> uploadTreatment(Map<String, dynamic> payload) async {
    if (isPlugin) {
      await appCtx.aapsBridge.uploadTreatment(payload);
      return;
    }
    if (payload.isEmpty || _settings.nightscoutUrl.isEmpty) return;
    await _uploadLock.synchronized(() => _pendingTreatments.add(payload));
  }

  Future<bool> uploadProfilePatch(Map<String, dynamic> patch) async {
    if (patch.isEmpty || _settings.nightscoutUrl.isEmpty) return false;

    if (isPlugin) {
      final ok = await appCtx.aapsBridge.uploadProfilePatch(patch);
      if (ok) _log('Profil‑Patch (Plugin) hochgeladen');
      return ok;
    }

    return GlobalRateLimiter.I.exec('nightscout', () async {
      final uri = Uri.parse('${_baseUrl()}/api/v1/profile');
      final resp = await http.post(
        uri,
        headers: _headers(contentType: true),
        body: jsonEncode(patch),
      );
      final ok = resp.statusCode == 200;
      if (ok) _log('Profil‑Patch hochgeladen');
      return ok;
    });
  }

  double? getAverage(DateTime from, DateTime to) {
    final sub = cachedEntries.where((e) => !e.date.isBefore(from) && !e.date.isAfter(to));
    if (sub.isEmpty) return null;
    final sum = sub.fold<int>(0, (acc, e) => acc + e.sgv.round());
    return sum / sub.length;
  }

  Future<void> refresh() async => await Future.wait([_updateGlucose(), _updateTreatments()]);

  Future<List<GlucoseEntry>> getRecentEntries({int limit = 96}) async {
    await _updateGlucose(limit: limit);
    return cachedEntries;
  }

  Future<bool> authorizePendingBolus() async {
    if (isPlugin) {
      final ok = await appCtx.aapsBridge.authorizeBolus();
      if (ok) _log('Bolus freigegeben (Plugin)');
      return ok;
    }

    if (_settings.nightscoutUrl.isEmpty) return false;
    return GlobalRateLimiter.I.exec('nightscout', () async {
      final uri = Uri.parse('${_baseUrl()}/api/v1/treatments');
      final resp = await http.post(
        uri,
        headers: _headers(contentType: true),
        body: jsonEncode({'action': 'approve-last-bolus'}),
      );
      final ok = resp.statusCode == 200;
      if (ok) _log('Bolus freigegeben');
      return ok;
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
    unawaited(refresh());
  }

  Future<void> _updateGlucose({int limit = 96}) async {
    try {
      final entries = await fetchGlucose(count: limit);
      cachedEntries = entries.reversed.toList();
      currentEntry = cachedEntries.isNotEmpty ? cachedEntries.last : null;
      notifyListeners();
    } catch (_) {/* ignore */ }
  }

  Future<void> _updateTreatments() async {
    try {
      final list = await fetchTreatments(count: 50);
      parentLog
        ..clear()
        ..addAll(list.map((t) => ParentLogEvent.fromTreatment(t.toJson())));
      notifyListeners();
    } catch (_) {/* ignore */ }
  }

  Future<void> _flushTreatments() async {
    if (_pendingTreatments.isEmpty) return;
    late final List<Map<String, dynamic>> batch;
    await _uploadLock.synchronized(() {
      batch = List<Map<String, dynamic>>.from(_pendingTreatments);
      _pendingTreatments.clear();
    });

    await GlobalRateLimiter.I.exec('nightscout', () async {
      final uri = Uri.parse('${_baseUrl()}/api/v1/treatments.json');
      final resp = await http.post(
        uri,
        headers: _headers(contentType: true),
        body: jsonEncode(batch),
      );
      if (resp.statusCode >= 400) {
        await _uploadLock.synchronized(() => _pendingTreatments.insertAll(0, batch));
        throw Exception('NS upload failed ${resp.statusCode}');
      } else {
        _log('Nightscout: ${batch.length} Treatments hochgeladen');
      }
    });
  }

  void _log(String msg) {
    final evt = ParentLogEvent(message: msg, timestamp: DateTime.now());
    parentLog.add(evt);
    eventBus.fire(evt);
    notifyListeners();
  }

  String _baseUrl() => _settings.nightscoutUrl.trim().replaceAll(RegExp(r'/$'), '');

  Map<String, String> _headers({bool contentType = false}) {
    final h = <String, String>{'API-SECRET': _settings.nightscoutSecretSHA1};
    if (contentType) h['Content-Type'] = 'application/json';
    return h;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _flushTimer?.cancel();
    super.dispose();
  }
}
