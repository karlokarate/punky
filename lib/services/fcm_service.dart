// lib/services/fcm_service.dart
//
// v2 – FINAL BRIDGE READY
// --------------------------------------------------------------
// Kapselt FCM-Empfang und Versand (Android/iOS only)
// • Empfang: onMessage / Background
// • Versand: optional über Bridge bei Plugin-Modus
// • Kompatibel mit PushService, CommunicationService
//
// © 2025 Kids Diabetes Companion – GPL-3.0-or-later

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/app_flavor.dart';
import '../services/push_service.dart';
import '../core/global.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _ctr = StreamController<PushMessage>.broadcast();
  Stream<PushMessage> get onMessage => _ctr.stream;

  /// Initialisiert FCM-Empfang (foreground & background).
  Future<void> init() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();

    FirebaseMessaging.onMessage.listen(_handleRemoteMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  /// Verarbeitet eingehende RemoteMessage (z. B. von Firebase).
  void _handleRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final push = PushMessage(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      data: data,
    );
    _ctr.add(push);
  }

  /// Erneuert und logged FCM-Token.
  Future<void> refreshToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('🔄 FCM refreshed token: $token');
  }

  /// Sendet Nachricht (wenn Plugin aktiv → Bridge, sonst false).
  Future<bool> send(PushMessage msg) async {
    if (appCtx.flavor == AppFlavor.plugin) {
      try {
        await appCtx.aapsBridge.sendPushMessage(msg);
        debugPrint('[FcmService] Push über Bridge gesendet');
        return true;
      } catch (e) {
        debugPrint('[FcmService] ⚠️ Bridge-Senden fehlgeschlagen: $e');
        return false;
      }
    }

    // Kein echter Versand im Standalone – müsste über Backend erfolgen
    debugPrint('[FcmService] Kein FCM-Senden im Standalone-Modus implementiert');
    return false;
  }
}

/// Hintergrundempfang (nur Android)
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  final data = message.data;
  final push = PushMessage(
    title: message.notification?.title ?? '',
    body: message.notification?.body ?? '',
    data: data,
  );
  FcmService.instance._ctr.add(push);
}
