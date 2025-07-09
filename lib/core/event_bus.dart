/*
 *  event_bus.dart   (v3 – mit get stream & Map-Fix)
 *  --------------------------------------------------------------
 *  Einziger Einstiegspunkt für den globalen EventBus.
 *
 *  • Standalone  : reiner dart:event_bus
 *  • Plugin      : zusätzlich Bridge zu AAPS per Plattform‑Channel
 *                    – Empfängt JSON‑Events aus AAPS (EventChannel)
 *                    – Sendet eigene Events an AAPS (MethodChannel)
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'dart:async';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/services.dart';

import '../core/app_initializer.dart';
import '../events/app_events.dart';

class AppEventBus {
  AppEventBus._(this.bus);
  final EventBus bus;

  static late AppEventBus I;

  static const _rx = EventChannel('kidsapp/aaps_events');
  static const _tx = MethodChannel('kidsapp/aaps_send');

  /// Initialisierung in AppInitializer.init()
  static Future<void> init(AppFlavor flavor) async {
    final bus = EventBus();
    I = AppEventBus._(bus);

    if (flavor == AppFlavor.plugin) {
      // Native → Dart
      _rx.receiveBroadcastStream().listen(_onNative);

      // Dart → Native
      bus.on<AppEvent>().listen(_onDart);
    }
  }

  /* ────────────────────────────────────────────────── */

  static void _onNative(dynamic msg) {
    // Erwartet {type:"ClassName", payload:{…}}
    if (msg is Map && msg['type'] is String) {
      final type = msg['type'] as String;
      final raw = msg['payload'];
      final Map<String, dynamic> payload = (raw is Map)
          ? Map<String, dynamic>.from(raw.map((k, v) => MapEntry(k.toString(), v)))
          : {};
      final evt = AppEventFactory.fromNative(type, payload);
      I.bus.fire(evt);
    }
  }

  static void _onDart(AppEvent e) async {
    try {
      await _tx.invokeMethod('sendEvent',
          {'type': e.runtimeType.toString(), 'payload': e.toJson()});
    } catch (_) {/* Ignorieren */}
  }

  /// Globale Event‑Bridge
  Stream<dynamic> get stream => bus.on();
}
EventBus get eventBus => AppEventBus.I.bus;