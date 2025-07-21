// lib/main.dart
//
// v2 – Standalone Start mit AppContext, globaler Initialisierung & Routing
// --------------------------------------------------------------
// • Initialisiert AppContext per initializeApp()
// • Setzt globale Variable appCtx
// • Übergibt AppContext an AppRouter
// • Nutzt onGenerateRoute für Navigation
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'package:flutter/material.dart';
import 'core/app_context.dart';
import 'core/app_flavor.dart';
import 'core/app_initializer.dart';
import 'core/app_router.dart';
import 'core/global.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final context = await initializeApp(AppFlavor.standalone);
  appCtx = context; // globale AppContext-Variable setzen

  runApp(MyApp(context));
}

class MyApp extends StatelessWidget {
  final AppContext context;
  const MyApp(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diabetes Companion',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: AppRouter(this.context).generate,
    );
  }
}
