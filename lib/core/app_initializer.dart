/*
 *  app_initializer.dart  (v6 – Bootstrapping erweitert)
 *  --------------------------------------------------------------
 *  • SettingsService & NightscoutService mit init()
 *  • Alle Dienste mit expliziter Init-Logik eingebunden
 *  • Zentrale AppContext-Rückgabe
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'event_bus.dart';
import '../services/settings_service.dart';
import '../services/push_service.dart';
import '../services/sms_service.dart';
import '../services/avatar_service.dart';
import '../services/gamification_service.dart';
import '../services/gpt_service.dart';
import '../services/image_input_service.dart';
import '../services/speech_service.dart';
import '../services/aaps_carb_sync_service.dart';
import '../services/meal_analyzer.dart';
import '../services/nightscout_service.dart';

enum AppFlavor { standalone, plugin }

class AppContext {
  final AppFlavor flavor;
  final Database db;
  final AppEventBus bus;
  final SettingsService settings;

  const AppContext({
    required this.flavor,
    required this.db,
    required this.bus,
    required this.settings,
  });
}

class AppInitializer {
  AppInitializer._();

  static Future<AppContext> init({required AppFlavor flavor}) async {
    // 1 | SQLite
    final dbPath = p.join(await getDatabasesPath(), 'kidsapp_${flavor.name}.db');
    final db = await openDatabase(dbPath, version: 1);

    // 2 | EventBus (inkl. Plugin‑Bridge)
    await AppEventBus.init(flavor);
    final bus = AppEventBus.I;

    // 3 | Settings vorbereiten
    final settings = await SettingsService.create();

    // 4 | Services initialisieren
    await PushService.instance.init(bus.bus);
    await SmsService.instance.init();
    await AvatarService.I.init(bus.bus);
    await GamificationService.instance.init();
    await GptService.I.init(bus.bus);
    await ImageInputService.instance.init(bus.bus);
    await NightscoutService.instance.init(settings);
    await AapsCarbSyncService.init(flavor);
    await MealAnalyzer.init(db);
    await SpeechService.instance.init(bus.bus);

    return AppContext(
      flavor: flavor,
      db: db,
      bus: bus,
      settings: settings,
    );
  }
}
