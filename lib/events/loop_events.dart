import 'app_events.dart';

/// ─────────────────── AAPS Loop Events ───────────────────
/// Diese Events erhalten Daten von AAPS via EventChannel
/// und werden über EventBus in der App verteilt.

class BGUpdatedEvent extends AppEvent {
  final double bg;
  final double slope;
  final DateTime timestamp;

  const BGUpdatedEvent({
    required this.bg,
    required this.slope,
    required this.timestamp,
  }) : super();

  @override
  Map<String, dynamic> toJson() => {
    'bg': bg,
    'slope': slope,
    'timestamp': timestamp.toIso8601String(),
  };
}

class LoopStatusEvent extends AppEvent {
  final double recommendedBolus;
  final double iob;
  final double cob;
  final String reason;

  const LoopStatusEvent({
    required this.recommendedBolus,
    required this.iob,
    required this.cob,
    required this.reason,
  }) : super();

  @override
  Map<String, dynamic> toJson() => {
    'bolus': recommendedBolus,
    'iob': iob,
    'cob': cob,
    'reason': reason,
  };
}

class CarbEntryAckEvent extends AppEvent {
  final double carbs;
  final DateTime timestamp;

  const CarbEntryAckEvent({
    required this.carbs,
    required this.timestamp,
  }) : super();

  @override
  Map<String, dynamic> toJson() => {
    'carbs': carbs,
    'timestamp': timestamp.toIso8601String(),
  };
}

class LoopWarningEvent extends AppEvent {
  final String message;

  const LoopWarningEvent(this.message) : super();

  @override
  Map<String, dynamic> toJson() => {'message': message};
}
