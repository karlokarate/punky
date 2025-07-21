// lib/speech_to_text_local/lib/speech_recognition_result.dart
//
// Minimalversion – nur Ergebnisstruktur für STT
// --------------------------------------------------------------

class SpeechRecognitionResult {
  final List<SpeechRecognitionWords> alternates;
  final bool finalResult;

  SpeechRecognitionResult(this.alternates, this.finalResult);
}

class SpeechRecognitionWords {
  final String recognizedWords;
  final double confidence;

  SpeechRecognitionWords(this.recognizedWords, [this.confidence = 0.0]);
}
