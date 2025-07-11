// lib/services/sms_service.dart
//
// v5 – FINAL BRIDGE READY
// --------------------------------------------------------------
// JSON‑SMS‑Bridge für strukturierte Nachrichten
// • Empfang via Plugin‑Bridge oder Multipart
// • Versand mit Rückgabewert (bool)
// • Kompatibel mit PushMessage (über Fallback nutzbar)
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../core/app_initializer.dart';
import '../services/push_service.dart';

class SmsService {
  SmsService._();
  static final SmsService instance = SmsService._();

  final Map<String, _MultipartBuffer> _buffers = {};
  final _ctr = StreamController<PushMessage>.broadcast();
  Stream<PushMessage> get onJsonSms => _ctr.stream;

  static const MethodChannel _bridge = MethodChannel('kidsapp/sms_bridge');

  /// Initialisiert Handler für eingehende SMS-Nachrichten (Bridge).
  Future<void> init() async {
    _bridge.setMethodCallHandler(_onSmsBridge);
    debugPrint('[SmsService] initialisiert');
  }

  /// Sendet strukturierte JSON-SMS via Plugin-Brücke.
  Future<bool> sendJsonSms(PushMessage msg) async {
    try {
      await appCtx.aapsBridge._channel.invokeMethod('sendJsonSms', msg.toMap());
      debugPrint('[SmsService] SMS erfolgreich gesendet');
      return true;
    } catch (e) {
      debugPrint('[SmsService] ⚠️ SMS-Versand fehlgeschlagen: $e');
      return false;
    }
  }

  /* ───────────────────────────── Empfang ───────────────────────────── */

  Future<void> _onSmsBridge(MethodCall call) async {
    switch (call.method) {
      case 'onJsonSmsPart':
        final map = Map<String, dynamic>.from(call.arguments);
        final id = map['id'];
        final part = map['part'] as int;
        final total = map['total'] as int;
        final data = map['data'] as String;

        final buf = _buffers.putIfAbsent(id, () => _MultipartBuffer(total));
        buf.addPart(part, data);

        if (buf.isComplete) {
          try {
            final jsonMap = jsonDecode(buf.concat()) as Map<String, dynamic>;
            _ctr.add(PushMessage.fromMap(jsonMap));
            debugPrint('[SmsService] Multipart JSON-SMS empfangen');
          } catch (e) {
            debugPrint('[SmsService] ⚠️ Ungültige JSON in Multipart: $e');
          }
          _buffers.remove(id);
        }
        break;

      case 'onJsonSms':
        try {
          final msgMap = Map<String, dynamic>.from(call.arguments);
          _ctr.add(PushMessage.fromMap(msgMap));
          debugPrint('[SmsService] JSON-SMS empfangen');
        } catch (e) {
          debugPrint('[SmsService] ⚠️ Ungültige JSON-SMS: $e');
        }
        break;
    }
  }
}

/* ────────────────────── Multipart Helper ────────────────────── */

class _MultipartBuffer {
  _MultipartBuffer(this.totalParts);
  final int totalParts;
  final Map<int, String> _parts = {};

  void addPart(int idx, String data) => _parts[idx] = data;

  bool get isComplete => _parts.length == totalParts;

  String concat() => List.generate(totalParts, (i) => _parts[i] ?? '').join();
}
