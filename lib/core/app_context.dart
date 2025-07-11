// lib/core/app_context.dart
//
// v1 – FINAL SYNCED CONTEXT
// --------------------------------------------------------------
// Enthält zentralen Zugriff auf alle initialisierten Dienste
// Wird vom AppInitializer erzeugt und übergeben
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'package:event_bus/event_bus.dart';
import 'package:sqflite/sqflite.dart';

import 'app_flavor.dart';
import 'event_bus.dart';
import '../services/settings_service.dart';
import '../services/aaps_bridge.dart';
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

class AppContext {
  final AppFlavor flavor;
  final Database db;
  final AppEventBus bus;

  final SettingsService settings;
  final AAPSBridge aapsBridge;
  final PushService pushService;
  final SmsService smsService;
  final AvatarService avatarService;
  final GamificationService gamificationService;
  final GptService gptService;
  final ImageInputService imageInputService;
  final SpeechService speechService;
  final NightscoutService nightscoutService;
  final MealAnalyzer mealAnalyzer;
  final AapsCarbSyncService carbSync;

  const AppContext({
    required this.flavor,
    required this.db,
    required this.bus,
    required this.settings,
    required this.aapsBridge,
    required this.pushService,
    required this.smsService,
    required this.avatarService,
    required this.gamificationService,
    required this.gptService,
    required this.imageInputService,
    required this.speechService,
    required this.nightscoutService,
    required this.mealAnalyzer,
    required this.carbSync,
  });

  Future<void> dispose() async {
    await aapsBridge.dispose();
    await db.close();
  }
}
