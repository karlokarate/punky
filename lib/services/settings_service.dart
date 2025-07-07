/*
 *  settings_service.dart  (v6 – FINAL)
 *  --------------------------------------------------------------
 *  • Verwaltet sämtliche Preferences (siehe settings_schema.yaml)
 *  • Mirror​-Funktion für Nightscout​-Keys in AAPS​-Prefs (Plugin)
 *  • Remote​-Update​-Engine  applyRemotePayload()
 *  • Getter/Setter​-API   (typed)
 *
 *  © 2025 Kids Diabetes Companion – GPL​-3.0​-or​later
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_initializer.dart';

class SettingsService {
  /* ---------------- Singleton ---------------- */
  SettingsService._(this.flavor);
  static late SettingsService I;
  final AppFlavor flavor;
  late SharedPreferences _prefs;

  /* ---------------- Init ---------------- */
  static Future<void> init(AppFlavor flavor) async {
    I = SettingsService._(flavor);
    await I._load();
  }

  Future<void> _load() async => _prefs = await SharedPreferences.getInstance();

  /* ---------------- Nightscout ---------------- */

  String get nightscoutUrl =>
      _prefs.getString('kidsapp_ns_url') ?? 'https://example.herokuapp.com';
  Future<void> setNightscoutUrl(String v) async =>
      _set('kidsapp_ns_url', v, mirrorKey: 'nightscout_url');

  String get nightscoutSecretSHA1 =>
      _prefs.getString('kidsapp_ns_secret') ?? '';
  Future<void> setNightscoutSecret(String v) async =>
      _set('kidsapp_ns_secret', v, mirrorKey: 'api_secret');

  /* ---------------- API​-Keys ---------------- */

  String get gptApiKey => _prefs.getString('kidsapp_gpt_key') ?? '';
  Future<void> setGptApiKey(String v) async => _set('kidsapp_gpt_key', v);

  String get whisperApiKey => _prefs.getString('kidsapp_whisper_key') ?? '';
  Future<void> setWhisperApiKey(String v) async =>
      _set('kidsapp_whisper_key', v);

  String get visionApiKey => _prefs.getString('kidsapp_vision_key') ?? '';
  Future<void> setVisionApiKey(String v) async => _set('kidsapp_vision_key', v);

  /* ---------------- Betriebsmodi ---------------- */

  String get speechMode => _prefs.getString('kidsapp_speech_mode') ?? 'hybrid';
  Future<void> setSpeechMode(String v) async => _set('kidsapp_speech_mode', v);

  String get imageMode => _prefs.getString('kidsapp_image_mode') ?? 'hybrid';
  Future<void> setImageMode(String v) async => _set('kidsapp_image_mode', v);

  String get integrationMode => const String.fromEnvironment('INTEGRATION_MODE', defaultValue: 'sa');

  double get insulinRatio => _prefs.getDouble('kidsapp_insulin_ratio') ?? 10.0;
  Future<void> setInsulinRatio(double v) async => _set('kidsapp_insulin_ratio', v);

  /* ---------------- Benachrichtigungen ---------------- */

  bool get enablePush => _prefs.getBool('kidsapp_push') ?? true;
  Future<void> setEnablePush(bool v) async => _set('kidsapp_push', v);

  bool get enableSms => _prefs.getBool('kidsapp_sms') ?? true;
  Future<void> setEnableSms(bool v) async => _set('kidsapp_sms', v);

  bool get muteAlarms => _prefs.getBool('kidsapp_alarm_mute') ?? false;
  Future<void> setMuteAlarms(bool v) async => _set('kidsapp_alarm_mute', v);

  String get parentPhone => _prefs.getString('kidsapp_phone') ?? '';
  Future<void> setParentPhone(String v) async => _set('kidsapp_phone', v);

  /* ---------------- Gamification ---------------- */

  int get pointsPerMeal => _prefs.getInt('kidsapp_pp_meal') ?? 10;
  Future<void> setPointsPerMeal(int v) async => _set('kidsapp_pp_meal', v);

  int get pointsPerSnack => _prefs.getInt('kidsapp_pp_snack') ?? 5;
  Future<void> setPointsPerSnack(int v) async => _set('kidsapp_pp_snack', v);

  int get bonusEverySnacks => _prefs.getInt('kidsapp_snack_bonus_every') ?? 5;
  Future<void> setBonusEverySnacks(int v) async =>
      _set('kidsapp_snack_bonus_every', v);

  int get childPoints => _prefs.getInt('kidsapp_points') ?? 0;
  int get childLevel => _prefs.getInt('kidsapp_level') ?? 1;
  Future<void> addPoints(int delta) async =>
      _set('kidsapp_points', childPoints + delta, silent: true)
          .then((_) => _set('kidsapp_level', 1 + (childPoints + delta) ~/ 100,
          silent: true));

  /* ---------------- Health ---------------- */

  int get carbWarnThreshold => _prefs.getInt('kidsapp_carb_warn') ?? 50;
  Future<void> setCarbWarnThreshold(int v) async =>
      _set('kidsapp_carb_warn', v);

  /* ---------------- Avatar ---------------- */

  static const List<String> defaultThemes = ['unicorn', 'space', 'ocean'];
  List<String> get availableThemes => defaultThemes; // simplifiziert

  String get childThemeKey =>
      _prefs.getString('kidsapp_theme') ?? defaultThemes.first;
  Future<void> setChildTheme(String v) async => _set('kidsapp_theme', v);

  List<String> get unlockedGimmicks =>
      _prefs.getStringList('kidsapp_gimmicks') ?? <String>[];
  Future<void> unlockGimmick(String k) async =>
      _set('kidsapp_gimmicks', {...unlockedGimmicks, k}.toList());

  /* *********************************************************************
   *  Remote​-Update / Asset​-Upload
   * *********************************************************************/

  Future<void> applyRemotePayload(Map<String, dynamic> p) async {
    switch (p['type']) {
      case 'settings_update':
        await _applySettingsUpdate(p);
        break;
      case 'asset_upload':
        await _applyAssetUpload(p);
        break;
      default:
    }
  }

  Future<void> _applySettingsUpdate(Map<String, dynamic> p) async {
    final field = p['field'] as String;
    final value = p['value'];
    final map = {
      'nightscoutUrl': () => setNightscoutUrl(value),
      'nightscoutSecretSHA1': () => setNightscoutSecret(value),
      'gptApiKey': () => setGptApiKey(value),
      'whisperApiKey': () => setWhisperApiKey(value),
      'visionApiKey': () => setVisionApiKey(value),
      'speechMode': () => setSpeechMode(value),
      'imageMode': () => setImageMode(value),
      'enablePush': () => setEnablePush(value),
      'enableSms': () => setEnableSms(value),
      'muteAlarms': () => setMuteAlarms(value),
      'parentPhone': () => setParentPhone(value),
      'pointsPerMeal': () => setPointsPerMeal(value),
      'pointsPerSnack': () => setPointsPerSnack(value),
      'bonusEverySnacks': () => setBonusEverySnacks(value),
      'carbWarnThreshold': () => setCarbWarnThreshold(value),
      'childThemeKey': () => setChildTheme(value),
      'insulinRatio': () => setInsulinRatio(value.toDouble()),
    };
    if (map[field] != null) await map[field]!();
  }

  Future<void> _applyAssetUpload(Map<String, dynamic> p) async {
    final dir = await getApplicationDocumentsDirectory();
    final bytes = base64Decode(p['data']);
    final mime = p['mime'] as String;
    final path =
        '${dir.path}/assets/remote_${p['name']}.${mime.split('/').last}';
    await File(path).create(recursive: true);
    await File(path).writeAsBytes(bytes);
    // Unlock handled in AvatarService after load
  }

  /* *********************************************************************
   *  Helpers
   * *********************************************************************/

  static const MethodChannel _prefBridge =
  MethodChannel('kidsapp/settings_bridge');

  Future<void> _set(String key, Object value,
      {String? mirrorKey, bool silent = false}) async {
    if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else {
      await _prefs.setString(key, value.toString());
    }
    if (flavor == AppFlavor.plugin && mirrorKey != null) {
      try {
        await _prefBridge
            .invokeMethod('setPref', {'key': mirrorKey, 'value': value});
      } catch (_) {/* ignore */}
    }
    if (!silent) _notifySettingsChanged();
  }

  void _notifySettingsChanged() {
    // Broadcast über EventBus falls nötig
  }
}
