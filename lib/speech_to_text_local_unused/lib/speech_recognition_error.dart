// lib/speech_to_text_local/lib/speech_recognition_error.dart
//
// Minimalversion – nur lokale Fehlerstruktur
// --------------------------------------------------------------

class SpeechRecognitionError {
  final String errorMsg;
  final bool permanent;

  SpeechRecognitionError(this.errorMsg, this.permanent);
}
