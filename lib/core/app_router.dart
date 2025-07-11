// lib/core/app_router.dart
//
// Globale Routenverwaltung für „punky“.
// Vollständig, keine weiteren Code‑Fragmente nötig.

import 'package:flutter/material.dart';
import '../services/app_context.dart';
import '../ui/start_screen.dart';
import '../ui/child_home_screen.dart';
import '../ui/parent_home_screen.dart';
import '../ui/settings_screen.dart';
import '../ui/meal_screen.dart';
import '../ui/snack_screen.dart';
import '../ui/guess_screen.dart';
import '../ui/avatar_editor_screen.dart';

/// Liste aller benannten Routen.
/// Verwende sie statt String‑Literals, um Tippfehler zu vermeiden.
abstract class AppRoutes {
  static const String start   = '/';
  static const String child   = '/child';
  static const String parent  = '/parent';
  static const String settings = '/settings';
  static const String meal    = '/meal';
  static const String snack   = '/snack';
  static const String guess   = '/guess';
  static const String avatar  = '/avatar';
}

/// Übergeordnete Router‑Klasse.
/// Bindet den [AppContext] ein, damit jede Page ihre Services erhält.
class AppRouter {
  AppRouter(this.context);

  final AppContext context;

  /// Wird an `MaterialApp.onGenerateRoute` übergeben.
  Route<dynamic> generate(RouteSettings settings) {
    final args = settings.arguments;
    Widget page;

    switch (settings.name) {
      case AppRoutes.start:
      // Plugin‑Variante: überspringe Wizard und gehe direkt ins Child‑Dashboard.
        if (context.flavor == AppFlavor.plugin) {
          page = ChildHomeScreen(appContext: context);
        } else {
          page = StartScreen(appContext: context);
        }
        break;

      case AppRoutes.child:
        page = ChildHomeScreen(appContext: context);
        break;

      case AppRoutes.parent:
        page = ParentHomeScreen(appContext: context);
        break;

      case AppRoutes.settings:
        page = SettingsScreen(appContext: context);
        break;

      case AppRoutes.meal:
        page = MealScreen(appContext: context, initialData: args);
        break;

      case AppRoutes.snack:
        page = SnackScreen(appContext: context, initialData: args);
        break;

      case AppRoutes.guess:
        page = GuessScreen(appContext: context, initialData: args);
        break;

      case AppRoutes.avatar:
        page = AvatarEditorScreen(appContext: context);
        break;

      default:
        page = Scaffold(
          body: Center(
            child: Text('Unbekannte Route: ${settings.name}'),
          ),
        );
    }

    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
