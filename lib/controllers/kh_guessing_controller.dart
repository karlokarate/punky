/*
 *  kh_guessing_controller.dart   (v2 – i18n)
 *  --------------------------------------------------------------
 *  Zentrales State‑Objekt für das KH‑Guessing‑Game.
 *
 *  Kern‑Features
 *  • hält: actualCarbs, aiGuess, userGuess, error, xpEarned
 *  • berechnet Fehlerdifferenz & XP (ruft GamificationService.awardGuess)
 *  • verwaltet Streak (SharedPrefs via GamificationService)
 *  • feuert Events   KhGuessingStartedEvent / KhGuessingFinishedEvent
 *  • Avatar‑Reaktion (Punky) per EventBus
 *  • funktioniert Stand‑alone & Plugin (keine plattformspezifischen Aufrufe)
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../core/event_bus.dart';
import '../events/app_events.dart';
import '../services/gamification_service.dart';
import '../services/avatar_service.dart';

class KhGuessingStartedEvent extends AppEvent {
  final double actual;
  final double aiGuess;
  KhGuessingStartedEvent(this.actual, this.aiGuess);
  @override
  Map<String, dynamic> toJson() =>
      {'actual': actual, 'aiGuess': aiGuess};
}

class KhGuessingFinishedEvent extends AppEvent {
  final double userGuess;
  final double error;
  final int xp;
  final bool duelWin;
  KhGuessingFinishedEvent({
    required this.userGuess,
    required this.error,
    required this.xp,
    required this.duelWin,
  });
  @override
  Map<String, dynamic> toJson() => {
    'userGuess': userGuess,
    'error': error,
    'xp': xp,
    'duelWin': duelWin
  };
}

enum DuelResult { win, draw, lose }

class KhGuessingController extends ChangeNotifier {
  /* Singleton – damit Provider & Screens ein Objekt teilen */
  KhGuessingController._();
  static final KhGuessingController I = KhGuessingController._();

  /* Kontext für Lokalisierung */
  BuildContext? _context;
  void setContext(BuildContext context) => _context = context;

  /* ─────────────────────────────────────────────────────────── */

  /* Eingangs‑Daten */
  double? _actualCarbs;
  double? _aiGuess;

  /* User‑State */
  double? _userGuess;
  double _error = 0;
  int _xp = 0;
  DuelResult? _duel;

  /* Getter */
  double? get actualCarbs => _actualCarbs;
  double? get aiGuess => _aiGuess;
  double? get userGuess => _userGuess;
  double get error => _error;
  int get xp => _xp;
  DuelResult? get duelResult => _duel;

  bool get isReady =>
      _actualCarbs != null && _aiGuess != null; // für UI‑Enable

  /* EventBus */
  final _bus = AppEventBus.I.bus;
  StreamSubscription? _mealSub;

  /* ───────────────────────────────────────────────────────────
   *   Initialisierung / Reset
   * ────────────────────────────────────────────────────────── */
  void attachMealStream() {
    _mealSub?.cancel();
    _mealSub = _bus.on<MealAnalyzedEvent>().listen((e) {
      // Ein neues Spiel beginnt, sobald der MealAnalyzer echte KH liefert
      _startNewGame(
        actual: e.totalCarbs,
        aiGuess: _estimateWithChefBot(e.totalCarbs),
      );
    });
  }

  void disposeController() {
    _mealSub?.cancel();
  }

  /* ───────────────────────────────────────────────────────────
   *   Spiel‑Ablauf
   * ────────────────────────────────────────────────────────── */

  void _startNewGame({required double actual, required double aiGuess}) {
    _actualCarbs = actual;
    _aiGuess = aiGuess;
    _userGuess = null;
    _error = 0;
    _xp = 0;
    _duel = null;

    notifyListeners();
    _bus
      ..fire(AvatarItemPreviewEvent('punky_think'))
      ..fire(KhGuessingStartedEvent(actual, aiGuess));
  }

  void setUserGuess(double g) {
    _userGuess = g;
    notifyListeners();
  }

  Future<void> finalizeGuess() async {
    if (_userGuess == null || _actualCarbs == null) return;

    _error = (_userGuess! - _actualCarbs!).abs();
    _duel = _evaluateDuel();
    _xp = await GamificationService.instance.awardGuess(
      baseXp: _baseXp(),
      duelWin: _duel == DuelResult.win,
      streak: await GamificationService.instance.currentStreak,
    );

    // Avatar‑Emotion
    if (_error <= 3) {
      _bus.fire(AvatarCelebrateEvent());
    } else if (_error > 10) {
      _bus.fire(AvatarSadEvent());
    } else {
      _bus.fire(AvatarItemPreviewEvent('punky_clap'));
    }

    _bus.fire(KhGuessingFinishedEvent(
        userGuess: _userGuess!,
        error: _error,
        xp: _xp,
        duelWin: _duel == DuelResult.win));

    notifyListeners();
  }

  /* ───────────────────────────────────────────────────────────
   *   Private Helpers
   * ────────────────────────────────────────────────────────── */

  int _baseXp() {
    if (_error <= 3) return 100;
    if (_error <= 7) return 75;
    if (_error <= 10) return 50;
    return 20;
  }

  DuelResult _evaluateDuel() {
    final aiErr = (_aiGuess! - _actualCarbs!).abs();
    if (_error < aiErr) return DuelResult.win;
    if (_error == aiErr) return DuelResult.draw;
    return DuelResult.lose;
  }

  // Placeholder – später ChefBot‐Service aufrufen
  double _estimateWithChefBot(double actual) {
    // Simples Heuristik‑Stub: ±10 %
    return (actual * 0.9) + (actual * 0.2 * (DateTime.now().millisecond / 1000));
  }

  String get feedbackText {
    final loc = _context != null ? AppLocalizations.of(_context!) : null;
    if (loc == null) return "";
    if (_error <= 3) {
      return loc.khGamePerfect;
    } else if (_error <= 7) {
      return loc.khGameClose;
    } else {
      return loc.khGameMiss;
    }
  }
}