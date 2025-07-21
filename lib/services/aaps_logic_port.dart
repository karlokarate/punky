/*
 *  aaps_logic_port.dart – Gemeinsames Gateway zu AAPS‑Kernroutinen
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 *
 *  Diese Datei stellt eine Dart‑API bereit, über die Flutter‑
 *  Komponenten (Standalone UND Plugin‑Variante) die nativen AAPS‑
 *  Funktionen nutzen können.  Die Implementierung erfolgt auf der
 *  Android‑Seite in AapsLogicPort.kt via MethodChannel.
 *
 *  Wichtig: Alle Aufrufe sind asynchron, um die UI nicht zu blockieren.
 *
 *  Projektpfad: lib/services/aaps_logic_port.dart
 */

import 'package:flutter/services.dart';

/// Kanal‑Bezeichnung – MUSS identisch mit dem Namen in AapsLogicPort.kt sein.
const String _kChannelName = 'kidsapp/aaps';

/// Wrapper‑Klasse für AAPS‑Features.
class AapsLogicPort {
  static final MethodChannel _channel = const MethodChannel(_kChannelName);

  /* *********************************************************************
   *  Profil‑Abfragen
   * *********************************************************************/

  /// Liefert das aktuell aktive Profil (Basal, ISF, I:C) als JSON‑Map.
  /// Gibt `null` zurück, wenn das Profil nicht gelesen werden konnte.
  static Future<Map<String, dynamic>?> getActiveProfile() async {
    try {
      final dynamic result = await _channel.invokeMethod('getActiveProfile');
      return (result as Map<dynamic, dynamic>).cast<String, dynamic>();
    } on PlatformException {
      return null;
    }
  }

  /// Liefert den KH/Insulin-Faktor (g/IE) aus dem aktiven AAPS-Profil.
  /// Gibt `null` zurück, wenn kein Profil verfügbar oder Faktor nicht enthalten ist.
  static Future<double?> getInsulinRatio() async {
    final profile = await getActiveProfile();
    if (profile == null) return null;
    final ratio = profile['carbRatio'] ?? profile['icRatio'];
    return ratio is num ? ratio.toDouble() : null;
  }

  /* *********************************************************************
   *  IOB / COB
   * *********************************************************************/

  /// Liefert [IOB] und [COB] zum gegebenen Zeitpunkt (epoch ms).
  static Future<IobCob?> getIobCob({int? atMillis}) async {
    try {
      final Map<dynamic, dynamic> result =
      await _channel.invokeMethod('getIobCob', {
        if (atMillis != null) 'atMillis': atMillis,
      });
      return IobCob(
        iob: (result['iob'] ?? 0).toDouble(),
        cob: (result['cob'] ?? 0).toDouble(),
      );
    } on PlatformException {
      return null;
    }
  }

  /* *********************************************************************
   *  Bolus‑Empfehlung
   * *********************************************************************/

  /// Fordert eine Bolus‑Empfehlung von AAPS an.
  ///
  /// * [carbs] – Gramm KH der anstehenden Mahlzeit
  /// * [bg]    – aktueller Blutzucker (in derselben Einheit wie AAPS)
  /// * [iob]   – aktuelles Insulin‑on‑Board
  /// * [cob]   – Carbs‑on‑Board
  /// * [isMeal] – `true` = Mahlzeit‑Bolus, `false` = Korrekturbolus
  static Future<BolusRecommendation> recommendBolus({
    required double carbs,
    double? bg,
    double? iob,
    double? cob,
    bool isMeal = true,
  }) async {
    final Map<String, dynamic> args = {
      'carbs': carbs,
      'isMeal': isMeal,
      if (bg != null) 'bg': bg,
      if (iob != null) 'iob': iob,
      if (cob != null) 'cob': cob,
    };

    final Map<dynamic, dynamic> result =
    await _channel.invokeMethod('recommendBolus', args);

    return BolusRecommendation(
      bolusUnits: (result['bolusUnits'] ?? 0).toDouble(),
      isSafe: (result['isSafe'] ?? true) as bool,
      reason: (result['reason'] ?? '') as String,
    );
  }
}

/* *************************************************************************
 *  Datentransfer‑Objekte (DTO)
 * *************************************************************************/

class IobCob {
  final double iob;
  final double cob;
  const IobCob({required this.iob, required this.cob});
}

class BolusRecommendation {
  final double bolusUnits;
  final bool isSafe;
  final String reason;
  const BolusRecommendation({
    required this.bolusUnits,
    required this.isSafe,
    required this.reason,
  });
}
