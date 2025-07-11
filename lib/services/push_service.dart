// lib/services/push_service.dart
//
// v6 – FINAL BRIDGE INTEGRATED
// --------------------------------------------------------------
// Vereinheitlichter Push‑Dienst für Plugin, FCM und SMS.
// • Sendet über: AAPSBridge, FCM, SMS (Fallback)
// • Erkennt Payloads für Settings, Assets, Punkte
// • Nutzt GlobalRateLimiter (push)
// • Retry über CommunicationService bei Totalfehler
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:event_bus/event_bus.dart';

import 'fcm_service.dart';
import 'sms_service.dart';
import 'settings_service.dart';
import 'communication_service.dart';
import '../core/app_initializer.dart';
import '../services/aaps_bridge.dart';
import '../network/global_rate_limiter.dart';

class PushMessage {
  final String title;
  final String body;
  final Map<String, dynamic> data;

  const PushMessage({
    required this.title,
    required this.body,
    required this.data,
  });

  factory PushMessage.fromMap(Map<String, dynamic> map) => PushMessage(
    title: map['title'] ?? '',
    body: map['body'] ?? '',
    data: Map<String, dynamic>.from(map['data'] ?? {}),
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'data': data,
  };
}

class PushReceivedEvent {
  final PushMessage message;
  const PushReceivedEvent(this.message);
}

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  late EventBus _bus;
  StreamSubscription<PushMessage>? _fcmSub;
  StreamSubscription<PushMessage>? _smsSub;

  /// Initialisiert PushService, FCM, SMS, und bindet Bridge-Handler.
  Future<void> init(EventBus bus) async {
    _bus = bus;

    await FcmService.instance.init();
    _fcmSub = FcmService.instance.onMessage.listen(_process);

    await SmsService.instance.init();
    _smsSub = SmsService.instance.onJsonSms.listen(_process);

    // Plugin-Bridge-Listener
    const MethodChannel('kidsapp/push_bridge')
        .setMethodCallHandler(_onPushBridge);
    const MethodChannel('kidsapp/sms_bridge')
        .setMethodCallHandler(_onSmsBridge);
  }

  /// Sendet Nachricht über Plugin, FCM oder SMS. Queue als Fallback.
  Future<void> send(PushMessage msg) async {
    await GlobalRateLimiter.I.exec('push', () async {
      try {
        await appCtx.aapsBridge._channel.invokeMethod(
          'sendAapsNotification',
          msg.toMap(),
        );
        debugPrint('[PushService] Plugin‑Bridge erfolgreich');
        return;
      } catch (e) {
        debugPrint('[PushService] Plugin‑Bridge fehlgeschlagen – versuche FCM ($e)');
      }

      final fcmSuccess = await FcmService.instance.send(msg);
      if (fcmSuccess) {
        debugPrint('[PushService] FCM erfolgreich');
        return;
      }

      final smsSuccess = await SmsService.instance.sendJsonSms(msg);
      if (smsSuccess) {
        debugPrint('[PushService] SMS erfolgreich');
        return;
      }

      debugPrint('[PushService] ⚠️ Alle Kanäle fehlgeschlagen – Queue');
      await CommunicationService.I.enqueue({
        'title': msg.title,
        'body': msg.body,
        'payload': msg.data,
        'type': 'fallback_push',
      });
    });
  }

  void _process(PushMessage msg) {
    final type = msg.data['type'];
    if (type == 'settings_update' ||
        type == 'asset_upload' ||
        type == 'points_grant') {
      SettingsService.I.applyRemotePayload(msg.data);
    }
    _bus.fire(PushReceivedEvent(msg));
  }

  Future<void> _onPushBridge(MethodCall call) async {
    if (call.method == 'onAapsNotification') {
      _process(
          PushMessage.fromMap(Map<String, dynamic>.from(call.arguments)));
    }
  }

  Future<void> _onSmsBridge(MethodCall call) async {
    if (call.method == 'onJsonSms') {
      _process(
          PushMessage.fromMap(Map<String, dynamic>.from(call.arguments)));
    }
  }

  Future<void> dispose() async {
    await _fcmSub?.cancel();
    await _smsSub?.cancel();
    const MethodChannel('kidsapp/push_bridge').setMethodCallHandler(null);
    const MethodChannel('kidsapp/sms_bridge').setMethodCallHandler(null);
  }
}
