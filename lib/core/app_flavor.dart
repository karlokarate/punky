// lib/core/app_flavor.dart
//
// v1 – FINAL
// --------------------------------------------------------------
// Definiert den App-Betriebsmodus:
//   • standalone → Autark laufende App (Smartphone, Tablet)
//   • plugin     → Eingebettet in AndroidAPS via Bridge
//
// Wird u. a. in: main.dart, app_initializer.dart, settings_service.dart verwendet
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

enum AppFlavor {
  standalone,
  plugin,
}

extension AppFlavorName on AppFlavor {
  String get name => toString().split('.').last;
}