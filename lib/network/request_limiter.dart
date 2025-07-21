/// --------------------------------------------------------------------------
///  request_limiter.dart  (v1 – Core‑Engine)
/// --------------------------------------------------------------------------
///  • FIFO‑Queue zur Begrenzung paralleler Request‑Ausführung
///  • Nutzung über: `schedule(() async => ...)`
///  • Kein Rückgabewert – Job muss intern mit Completer<T> arbeiten, wenn nötig.
///  • Fehler im Job müssen intern behandelt werden – kein catch hier!
/// --------------------------------------------------------------------------
library;

import 'dart:async';
import 'dart:collection';
import 'package:synchronized/synchronized.dart';

class RequestLimiter {
  /// Mindestabstand zwischen zwei Jobs.
  final Duration interval;

  /// Lock zur Vermeidung paralleler Jobs.
  final Lock _lock = Lock();

  /// Warteschlange aller geplanten Jobs.
  final Queue<Future Function()> _queue = Queue<Future Function()>();

  bool _running = false;

  RequestLimiter(this.interval);

  /// Fügt einen neuen Job zur Queue hinzu.
  void schedule(Future Function() job) {
    _queue.add(job);
    _run();
  }

  /// Interner Ablauf der Warteschlange
  Future<void> _run() async {
    if (_running) return;
    _running = true;

    try {
      while (_queue.isNotEmpty) {
        await _lock.synchronized(() async {
          final job = _queue.removeFirst();
          await job();
          await Future.delayed(interval);
        });
      }
    } finally {
      _running = false;
      if (_queue.isNotEmpty) _run(); // Re-trigger bei Nachzüglern
    }
  }
}
