// lib/services/communication_service.dart
//
// v4.2 – BRIDGE READY
// ---------------------------------------------------------------------------
// Vereinheitlichte Messaging‑Ebene (Push + SMS + Offline‑Queue)
// • sendPush(...) mit Retry, Offline-Queue, Rate Limiter
// • SMS-Handler mit JSON-Payload-Router
// • Android 13+: Permission-Check für SMS
// • Plugin-kompatibel: Alarme via AAPSBridge (invokeAlarm)
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/app_context.dart';
import '../core/app_flavor.dart';
import '../core/event_bus.dart';
import '../events/app_events.dart';
import '../services/settings_service.dart';
import '../services/alarm_manager.dart';
import '../services/sms_service.dart';
import '../services/push_service.dart';
import '../services/aaps_bridge.dart';
import '../network/global_rate_limiter.dart';

class CommunicationService {
  CommunicationService._(this.flavor);
  static late CommunicationService I;
  final AppFlavor flavor;

  late final Box _queue;
  late final EventBus _bus;
  final _random = Random();

  static Future<void> init(AppFlavor flavor) async {
    I = CommunicationService._(flavor);
    await I._setup();
  }

  Future<void> _setup() async {
    _bus = AppEventBus.I.bus;
    _queue = await Hive.openBox('push_queue');

    if (SettingsService.I.enablePush == true) {
      await _initPush();
    }

    if (SettingsService.I.enableSms && flavor != AppFlavor.plugin) {
      final granted = await _checkAndRequestSmsPermission();
      if (!granted) {
        debugPrint('❌ SMS-Permission verweigert – kein Listener aktiv');
        return;
      }

      final telephony = Telephony.instance;
      telephony.listenIncomingSms(
        onNewMessage: _handleIncomingSms,
        onBackgroundMessage: _smsBgHandler,
      );

      SmsService.instance.onJsonSms.listen((PushMessage msg) {
        if (!_handlePayload(msg.data)) {
          _raiseAlarm('Unverarbeitbare SMS‑Payload', msg.data.toString());
        }
      });
    }
  }

  Future<bool> _checkAndRequestSmsPermission() async {
    final status = await Permission.sms.status;
    if (status.isGranted) return true;
    final result = await Permission.sms.request();
    return result.isGranted;
  }

  Future<void> _initPush() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
    final token = await fcm.getToken();
    if (token != null) await _registerToken(token);

    FirebaseMessaging.onMessage.listen(_onPush);
    FirebaseMessaging.instance.onTokenRefresh.listen((t) => _registerToken(t));
  }

  Future<void> _registerToken(String t) async {
    debugPrint('FCM Token registered: $t');
    // TODO: ggf. an eigenes Backend melden
  }

  Future<void> refreshToken() async {
    final t = await FirebaseMessaging.instance.getToken();
    if (t != null) await _registerToken(t);
  }

  void _onPush(RemoteMessage msg) {
    if (_handlePayload(msg.data)) return;
    _raiseAlarm('Unknown Push', msg.data.toString());
  }

  Future<void> sendPush({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
    String? target,
    List<String>? tokens,
  }) async {
    if (SettingsService.I.enablePush != true) return;

    try {
      await GlobalRateLimiter.I.exec('push', () async {
        await PushService.instance.send(
          PushMessage(title: title, body: body, data: payload),
        );
      });
    } catch (_) {
      await enqueue({
        'title': title,
        'body': body,
        'payload': payload,
        'topic': target,
        'tokens': tokens,
      });
    }
  }

  static void _smsBgHandler(SmsMessage msg) =>
      CommunicationService.I._handleIncomingSms(msg);

  void _handleIncomingSms(SmsMessage msg) {
    try {
      final data = jsonDecode(msg.body ?? '{}') as Map<String, dynamic>;
      if (!_handlePayload(data)) {
        _raiseAlarm('Unverarbeitbare SMS', msg.body ?? '');
      }
    } catch (_) {
      _raiseAlarm('Ungültige JSON-SMS', msg.body ?? '');
    }
  }

  bool _handlePayload(Map<String, dynamic> p) {
    switch (p['type']) {
      case 'settings_update':
      case 'asset_upload':
        SettingsService.I.applyRemotePayload(p);
        return true;

      case 'points_grant':
        _bus.fire(PointsChangedEvent(
          (p['delta'] as num?)?.toInt() ?? 0 + SettingsService.I.childPoints,
        ));
        return true;

      case 'profile_suggestion':
        final recs = List<Map<String, dynamic>>.from(p['recommendations'] ?? []);
        _bus.fire(NightscoutAnalysisAvailableEvent(recs));
        return true;

      default:
        return false;
    }
  }

  Future<void> enqueue(Map<String, dynamic> p) async {
    await _queue.add(p);
  }

  Future<void> flushQueue() async {
    if (_queue.isEmpty) return;
    final failed = <int>[];
    for (int i = 0; i < _queue.length; i++) {
      final p = Map<String, dynamic>.from(_queue.getAt(i));
      try {
        await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(500)));
        await GlobalRateLimiter.I.exec('push', () async {
          await PushService.instance.send(
            PushMessage(
              title: p['title'],
              body: p['body'],
              data: Map<String, dynamic>.from(p['payload']),
            ),
          );
        });
        await _queue.deleteAt(i);
      } catch (_) {
        failed.add(i);
      }
    }
  }

  /* ───────────────────────────────
   * Plugin: native Alarm via Bridge
   * ─────────────────────────────── */
  void _raiseAlarm(String title, String body) async {
    try {
      if (flavor == AppFlavor.plugin) {
        await appCtx.aapsBridge.invokeAlarm(
          title: title,
          body: body,
          level: 'normal',
          silent: false,
        );
      } else {
        await AlarmManager.I.fireAlarm(
          title: title,
          body: body,
          level: AlarmLevel.normal,
        );
      }
    } catch (_) {
      debugPrint('⚠️ Alarmfehler: $title');
    }
  }
}
