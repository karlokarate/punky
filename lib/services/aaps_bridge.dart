// lib/services/aaps_bridge.dart
//
// v6 – FINAL BRIDGE + PREF + SMS SUPPORT
// --------------------------------------------------------------
// Flutter‑zu‑AAPS‑Bridge mit vollständiger Plugin-Integration
// • Steuert AAPS über MethodChannel (getEntries, Treatments, Alarme, etc.)
// • Empfängt Live-Events via EventChannel (Loop, BG, Carb-Ack)
// • Unterstützt Plugin-spezifische Push, Pref-Sync und JSON-SMS-Kommandos
// • Eingesetzt in: NightscoutService, SettingsService, PushService, SmsService, AlarmManager
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:event_bus/event_bus.dart';
import '../events/loop_events.dart';
import 'push_service.dart'; // für PushMessage

class AAPSBridge {
  static const _channel = MethodChannel('punky/aaps_bridge');
  static const _eventChannel = EventChannel('punky/aaps_bridge/stream');

  AAPSBridge(this.bus) {
    _eventSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(_onEvent, onError: (e) {
      bus.fire(LoopWarningEvent('AAPS-Stream-Fehler: $e'));
    });
  }

  final EventBus bus;
  late final StreamSubscription<dynamic> _eventSubscription;

  Future<void> dispose() async {
    await _eventSubscription.cancel();
  }

  /* ───────────── Daten Senden ───────────── */

  Future<void> sendCarbEntry({
    required double carbs,
    required DateTime time,
    required String note,
  }) async {
    await _channel.invokeMethod('addCarbs', {
      'carbs': carbs,
      'timestamp': time.millisecondsSinceEpoch,
      'note': note,
    });
  }

  Future<void> uploadTreatment(Map<String, dynamic> payload) async {
    await _channel.invokeMethod('uploadTreatment', payload);
  }

  Future<bool> uploadProfilePatch(Map<String, dynamic> patch) async {
    return await _channel.invokeMethod('uploadProfilePatch', patch) ?? false;
  }

  Future<void> startTempTarget({
    required double lower,
    required double upper,
    required Duration duration,
  }) async {
    await _channel.invokeMethod('startTempTarget', {
      'lower': lower,
      'upper': upper,
      'durationMin': duration.inMinutes,
    });
  }

  Future<void> cancelTempTargets() async {
    await _channel.invokeMethod('cancelTempTargets');
  }

  Future<void> invokeAlarm({
    required String title,
    required String body,
    required String level,
    bool silent = false,
  }) async {
    await _channel.invokeMethod('fireAlarm', {
      'title': title,
      'body': body,
      'level': level,
      'silent': silent,
    });
  }

  Future<void> sendPushMessage(PushMessage msg) async {
    await _channel.invokeMethod('sendAapsNotification', msg.toMap());
  }

  Future<void> sendJsonSms(PushMessage msg) async {
    await _channel.invokeMethod('sendJsonSms', msg.toMap());
  }

  Future<void> setPref(String key, dynamic value) async {
    await _channel.invokeMethod('setPref', {
      'key': key,
      'value': value,
    });
  }
  Future<void> speak(String text) async {
    await _channel.invokeMethod('speak', {
      'text': text,
      'lang': 'de',
    });
  }

  /* ───────────── Daten Abfragen ───────────── */

  Future<double?> getInsulinRatio() async {
    final result = await _channel.invokeMethod('getInsulinRatio');
    if (result is num) return result.toDouble();
    return null;
  }

  Future<double?> getCurrentBG() async {
    final result = await _channel.invokeMethod('currentBG');
    if (result is num) return result.toDouble();
    return null;
  }

  Future<List<Map<String, dynamic>>> getEntries(int count) async {
    final result = await _channel.invokeMethod('getEntries', {'count': count});
    return List<Map<String, dynamic>>.from(result);
  }

  Future<List<Map<String, dynamic>>> getTreatments(int count) async {
    final result = await _channel.invokeMethod('getTreatments', {'count': count});
    return List<Map<String, dynamic>>.from(result);
  }

  Future<Map<String, dynamic>?> getDeviceStatus() async {
    final result = await _channel.invokeMethod('getDeviceStatus');
    return result != null ? Map<String, dynamic>.from(result) : null;
  }

  Future<bool> authorizeBolus() async {
    return await _channel.invokeMethod('authorizeBolus') ?? false;
  }

  /* ───────────── AAPS Events (z. B. BG, Loop, Carb-Ack) ───────────── */

  void _onEvent(dynamic raw) {
    if (raw is! Map<String, dynamic>) return;
    final type = raw['type'];
    try {
      switch (type) {
        case 'bg':
          final value = raw['value'];
          final slope = raw['slope'];
          final ts = raw['ts'];
          if (value is num && slope is num && ts is int) {
            bus.fire(BGUpdatedEvent(
              bg: value.toDouble(),
              slope: slope.toDouble(),
              timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
            ));
          }
          break;
        case 'loop':
          final bolus = raw['bolus'];
          final iob = raw['iob'];
          final cob = raw['cob'];
          final reason = raw['reason'];
          if (bolus is num &&
              iob is num &&
              cob is num &&
              reason is String) {
            bus.fire(LoopStatusEvent(
              recommendedBolus: bolus.toDouble(),
              iob: iob.toDouble(),
              cob: cob.toDouble(),
              reason: reason,
            ));
          }
          break;
        case 'carb_ack':
          final carbs = raw['carbs'];
          final tsAck = raw['ts'];
          if (carbs is num && tsAck is int) {
            bus.fire(CarbEntryAckEvent(
              carbs: carbs.toDouble(),
              timestamp: DateTime.fromMillisecondsSinceEpoch(tsAck),
            ));
          }
          break;
        default:
          break;
      }
    } catch (e) {
      bus.fire(LoopWarningEvent('Fehler bei Event‑Verarbeitung: $e'));
    }
  }
}
