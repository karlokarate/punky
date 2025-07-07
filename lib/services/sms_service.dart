/*
 *  sms_service.dart – v3
 *  --------------------------------------------------------------
 *  SMS​-Bridge zur JSON​-Übertragung via Telephony (Fallback zu Push).
 *  Empfängt JSON-Bodies (auch Multipart), sendet via platform channel.
 *
 *  © 2025 Kids Diabetes Companion – GPL​-3.0​-or​later
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'push_service.dart';

class SmsService {
  SmsService._();
  static final SmsService instance = SmsService._();

  static const MethodChannel _smsBridge =
  MethodChannel('kidsapp/sms_bridge');

  final Map<String, _MultipartBuffer> _buffers = {};
  final _ctr = StreamController<PushMessage>.broadcast();
  Stream<PushMessage> get onJsonSms => _ctr.stream;

  Future<void> init() async {
    _smsBridge.setMethodCallHandler(_onSmsBridge);
  }

  Future<void> sendJsonSms(PushMessage msg) async {
    await _smsBridge.invokeMethod('sendJsonSms', msg.toMap());
  }

  /* ---------------- Empfang ---------------- */

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
        } catch (e) {
          // Fehlerhafte JSON? Ignorieren.
        }
        _buffers.remove(id);
      }
    } else if (call.method == 'onJsonSms') {
      try {
        final msgMap = Map<String, dynamic>.from(call.arguments);
        _ctr.add(PushMessage.fromMap(msgMap));
      } catch (e) {
        // Fehlerhafte JSON? Ignorieren.
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
  String concat() => List.generate(totalParts, (i) => _parts[i] ?? '').join();
}
