// lib/core/app_router.dart
//
// Globale Routenverwaltung für „punky“ – FINAL
// Alle Ziel-Screens geprüft & EventBus korrekt übergeben.

import 'package:flutter/material.dart';
import '../core/app_context.dart';
import '../core/app_flavor.dart';
import '../ui/start_screen.dart';
import '../ui/child_home_screen.dart';
import '../ui/parent_screen.dart';
import '../ui/settings_screen.dart';
import '../ui/meal_review_screen.dart';
import '../ui/kh_guessing_page.dart';
import '../ui/avatar_screen.dart';
import '../ui/setup_wizard.dart';

/// Liste aller benannten Routen.
abstract class AppRoutes {
  static const String start   = '/';
  static const String child   = '/child';
  static const String parent  = '/parent';
  static const String settings = '/settings';
  static const String meal    = '/meal';
  static const String snack   = '/snack';
  static const String guess   = '/guess';
  static const String avatar  = '/avatar';
  static const String setup   = '/setup';
}

/// Globale Routing-Klasse mit AppContext-Anbindung.
class AppRouter {
  AppRouter(this.context);

  final AppContext context;

  Route<dynamic> generate(RouteSettings settings) {
    final args = settings.arguments;
    Widget page;

    switch (settings.name) {
      case AppRoutes.start:
        page = (context.flavor == AppFlavor.plugin)
            ? ChildHomeScreen(appContext: context)
            : StartScreen(appContext: context);
        break;

      case AppRoutes.child:
        page = ChildHomeScreen(appContext: context);
        break;

      case AppRoutes.parent:
        page = ParentScreen(appContext: context);
        break;

      case AppRoutes.settings:
        page = SettingsScreen(appContext: context);
        break;

      case AppRoutes.meal:
        page = MealReviewScreen(
          appContext: context,
          initialData: args,
          eventBus: context.bus,
        );
        break;

      case AppRoutes.guess:
        final guessData = args is Map<String, dynamic> ? args : {};
        page = KhGuessingPage(
          appContext: context,
          initialData: guessData,
        );
        break;

      case AppRoutes.avatar:
        page = AvatarScreen(appContext: context);
        break;

      case AppRoutes.setup:
        page = SetupWizard(appContext: context);
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
