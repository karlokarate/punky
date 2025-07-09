/*
 *  push_service.dart – v5 (mit Retry + Logging)
 *  --------------------------------------------------------------
 *  Vereinheitlichter Push​-Dienst für FCM + SMS + PluginBridge.
 *  • Erkennt spezielle Payload-Typen (settings_update, asset_upload, points_grant)
 *  • Sendet fallback​-fähig via native Bridge, FCM oder SMS
 *  • Verwendet GlobalRateLimiter ('push') für alle Sendeaktionen
 *  • Ergänzt um: Logging + Retry-Fallback (Queue)
 *
 *  © 2025 Kids Diabetes Companion – GPL​-3.0​-or​later
 */

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:event_bus/event_bus.dart';

import 'fcm_service.dart';
import 'sms_service.dart';
import 'settings_service.dart';
import 'communication_service.dart';
import '../network/global_rate_limiter.dart';

/// Datenmodell für eine Push-Nachricht.
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

/// Event, das bei Empfang einer Push-Nachricht ausgelöst wird.
class PushReceivedEvent {
  final PushMessage message;
  const PushReceivedEvent(this.message);
}

/// Singleton-Dienst für das Senden und Empfangen von Push-Nachrichten.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  static const MethodChannel _pushBridge = MethodChannel('kidsapp/push_bridge');
  static const MethodChannel _smsBridge = MethodChannel('kidsapp/sms_bridge');

  late EventBus _bus;
  StreamSubscription<PushMessage>? _fcmSub;
  StreamSubscription<PushMessage>? _smsSub;

  /// Initialisiert den PushService mit EventBus.
  Future<void> init(EventBus bus) async {
    _bus = bus;

    await FcmService.instance.init();
    _fcmSub = FcmService.instance.onMessage.listen(_process);

    await SmsService.instance.init();
    _smsSub = SmsService.instance.onJsonSms.listen(_process);

    _pushBridge.setMethodCallHandler(_onPushBridge);
    _smsBridge.setMethodCallHandler(_onSmsBridge);
  }

  /// Versendet eine Nachricht via Plugin, FCM oder SMS – gesteuert durch GlobalRateLimiter.
  /// Falls alle Wege fehlschlagen, landet sie in der Offline‑Queue (siehe CommunicationService).
  Future<void> send(PushMessage msg) async {
    await GlobalRateLimiter.I.exec('push', () async {
      try {
        await _pushBridge.invokeMethod('sendAapsNotification', msg.toMap());
        debugPrint('[PushService] Plugin‑Bridge erfolgreich');
        return;
      } catch (e) {
        debugPrint('[PushService] Plugin‑Bridge fehlgeschlagen – versuche FCM ($e)');
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

      debugPrint('[PushService] ⚠️ Alle Kanäle fehlgeschlagen – Nachricht geht in die Queue');
      await CommunicationService.I.enqueue({
        'title': msg.title,
        'body': msg.body,
        'payload': msg.data,
        'type': 'fallback_push'
      });
    });
  }

  /// Verarbeitet eingehende Nachrichten und feuert Events.
  void _process(PushMessage msg) {
    final type = msg.data['type'];
    if (type == 'settings_update' ||
        type == 'asset_upload' ||
        type == 'points_grant') {
      SettingsService.I.applyRemotePayload(msg.data);
    }
    _bus.fire(PushReceivedEvent(msg));
  }

  /// Interner Handler für native Plugin-Push-Bridge.
  Future<void> _onPushBridge(MethodCall call) async {
    if (call.method == 'onAapsNotification') {
      _process(PushMessage.fromMap(Map<String, dynamic>.from(call.arguments)));
    }
  }

  /// Interner Handler für native Plugin-SMS-Bridge.
  Future<void> _onSmsBridge(MethodCall call) async {
    if (call.method == 'onJsonSms') {
      _process(PushMessage.fromMap(Map<String, dynamic>.from(call.arguments)));
    }
  }

  /// Gibt Ressourcen (Subscriptions) frei.
  Future<void> dispose() async {
    await _fcmSub?.cancel();
    await _smsSub?.cancel();
    _pushBridge.setMethodCallHandler(null);
    _smsBridge.setMethodCallHandler(null);
  }
}
