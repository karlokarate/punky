/*
 *  push_service.dart – v3
 *  --------------------------------------------------------------
 *  Vereinheitlichter Push​-Dienst für FCM + SMS + PluginBridge.
 *  • Erkennt spezielle Payload-Typen (settings_update, asset_upload, points_grant)
 *  • Sendet fallback​-fähig via native Bridge, FCM oder SMS
 *  • JSON-kompatibel, gleiches Schema für alle Kanäle
 *
 *  © 2025 Kids Diabetes Companion – GPL​-3.0​-or​later
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:event_bus/event_bus.dart';

import '../app_initializer.dart';
import 'fcm_service.dart';
import 'sms_service.dart';
import 'settings_service.dart';

/* ---------------- JSON​-Schema (Beispiele) ----------------

1) Settings-Update
{
  "type": "settings_update",
  "field": "gptApiKey",
  "value": "sk-…"
}

2) Asset-Upload
{
  "type": "asset_upload",
  "assetType": "avatarItem",
  "name": "sunglasses",
  "mime": "image/png",
  "data": "<BASE64_DATA>"
}

3) Punkte-Gutschrift
{
  "type": "points_grant",
  "delta": 50
}
-----------------------------------------------------------*/

class PushMessage {
  final String title;
  final String body;
  final Map<String, dynamic> data;
  const PushMessage({required this.title, required this.body, required this.data});

  factory PushMessage.fromMap(Map<String, dynamic> map) =>
      PushMessage(
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

  static const MethodChannel _pushBridge =
  MethodChannel('kidsapp/push_bridge');
  static const MethodChannel _smsBridge =
  MethodChannel('kidsapp/sms_bridge');

  late EventBus _bus;
  StreamSubscription<PushMessage>? _fcmSub;
  StreamSubscription<PushMessage>? _smsSub;

  Future<void> init(EventBus bus) async {
    _bus = bus;

    await FcmService.instance.init();
    _fcmSub = FcmService.instance.onMessage.listen(_process);

    await SmsService.instance.init();
    _smsSub = SmsService.instance.onJsonSms.listen(_process);

    _pushBridge.setMethodCallHandler(_onPushBridge);
    _smsBridge.setMethodCallHandler(_onSmsBridge);
  }

  /* ---------------- Senden ---------------- */

  Future<void> send(PushMessage msg) async {
    try {
      await _pushBridge.invokeMethod('sendAapsNotification', msg.toMap());
      return;
    } catch (_) {/* fallback */}

    if (await FcmService.instance.send(msg)) return;
    await SmsService.instance.sendJsonSms(msg);
  }

  /* ---------------- Empfang & Verarbeitung ---------------- */

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
      _process(PushMessage.fromMap(Map<String, dynamic>.from(call.arguments)));
    }
  }

  Future<void> _onSmsBridge(MethodCall call) async {
    if (call.method == 'onJsonSms') {
      _process(PushMessage.fromMap(Map<String, dynamic>.from(call.arguments)));
    }
  }

  Future<void> dispose() async {
    await _fcmSub?.cancel();
    await _smsSub?.cancel();
    _pushBridge.setMethodCallHandler(null);
    _smsBridge.setMethodCallHandler(null);
  }
}
