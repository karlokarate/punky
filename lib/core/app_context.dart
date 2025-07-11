import 'package:event_bus/event_bus.dart';
import 'package:sqflite/sqflite.dart';

import '../services/aaps_carb_sync_service.dart';
import '../services/aaps_logic_port.dart'; // for AAPSBridge placeholder
import '../services/alarm_manager.dart';
import '../services/avatar_service.dart';
import '../services/background_service.dart'; // not used maybe
import '../services/communication_service.dart';
import '../services/gamification_service.dart';
import '../services/gpt_service.dart';
import '../services/image_input_service.dart';
import '../services/nightscout_service.dart';
import '../services/push_service.dart';
import '../services/recommendation_history_service.dart';
import '../services/settings_service.dart';
import '../services/sms_service.dart';
import '../services/speech_service.dart';
import '../services/meal_analyzer.dart';

import 'app_flavor.dart';
import 'event_bus.dart';

/// Central container for all globally accessible services.
class AppContext {
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
    required this.recommendationHistoryService,
    required this.communicationService,
    required this.alarmManager,
  });

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
  final RecommendationHistoryService recommendationHistoryService;
  final CommunicationService communicationService;
  final AlarmManager alarmManager;
}

/// Global reference set in [AppInitializer].
late AppContext appCtx;
