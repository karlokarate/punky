// lib/main.dart
//
// v4 – FINAL
// Vollständiger Einstiegspunkt der Kids Diabetes Companion-App
// --------------------------------------------------------------
// • Erkennt Plugin- vs Standalone-Modus (via --dart-define)
// • Startet mit globalem AppContext & AppRouter
// • Aktiviert alle globalen Services über AppInitializer
// • Inklusive Theme, Error-Handler und initialer Router-Integration
//
// © 2025 Kids Diabetes Companion – GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'core/app_flavor.dart';
import 'core/app_initializer.dart';
import 'core/app_router.dart';
import 'core/app_context.dart';
import 'core/event_bus.dart';
late AppContext appCtx;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Build-Flavor bestimmen (plugin oder standalone)
  const mode = String.fromEnvironment('INTEGRATION_MODE', defaultValue: 'sa');
  final flavor = mode.toLowerCase().startsWith('p')
      ? AppFlavor.plugin
      : AppFlavor.standalone;

  // Initialisiere Services, EventBus, Storage usw.
  appCtx = await initializeApp(flavor);
  // Initialisiere EventBus
  await AppEventBus.init(flavor);
  // Globaler Error-Handler
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // TODO: Optional: Fehler an Crashlytics / Sentry senden
  };

  runApp(KidsApp(appCtx: appCtx));
}

class KidsApp extends StatefulWidget {
  final AppContext appCtx;
  const KidsApp({super.key, required this.appCtx});

  @override
  State<KidsApp> createState() => _KidsAppState();
}

class _KidsAppState extends State<KidsApp> {
  late final AppRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter(widget.appCtx);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids Diabetes Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
      ),
      themeMode: ThemeMode.system, // oder .light / .dark je nach Settings
      initialRoute: '/',
      onGenerateRoute: _router.generate,
    );
  }
}
