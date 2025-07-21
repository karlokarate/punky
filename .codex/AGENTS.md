# Codex Agent Leitfaden

Diese Repository enthält die **Kids Diabetes Companion** – eine Flutter-App,
die Kindern beim Schätzen von Kohlenhydraten hilft und AAPS integrieren kann.

## Hauptziele der App
1. **KH-Berechnung** über Spracheingabe (Whisper/Vosk) oder Bildanalyse.
2. **Gamification** zur Verbesserung des KH-Schätzens (Avatar, Punkte, Levels).
3. **AAPS-Integration** im Plugin-Modus inklusive Bolus- und CGM-Daten.
4. **Eltern-Steuerung** über Nightscout, Push und SMS.

## Arbeitsanweisungen für Codex
- **Vor jedem Commit** `bash codex_dev.sh` ausführen. Das Skript versucht
  Abhängigkeiten zu laden und `dart analyze` aufzurufen.
- Falls das Skript aufgrund fehlender Flutter-SDK scheitert, darf der Commit
  trotzdem erfolgen, aber die Ausführung muss im PR-Protokoll erwähnt werden.
- Neue Dateien immer im bestehenden Stil anlegen. Services liegen unter
  `lib/services`, UI unter `lib/ui`, zentrale Modelle in `lib/core` oder
  `lib/events`.
- Die App nutzt einen globalen `EventBus`. Neue Events gehören in
  `lib/events/app_events.dart`.
- Auf Lokalisierung achten: Texte werden über `AppLocalizations` geladen.
- Bei Änderungen an Abhängigkeiten `pubspec.yaml` anpassen und anschließend
  `bash codex_dev.sh` ausführen.

## Tests
Es existieren keine Unit-Tests. Verwende `dart analyze` um statische Fehler zu
vermeiden. Wenn möglich, sollte `flutter analyze` oder `dart analyze` ohne
Fehler durchlaufen.

## Dokumentation
Architektur und Abhängigkeitsgraph sind in `docs/ARCHITECTURE.md` beschrieben.
Bitte pflege diese Datei, wenn sich zentrale Strukturen ändern.
