import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:event_bus/event_bus.dart';

import '../events/app_events.dart';
import '../core/event_bus.dart';
import 'push_service.dart';
final EventBus eventBus = AppEventBus.I.bus;

/// SyncService: synchronisiert Events lokal (Push/SMS) oder mit Server
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _serverUrl = "https://mein-server.de/api/sync"; // optional
  bool _initialized = false;

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

  /// Sendet Event als PushMessage (JSON-kompatibel) lokal oder remote
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

  /// Optionaler Cloud-Sync an API (wenn gewünscht)
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

  /// Eingehende Remote-Events lokal ausführen
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
        if (payload['action'] != null && payload['approved'] != null) {
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
