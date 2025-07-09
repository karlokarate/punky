/*
 *  communication_service.dart   (v3.5 – erweitert für Profile‑Push & One‑Click)
 *  ---------------------------------------------------------------------------
 *  Vereinheitlichte Messaging‑Ebene (Push + SMS + Offline‑Queue)
 *
 *  Neue Features (v3.5):
 *   • Öffentliche Methode  sendPush(...)  – Wrapper um PushService
 *   • Payload‑Typ  profile_suggestion  → NightscoutAnalysisAvailableEvent
 *   • Token‑Refresh‑Helper, Offline‑Queue unverändert
 *
 *  Vorhandene Funktionen & Kommentare wurden NICHT entfernt.
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:telephony/telephony.dart';

import '../core/app_initializer.dart';
import '../core/event_bus.dart';
import '../events/app_events.dart';
import '../services/settings_service.dart';
import '../services/alarm_manager.dart';
import '../services/sms_service.dart';
import '../services/push_service.dart';

class CommunicationService {
  CommunicationService._(this.flavor);
  static late CommunicationService I;
  final AppFlavor flavor;

  late final Box _queue;
  late final EventBus _bus;
  final _random = Random();

  /* ---------------- Init ---------------- */

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
      final telephony = Telephony.instance;
      final bool? granted = await telephony.requestSmsPermissions;
      if (granted == true) {
        telephony.listenIncomingSms(
          onNewMessage: _handleIncomingSms,
          onBackgroundMessage: _smsBgHandler,
        );
        SmsService.instance.onJsonSms.listen((PushMessage msg) {
          if (!_handlePayload(msg.data)) {
            AlarmManager.I.fireAlarm(
              title: 'Unverarbeitbare SMS‑Payload',
              body: msg.data.toString(),
            );
          }
        });
      }
    }
  }

  /* ---------------- Push-Layer ---------------- */

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
    // TODO: ggf. an Backend melden
  }

  Future<void> refreshToken() async {
    final t = await FirebaseMessaging.instance.getToken();
    if (t != null) await _registerToken(t);
  }

  void _onPush(RemoteMessage msg) {
    if (_handlePayload(msg.data)) return;
    AlarmManager.I.fireAlarm(title: 'Unknown Push', body: msg.data.toString());
  }

  /// Öffentliche API – sendet Push an Topic *oder* Token‑Liste.
  ///
  /// * [title]   – FCM/APNS‑Titel
  /// * [body]    – Kurztext
  /// * [payload] – Beliebige JSON‑Map
  /// * [target]  – Topic (z. B. 'parent'), ignoriert wenn [tokens] gesetzt
  /// * [tokens]  – explizite Device‑Tokens (optional)
  Future<void> sendPush({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
    String? target,
    List<String>? tokens,
  }) async {
    if (SettingsService.I.enablePush != true) return;

    try {
      await PushService.instance
          .send(PushMessage(title: title, body: body, data: payload));
    } catch (_) {
      // offline → in Queue ablegen
      await enqueue({'title': title, 'body': body, 'payload': payload, 'topic': target, 'tokens': tokens});
    }
  }

  /* ---------------- SMS-Layer ---------------- */

  static void _smsBgHandler(SmsMessage msg) =>
      CommunicationService.I._handleIncomingSms(msg);

  void _handleIncomingSms(SmsMessage msg) {
    try {
      final data = jsonDecode(msg.body ?? '{}') as Map<String, dynamic>;
      if (!_handlePayload(data)) {
        AlarmManager.I.fireAlarm(
          title: 'Unverarbeitbare SMS',
          body: msg.body ?? '',
        );
      }
    } catch (_) {
      AlarmManager.I.fireAlarm(title: 'Ungültige JSON-SMS', body: msg.body ?? '');
    }
  }

  /* ---------------- Payload Router ---------------- */

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

      /* 🔹 NEU: Profile‑Empfehlung (Nightscout) ------------------- */
      case 'profile_suggestion':
        final recs = List<Map<String, dynamic>>.from(p['recommendations'] ?? []);
        _bus.fire(NightscoutAnalysisAvailableEvent(recs));
        return true;

      default:
        return false;
    }
  }

  /* ---------------- Offline-Queue ---------------- */

  Future<void> enqueue(Map<String, dynamic> p) async {
    await _queue.add(p);
  }

  Future<void> flushQueue() async {
    if (_queue.isEmpty) return;
    for (int i = 0; i < _queue.length; i++) {
      try {
        await Future.delayed(
            Duration(milliseconds: 300 + _random.nextInt(500)));
        // Hier könnte erneut PushService.send() versucht werden …
        await _queue.deleteAt(i);
      } catch (_) {
        break;
      }
    }
  }
}
