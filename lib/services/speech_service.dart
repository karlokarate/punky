//
// lib/services/speech_service.dart
//
// v14 – WHISPER FFI WRAPPER FINAL
// --------------------------------------------------------------
// Sprachverarbeitung (TTS, Whisper FFI, iOS STT)
// • Whisper-Wrapper mit FFI wird über init() geladen
// • TextParser erwartet: lowercase, keine Satzzeichen
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
//

import 'dart:async';
import 'dart:io';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/global.dart';
import '../events/app_events.dart';
import 'meal_analyzer.dart';
import 'settings_service.dart';
import 'text_parser.dart';
import '../whisper/flutter_whisper.dart'; // ✅ FFI-basierter Wrapper

class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  static const MethodChannel _micBridge = MethodChannel('kidsapp/mic');
  static const MethodChannel _speechBridge = MethodChannel('kidsapp/speech_bridge');

  late SettingsService _settings;
  late EventBus _bus;

  stt.SpeechToText? _iosFallback;
  bool _whisperReady = false;

  Future<void> init(EventBus bus) async {
    _bus = bus;
    _settings = SettingsService.I;

    _bus.on<AvatarSpeakEvent>().listen((evt) => _speak(evt.text));

    _speechBridge.setMethodCallHandler(_onPluginCall);

    // Whisper-Modell vorbereiten
    try {
      final modelPath = await getAssetPath('assets/whisper/ggml-tiny.bin');
      await FlutterWhisper().init(modelPath);
      _whisperReady = true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Whisper init failed: $e');
      }
    }

    if (kDebugMode) {
      print('✅ SpeechService: initialized in ${_settings.speechMode} mode');
    }
  }

  Future<void> startListening() async {
    _bus.fire(SpeechInputStartedEvent());

    switch (_settings.speechMode) {
      case 'offline':
        await _listenOffline();
        break;
      case 'online':
        final ok = await _listenWhisper();
        if (!ok) _fail('whisper_failed');
        break;
      case 'hybrid':
      default:
        final ok = await _listenWhisper();
        if (!ok) await _listenOffline();
    }
  }

  Future<bool> _listenWhisper() async {
    try {
      if (!_whisperReady) return false;

      final tmp = '${(await getTemporaryDirectory()).path}/rec.wav';
      if (!await _recordNative(tmp)) return false;

      final result = await FlutterWhisper().transcribe(tmp);
      if (result.isEmpty) return false;

      await _handleTranscript(result);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Whisper FFI error: $e');
      }
      return false;
    }
  }

  Future<void> _listenOffline() async {
    try {
      if (_iosFallback != null) {
        await _iosFallback!.initialize();
        String text = '';
        await _iosFallback!.listen(
          onResult: (r) => text = r.recognizedWords,
          listenFor: const Duration(seconds: 5),
        );
        await Future.delayed(const Duration(seconds: 6));
        await _handleTranscript(text);
      } else {
        _fail('offline_engine_missing');
      }
    } catch (e) {
      _fail(e.toString());
    }
  }

  Future<bool> _recordNative(String outPath) async {
    try {
      final res = await _micBridge.invokeMethod<String>('recordOnce', {'path': outPath});
      return res == 'ok' && File(outPath).existsSync();
    } catch (e) {
      if (kDebugMode) print('❌ Native recording failed: $e');
      return false;
    }
  }

  Future<void> _handleTranscript(String txt) async {
    _bus
      ..fire(SpeechInputFinishedEvent(txt))
      ..fire(AvatarCelebrateEvent());

    final cleaned = txt.toLowerCase().replaceAll(RegExp(r'[^\w\säöüß]'), '');
    final parsed = TextParser.parse(cleaned);
    if (parsed.isEmpty) {
      _fail('no_keywords_detected');
    }

    await MealAnalyzer.I.analyze(txt);
  }

  void _fail(String r) {
    _bus
      ..fire(SpeechInputFailedEvent(r))
      ..fire(AvatarSadEvent());
  }

  Future<void> _onPluginCall(MethodCall call) async {
    if (call.method == 'onSpeechError') {
      _fail(call.arguments ?? 'plugin_error');
    }
  }

  Future<void> _speak(String text) async {
    try {
      await appCtx.aapsBridge.speak(text);
    } catch (_) {/* ignore */ }
  }

  /// 🆕 Helper: Kopiert Whisper-Modell aus Asset nach temp-Folder
  Future<String> getAssetPath(String asset) async {
    final byteData = await rootBundle.load(asset);
    final file = File('${(await getTemporaryDirectory()).path}/${asset.split('/').last}');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }
}
