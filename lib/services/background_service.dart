/*
 *  background_service.dart  (v6 – FINAL)
 *  --------------------------------------------------------------
 *  Plattform‑unabhängiger Background‑Scheduler.
 *  • Android → WorkManager   • iOS → BGTaskScheduler
 *  • Tasks:
 *      1. Nightscout‑LoopStatus Refresh (IOB/COB)
 *      2. Push‑Token‑Sync  (FCM  / APNS)
 *      3. Upload Offline‑Queue  (CommunicationService)
 *  • EventBus‑Broadcast  LoopStatusUpdatedEvent
 *  • Plugin‑Modus: nutzt AAPS‑ContentProvider statt REST‑NS
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'dart:async';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/app_initializer.dart';
import '../core/event_bus.dart';
import '../events/app_events.dart';
import '../services/nightscout_service.dart';
import '../services/communication_service.dart';
import '../services/settings_service.dart';
import '../services/nightscout_models.dart';

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
      _registerAapsListeners();
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

  void _registerAapsListeners() {
    // nichts erforderlich – AAPS liefert LoopStatus via ContentObserver
  }

  /* ─────────────────────────   Core‑Job   ─────────────────────────── */

  Future<void> _refreshLoop() async {
    final ns = NightscoutService.instance;
    final status = await ns.fetchDeviceStatus();
    if (status != null) {
      final iob = status.iob ?? 0.0;
      final cob = status.cob ?? 0.0;
      _bus.fire(LoopStatusUpdatedEvent(iob, cob));
    }
  }
}
