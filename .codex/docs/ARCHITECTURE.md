# Projektüberblick

Dieses Flutter-Projekt implementiert die **Kids Diabetes Companion**. Der Code ist modular
organisiert und basiert auf einem zentralen EventBus. Die App kann im
Standalone- oder Plugin-Modus (AAPS-Integration) betrieben werden.

## Einstiegspunkt

* `lib/main.dart` initialisiert mittels `AppInitializer` einen `AppContext`.
* `AppRouter` definiert die Navigation zwischen Screens.

## Kernkomponenten

### AppContext und Initializer

* `lib/core/app_context.dart` hält Referenzen auf alle globalen Dienste
  (Settings, Nightscout, Avatar, Gamification usw.).
* `lib/core/app_initializer.dart` erzeugt diese Dienste je nach `AppFlavor`
  (plugin oder standalone) und bindet den `AppEventBus`.

### EventBus

* `lib/core/event_bus.dart` richtet einen globalen EventBus ein und verbindet
  ihn im Plugin-Modus per Method-/EventChannel mit AAPS.
* Alle Events sind in `lib/events/app_events.dart` definiert.

### Services

* **AAPSBridge** (`lib/services/aaps_bridge.dart`)
  Plattform-Integration mit AndroidAPS (Carbs, Bolus, Loop-Daten, Push).

* **SettingsService** (`lib/services/settings_service.dart`)
  Verwaltung persistenter Einstellungen und Synchronisation im Plugin-Modus.

* **NightscoutService** (`lib/services/nightscout_service.dart`)
  Anbindung an Nightscout API – optional via AAPSBridge im Plugin-Modus.

* **MealAnalyzer** (`lib/services/meal_analyzer.dart`)
  Kernelement zur KH-Berechnung. Nutzt `TextParser` + `ProductMatcher` mit SQLite-Produktdaten.

* **SpeechService** (`lib/services/speech_service.dart`)
  Spracherkennung über **Whisper.cpp** (offline). FFI-Anbindung an `libwhisper.so`.
  Unterstützt Mehrsprachigkeit, nutzt lokale `tiny`-Modelle  zur Zwischenspeicherung.
  Transkripte werden an den `TextParser` übergeben.

* **ImageInputService** (`lib/services/image_input_service.dart`)
  Analyse von Kamera- oder Galerie-Bildern via TFLite, ggf. GPT‑Vision (optional).
  Output → `MealAnalyzer`.

* **AvatarService** (`lib/services/avatar_service.dart`)
  Verwaltung aller Avatare, Speicherstände, Belohnungen, SQLite-basiert.

* **GamificationService** (`lib/services/gamification_service.dart`)
  Punktesystem, Avatar-Freischaltungen, Benachrichtigungen via EventBus.

* **GptService** (`lib/services/gpt_service.dart`)
  Analysiert Eingaben anhand definierter Regeln aus `assets/config/gpt_rules.yaml`,
  ruft OpenAI GPT-API auf, limitiert über `GlobalRateLimiter`.

* **PushService / SmsService / CommunicationService**
  Nachrichtenkanäle: FCM, Plugin oder SMS. Alarme und Feedback-Nachrichten zentralisiert.

* **BackgroundService** (`lib/services/background_service.dart`)
  Loop-Daten, Queue-Verarbeitung, Token-Refresh, Perioden-Tasks via WorkManager.

* **BolusEngine** (`lib/services/bolus_engine.dart`)
  Berechnet Bolusvorschläge aus KH und Insulinprofilen.

* **GptAnalysisService** und **RecommendationHistoryService**
  führen Nightscout-Analysen aus, speichern Empfehlungen in Verlauf.

### Datenbanken und Assets

* Produkt-Datenbank: `lib/assets/db/products.sqlite`
* Whisper-Modelle: /assets/whisper/ggml-tiny.bin
* Parser-Regeln & Einheiten: `assets/config/*.yaml`
* Avatar- und UI-Assets: `assets/`

### User Interface

* Hauptscreens: `lib/ui/child_home_screen.dart`, `avatar_screen.dart`, `parent_screen.dart`
* Widgets: z. B. `PinGuard`, `VoiceCameraFab`, `AvatarLevelBadge`
* Alle Screens verwenden zentrale Lokalisierung (`AppLocalizations`)

## Daten- und Ereignisfluss

1. **Eingabe** – Sprache (`SpeechService`) → Whisper → Transkript → TextParser
   oder Bild (`ImageInputService`) → KH-Schätzung → `MealAnalyzer`.

2. **Analyse** – `MealAnalyzer` verknüpft Erkennung mit Produkten in SQLite.
   Erkennt Portionseinheiten, berechnet KH-Wert.

3. **Events** – Es werden Events ausgelöst:

    * `MealAnalyzedEvent`
    * `MealWarningEvent`
    * `BolusCalculatedEvent`
    * `AvatarCelebrateEvent` (bei Gamification)

4. **Sync & Persistenz** – Übertragung an AAPS oder Nightscout
   → via `AapsCarbSyncService` oder `NightscoutService`.

5. **Gamification & Feedback** – Avatar & Punkte bei erfolgreicher Eingabe,
   positive Rückmeldung + Push/SMS (Eltern-App).

6. **Hintergrunddienste** – `BackgroundService` synchronisiert Loop-Status,
   verarbeitet Queues, lädt Whisper-Modelle bei Bedarf.

## Build & Entwicklung

* Abhängigkeiten: `pubspec.yaml`
* Dev-Skript: `bash codex_dev.sh` (führt `flutter pub get` & `dart analyze` aus)
* Codex-Integration:

Codex-Integration erfolgt über `.codex/context.yaml` + optional `.codex/agents.md`.

