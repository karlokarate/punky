/*
 *  fcm_service.dart – v1
 *  --------------------------------------------------------------
 *  Kapselt FCM-Empfang und Versand (nur Android/iOS).
 *  Dient als Backend für push_service.dart und communication_service.dart.
 *  Empfängt Nachrichten, wandelt sie in PushMessage um.
 *
 *  © 2025 Kids Diabetes Companion – GPL-3.0-or-later
 */

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../services/push_service.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _ctr = StreamController<PushMessage>.broadcast();
  Stream<PushMessage> get onMessage => _ctr.stream;

  Future<void> init() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();

    FirebaseMessaging.onMessage.listen(_handleRemoteMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  void _handleRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final push = PushMessage(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      data: data,
    );
    _ctr.add(push);
  }

  Future<void> refreshToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('🔄 FCM refreshed token: $token');
  }

  Future<bool> send(PushMessage msg) async {
    // Placeholder: kein echtes FCM-Senden ohne Server-Key/API
    // Kann später durch eigene Serverweiterleitung ergänzt werden
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
  FcmService.instance.onMessage.drain(); // optionaler Reset
  FcmService.instance._ctr.add(push);
}
