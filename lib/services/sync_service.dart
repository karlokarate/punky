// lib/services/sync_service.dart
//
// v3 – FINAL BRIDGE READY
// --------------------------------------------------------------
// Synchronisiert lokale Events via PushService (SMS/FCM/Bridge)
// • Settings, Snacks, Parent-Approvals
// • Optional: REST-Sync an API (einstellbar)
// • EventRouter für Remote-Events
//
// © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:event_bus/event_bus.dart';

import '../core/event_bus.dart';
import '../events/app_events.dart';
import '../services/push_service.dart';

final EventBus eventBus = AppEventBus.I.raw;

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _serverUrl = "https://mein-server.de/api/sync"; // optional extern

  bool _initialized = false;

  /// Initialisiert Listener für Events → Push-Sync
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    eventBus.on<SettingsChangedEvent>().listen((event) {
      _syncLocally('settings', {
        'key': event.key,
        'value': event.value,
      });
    });

    eventBus.on<SnackLoggedEvent>().listen((event) {
      _syncLocally('snack', {
        'carbs': event.carbs,
        'time': event.time.toIso8601String(),
      });
    });

    eventBus.on<ParentApprovalEvent>().listen((event) {
      _syncLocally('approval', {
        'action': event.action,
        'approved': event.approved,
      });
    });
  }

  /// Lokaler Sync (Push über AAPSBridge, FCM, SMS oder Queue)
  Future<void> _syncLocally(String type, Map<String, dynamic> payload) async {
    final msg = PushMessage(
      title: 'Sync',
      body: type,
      data: {
        'type': type,
        ...payload,
      },
    );
    await PushService.instance.send(msg);
  }

  /// REST-Sync an zentralen API-Endpunkt
  Future<void> syncToServer(String type, Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'type': type,
          'payload': payload,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ Sync fehlgeschlagen [$type]: ${response.body}');
      } else {
        debugPrint('✅ Sync erfolgreich [$type]');
      }
    } catch (e) {
      debugPrint('❗ Sync Fehler: $e');
    }
  }

  /// Führt empfangene Events (vom Server/anderen Geräten) lokal aus
  void receiveRemoteEvent(String type, Map<String, dynamic> payload) {
    switch (type) {
      case 'settings':
        if (payload.containsKey('key') && payload.containsKey('value')) {
          eventBus.fire(SettingsChangedEvent(
            key: payload['key'],
            value: payload['value'],
          ));
        }
        break;

      case 'snack':
        if (payload.containsKey('carbs') && payload.containsKey('time')) {
          eventBus.fire(SnackLoggedEvent(
            carbs: payload['carbs'],
            time: DateTime.parse(payload['time']),
          ));
        }
        break;

      case 'approval':
        if (payload.containsKey('action') && payload.containsKey('approved')) {
          eventBus.fire(ParentApprovalEvent(
            action: payload['action'],
            approved: payload['approved'],
          ));
        }
        break;

      default:
        debugPrint('⚠️ Unbekannter Event-Typ vom Server: $type');
    }
  }
}
