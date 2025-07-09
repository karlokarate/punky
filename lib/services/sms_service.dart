/*
 *  sms_service.dart – v4 (mit Rückgabewert + Logging)
 *  --------------------------------------------------------------------------
 *  SMS‑Bridge zur JSON‑Übertragung via Telephony (Fallback zu Push).
 *  Empfängt JSON‑Bodies (auch Multipart), sendet via platform channel.
 *  Rückgabewert für sendJsonSms = Future<bool> (für Fallback‑Logik).
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'push_service.dart';

class SmsService {
  SmsService._();
  static final SmsService instance = SmsService._();

  static const MethodChannel _smsBridge = MethodChannel('kidsapp/sms_bridge');

  final Map<String, _MultipartBuffer> _buffers = {};
  final _ctr = StreamController<PushMessage>.broadcast();
  Stream<PushMessage> get onJsonSms => _ctr.stream;

  /// Initialisiert den SMS‑Service und registriert den Bridge‑Handler.
  Future<void> init() async {
    _smsBridge.setMethodCallHandler(_onSmsBridge);
    debugPrint('[SmsService] initialisiert');
  }

  /// Sendet eine JSON‑SMS an ein anderes Gerät.
  ///
  /// Gibt `true` zurück bei Erfolg, sonst `false`.
  Future<bool> sendJsonSms(PushMessage msg) async {
    try {
      await _smsBridge.invokeMethod('sendJsonSms', msg.toMap());
      debugPrint('[SmsService] SMS erfolgreich gesendet');
      return true;
    } catch (e) {
      debugPrint('[SmsService] ⚠️ SMS-Versand fehlgeschlagen: $e');
      return false;
    }
  }

  /* ────────────────────── Empfang & Verarbeitung ────────────────────── */

  Future<void> _onSmsBridge(MethodCall call) async {
    if (call.method == 'onJsonSmsPart') {
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
    } else if (call.method == 'onJsonSms') {
      try {
        final msgMap = Map<String, dynamic>.from(call.arguments);
        _ctr.add(PushMessage.fromMap(msgMap));
        debugPrint('[SmsService] JSON-SMS empfangen');
      } catch (e) {
        debugPrint('[SmsService] ⚠️ Ungültige JSON-SMS: $e');
      }
    }
  }
}

class _MultipartBuffer {
  _MultipartBuffer(this.totalParts);
  final int totalParts;
  final Map<int, String> _parts = {};

  void addPart(int idx, String data) => _parts[idx] = data;

  bool get isComplete => _parts.length == totalParts;

  String concat() =>
      List.generate(totalParts, (i) => _parts[i] ?? '').join();
}
