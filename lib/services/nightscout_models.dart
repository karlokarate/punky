// lib/services/nightscout_models.dart
//
// v3 – FINAL BRIDGE READY
// --------------------------------------------------------------
// • DTOs für Nightscout-Glukose, Behandlungen & Geräte-Status
// • Unterstützt toJson(), Upload, Bridge-Kommunikation
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'package:meta/meta.dart';

@immutable
class GlucoseEntry {
  final DateTime time;
  final double value;
  final int? trend;

  const GlucoseEntry({required this.time, required this.value, this.trend});

  factory GlucoseEntry.fromJson(Map<String, dynamic> json) {
    final rawTime = json['dateString'] ?? json['date'] ?? json['dateTime'];
    return GlucoseEntry(
      time: DateTime.parse(rawTime as String),
      value: (json['sgv'] as num?)?.toDouble() ?? 0,
      trend: (json['trend'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'dateString': time.toIso8601String(),
    'sgv': value,
    if (trend != null) 'trend': trend,
  };

  DateTime get date => time;
  double get sgv => value;

  static List<GlucoseEntry> listFromJson(List<dynamic> list) =>
      list.map((e) => GlucoseEntry.fromJson(e)).toList();
}

@immutable
class Treatment {
  final String type;
  final double amount;
  final DateTime time;
  final Map<String, dynamic> raw;

  const Treatment({
    required this.type,
    required this.amount,
    required this.time,
    required this.raw,
  });

  factory Treatment.fromJson(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(json);
    return Treatment(
      type: json['eventType'] as String,
      amount: (json['insulin'] ?? json['carbs'] ?? 0).toDouble(),
      time: DateTime.parse(json['created_at'] as String),
      raw: raw,
    );
  }

  Map<String, dynamic> toJson() => {
    'eventType': type,
    'amount': amount,
    'time': time.toIso8601String(),
    'raw': raw,
  };

  Map<String, dynamic> toUploadJson() {
    final json = <String, dynamic>{
      'eventType': type,
      'created_at': time.toIso8601String(),
      'enteredBy': 'kidsapp',
    };
    if (type.toLowerCase().contains('bolus')) {
      json['insulin'] = amount;
    }
    if (type.toLowerCase().contains('carb')) {
      json['carbs'] = amount;
    }
    return json;
  }

  static List<Treatment> listFromJson(List<dynamic> list) =>
      list.map((e) => Treatment.fromJson(e)).toList();
}

@immutable
class DeviceStatus {
  final DateTime time;
  final int uploaderBattery;
  final int pumpBattery;
  final Duration? podTimeLeft;
  final Duration? reservoirTimeLeft;
  final double? iob;
  final double? cob;

  const DeviceStatus({
    required this.time,
    required this.uploaderBattery,
    required this.pumpBattery,
    this.podTimeLeft,
    this.reservoirTimeLeft,
    this.iob,
    this.cob,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    Duration? parseDuration(dynamic v, String key) {
      if (v == null) return null;
      if (key == 'reservoir') {
        final hours = (v['Clock'] as num?)?.toDouble();
        if (hours != null) return Duration(hours: hours.floor());
      }
      if (key == 'pod') {
        final min = (v['minutesRemaining'] as num?)?.toInt();
        if (min != null) return Duration(minutes: min);
      }
      return null;
    }

    final dev = json;
    final pumpObj = dev['pump'] as Map<String, dynamic>? ?? {};

    final durationReservoir = parseDuration(pumpObj['reservoir'], 'reservoir');
    final durationPod = parseDuration(pumpObj['pod'], 'pod');

    return DeviceStatus(
      time: DateTime.parse(dev['created_at'] as String),
      uploaderBattery: (dev['uploaderBattery'] as num?)?.toInt() ?? 0,
      pumpBattery: ((pumpObj['battery']?['percent']) as num?)?.toInt() ?? 0,
      reservoirTimeLeft: durationReservoir,
      podTimeLeft: durationPod,
      iob: (dev['iob'] as num?)?.toDouble(),
      cob: (dev['cob'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'created_at': time.toIso8601String(),
      'uploaderBattery': uploaderBattery,
      'pumpBattery': pumpBattery,
      'iob': iob,
      'cob': cob,
    };
    if (podTimeLeft != null) json['pod'] = podTimeLeft!.inMinutes;
    if (reservoirTimeLeft != null) json['reservoir'] = reservoirTimeLeft!.inHours;
    return json;
  }

  bool get isLoopValid => (iob ?? 0) > 0 || (cob ?? 0) > 0;
}
