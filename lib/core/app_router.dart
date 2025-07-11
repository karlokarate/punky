import 'package:flutter/material.dart';

import 'app_context.dart';
import '../ui/start_screen.dart';
import '../ui/child_home_screen.dart';
import '../ui/parent_screen.dart';
import '../ui/settings_screen.dart';
import '../ui/setup_wizard.dart';
import '../ui/avatar_screen.dart';
import '../ui/kh_guessing_page.dart';
import '../ui/meal_review_screen.dart';

class AppRouter {
  AppRouter(this.appContext);
  final AppContext appContext;

  Route<dynamic>? generate(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const StartScreen());
      case '/child':
        return MaterialPageRoute(builder: (_) => const ChildHomeScreen());
      case '/parent':
        return MaterialPageRoute(builder: (_) => const ParentScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/setup':
        return MaterialPageRoute(builder: (_) => const SetupWizard());
      case '/profile_select':
        return MaterialPageRoute(builder: (_) => const AvatarScreen());
      case '/guess':
        return MaterialPageRoute(builder: (_) => const KhGuessingPage());
      case '/meal_review':
        return MaterialPageRoute(builder: (_) => const MealReviewScreen());
      default:
        return null;
    }
  }
}
