// lib/services/aaps_bridge.dart
//
// v4 – FINAL SEND PUSH SUPPORT
// --------------------------------------------------------------
// Flutter‑zu‑AAPS-Bridge mit vollständiger Push- und Event-Integration
// • sendCarbEntry, getInsulinRatio, getCurrentBG, invokeAlarm
// • NEU: sendPushMessage(PushMessage)
// • EventChannel-Forwarding: bg, loop, carb_ack
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'dart:async';
import 'package:flutter/services.dart';
import '../core/event_bus.dart';
import '../core/events/loop_events.dart';
import '../core/events/carb_events.dart';
import '../core/events/bg_events.dart';
import 'push_service.dart'; // für PushMessage

class AAPSBridge {
  static const _channel = MethodChannel('punky/aaps_bridge');
  static const _eventChannel = EventChannel('punky/aaps_bridge/stream');

  AAPSBridge(this.bus) {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(_onEvent);
  }

  final EventBus bus;
  late final StreamSubscription<dynamic> _eventSubscription;

  /* ──────────────────────────────────────────
   * Öffentliche Aufrufe
   * ────────────────────────────────────────── */


  Future<void> sendCarbEntry({
    required double carbs,
    required DateTime time,
    required String note,
  }) async {
    await channel.invokeMethod('sendCarbEntry', {
      'carbs': carbs,
      'time': time.toIso8601String(),
    await _channel.invokeMethod('addCarbs', {
      'carbs': carbs,
      'timestamp': time.millisecondsSinceEpoch,
      'note': note,
    });
  }


  Future<double?> getInsulinRatio() async {
    final ratio = await channel.invokeMethod<double>('getInsulinRatio');
    return ratio;
  }

  Future<double?> getCurrentBG() async {
    final result = await _channel.invokeMethod('currentBG');
    if (result is double) return result;
    return null;
  }

  Future<double?> getInsulinRatio() async {
    final result = await _channel.invokeMethod('getInsulinRatio');
    if (result is double) return result;
    if (result is int) return result.toDouble();
    return null;
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

  Future<void> cancelTempTargets() =>
      _channel.invokeMethod('cancelTempTargets');

  Future<void> invokeAlarm({
    required String title,
    required String body,
    required String level,
    bool silent = false,
  }) async {
    await channel.invokeMethod('invokeAlarm', {
    required bool silent,
  }) async {
    await _channel.invokeMethod('fireAlarm', {
      'title': title,
      'body': body,
      'level': level,
      'silent': silent,
    });
  }

  /// NEU: Sendet strukturierte PushMessage über Plugin‑Bridge
  Future<void> sendPushMessage(PushMessage msg) async {
    await _channel.invokeMethod('sendAapsNotification', msg.toMap());
  }

  /* ──────────────────────────────────────────
   * Event‑Weiterleitung
   * ────────────────────────────────────────── */

  void _onEvent(dynamic raw) {
    if (raw is Map) {
      switch (raw['type']) {
        case 'bg':
          bus.fire(BGUpdatedEvent(
            bg: raw['value'] as double,
            slope: raw['slope'] as double,
            timestamp: DateTime.fromMillisecondsSinceEpoch(raw['ts'] as int),
          ));
          break;
        case 'loop':
          bus.fire(LoopStatusEvent(
            recommendedBolus: raw['bolus'] as double,
            iob: raw['iob'] as double,
            cob: raw['cob'] as double,
            reason: raw['reason'] as String,
          ));
          break;
        case 'carb_ack':
          bus.fire(CarbEntryAckEvent(
            carbs: raw['carbs'] as double,
            timestamp: DateTime.fromMillisecondsSinceEpoch(raw['ts'] as int),
          ));
          break;
        default:
          break;
      }
    }
  }

  Future<void> dispose() async {
    await _eventSubscription.cancel();
  }
}