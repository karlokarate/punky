import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import '../services/settings_service.dart';
import '../events/app_events.dart';
import '../core/event_bus.dart';

typedef JobLogger = void Function(String channel, DateTime timestamp);

class RequestLimiter {
  Duration interval;
  final String channel;
  final Lock _lock = Lock();
  final Queue<Future Function()> _queue = Queue();
  final JobLogger? logger;
  final int? maxQueueLength;
  bool _running = false;

  RequestLimiter(this.channel, this.interval, {this.logger, this.maxQueueLength});

  void updateInterval(Duration newInterval) {
    interval = newInterval;
    debugPrint('🔁 [$channel] Limiter-Intervall aktualisiert auf ${interval.inSeconds}s');
  }

  void schedule(Future Function() job) {
    if (maxQueueLength != null && _queue.length >= maxQueueLength!) {
      debugPrint('⚠️ $channel-Limiter: Queue überfüllt (${_queue.length})');
    }
    _queue.add(job);
    _run();
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;

    try {
      while (_queue.isNotEmpty) {
        await _lock.synchronized(() async {
          final job = _queue.removeFirst();
          try {
            await job();
            logger?.call(channel, DateTime.now());
          } catch (e, st) {
            debugPrint('❌ Fehler im Job ($channel): $e\n$st');
          }
          await Future.delayed(interval);
        });
      }
    } finally {
      _running = false;
      if (_queue.isNotEmpty) _run();
    }
  }
}

class GlobalRateLimiter {
  static final GlobalRateLimiter I = GlobalRateLimiter._();

  final Map<String, RequestLimiter> _limiters = {};
  final SettingsService _settings = SettingsService.I;

  GlobalRateLimiter._() {
    _initWithSettings();
    _listenToSettingsChanges();
  }

  void _initWithSettings() {
    _limiters['nightscout'] = RequestLimiter(
      'nightscout',
      Duration(seconds: _settings.rateLimitNightscout),
      logger: _logJob,
    );

    _limiters['gpt'] = RequestLimiter(
      'gpt',
      Duration(seconds: _settings.rateLimitGpt),
      logger: _logJob,
    );

    _limiters['sms'] = RequestLimiter(
      'sms',
      Duration(seconds: _settings.rateLimitSms),
      logger: _logJob,
      maxQueueLength: 5,
    );

    _limiters['push'] = RequestLimiter(
      'push',
      Duration(seconds: _settings.rateLimitPush),
      logger: _logJob,
    );
  }

  void _listenToSettingsChanges() {
    eventBus.on<SettingsChangedEvent>().listen((e) {
      final channelMap = {
        'kidsapp_rate_ns': 'nightscout',
        'kidsapp_rate_gpt': 'gpt',
        'kidsapp_rate_sms': 'sms',
        'kidsapp_rate_push': 'push',
      };

      final channel = channelMap[e.key];
      if (channel != null && e.value is int) {
        final limiter = _limiters[channel];
        limiter?.updateInterval(Duration(seconds: e.value));
      }
    });
  }

  Future<T> exec<T>(String channel, Future<T> Function() job) {
    final limiter = _limiters[channel];
    if (limiter == null) {
      debugPrint('❌ Kein Limiter für "$channel" registriert');
      throw ArgumentError('No limiter configured for "$channel"');
    }

    final completer = Completer<T>();
    limiter.schedule(() async {
      try {
        final result = await job();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });

    return completer.future;
  }

  void schedule(String channel, Future Function() job) {
    final limiter = _limiters[channel];
    if (limiter == null) {
      debugPrint('❌ Kein Limiter für "$channel" registriert');
      throw ArgumentError('No limiter configured for "$channel"');
    }
    limiter.schedule(job);
  }

  void _logJob(String channel, DateTime timestamp) {
    debugPrint('✅ [$channel] Job ausgeführt um ${timestamp.toIso8601String()}');
  }
}
