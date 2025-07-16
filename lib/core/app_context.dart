// lib/core/app_context.dart
//
// v4 – FINAL
// --------------------------------------------------------------
// Globaler AppContext mit Zugriff auf Services und globale State-Objekte
// Wird durch app_initializer.dart befüllt
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import '../core/app_flavor.dart';
import '../services/aaps_bridge.dart';
import '../services/avatar_service.dart';
import '../services/bolus_engine.dart';
import '../services/aaps_carb_sync_service.dart';
import '../services/communication_service.dart';

import '../services/gamification_service.dart';
import '../services/gpt_service.dart';
import '../services/image_input_service.dart';
import '../services/meal_analyzer.dart';
import '../services/nightscout_service.dart';
import '../services/push_service.dart';
import '../services/recommendation_history_service.dart';
import '../services/settings_service.dart';
import '../services/sms_service.dart';
import '../services/speech_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:event_bus/event_bus.dart';


class AppContext {
  final AppFlavor flavor;
  final Database db;
  final EventBus bus;
  final SettingsService settings;
  final AAPSBridge aapsBridge;
  final PushService pushService;
  final SmsService smsService; // Korrigiert
  final AvatarService avatarService;
  final GamificationService gamificationService;
  final GptService gptService; // Korrigiert
  final ImageInputService imageInputService;
  final SpeechService speechService;
  final NightscoutService nightscoutService;
  final MealAnalyzer mealAnalyzer;
  final AapsCarbSyncService carbSync; // Korrigiert
  final RecommendationHistoryService recommendationHistoryService;
  final CommunicationService communicationService;
  final BolusEngine bolusEngine;

  const AppContext({
    required this.flavor,
    required this.db,
    required this.bus,
    required this.settings,
    required this.aapsBridge,
    required this.pushService,
    required this.smsService, // Korrigiert
    required this.avatarService,
    required this.gamificationService,
    required this.gptService, // Korrigiert
    required this.imageInputService,
    required this.speechService,
    required this.nightscoutService,
    required this.mealAnalyzer,
    required this.carbSync, // Korrigiert
    required this.recommendationHistoryService,
    required this.communicationService,
    required this.bolusEngine,
  });
}