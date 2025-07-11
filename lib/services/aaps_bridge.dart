import 'package:event_bus/event_bus.dart';
import 'package:flutter/services.dart';

/// Minimal bridge to the native AAPS implementation.
class AAPSBridge {
  AAPSBridge(this.bus);

  final EventBus bus;

  /// Public channel for method calls.
  static const MethodChannel channel = MethodChannel('kidsapp/aaps');

  Future<void> sendCarbEntry({
    required double carbs,
    required DateTime time,
    required String note,
  }) async {
    await channel.invokeMethod('sendCarbEntry', {
      'carbs': carbs,
      'time': time.toIso8601String(),
      'note': note,
    });
  }

  Future<double?> getInsulinRatio() async {
    final ratio = await channel.invokeMethod<double>('getInsulinRatio');
    return ratio;
  }

  Future<void> invokeAlarm({
    required String title,
    required String body,
    required String level,
    bool silent = false,
  }) async {
    await channel.invokeMethod('invokeAlarm', {
      'title': title,
      'body': body,
      'level': level,
      'silent': silent,
    });
  }
}
