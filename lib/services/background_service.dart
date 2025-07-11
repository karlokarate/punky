// lib/services/background_service.dart
//
// v7 – FINAL mit AAPSBridge-Unterstützung
// --------------------------------------------------------------
// Plattform-unabhängiger Background-Scheduler.
// • Android → WorkManager   • iOS → BGTaskScheduler
// • Tasks:
//     1. LoopStatusRefresh (IOB/COB)
//     2. Push-Token-Sync
//     3. Upload Offline-Queue
// • EventBus feuert LoopStatusUpdatedEvent
// • Plugin-Modus nutzt AAPSBridge statt REST-Nightscout
//
// © 2025 Kids Diabetes Companion – GPL-3.0-or-later

import 'dart:async';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/app_context.dart';
import '../core/app_flavor.dart';
import '../core/event_bus.dart';
import '../events/app_events.dart';
import '../services/nightscout_service.dart';
import '../services/communication_service.dart';
import '../services/settings_service.dart';
import '../services/aaps_bridge.dart';

class LoopStatusUpdatedEvent extends AppEvent {
  final double iob;
  final double cob;
  LoopStatusUpdatedEvent(this.iob, this.cob);

  @override
  Map<String, dynamic> toJson() => {'iob': iob, 'cob': cob};
}

class BackgroundService {
  BackgroundService._(this.flavor);
  static late BackgroundService I;
  final AppFlavor flavor;

  static const MethodChannel _bgCh =
  MethodChannel('kidsapp/background_tasks');

  late final EventBus _bus;

  static Future<void> init(AppFlavor flavor) async {
    I = BackgroundService._(flavor);
    await I._setup();
  }

  Future<void> _setup() async {
    _bus = AppEventBus.I.bus;

    if (flavor == AppFlavor.plugin) {
      _registerAapsBridgeListener();
    } else {
      _schedulePlatformTasks();
    }
  }

  /* ─────────────────────────   Stand‑alone   ───────────────────────── */

  Future<void> _schedulePlatformTasks() async {
    try {
      await _bgCh.invokeMethod('registerTasks');
    } catch (_) {
      debugPrint('Background‑Task registration failed');
    }

    _bgCh.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'runTask':
          final String taskId = call.arguments as String;
          await _runTask(taskId);
          break;
      }
    });
  }

  Future<void> _runTask(String id) async {
    switch (id) {
      case 'loop_refresh':
        await _refreshLoop();
        break;
      case 'push_token':
        await CommunicationService.I.refreshToken();
        break;
      case 'upload_queue':
        await CommunicationService.I.flushQueue();
        break;
    }
  }

  /* ─────────────────────────   Plugin‑Modus   ──────────────────────── */

  void _registerAapsBridgeListener() {
    // EventChannel in AAPSBridge übernimmt schon das Live-Listening
    // → kein zusätzlicher Listener nötig
  }

  /* ─────────────────────────   Core‑Job   ─────────────────────────── */

  Future<void> _refreshLoop() async {
    if (flavor == AppFlavor.plugin) {
      // Werte direkt via AAPSBridge holen (aktuellster Stand)
      final bridge = appCtx.aapsBridge;
      final bg = await bridge.getCurrentBG();
      // IOB/COB sind bei plugin-mode nicht direkt abrufbar – kommen per Event
      debugPrint('[BG] Aktueller BZ laut AAPSBridge: $bg');
      // kein bus.fire – erfolgt automatisch durch AAPSBridge
    } else {
      // Nightscout REST-Fallback
      final ns = NightscoutService.instance;
      final status = await ns.fetchDeviceStatus();
      if (status != null) {
        final iob = status.iob ?? 0.0;
        final cob = status.cob ?? 0.0;
        _bus.fire(LoopStatusUpdatedEvent(iob, cob));
      }
    }
  }
}
