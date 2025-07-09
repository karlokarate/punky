import 'package:rate_limiter/rate_limiter.dart';

/// Globale Instanz für alle externen HTTP-Aufrufe.
/// Konfig: 1 Request alle 30 s (Burst-Größe 1).
class ApiRateLimiter {
  static final ApiRateLimiter I = ApiRateLimiter._();
  late final RateLimiter _limiter;

  ApiRateLimiter._() {
    _limiter = RateLimiter(const Duration(seconds: 30), 1);
  }

  /// Führt [fn] erst aus, wenn mindestens ein Token verfügbar ist.
  /// Gibt das Ergebnis von [fn] zurück.
  Future<T> exec<T>(Future<T> Function() fn) => _limiter.schedule(fn);
}
