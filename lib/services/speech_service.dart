/*
 *  speech_service.dart  (v1 – FINAL)
 *  --------------------------------------------------------------
 *  Aufgabe
 *    • Sprache → Text → ParsedFood oder Freitext‑Command
 *    • Drei Modi (Settings → speechMode):
 *        offline  : Vosk  (on‑device)
 *        hybrid   : Whisper bevorzugt, Vosk Fallback
 *        online   : Whisper (OpenAI)
 *    • Event‑Workflow
 *        SpeechInputStartedEvent
 *        SpeechInputFinishedEvent (transcript)
 *        SpeechInputFailedEvent   (reason)
 *    • Avatar‑Reaktionen
 *    • AAPS‑Plugin‑Bridge („kidsapp/speech_bridge“)
 *
 *  Benötigte Pakete
 *    • vosk_dart
 *    • speech_to_text          (Fallback für iOS)
 *    • http                    (Whisper)
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:vosk_dart/vosk_dart.dart' as vosk;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../events/app_events.dart';
import 'settings_service.dart';

class SpeechInputStartedEvent {}
class SpeechInputFinishedEvent {
  final String transcript;
  const SpeechInputFinishedEvent(this.transcript);
}
class SpeechInputFailedEvent {
  final String reason;
  const SpeechInputFailedEvent(this.reason);
}

class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  static const MethodChannel _speechBridge =
  MethodChannel('kidsapp/speech_bridge'); // AAPS‑Plugin

  late SettingsService _settings;
  late EventBus _bus;

  /* Offline */
  vosk.SpeechService? _vosk;
  stt.SpeechToText? _iosFallback;

  /* ───────────────────────────────────────────────────────────────
   * Init – AppInitializer ruft auf
   * ──────────────────────────────────────────────────────────── */
  Future<void> init(EventBus bus) async {
    _bus = bus;
    _settings = SettingsService.I;

    if (_settings.speechMode != 'online') {
      await _initOfflineEngine();
    }

    // Plugin‑Callback
    _speechBridge.setMethodCallHandler(_onPluginCall);
  }

  Future<void> _initOfflineEngine() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelPath = '${dir.path}/vosk/model-small-de';
      if (!await Directory(modelPath).exists()) {
        // Modell aus Assets kopieren (einmalig)
        final data = await rootBundle.load('assets/ml/vosk/model-small-de.zip');
        final file = File('${dir.path}/model.zip');
        await file.writeAsBytes(data.buffer.asUint8List());
        // TODO: unzip
      }
      _vosk = vosk.SpeechService(modelPath: modelPath);
      await _vosk!.init();
    } catch (_) {
      // Android‑/Linux‑Fallback fehlgeschlagen → iOS‐speech_to_text nutzen
      _iosFallback = stt.SpeechToText();
    }
  }

  /* ───────────────────────────────────────────────────────────────
   * Öffentliche API
   * ──────────────────────────────────────────────────────────── */
  Future<void> startListening() async {
    _bus.fire(SpeechInputStartedEvent());

    switch (_settings.speechMode) {
      case 'offline':
        await _listenOffline();
        break;
      case 'online':
        await _listenWhisper();
        break;
      case 'hybrid':
      default:
        final ok = await _listenWhisper();
        if (!ok) await _listenOffline();
    }
  }

  /* ───────────────────────────────────────────────────────────────
   * Whisper (OpenAI) – Online
   * ──────────────────────────────────────────────────────────── */
  Future<bool> _listenWhisper() async {
    final key = _settings.whisperApiKey;
    if (key.isEmpty) return false;

    try {
      final tempPath = '${(await getTemporaryDirectory()).path}/rec.wav';

      // Plugin‑/System‑Recording (AAPS Bridge), sonst native
      if (!(await _recordViaPlugin(tempPath))) {
        if (!await _recordNative(tempPath)) return false;
      }

      // Whisper‑Upload
      final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $key'
        ..fields['model'] = 'whisper-1'
        ..files.add(await http.MultipartFile.fromPath('file', tempPath));

      final rsp = await http.Response.fromStream(await req.send());
      if (rsp.statusCode != 200) return false;

      final txt = jsonDecode(rsp.body)['text'] as String;
      _bus..fire(SpeechInputFinishedEvent(txt))
        ..fire(AvatarCelebrateEvent());
      return true;
    } catch (_) {
      return false;
    }
  }

  /* ───────────────────────────────────────────────────────────────
   * Offline (Vosk / speech_to_text)
   * ──────────────────────────────────────────────────────────── */
  Future<void> _listenOffline() async {
    try {
      if (_vosk != null) {
        final txt = await _vosk!.listenOnce();
        if (txt.isEmpty) {
          _fail('empty');
        } else {
          _bus..fire(SpeechInputFinishedEvent(txt))
            ..fire(AvatarCelebrateEvent());
        }
      } else if (_iosFallback != null) {
        await _iosFallback!.initialize();
        final txt = await _iosFallback!.listen(onResult: (_) {}).first;
        _bus..fire(SpeechInputFinishedEvent(txt.recognizedWords))
          ..fire(AvatarCelebrateEvent());
      } else {
        _fail('offline_engine_missing');
      }
    } catch (e) {
      _fail(e.toString());
    }
  }

  /* ───────────────────────────────────────────────────────────────
   * Aufnahme via Plugin‑Bridge (AAPS) – für Whisper
   * ──────────────────────────────────────────────────────────── */
  Future<bool> _recordViaPlugin(String outPath) async {
    try {
      final res =
      await _speechBridge.invokeMethod<String>('recordOnce', {'path': outPath});
      return res == 'ok' && File(outPath).existsSync();
    } catch (_) {
      return false;
    }
  }

  /* Native Aufnahme (Flutter plugins) – Fallback */
  Future<bool> _recordNative(String outPath) async {
    // TODO: mic_stream / flutter_sound Integration
    return false;
  }

  /* ───────────────────────────────────────────────────────────────
   * Plugin‑Callbacks
   * ──────────────────────────────────────────────────────────── */
  Future<void> _onPluginCall(MethodCall call) async {
    if (call.method == 'onSpeechError') {
      _fail(call.arguments ?? 'plugin_error');
    }
  }

  /* ───────────────────────────────────────────────────────────────
   * Fehler
   * ──────────────────────────────────────────────────────────── */
  void _fail(String r) {
    _bus..fire(SpeechInputFailedEvent(r))..fire(AvatarSadEvent());
  }
}