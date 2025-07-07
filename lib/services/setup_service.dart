/*
 *  setup_service.dart  (v1 – FLOW CONTROL)
 *  --------------------------------------------------------------
 *  Prüft Setup-Status und entscheidet, ob SetupWizard oder StartScreen gezeigt wird.
 *  • Nutzt SettingsService als Single-Source
 *  • Optional: EventBus-Signal nach Abschluss
 *
 *  Projektpfad: lib/services/setup_service.dart
 */

import 'settings_service.dart';

class SetupService {
  static final SetupService I = SetupService._();
  SetupService._();

  /// Prüft ob die Ersteinrichtung abgeschlossen ist.
  Future<bool> isSetupDone() async {
    return SettingsService.I.initialSetupDone;
  }

  /// Routing-Hilfe für main.dart
  Future<String> initialRoute() async {
    return (await isSetupDone()) ? '/start' : '/setup';
  }

  /// Für zukünftige Erweiterung: Setup neu starten
  Future<void> resetSetup() async {
    await SettingsService.I.resetSetup();
  }
}
