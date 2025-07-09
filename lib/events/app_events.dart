/*
 *  app_events.dart  (v7 – MERGED FINAL)
 *  --------------------------------------------------------------------------
 *  • Vereint alle bisherigen App‑/Sync‑Event‑Klassen (v6) mit den neuen
 *    Parent‑/GPT‑Events, die der Nightscout‑Service und der Parent‑Screen
 *    verwenden.
 *  • Jede Klasse erbt von [AppEvent] und implementiert [toJson()], damit sie
 *    weiterhin über die AAPS‑Bridge serialisierbar ist.
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

/* ------------------------------------------------------------------------- */
/*  Basis ‑ Root Event                                                       */
/* ------------------------------------------------------------------------- */
abstract class AppEvent {
  Map<String, dynamic> toJson();
}

/* ------------------------------------------------------------------------- */
/*  Navigation Events                                                        */
/* ------------------------------------------------------------------------- */
enum NavTarget {
  start,
  childHome,
  parentHome,
  settings,
  addMeal,
  addSnack,
  history,
  avatar,
  guess,
  meal,
  snack,
  imageInput,
  imagePreview,
  imageResult,
  imageError,
  imageInputFinished,
  imageInputStarted,
  imageInputCanceled,
  imageInputFailed,
  imageInputError,
  imageInputWarning,
  imageInputInfo,
  imageInputDebug,
  imageInputTrace,
  imageInputFatal,
  imageInputErrorEvent,
  imageInputWarningEvent,
  imageInputInfoEvent,
  imageInputDebugEvent,
  imageInputTraceEvent,
  imageInputFatalEvent,
  imageInputErrorEvent2,
  imageInputWarningEvent2,
  imageInputInfoEvent2,
  imageInputDebugEvent2,
  imageInputTraceEvent2,
  imageInputFatalEvent2,
  imageInputErrorEvent3
}

class AppNavigationEvent extends AppEvent {
  final NavTarget target;
  AppNavigationEvent(this.target);
  @override
  Map<String, dynamic> toJson() => {'target': target.name};
}

/* ------------------------------------------------------------------------- */
/*  Meal / Analyzer Events                                                   */
/* ------------------------------------------------------------------------- */
class MealAnalyzedEvent extends AppEvent {
  final double totalCarbs;
  final List<Map<String, dynamic>> components;
  MealAnalyzedEvent({required this.totalCarbs, required this.components});
  @override
  Map<String, dynamic> toJson() =>
      {'totalCarbs': totalCarbs, 'components': components};
}

class MealWarningEvent extends AppEvent {
  final List<String> warnings;
  MealWarningEvent({required this.warnings});
  @override
  Map<String, dynamic> toJson() => {'warnings': warnings};
}

/* ------------------------------------------------------------------------- */
/*  Image Input Events                                                       */
/* ------------------------------------------------------------------------- */
class ImageInputStartedEvent extends AppEvent {
  @override
  Map<String, dynamic> toJson() => {};
}

class ImageInputFinishedEvent extends AppEvent {
  final List<Map<String, dynamic>> items;
  ImageInputFinishedEvent(this.items);
  @override
  Map<String, dynamic> toJson() => {'items': items};
}

class ImageInputFailedEvent extends AppEvent {
  final String reason;
  ImageInputFailedEvent(this.reason);
  @override
  Map<String, dynamic> toJson() => {'reason': reason};
}

/* ------------------------------------------------------------------------- */
/*  Speech Input Events                                                      */
/* ------------------------------------------------------------------------- */
class SpeechInputStartedEvent extends AppEvent {
  @override
  Map<String, dynamic> toJson() => {};
}

class SpeechInputFinishedEvent extends AppEvent {
  final String transcript;
  SpeechInputFinishedEvent(this.transcript);
  @override
  Map<String, dynamic> toJson() => {'transcript': transcript};
}

class SpeechInputFailedEvent extends AppEvent {
  final String reason;
  SpeechInputFailedEvent(this.reason);
  @override
  Map<String, dynamic> toJson() => {'reason': reason};
}

/* ------------------------------------------------------------------------- */
/*  Gamification Events                                                      */
/* ------------------------------------------------------------------------- */
class PointsChangedEvent extends AppEvent {
  final int newPoints;
  PointsChangedEvent(this.newPoints);
  @override
  Map<String, dynamic> toJson() => {'points': newPoints};
}

class LevelUpEvent extends AppEvent {
  final int newLevel;
  LevelUpEvent(this.newLevel);
  @override
  Map<String, dynamic> toJson() => {'level': newLevel};
}

/* ------------------------------------------------------------------------- */
/*  Bolus Events (Analysed + Authorization)                                  */
/* ------------------------------------------------------------------------- */
class BolusCalculatedEvent extends AppEvent {
  final double carbs;
  final double units;
  final String reason;
  final bool isSafe;
  final double insulin;
  final double ratio;
  final String source;
  BolusCalculatedEvent({
    required this.carbs,
    required this.units,
    required this.reason,
    required this.isSafe,
    required this.insulin,
    required this.ratio,
    required this.source,
  });
  @override
  Map<String, dynamic> toJson() => {
    'carbs': carbs,
    'units': units,
    'reason': reason,
    'isSafe': isSafe,
    'insulin': insulin,
    'ratio': ratio,
    'source': source,
  };
}

/// Eltern‑Freigabe eines Bolus‑Vorschlags (genutzt vom Nightscout‑Service)
class BolusAuthorizationEvent extends AppEvent {
  final double units;
  BolusAuthorizationEvent(this.units);
  @override
  Map<String, dynamic> toJson() => {'units': units};
}

/* ------------------------------------------------------------------------- */
/*  Sync / Settings Events                                                   */
/* ------------------------------------------------------------------------- */
class SettingsChangedEvent extends AppEvent {
  final String key;
  final dynamic value;
  SettingsChangedEvent({required this.key, required this.value});
  @override
  Map<String, dynamic> toJson() => {'key': key, 'value': value};
}

class SnackLoggedEvent extends AppEvent {
  final double carbs;
  final DateTime time;
  SnackLoggedEvent({required this.carbs, required this.time});
  @override
  Map<String, dynamic> toJson() =>
      {'carbs': carbs, 'time': time.toIso8601String()};
}

class ParentApprovalEvent extends AppEvent {
  final String action;
  final bool approved;
  ParentApprovalEvent({required this.action, required this.approved});
  @override
  Map<String, dynamic> toJson() =>
      {'action': action, 'approved': approved};
}

class NewMealDetectedEvent extends AppEvent {
  final String source;
  NewMealDetectedEvent({required this.source});
  @override
  Map<String, dynamic> toJson() => {'source': source};
}

/* ------------------------------------------------------------------------- */
/*  Avatar Events                                                            */
/* ------------------------------------------------------------------------- */
abstract class AvatarEvent extends AppEvent {}

class AvatarCelebrateEvent extends AvatarEvent {
  @override
  Map<String, dynamic> toJson() => {};
}

class AvatarSadEvent extends AvatarEvent {
  @override
  Map<String, dynamic> toJson() => {};
}

class AvatarItemPreviewEvent extends AvatarEvent {
  final String itemKey;
  AvatarItemPreviewEvent(this.itemKey);
  @override
  Map<String, dynamic> toJson() => {'itemKey': itemKey};
}

/* ------------------------------------------------------------------------- */
/*  Parent / Log Events (NEU)                                                */
/* ------------------------------------------------------------------------- */
class ParentLogEvent extends AppEvent {
  final String message;
  final DateTime timestamp;
  ParentLogEvent({required this.message, required this.timestamp});

  factory ParentLogEvent.fromTreatment(Map<String, dynamic> t) {
    final ts = DateTime.parse(t['created_at'] as String);
    final msg = t['eventType'] == 'Carb Correction'
        ? 'KH ${t['carbs']} g eingegeben'
        : t['eventType'] == 'Bolus'
        ? 'Bolus ${t['insulin']} U'
        : t['eventType'];
    return ParentLogEvent(message: msg, timestamp: ts);
  }

  @override
  Map<String, dynamic> toJson() =>
      {'message': message, 'timestamp': timestamp.toIso8601String()};
}

/* ------------------------------------------------------------------------- */
/*  GPT Recommendation Event (NEU)                                           */
/* ------------------------------------------------------------------------- */
class GPTRecommendationEvent extends AppEvent {
  final dynamic result; // z. B. GPTAnalysisResult
  GPTRecommendationEvent(this.result);
  @override
  Map<String, dynamic> toJson() => {'result': result};
}

/// Neue Nightscout-Analyse mit Empfehlungen steht bereit.
class NightscoutAnalysisAvailableEvent extends AppEvent {
  final List<Map<String, dynamic>> recommendations;
  NightscoutAnalysisAvailableEvent(this.recommendations);
  @override
  Map<String, dynamic> toJson() => {'recommendations': recommendations};
}

/* ------------------------------------------------------------------------- */
/*  Fallback für unbekannte Native‑Events                                    */
/* ------------------------------------------------------------------------- */
class GenericAapsEvent extends AppEvent {
  final String nativeType;
  final Map<String, dynamic> payload;
  GenericAapsEvent(this.nativeType, this.payload);
  @override
  Map<String, dynamic> toJson() => payload;
}

/* ------------------------------------------------------------------------- */
/*  Factory‑Helper – wandelt Native ↔︎ Dart‑Events                           */
/* ------------------------------------------------------------------------- */
class AppEventFactory {
  static AppEvent fromNative(String type, Map<String, dynamic> p) {
    switch (type) {
      case 'MealAnalyzedEvent':
        return MealAnalyzedEvent(
          totalCarbs: (p['totalCarbs'] as num).toDouble(),
          components:
          (p['components'] as List).cast<Map<String, dynamic>>(),
        );

      case 'BolusCalculatedEvent':
        return BolusCalculatedEvent(
          carbs: (p['carbs'] as num).toDouble(),
          units: (p['units'] as num).toDouble(),
          reason: p['reason'] ?? '',
          isSafe: p['isSafe'] == true,
          insulin: (p['insulin'] as num).toDouble(),
          ratio: (p['ratio'] as num).toDouble(),
          source: p['source'] ?? '',
        );

      case 'ParentLogEvent':
        return ParentLogEvent(
          message: p['message'] ?? '',
          timestamp: DateTime.parse(p['timestamp']),
        );

      case 'BolusAuthorizationEvent':
        return BolusAuthorizationEvent(
          (p['units'] as num).toDouble(),
        );

      case 'GPTRecommendationEvent':
        return GPTRecommendationEvent(p['result']);

      case 'NightscoutAnalysisAvailableEvent':
        return NightscoutAnalysisAvailableEvent(
            List<Map<String, dynamic>>.from(p['recommendations'] ?? []));

      default:
        return GenericAapsEvent(type, p);
    }
  }
}
