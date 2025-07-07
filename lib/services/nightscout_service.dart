/*
 *  nightscout_service.dart (v3 – FINAL)
 *  --------------------------------------------------------------
 *  Vollwertiger Nightscout​-Client für beide Integrations​-Varianten:
 *    • Standalone ("sa") – direkter REST​-Zugriff über HTTP
 *    • Plugin     ("pl") – Delegation an AAPS​-NightscoutSyncService
 *
 *  Unterstützte Features:
 *    ✓ Glukose​-Einträge       (/entries.json)
 *    ✓ Treatments             (/treatments.json)
 *    ✓ DeviceStatus           (/devicestatus.json)
 *    ✓ Upload neuer Treatments (Bolus, Carbs, TempBasal, etc.)
 *
 *  Bridge: MethodChannel 'kidsapp/ns_bridge' (AAPS-Koppelung)
 *
 *  © 2025 Kids Diabetes Companion – GPL​-3.0​-or​later
 */

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../core/app_initializer.dart';
import 'settings_service.dart';
import '../services/nightscout_models.dart';

class NightscoutService {
  NightscoutService._();
  static final NightscoutService instance = NightscoutService._();

  late final SettingsService _settings;
  late final AppFlavor _flavor;

  static const MethodChannel _nsBridge =
  MethodChannel('kidsapp/ns_bridge');

  Future<void> init(SettingsService settings) async {
    _settings = settings;
    _flavor = const String.fromEnvironment('INTEGRATION_MODE', defaultValue: 'sa')
        .toLowerCase()
        .startsWith('p')
        ? AppFlavor.plugin
        : AppFlavor.standalone;
  }

  bool get isPlugin => _flavor == AppFlavor.plugin;

  Future<List<GlucoseEntry>> fetchGlucose({int count = 12}) async {
    if (isPlugin) {
      final List<dynamic> list =
      await _nsBridge.invokeMethod('getEntries', {'count': count});
      return list.map((e) => GlucoseEntry.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      final uri = Uri.parse(
          '${_baseUrl()}/api/v1/entries.json?count=$count&find[device]=Dexcom');
      final resp = await http.get(uri, headers: _headers());
      if (resp.statusCode != 200) throw Exception('NS ${resp.statusCode}');
      final list = jsonDecode(resp.body);
      return list.map<GlucoseEntry>((e) => GlucoseEntry.fromJson(Map<String, dynamic>.from(e))).toList();
    }
  }

  Future<List<Treatment>> fetchTreatments({int count = 10}) async {
    if (isPlugin) {
      final List<dynamic> list =
      await _nsBridge.invokeMethod('getTreatments', {'count': count});
      return list.map((e) => Treatment.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      final uri =
      Uri.parse('${_baseUrl()}/api/v1/treatments.json?count=$count');
      final resp = await http.get(uri, headers: _headers());
      if (resp.statusCode != 200) throw Exception('NS ${resp.statusCode}');
      final list = jsonDecode(resp.body);
      return list.map<Treatment>((e) => Treatment.fromJson(Map<String, dynamic>.from(e))).toList();
    }
  }

  Future<DeviceStatus?> fetchDeviceStatus() async {
    if (isPlugin) {
      final Map? map = await _nsBridge.invokeMethod('getDeviceStatus');
      return map != null ? DeviceStatus.fromJson(Map<String, dynamic>.from(map)) : null;
    } else {
      final uri = Uri.parse('${_baseUrl()}/api/v1/devicestatus.json?count=1');
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
        throw Exception('Upload failed: ${resp.statusCode} ${resp.body}');
      }
    }
  }

  String _baseUrl() =>
      _settings.nightscoutUrl.trim().replaceAll(RegExp(r'/\$'), '');

  Map<String, String> _headers({bool contentType = false}) {
    final h = <String, String>{
      'API-SECRET': _settings.nightscoutSecretSHA1,
    };
    if (contentType) h['Content-Type'] = 'application/json';
    return h;
  }
}
