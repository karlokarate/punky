/*
 *  main.dart  (v3 – vollständig)
 *  --------------------------------------------------------------
 *  Einstiegspunkt der Kids Diabetes Companion‑App.
 *  Erkennt via --dart-define, ob Standalone‑ oder Plugin‑Modus.
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'package:flutter/material.dart';
import 'app_initializer.dart';
import 'ui/start_screen.dart';
import 'ui/child_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Build‑Flavor bestimmen (sa = Standalone, pl = Plugin)
  const mode =
      String.fromEnvironment('INTEGRATION_MODE', defaultValue: 'sa');
  final flavor =
      mode.toLowerCase().startsWith('p') ? AppFlavor.plugin : AppFlavor.standalone;

  // System‑Bootstrap
  final appCtx = await AppInitializer.init(flavor: flavor);

  // Globaler Error‑Handler
  FlutterError.onError = (details) {
    FlutterError.presentError(details); // TODO: Crash‑Reporting
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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids Diabetes Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Plugin‑Variante startet direkt im Kinder‑Home‑Screen
      home: widget.appCtx.flavor == AppFlavor.plugin
          ? const ChildHomeScreen()
          : const StartScreen(),
    );
  }
}