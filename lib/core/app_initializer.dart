/*
 *  app_initializer.dart  (v4 – FINAL)
 *  --------------------------------------------------------------
 *  Boot‑Strap mit neuem AppEventBus.
 *
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
    /* 1 | SQLite */
    final dbPath = p.join(await getDatabasesPath(), 'kidsapp_${flavor.name}.db');
    final db = await openDatabase(dbPath, version: 1);

    /* 2 | EventBus (inkl. Plugin‑Bridge) */
    await AppEventBus.init(flavor);
    final bus = AppEventBus.I;

    /* 3 | Settings */
    await SettingsService.init(flavor);
    final settings = SettingsService.I;

    /* 4 | Services */
    await PushService.instance.init(bus.bus);
    await SmsService.instance.init();

    final avatar = AvatarService.I;
    await avatar.init();
    avatar.attachEventBus(bus.bus);

    await GamificationService.instance.init();
    await GptService.I.init(bus.bus);
    await ImageInputService.instance.init(bus.bus);
    await SpeechService.instance.init(bus.bus);

    return AppContext(
      flavor: flavor,
      db: db,
      bus: bus,
      settings: settings,
    );
  }
}
