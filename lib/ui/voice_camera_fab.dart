/*
 *  voice_camera_fab.dart  (v1)
 *  --------------------------------------------------------------
 *  • Tap      = Spracheingabe starten
 *  • LongTap  = Kamera‑Eingabe starten
 *  • Abwärts‑kompatibel (Services feuern Events & handlen selbst)
 */

import 'package:flutter/material.dart';
import '../core/app_context.dart';
import '../events/app_events.dart';
import '../core/event_bus.dart';

class VoiceCameraFab extends StatelessWidget {
  const VoiceCameraFab({super.key, required this.appContext});

  final AppContext appContext;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        // Kamera
        appContext.imageInputService.captureAndAnalyze(); // war: startImageInput()
        appContext.bus.fire(const ImageInputStartedEvent());
      },
      child: FloatingActionButton(
        onPressed: () {
          // Sprache
          appContext.speechService.startListening(); // war: startSpeechInput()
          appContext.bus.fire(const SpeechInputStartedEvent());
        },
        tooltip: 'Sprache / Bild',
        child: const Icon(Icons.mic),
      ),
    );
  }
}
