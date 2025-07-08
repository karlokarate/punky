/*
 *  gamification_service.dart  (v3 – FINAL)
 *  --------------------------------------------------------------
 *  Kapselt Punkte‑ & Level‑Logik + Guess‑XP inkl. Streaks.
 *
 *  • awardMeal(), awardSnack()     (bestehend)
 *  • awardGuess({baseXp, duelWin}) (NEU)
 *  • Persistiert Streak in SharedPreferences
 *  • Broadcastet Events:
 *        PointsChangedEvent, LevelUpEvent
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'package:shared_preferences/shared_preferences.dart';

import '../core/event_bus.dart';
import '../events/app_events.dart';
import 'settings_service.dart';
import 'avatar_service.dart';

class GamificationService {
  GamificationService._();
  static final GamificationService instance = GamificationService._();

  late SettingsService _set;
  late AvatarService _avatar;
  final _bus = AppEventBus.I.bus;
  late SharedPreferences _prefs;

  /* ─────────────────────────────────────────────────────────── */

  Future<void> init() async {
    _set = SettingsService.I;
    _avatar = AvatarService.I;
    _prefs = await SharedPreferences.getInstance();
  }

  /* =====================   Mahlzeiten / Snacks   ===================== */

  Future<void> awardMeal() async => _addPoints(_set.pointsPerMeal);
  Future<void> awardSnack() async => _addPoints(_set.pointsPerSnack);

  /* =====================   Guess‑Game – NEU   ======================= */

  /// Liefert gesamte XP, die vergeben wurden.
  Future<int> awardGuess({
    required int baseXp,
    required bool duelWin,
    required int streak,
  }) async {
    final int streakBonus = 10 * streak.clamp(0, 7);
    final int duelBonus = duelWin ? 50 : 0;
    final int xp = baseXp + streakBonus + duelBonus;

    await _updateStreak();
    await _addPoints(xp);

    return xp;
  }

  Future<void> _updateStreak() async {
    final today = DateTime.now();
    final last = DateTime.tryParse(
        _prefs.getString('kidsapp_guess_last') ?? '') ??
        today.subtract(const Duration(days: 2));
    var streak = _prefs.getInt('kidsapp_guess_streak') ?? 0;

    if (today.difference(last).inDays == 1) {
      streak += 1;
    } else if (today.difference(last).inDays == 0) {
      // gleich­bleibend
    } else {
      streak = 1;
    }

    await _prefs.setString('kidsapp_guess_last', today.toIso8601String());
    await _prefs.setInt('kidsapp_guess_streak', streak);
  }

  Future<int> get currentStreak async =>
      _prefs.getInt('kidsapp_guess_streak') ?? 0;

  /* =====================   Intern – Punkte    ======================= */

  Future<void> _addPoints(int delta) async {
    final oldLvl = _set.childLevel;
    await _set.addPoints(delta);

    _bus.fire(PointsChangedEvent(_set.childPoints));

    if (_set.childLevel > oldLvl) {
      _bus
        ..fire(LevelUpEvent(_set.childLevel))
        ..fire(AvatarCelebrateEvent());
    }

    // Unlock‑Check
    await _avatar.checkUnlocks();
  }
}