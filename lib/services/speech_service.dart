/*
 *  speech_service.dart  (v5 – FIXED VOSK API USAGE)
 *  --------------------------------------------------------------
 *  Whisper: Online mit Sprache "de"
 *  Vosk: Offline mit Modell im Asset-Verzeichnis
 *  iOS: Fallback mit speech_to_text
 *  Ergebnis geht direkt an TextParser
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../events/app_events.dart';
import '../services/text_parser.dart';
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

  static const MethodChannel _speechBridge = MethodChannel('kidsapp/speech_bridge');

  late SettingsService _settings;
  late EventBus _bus;

  Recognizer? _voskRecognizer;

  stt.SpeechToText? _iosFallback;

  Future<void> init(EventBus bus) async {
    _bus = bus;
    _settings = SettingsService.I;

    if (_settings.speechMode != 'online') {
      await _initOfflineEngine();
    }

    _speechBridge.setMethodCallHandler(_onPluginCall);
  }

  Future<void> _initOfflineEngine() async {
    try {
      final vosk = VoskFlutterPlugin.instance();
      final modelPath = await ModelLoader().loadFromAssets('assets/models/vosk-model-small-de-0.15.zip');
      final model = await vosk.createModel(modelPath);
      _voskRecognizer = await vosk.createRecognizer(model: model, sampleRate: 16000);
    } catch (_) {
      _iosFallback = stt.SpeechToText();
    }
  }

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

  Future<bool> _listenWhisper() async {
    final key = _settings.whisperApiKey;
    if (key.isEmpty) return false;

    try {
      final tempPath = '${(await getTemporaryDirectory()).path}/rec.wav';
      if (!await _recordNative(tempPath)) return false;

      final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $key'
        ..fields['model'] = 'whisper-1'
        ..fields['language'] = 'de'
        ..files.add(await http.MultipartFile.fromPath('file', tempPath));

      final rsp = await http.Response.fromStream(await req.send());
      if (rsp.statusCode != 200) return false;

      final txt = jsonDecode(rsp.body)['text'] as String;
      _handleTranscript(txt);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _listenOffline() async {
    try {
      if (_voskRecognizer != null) {
        final audioPath = '${(await getTemporaryDirectory()).path}/vosk.wav';

        if (!await _recordNative(audioPath)) {
          _fail('no_audio');
          return;
        }

        final file = File(audioPath);
        final bytes = await file.readAsBytes();
        final isFinal = await _voskRecognizer!.acceptWaveformBytes(bytes);
        final resultJson = isFinal
            ? await _voskRecognizer!.getFinalResult()
            : await _voskRecognizer!.getResult();
        final result = jsonDecode(resultJson)['text'] as String;

        if (result.isEmpty) {
          _fail('empty');
        } else {
          _handleTranscript(result);
        }
      } else if (_iosFallback != null) {
        await _iosFallback!.initialize();
        String text = '';
        await _iosFallback!.listen(
          onResult: (res) => text = res.recognizedWords,
          listenFor: const Duration(seconds: 5),
        );
        await Future.delayed(const Duration(seconds: 6));
        _handleTranscript(text);
      } else {
        _fail('offline_engine_missing');
      }
    } catch (e) {
      _fail(e.toString());
    }
  }

  Future<bool> _recordNative(String outPath) async {
    try {
      const channel = MethodChannel('kidsapp/mic');
      final res = await channel.invokeMethod<String>('recordOnce', {'path': outPath});
      return res == 'ok' && File(outPath).existsSync();
    } catch (_) {
      return false;
    }
  }

  void _handleTranscript(String txt) {
    _bus
      ..fire(SpeechInputFinishedEvent(txt))
      ..fire(AvatarCelebrateEvent());

    final parsed = TextParser.parse(txt);
    if (parsed.isEmpty) {
      _fail('no_keywords_detected');
    }
  }

  Future<void> _onPluginCall(MethodCall call) async {
    if (call.method == 'onSpeechError') {
      _fail(call.arguments ?? 'plugin_error');
    }
  }

  void _fail(String r) {
    _bus
      ..fire(SpeechInputFailedEvent(r))
      ..fire(AvatarSadEvent());
  }
}
