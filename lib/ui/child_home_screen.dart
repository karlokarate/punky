/*
 *  child_home_screen.dart  (v6 – state‑of‑the‑art)
 *  --------------------------------------------------------------
 *  • Live‑Status‑Dashboard (IOB / COB / Loop)
 *  • Mini‑Avatar mit Theme‑Cycling (Long‑Press) & Editor‑Shortcut (Double‑Tap)
 *  • Punkte‑ & Level‑Anzeige inkl. Fortschrittsbalken
 *  • Schnelle Haupt‑Aktionen (Meal, Snack, Guess‑Game)
 *  • Voll lokalisiert (keine verschachtelten ARB‑Keys mehr)
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'dart:async';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:diabetes_kids_app/l10n/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../core/event_bus.dart';
import '../events/app_events.dart';
import '../services/aaps_logic_port.dart';
import '../services/avatar_service.dart';
import '../services/settings_service.dart';
import '../services/push_service.dart';
import 'avatar_screen.dart';

/* ───────── Main Class ───────── */

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  /* ───────── Services & State ───────── */

  final SettingsService _settings = SettingsService.I;
  final AvatarService _avatar = AvatarService.I;
  final EventBus _bus = AppEventBus.I.bus;

  double _iob = .0, _cob = .0;
  String _loop = '—';
  int _points = 0, _level = 1;

  Timer? _statusTimer;
  late final StreamSubscription _busSub;
  late final VoidCallback _avatarListener;

  String get _theme => _settings.childThemeKey;

  /* ───────── Lifecycle ───────── */

  @override
  void initState() {
    super.initState();

    _avatarListener = () => setState(() {});
    _avatar.addListener(_avatarListener);

    _busSub = _bus.on<PushReceivedEvent>().listen(_onPush);

    _reloadGamification();
    _refreshStatus();
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) => _refreshStatus());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _avatar.removeListener(_avatarListener);
    _busSub.cancel();
    super.dispose();
  }

  /* ───────── Helpers ───────── */

  Future<void> _refreshStatus() async {
    final io = await AapsLogicPort.getIobCob();
    if (!mounted) return;
    setState(() {
      _iob = io?.iob ?? 0;
      _cob = io?.cob ?? 0;
      _loop = io == null ? '❔' : '😊';
    });
  }

  void _reloadGamification() {
    _points = _settings.childPoints;
    _level = _settings.childLevel;
  }

  void _onPush(PushReceivedEvent e) {
    final delta = int.tryParse(e.message.data['points'] ?? '0') ?? 0;
    if (delta == 0) return;

    _settings.addPoints(delta);
    _reloadGamification();
    _bus
      ..fire(AvatarCelebrateEvent())
      ..fire(PointsChangedEvent(_points));

    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.homeMsgPoints(delta))),
    );
    setState(() {});
  }

  Future<void> _cycleTheme() async {
    final idx = _settings.availableThemes.indexOf(_theme);
    final next = _settings.availableThemes[(idx + 1) % _settings.availableThemes.length];
    await _settings.setChildTheme(next);
    setState(() {});
  }

  /* ───────── Build ───────── */

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final nf = NumberFormat.compact(locale: l.localeName);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/themes/$_theme/background.png', fit: BoxFit.cover),
          Container(color: Colors.black.withAlpha(77)), // 77 = 30% Opazität

          SafeArea(
            child: Column(
              children: [
                _header(l, nf),
                const SizedBox(height: 12),
                _statusRow(l, nf),
                const Spacer(),
                _mainActions(l),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ───────── Header ───────── */

  Widget _header(AppLocalizations l, NumberFormat nf) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        GestureDetector(
          onDoubleTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvatarScreen())),
          onLongPress: _cycleTheme,
          child: _miniAvatar(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.homeLevel(_level), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              LinearProgressIndicator(
                value: (_points % 100) / 100,
                backgroundColor: Colors.white24,
                color: Colors.amber,
                minHeight: 6,
              ),
              const SizedBox(height: 2),
              Text(l.homePoints(nf.format(_points)), style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.1)),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _bus.fire(AppNavigationEvent(NavTarget.settings)),
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    ),
  );

  /* ───────── Status ───────── */

  Widget _statusRow(AppLocalizations l, NumberFormat nf) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statusCard(title: 'IOB', value: nf.format(_iob), color: Colors.orangeAccent),
        _statusCard(title: 'COB', value: nf.format(_cob), color: Colors.lightBlueAccent),
        _statusCard(title: 'LOOP', value: _loop, color: _loop == '😊' ? Colors.greenAccent : Colors.redAccent),
      ],
    ),
  );

  Widget _statusCard({required String title, required String value, required Color color}) => Container(
    width: 90,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white24),
    ),
    child: Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    ),
  );

  /* ───────── Main‑Actions ───────── */

  Widget _mainActions(AppLocalizations l) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _actionButton(Icons.restaurant_menu, l.btnMeal, () => _bus.fire(AppNavigationEvent(NavTarget.meal))),
        _actionButton(Icons.cookie, l.btnSnack, () => _bus.fire(AppNavigationEvent(NavTarget.snack))),
        _actionButton(Icons.question_mark, l.btnGuess, () => _bus.fire(AppNavigationEvent(NavTarget.guess))),
      ],
    ),
  );

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white24,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    onPressed: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 30),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );

  /* ───────── Avatar‑Preview ───────── */

  Widget _miniAvatar() => SizedBox(
    width: 60,
    height: 60,
    child: Stack(
      fit: StackFit.expand,
      children: _avatar.getImagePaths().map((p) {
        final provider = p.startsWith('/') ? FileImage(File(p)) : AssetImage(p) as ImageProvider;
        return Image(image: provider);
      }).toList(),
    ),
  );
}
