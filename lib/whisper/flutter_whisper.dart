//
// lib/whisper/flutter_whisper.dart
//
// v1 – FFI-basierter Whisper Wrapper (ohne JNI)
// --------------------------------------------------------------
// • Direkte Nutzung von libwhisper.so über dart:ffi
// • Sendet Events über AppEventBus (z. B. WhisperReadyEvent)
// • Bereit für Integration in SpeechService
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
//

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../core/global.dart';
import '../events/app_events.dart';

class FlutterWhisper {
  static final FlutterWhisper _instance = FlutterWhisper._internal();
  factory FlutterWhisper() => _instance;
  FlutterWhisper._internal();

  late final DynamicLibrary _lib;
  late final _WhisperInitDart _init;
  late final _WhisperTranscribeDart _transcribe;

  bool _isReady = false;

  /// Initialisiert Whisper mit gegebenem Modelpfad
  Future<void> init(String modelPath) async {
    try {
      _lib = DynamicLibrary.open(_resolveLibPath());

      _init = _lib
          .lookup<NativeFunction<_WhisperInitNative>>('whisper_init')
          .asFunction();
      _transcribe = _lib
          .lookup<NativeFunction<_WhisperTranscribeNative>>('whisper_transcribe')
          .asFunction();

      final Pointer<Utf8> modelPtr = modelPath.toNativeUtf8();
      final int result = _init(modelPtr);
      calloc.free(modelPtr);

      if (result != 0) {
        appCtx.bus.fire(WhisperErrorEvent('Whisper init failed (code: $result)'));
        throw Exception('Whisper init failed (code: $result)');
      }

      _isReady = true;
      appCtx.bus.fire(const WhisperReadyEvent());
    } catch (e) {
      appCtx.bus.fire(WhisperErrorEvent(e.toString()));
      rethrow;
    }
  }

  /// Gibt transkribierten Text zurück (Pfad zu WAV-Datei)
  Future<String> transcribe(String wavPath) async {
    if (!_isReady) {
      throw Exception("Whisper is not initialized");
    }

    final Pointer<Utf8> audioPtr = wavPath.toNativeUtf8();
    final Pointer<Utf8> resultPtr = _transcribe(audioPtr);
    final result = resultPtr.toDartString();
    calloc.free(audioPtr);

    // Achtung: Nur freigeben, wenn C-Seite nicht shared buffer verwendet!
    // calloc.free(resultPtr);  // ggf. nur bei C-allokation

    return result;
  }

  String _resolveLibPath() {
    if (Platform.isAndroid) return 'libwhisper.so';
    if (Platform.isIOS) return 'whisper.framework/whisper';
    throw UnsupportedError('Whisper only supported on Android/iOS');
  }
}

// native int whisper_init(const char* model_path);
typedef _WhisperInitNative = Int32 Function(Pointer<Utf8>);
typedef _WhisperInitDart = int Function(Pointer<Utf8>);

// native const char* whisper_transcribe(const char* audio_path);
typedef _WhisperTranscribeNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _WhisperTranscribeDart = Pointer<Utf8> Function(Pointer<Utf8>);
