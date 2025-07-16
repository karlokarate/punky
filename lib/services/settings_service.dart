// lib/services/settings_service.dart
//
// v11 – FINAL BRIDGE READY
// --------------------------------------------------------------
// Singleton Settings-Service mit lokaler + Plugin-Persistenz
// • SharedPreferences für Standalone
// • Spiegelung via appCtx.aapsBridge bei Plugin-Modus
// • Alle Schlüssel rückwärtskompatibel
// • Remote-Sync (settings_update, asset_upload)
// • ChangeNotifier + EventBus-Integration
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_flavor.dart';
import '../events/app_events.dart';
import '../core/event_bus.dart';
import '../core/global.dart';
class SettingsService extends ChangeNotifier {
  SettingsService._(this.flavor);
  static late SettingsService I;

  static Future<SettingsService> create() async {
    final flavor = const String.fromEnvironment('INTEGRATION_MODE', defaultValue: 'sa')
        .toLowerCase()
        .startsWith('p')
        ? AppFlavor.plugin
        : AppFlavor.standalone;
    final s = SettingsService._(flavor);
    await s._load();
    I = s;
    return s;
  }

  final AppFlavor flavor;
  late SharedPreferences _prefs;

  Future<void> _load() async => _prefs = await SharedPreferences.getInstance();

  /* --- Setup / Wizard --- */
  bool get initialSetupDone => _prefs.getBool('kidsapp_setup_done') ?? false;
  Future<void> setInitialSetupDone(bool v) async => _set('kidsapp_setup_done', v);
  Future<void> resetSetup() async => _set('kidsapp_setup_done', false, silent: true);

  /* --- Nightscout --- */
  String get nightscoutUrl => _prefs.getString('kidsapp_ns_url') ?? 'https://example.herokuapp.com';
  Future<void> setNightscoutUrl(String v) async => _set('kidsapp_ns_url', v, mirrorKey: 'nightscout_url');

  String get nightscoutSecretSHA1 => _prefs.getString('kidsapp_ns_secret') ?? '';
  Future<void> setNightscoutSecret(String v) async => _set('kidsapp_ns_secret', v, mirrorKey: 'api_secret');

  /* --- GPT / KI --- */
  String get gptEndpoint => _prefs.getString('kidsapp_gpt_endpoint') ?? '';
  Future<void> setGptEndpoint(String v) async => _set('kidsapp_gpt_endpoint', v);

  String get gptApiKey => _prefs.getString('kidsapp_gpt_key') ?? '';
  Future<void> setGptApiKey(String v) async => _set('kidsapp_gpt_key', v);

  String get whisperApiKey => _prefs.getString('kidsapp_whisper_key') ?? '';
  Future<void> setWhisperApiKey(String v) async => _set('kidsapp_whisper_key', v);

  String get visionApiKey => _prefs.getString('kidsapp_vision_key') ?? '';
  Future<void> setVisionApiKey(String v) async => _set('kidsapp_vision_key', v);

  /* --- Push / SMS --- */
  String get pushEndpoint => _prefs.getString('kidsapp_push_endpoint') ?? '';
  Future<void> setPushEndpoint(String v) async => _set('kidsapp_push_endpoint', v);

  String get parentTopic => _prefs.getString('kidsapp_parent_topic') ?? 'parents';
  Future<void> setParentTopic(String v) async => _set('kidsapp_parent_topic', v);

  bool get enablePush => _prefs.getBool('kidsapp_push') ?? true;
  Future<void> setEnablePush(bool v) async => _set('kidsapp_push', v);

  bool get enableSms => _prefs.getBool('kidsapp_sms') ?? true;
  Future<void> setEnableSms(bool v) async => _set('kidsapp_sms', v);

  bool get muteAlarms => _prefs.getBool('kidsapp_alarm_mute') ?? false;
  Future<void> setMuteAlarms(bool v) async => _set('kidsapp_alarm_mute', v);

  String get parentPhone => _prefs.getString('kidsapp_phone') ?? '';
  Future<void> setParentPhone(String v) async => _set('kidsapp_phone', v);

  /* --- Eltern-PIN --- */
  String get parentPin => _prefs.getString('kidsapp_parent_pin') ?? '';
  Future<void> setParentPin(String v) async => _set('kidsapp_parent_pin', v);

  /* --- Modi / Integration --- */
  String get speechMode => _prefs.getString('kidsapp_speech_mode') ?? 'hybrid';
  Future<void> setSpeechMode(String v) async => _set('kidsapp_speech_mode', v);

  String get imageMode => _prefs.getString('kidsapp_image_mode') ?? 'hybrid';
  Future<void> setImageMode(String v) async => _set('kidsapp_image_mode', v);

  double get insulinRatio => _prefs.getDouble('kidsapp_insulin_ratio') ?? 10.0;
  Future<void> setInsulinRatio(double v) async => _set('kidsapp_insulin_ratio', v);

  double get maxBolusUnits => _prefs.getDouble('kidsapp_max_bolus') ?? 10.0;
  Future<void> setMaxBolusUnits(double v) async => _set('kidsapp_max_bolus', v);

  /* --- Rate Limits --- */
  int get rateLimitNightscout => _prefs.getInt('kidsapp_rate_ns') ?? 30;
  Future<void> setRateLimitNightscout(int v) async => _set('kidsapp_rate_ns', v);

  int get rateLimitGpt => _prefs.getInt('kidsapp_rate_gpt') ?? 3;
  Future<void> setRateLimitGpt(int v) async => _set('kidsapp_rate_gpt', v);

  int get rateLimitSms => _prefs.getInt('kidsapp_rate_sms') ?? 20;
  Future<void> setRateLimitSms(int v) async => _set('kidsapp_rate_sms', v);

  int get rateLimitPush => _prefs.getInt('kidsapp_rate_push') ?? 5;
  Future<void> setRateLimitPush(int v) async => _set('kidsapp_rate_push', v);

  /* --- Gamification --- */
  int get pointsPerMeal => _prefs.getInt('kidsapp_pp_meal') ?? 10;
  Future<void> setPointsPerMeal(int v) async => _set('kidsapp_pp_meal', v);

  int get pointsPerSnack => _prefs.getInt('kidsapp_pp_snack') ?? 5;
  Future<void> setPointsPerSnack(int v) async => _set('kidsapp_pp_snack', v);

  int get bonusEverySnacks => _prefs.getInt('kidsapp_snack_bonus_every') ?? 5;
  Future<void> setBonusEverySnacks(int v) async => _set('kidsapp_snack_bonus_every', v);

  int get childPoints => _prefs.getInt('kidsapp_points') ?? 0;
  int get childLevel => _prefs.getInt('kidsapp_level') ?? 1;

  Future<void> addPoints(int delta) async {
    final newPoints = childPoints + delta;
    await _set('kidsapp_points', newPoints, silent: true);
    await _set('kidsapp_level', 1 + newPoints ~/ 100, silent: true);
    notifyListeners();
  }

  /* --- Health & Warnungen --- */
  int get carbWarnThreshold => _prefs.getInt('kidsapp_carb_warn') ?? 50;
  Future<void> setCarbWarnThreshold(int v) async => _set('kidsapp_carb_warn', v);

  /* --- Themes / Avatar --- */
  static const List<String> defaultThemes = ['unicorn', 'space', 'ocean'];
  List<String> get availableThemes => defaultThemes;

  String get childThemeKey => _prefs.getString('kidsapp_theme') ?? defaultThemes.first;
  Future<void> setChildTheme(String v) async => _set('kidsapp_theme', v);

  List<String> get unlockedGimmicks =>
      _prefs.getStringList('kidsapp_gimmicks') ?? <String>[];
  Future<void> unlockGimmick(String k) async =>
      _set('kidsapp_gimmicks', {...unlockedGimmicks, k}.toList());

  /* --- Remote Payload Handler --- */
  Future<void> applyRemotePayload(Map<String, dynamic> p) async {
    switch (p['type']) {
      case 'settings_update':
        await _applySettingsUpdate(p);
        break;
      case 'asset_upload':
        await _applyAssetUpload(p);
        break;
    }
  }

  Future<void> _applySettingsUpdate(Map<String, dynamic> p) async {
    final field = p['field'] as String;
    final value = p['value'];
    final map = {
      'nightscoutUrl': () => setNightscoutUrl(value),
      'nightscoutSecretSHA1': () => setNightscoutSecret(value),
      'gptEndpoint': () => setGptEndpoint(value),
      'gptApiKey': () => setGptApiKey(value),
      'whisperApiKey': () => setWhisperApiKey(value),
      'visionApiKey': () => setVisionApiKey(value),
      'speechMode': () => setSpeechMode(value),
      'imageMode': () => setImageMode(value),
      'enablePush': () => setEnablePush(value),
      'enableSms': () => setEnableSms(value),
      'muteAlarms': () => setMuteAlarms(value),
      'parentPhone': () => setParentPhone(value),
      'parentPin': () => setParentPin(value),
      'pointsPerMeal': () => setPointsPerMeal(value),
      'pointsPerSnack': () => setPointsPerSnack(value),
      'bonusEverySnacks': () => setBonusEverySnacks(value),
      'rateLimitNightscout': () => setRateLimitNightscout(value),
      'rateLimitGpt': () => setRateLimitGpt(value),
      'rateLimitSms': () => setRateLimitSms(value),
      'rateLimitPush': () => setRateLimitPush(value),
      'carbWarnThreshold': () => setCarbWarnThreshold(value),
      'childThemeKey': () => setChildTheme(value),
      'insulinRatio': () => setInsulinRatio(
          (value is num) ? value.toDouble() : double.parse(value)),
      'initialSetupDone': () => setInitialSetupDone(value),
      'pushEndpoint': () => setPushEndpoint(value),
      'parentTopic': () => setParentTopic(value),
      'maxBolusUnits': () => setMaxBolusUnits(
          (value is num) ? value.toDouble() : double.parse(value)),
    };
    if (map[field] != null) await map[field]!();
  }

  Future<void> _applyAssetUpload(Map<String, dynamic> p) async {
    final dir = await getApplicationDocumentsDirectory();
    final bytes = base64Decode(p['data']);
    final mime = p['mime'] as String;
    final path = '${dir.path}/assets/remote_${p['name']}.${mime.split('/').last}';
    await File(path).create(recursive: true);
    await File(path).writeAsBytes(bytes);
  }

  /* --- Set Helper --- */
  Future<void> _set(String key, Object value,
      {String? mirrorKey, bool silent = false}) async {
    if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else {
      await _prefs.setString(key, value.toString());
    }

    if (flavor == AppFlavor.plugin && mirrorKey != null) {
      try {
        await appCtx.aapsBridge.setPref(mirrorKey, value);
      } catch (_) {/* ignore */}
    }


    if (!silent) {
      eventBus.fire(SettingsChangedEvent(key: key, value: value));
      notifyListeners();
    }
  }
}
