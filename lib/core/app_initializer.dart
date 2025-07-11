// lib/core/app_initializer.dart
//
// v8 – FINAL CONTEXT MATCHED
// ----------------------------------------------------------------
// • Synchronisiert mit app_context.dart (v1)
// • Erstellt alle Dienste und gibt vollständigen AppContext zurück
// • Unterstützt Standalone- & Plugin-Modus via AppFlavor
//
// © 2025 Kids Diabetes Companion – GPL-3.0-or-later

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'app_flavor.dart';
import 'event_bus.dart';
import 'app_context.dart';

import '../services/aaps_bridge.dart';
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
import '../services/recommendation_history_service.dart';
import '../services/communication_service.dart';
import '../services/alarm_manager.dart';

class AppInitializer {
  AppInitializer._();

  static Future<AppContext> init({required AppFlavor flavor}) async {
    // 1 | SQLite initialisieren
    final dbPath = p.join(await getDatabasesPath(), 'kidsapp_${flavor.name}.db');
    final db = await openDatabase(dbPath, version: 1);

    // 2 | EventBus + PluginBridge
    await AppEventBus.init(flavor);
    final bus = AppEventBus.I;

    // 3 | Settings laden
    final settings = await SettingsService.create();

    // 4 | AAPSBridge starten
    final aapsBridge = AAPSBridge(bus.bus);

    // 5 | Services initialisieren
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
    await RecommendationHistoryService.i.init();
    await CommunicationService.init(flavor);
    await AlarmManager.I.init(flavor);

    return AppContext(
      flavor: flavor,
      db: db,
      bus: bus,
      settings: settings,
      aapsBridge: aapsBridge,
      pushService: PushService.instance,
      smsService: SmsService.instance,
      avatarService: AvatarService.I,
      gamificationService: GamificationService.instance,
      gptService: GptService.I,
      imageInputService: ImageInputService.instance,
      speechService: SpeechService.instance,
      nightscoutService: NightscoutService.instance,
      mealAnalyzer: MealAnalyzer.I,
      carbSync: AapsCarbSyncService.I,
      recommendationHistoryService: RecommendationHistoryService.i,
      communicationService: CommunicationService.I,
      alarmManager: AlarmManager.I,
    );
  }
}
