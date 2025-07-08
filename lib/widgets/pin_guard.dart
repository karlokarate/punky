// lib/widgets/pin_guard.dart
//
// v2 – Eltern‑PIN‑Guard (komfortabel & performant)
//
// • Ein einziger statischer Aufruf:   `await PinGuard.require(context [, reason])`
// • Features
//   ①  Session‑Cache   – nach einer erfolgreichen Eingabe für die laufende
//      App‑Sitzung kein weiteres Prompt (bis App‑Kill).
//   ②  Local Biometrics (Face ID / Fingerprint)   – falls verfügbar, optional
//      One‑Touch‑Freischaltung vor PIN‑Eingabe.
//   ③  Falsche‑PIN‑Limit (5 Versuche) mit 30 s Cool‑Down.
//   ④  Vollständige Integration in SettingsService (parentPin).
//
// ---------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../services/settings_service.dart';

class PinGuard {
  PinGuard._();

  /* ─────────────────────  Public API  ───────────────────── */

  /// Zeigt bei Bedarf den Eltern‑PIN‑Dialog.
  ///
  /// Gibt **true** zurück, wenn
  ///   • keine PIN gesetzt oder
  ///   • PIN bzw. biometrische Auth erfolgreich.
  static Future<bool> require(
    BuildContext context, {
    String? reason,
  }) async {
    // 1. Keine PIN gesetzt?
    final storedPin = SettingsService.I.parentPin.trim();
    if (storedPin.isEmpty) return true;

    // 2. Session‑Cache (für schnelle Mehrfach‑Aktionen)
    if (_sessionValidated) return true;

    // 3. Biometrie zuerst versuchen
    if (await _tryBiometrics(reason ?? 'Eltern‑Freigabe')) {
      _sessionValidated = true;
      return true;
    }

    // 4. Fallback: PIN‑Dialog
    final ok = await _showPinDialog(context, storedPin, reason);
    if (ok) _sessionValidated = true;
    return ok;
  }

  /* ─────────────────────  Internal  ───────────────────── */

  static bool _sessionValidated = false;
  static int  _failedAttempts   = 0;
  static DateTime? _lockUntil;

  /// Zeigt den PIN‑Dialog. Limitiert auf 5 Versuche mit Cool‑Down.
  static Future<bool> _showPinDialog(
      BuildContext ctx, String storedPin, String? reason) async {
    if (_lockUntil != null && DateTime.now().isBefore(_lockUntil!)) {
      _showSnack(ctx,
          'Zu viele Fehlversuche – erneut versuchen ab ${_lockUntil!.hour}:${_lockUntil!.minute.toString().padLeft(2, '0')}');
      return false;
    }

    final ctrl = TextEditingController();
    bool? ok = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('PIN bestätigen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reason != null) Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(reason,
                  style: Theme.of(c).textTheme.bodySmall),
            ),
            TextField(
              controller: ctrl,
              obscureText: true,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Eltern‑PIN',
              ),
              onSubmitted: (_) =>
                  Navigator.pop(c, ctrl.text.trim() == storedPin),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(c, ctrl.text.trim() == storedPin),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    ok ??= false;

    if (!ok) {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockUntil = DateTime.now().add(const Duration(seconds: 30));
        _showSnack(ctx, 'Falsche PIN. Versuche gesperrt für 30 Sek.');
      } else {
        _showSnack(ctx, 'Falsche PIN');
      }
    } else {
      _failedAttempts = 0;
    }

    return ok;
  }

  /// Biometrische Authentifizierung (falls verfügbar).
  static Future<bool> _tryBiometrics(String reason) async {
    final auth = LocalAuthentication();
    try {
      final avail = await auth.canCheckBiometrics &&
          await auth.isDeviceSupported();
      if (!avail) return false;
      return await auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );
    } catch (_) {
      // z. B. wenn kein Sensor eingerichtet.
      return false;
    }
  }

  static void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}
