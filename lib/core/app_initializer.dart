// lib/core/app_initializer.dart
//
// v7 – Hintergrunddienste explizit initialisiert
// --------------------------------------------------------------
// Initialisiert AppContext und alle Services asynchron beim App-Start
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'package:sqflite/sqflite.dart';
import '../core/app_context.dart';
import '../core/app_flavor.dart';
import '../core/event_bus.dart';
import '../services/settings_service.dart';
import '../services/avatar_service.dart';
import '../services/gamification_service.dart';
import '../services/image_input_service.dart';
import '../services/speech_service.dart';
import '../services/nightscout_service.dart';
import '../services/recommendation_history_service.dart';
import '../services/communication_service.dart';
import '../services/bolus_engine.dart';
import '../services/sms_service.dart';
import '../services/gpt_service.dart';
import '../services/meal_analyzer.dart';
import '../services/aaps_bridge.dart';
import '../services/background_service.dart';
import '../services/fcm_service.dart';
import '../services/push_service.dart';
import '../services/aaps_carb_sync_service.dart';

/// Initialisiert den globalen [AppContext] und alle abhängigen Services.
/// Muss beim App-Start einmalig aufgerufen werden.
Future<AppContext> initializeApp(AppFlavor flavor) async {
  // Öffne die lokale SQLite-Datenbank
  final Database db = await openDatabase('punky.db');

  // Initialisiere SettingsService (Singleton, lädt Einstellungen)
  final settings = await SettingsService.create();

  // Initialisiere EventBus für globale Events (vor allen Listeners!)
  await AppEventBus.init(flavor);

  // Initialisiere alle weiteren Services als Singletons mit ihren jeweiligen Methoden
  await AvatarService.I.init(AppEventBus.I.raw);
  await GamificationService.instance.init();
  await ImageInputService.instance.init(AppEventBus.I.raw);
  await SpeechService.instance.init(AppEventBus.I.raw);
  await NightscoutService.instance.init(SettingsService.I);
  await RecommendationHistoryService.i.init();
  await CommunicationService.init(flavor);
  await SmsService.instance.init();
  await GptService.I.init(AppEventBus.I.raw);
  await MealAnalyzer.init(db);
  await AapsCarbSyncService.init(flavor);
  await PushService.instance.init(AppEventBus.I.raw);

  // BolusEngine ist lazy, keine explizite Init nötig
  final bolusEngine = BolusEngine.I;

  // Weitere optionale Services (sofern benötigt)
  final aapsBridge = AAPSBridge(AppEventBus.I.raw);

  // Erstelle AppContext mit allen Services
  final context = AppContext(
    flavor: flavor,
    db: db,
    bus: AppEventBus.I.raw,
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
    bolusEngine: bolusEngine,
  );

  // Hintergrunddienste explizit initialisieren
  await BackgroundService.init(flavor);
  await FcmService.instance.init();

  return context;
}