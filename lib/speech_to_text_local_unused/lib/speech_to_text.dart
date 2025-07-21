// lib/speech_to_text_local/lib/speech_to_text.dart
//
// Minimalversion – direkte STT API für Flutter
// --------------------------------------------------------------

import 'dart:async';
import 'package:flutter/services.dart';

import 'speech_recognition_result.dart';
import 'speech_recognition_error.dart';

typedef SpeechResultCallback = void Function(SpeechRecognitionResult result);
typedef SpeechErrorCallback = void Function(SpeechRecognitionError error);
typedef SpeechStatusCallback = void Function(String status);

class SpeechToText {
  static const MethodChannel _channel = MethodChannel('plugin.csdcorp.com/speech_to_text');

  bool _isListening = false;
  bool get isListening => _isListening;

  late SpeechResultCallback _onResult;
  late SpeechErrorCallback _onError;
  late SpeechStatusCallback _onStatus;

  Future<bool> initialize({
    required SpeechErrorCallback onError,
    required SpeechStatusCallback onStatus,
  }) async {
    _onError = onError;
    _onStatus = onStatus;

    try {
      final bool available = await _channel.invokeMethod('initialize');
      return available;
    } catch (e) {
      _onError(SpeechRecognitionError('init_error: $e', true));
      return false;
    }
  }

  Future<void> listen({
    required SpeechResultCallback onResult,
    String? localeId,
    bool partialResults = true,
  }) async {
    _onResult = onResult;

    try {
      _isListening = true;
      _channel.setMethodCallHandler(_handleMethodCall);
      await _channel.invokeMethod('listen', {
        'localeId': localeId,
        'partialResults': partialResults,
      });
    } catch (e) {
      _onError(SpeechRecognitionError('listen_error: $e', true));
    }
  }

  Future<void> stop() async {
    try {
      _isListening = false;
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }

  Future<void> cancel() async {
    try {
      _isListening = false;
      await _channel.invokeMethod('cancel');
    } catch (_) {}
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSpeechAvailability':
        break; // optional
      case 'onSpeech':
        final text = call.arguments['recognizedWords'] ?? '';
        final result = SpeechRecognitionResult([
          SpeechRecognitionWords(text, 0.0)
        ], call.arguments['finalResult'] ?? false);
        _onResult(result);
        break;
      case 'onError':
        _onError(SpeechRecognitionError(call.arguments ?? 'unknown_error', false));
        break;
      case 'onStatus':
        _onStatus(call.arguments ?? '');
        break;
    }
  }
}
