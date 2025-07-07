/*
 *  alarm_manager.dart  (v1.1 – FIXED)
 *  --------------------------------------------------------------
 *  Globale Alarm‑Engine
 *   • Subscribt auf AppEventBus
 *   • Erstellt Local‑Notification, Vibration, Sound
 *   • Plugin‑Modus: ruft AAPS‑Alarm via Plattform‑Channel auf
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:just_audio/just_audio.dart';

import '../core/event_bus.dart';
import '../core/app_initializer.dart';
import '../events/app_events.dart';
import 'settings_service.dart';

enum AlarmLevel { normal, critical }

class AlarmManager {
  AlarmManager._();
  static final AlarmManager I = AlarmManager._();

  static const MethodChannel _pluginCh =
  MethodChannel('kidsapp/alarm_bridge'); // AAPS‑Alarm

  final _localNoti = FlutterLocalNotificationsPlugin();
  final _player = AudioPlayer();
  late StreamSubscription _sub;

  /// Initialisierung in [AppInitializer]
  Future<void> init(AppFlavor flavor) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    await _localNoti.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );

    _sub = AppEventBus.I.bus.on<AppEvent>().listen(_onEvent);

    await _player.setAsset('assets/sounds/alarm.mp3');

    AppEventBus.I.bus.on<GenericAapsEvent>().listen((e) {
      if (e.nativeType == 'OnStopAlarms') _stopAlarm();
    });
  }

  void dispose() => _sub.cancel();

  /* ---------------- Event Listener ---------------- */

  Future<void> _onEvent(AppEvent e) async {
    switch (e.runtimeType) {
      case MealWarningEvent:
        await fireAlarm(
          title: '⚠️ Hohe KH‑Menge',
          body: 'Bitte Bolus prüfen!',
          level: AlarmLevel.critical,
        );
        break;
      case PointsChangedEvent:
        final ev = e as PointsChangedEvent;
        if (ev.newPoints % 100 == 0) {
          await fireAlarm(
            title: '🎉 Level‑Up',
            body: 'Du hast ${ev.newPoints} Punkte erreicht!',
            level: AlarmLevel.normal,
          );
        }
        break;
      case AvatarItemPreviewEvent:
        await fireAlarm(
          title: '🔓 Neues Avatar‑Item!',
          body: 'Schau dir dein Upgrade an.',
          level: AlarmLevel.normal,
          silent: true,
        );
        break;
      case ImageInputFailedEvent:
      case SpeechInputFailedEvent:
        await fireAlarm(
          title: '⚠️ Eingabe fehlgeschlagen',
          body: 'Bitte noch einmal versuchen.',
          level: AlarmLevel.normal,
        );
        break;
      default:
        break;
    }
  }

  /* ---------------- Öffentliche API ---------------- */

  Future<void> fireAlarm({
    required String title,
    required String body,
    AlarmLevel level = AlarmLevel.normal,
    bool silent = false,
  }) async {
    final flavor = SettingsService.I.flavor;
    if (flavor == AppFlavor.plugin) {
      try {
        await _pluginCh.invokeMethod('fireAlarm', {
          'title': title,
          'body': body,
          'level': level.name,
          'silent': silent,
        });
        return;
      } catch (_) {/* fallback */}
    }

    await _showLocalNotification(title, body, level, silent);

    if (!silent) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 400, 300, 400]);
      }
      await _playSound();
    }
  }

  Future<void> _showLocalNotification(
      String title,
      String body,
      AlarmLevel level,
      bool silent,
      ) async {
    final android = AndroidNotificationDetails(
      'kidsapp_alarm',
      'Alarme',
      importance:
      level == AlarmLevel.critical ? Importance.max : Importance.high,
      priority:
      level == AlarmLevel.critical ? Priority.max : Priority.high,
      playSound: !silent,
      enableVibration: !silent,
      channelShowBadge: false,
      fullScreenIntent: level == AlarmLevel.critical,
      visibility: NotificationVisibility.public,
    );
    final iOS = DarwinNotificationDetails(
      presentSound: !silent,
      presentAlert: true,
      presentBadge: false,
    );
    await _localNoti.show(
      0,
      title,
      body,
      NotificationDetails(android: android, iOS: iOS),
    );
  }

  Future<void> _playSound() async {
    try {
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (_) {/* ignore */}
  }

  Future<void> _stopAlarm() async {
    await _player.stop();
    await _localNoti.cancelAll();
  }
}
