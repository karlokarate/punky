// lib/services/sms_service.dart
//
// v6 – NATIVE SMS BRIDGE (AAPS‑Style)
// --------------------------------------------------------------
// JSON‑SMS‑Bridge für strukturierte Nachrichten
// • Empfang über native MethodChannel (SmsReceiver)
// • Versand über native Methode sendSms
// • Kompatibel mit PushMessage (über Fallback nutzbar)
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'dart:async';
import 'dart:convert';
import 'package:diabetes_kids_app/services/settings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../services/push_service.dart';

class SmsService {
  SmsService._();
  static final SmsService instance = SmsService._();

  final Map<String, _MultipartBuffer> _buffers = {};
  final _ctr = StreamController<PushMessage>.broadcast();
  Stream<PushMessage> get onJsonSms => _ctr.stream;

  static const MethodChannel _channel = MethodChannel('sms_channel');

  /// Initialisiert MethodChannel-Handler für empfangene SMS
  Future<void> init() async {
    _channel.setMethodCallHandler(_onSmsBridge);
    debugPrint('[SmsService] initialisiert');
  }

  /// Sendet eine JSON-formatierte SMS über native Android-Methode
  Future<bool> sendJsonSms(PushMessage msg) async {
    try {
      await _channel.invokeMethod('sendSms', {
        'to': SettingsService.I.smsTarget,
        'text': jsonEncode(msg.toMap()),
      });
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
      case 'smsReceived':
        final data = Map<String, dynamic>.from(call.arguments);
        final body = data['body'] ?? '';
        final from = data['from'] ?? '';

        debugPrint('[SmsService] SMS von $from empfangen');

        try {
          final jsonMap = jsonDecode(body) as Map<String, dynamic>;
          _ctr.add(PushMessage.fromMap(jsonMap));
          debugPrint('[SmsService] JSON-SMS empfangen');
        } catch (e) {
          debugPrint('[SmsService] ⚠️ Ungültige JSON-SMS: $e');
        }
        break;

      case 'onJsonSmsPart':
        final map = Map<String, dynamic>.from(call.arguments);
        final id = map['id'];
        final part = map['part'] as int;
        final total = map['total'] as int;
        final content = map['data'] as String;

        final buf = _buffers.putIfAbsent(id, () => _MultipartBuffer(total));
        buf.addPart(part, content);

        if (buf.isComplete) {
          try {
            final jsonMap = jsonDecode(buf.concat()) as Map<String, dynamic>;
            _ctr.add(PushMessage.fromMap(jsonMap));
            debugPrint('[SmsService] Multipart JSON-SMS empfangen');
          } catch (e) {
            debugPrint('[SmsService] ⚠️ Fehler in Multipart-JSON: $e');
          }
          _buffers.remove(id);
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
