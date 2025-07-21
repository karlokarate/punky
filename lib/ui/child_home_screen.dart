/*
 *  child_home_screen.dart  (v9 – Whisper-FAB animiert + Feedback)
 *  --------------------------------------------------------------------------
 *  • CGM‑Wert + Whisper-Input als Hauptaktionen
 *  • Mikrofon-FAB mit cooler Animation (kindgerecht)
 *  • Whisper-Spracherkennung + visuelles Feedback + Snackbar
 *  • Sprach-/Bild-Eingabe via Tap/LongPress auf animiertem Button
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'dart:async';
import 'dart:io';
import 'package:diabetes_kids_app/core/app_context.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:diabetes_kids_app/l10n/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../core/event_bus.dart';
import '../events/app_events.dart';
import '../events/loop_events.dart';
import '../services/aaps_logic_port.dart';
import '../services/avatar_service.dart';
import '../services/nightscout_service.dart';
import '../services/settings_service.dart';
import '../services/push_service.dart';
import '../services/speech_service.dart';
import 'avatar_screen.dart';
import 'status_cgm_card.dart';

class ChildHomeScreen extends StatefulWidget {
  final AppContext appContext;
  const ChildHomeScreen({super.key, required this.appContext});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen>
    with SingleTickerProviderStateMixin {
  final SettingsService _settings = SettingsService.I;
  final AvatarService _avatar = AvatarService.I;
  final EventBus _bus = AppEventBus.I.raw;
  final NightscoutService _ns = NightscoutService.instance;

  double _iob = .0, _cob = .0;
  String _loop = '—';
  double? _bg;
  String _trend = '';

  int _points = 0, _level = 1;
  bool _detailsVisible = true;
  bool _isListening = false;

  Timer? _statusTimer;
  late final StreamSubscription _busSub;
  late final VoidCallback _avatarListener;
  late final VoidCallback _nsListener;

  String get _theme => _settings.childThemeKey;

  @override
  void initState() {
    super.initState();

    _avatarListener = () => setState(() {});
    _avatar.addListener(_avatarListener);

    _nsListener = _onGlucoseUpdated;
    _ns.addListener(_nsListener);

    _busSub = _bus.on<PushReceivedEvent>().listen(_onPush);

    _reloadGamification();
    _refreshStatus();
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (_) => _refreshStatus());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _avatar.removeListener(_avatarListener);
    _ns.removeListener(_nsListener);
    _busSub.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final io = await AapsLogicPort.getIobCob();
    if (!mounted) return;
    setState(() {
      _iob = io?.iob ?? 0;
      _cob = io?.cob ?? 0;
      _loop = io == null ? '❔' : '😊';
    });
  }

  void _onGlucoseUpdated() {
    final entry = _ns.currentEntry;
    if (!mounted) return;
    setState(() {
      _bg = entry?.sgv.toDouble();
      _trend = entry?.trendArrow ?? '';
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

  Future<void> _startWhisperInput() async {
    setState(() => _isListening = true);
    await SpeechService.instance.startListening();
    if (!mounted) return;
    setState(() => _isListening = false);

    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.homeMsgSpeechSuccess)),
    );
  }

  void _onFabTap() => _startWhisperInput();

  void _onFabLongPress() {
    _bus.fire(const AppNavigationEvent(NavTarget.imageInput));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final nf = NumberFormat.compact(locale: l.localeName);

    return Scaffold(
      floatingActionButton: GestureDetector(
        onTap: _onFabTap,
        onLongPress: _onFabLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            color: _isListening ? Colors.redAccent : Colors.blueAccent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: _isListening
                ? Lottie.asset('assets/lottie/mic_wave.json')
                : const Icon(Icons.mic, color: Colors.white, size: 34),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/themes/$_theme/background.png', fit: BoxFit.cover),
          Container(color: Colors.black.withAlpha(77)),
          SafeArea(
            child: Column(
              children: [
                _header(l, nf),
                const SizedBox(height: 12),
                _cgmRow(l, nf),
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

  Widget _header(AppLocalizations l, NumberFormat nf) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        GestureDetector(
          onDoubleTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AvatarScreen(appContext: widget.appContext),
            ),
          ),
          onLongPress: _cycleTheme,
          child: _miniAvatar(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.homeLevel(_level),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              LinearProgressIndicator(
                value: (_points % 100) / 100,
                backgroundColor: Colors.white24,
                color: Colors.amber,
                minHeight: 6,
              ),
              const SizedBox(height: 2),
              Text(l.homePoints(nf.format(_points)),
                  style:
                  const TextStyle(color: Colors.white70, fontSize: 12, height: 1.1)),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _bus.fire(const AppNavigationEvent(NavTarget.settings)),
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    ),
  );

  Widget _cgmRow(AppLocalizations l, NumberFormat nf) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        Expanded(
          child: StatusCgmCard(
            bg: _bg,
            trend: _trend,
            iob: _iob,
            cob: _cob,
            loopState: _loop,
            onTap: () {
              final msg = 'IOB ${nf.format(_iob)} • COB ${nf.format(_cob)} • Loop $_loop';
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(msg)));
            },
          ),
        ),
      ],
    ),
  );

  Widget _mainActions(AppLocalizations l) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _actionButton(Icons.restaurant_menu, l.btnMeal,
                () => _bus.fire(const AppNavigationEvent(NavTarget.meal))),
        _actionButton(Icons.cookie, l.btnSnack,
                () => _bus.fire(const AppNavigationEvent(NavTarget.snack))),
        _actionButton(Icons.question_mark, l.btnGuess,
                () => _bus.fire(const AppNavigationEvent(NavTarget.guess))),
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

  Widget _miniAvatar() => SizedBox(
    width: 60,
    height: 60,
    child: Stack(
      fit: StackFit.expand,
      children: _avatar.getImagePaths().map((p) {
        final provider =
        p.startsWith('/') ? FileImage(File(p)) : AssetImage(p) as ImageProvider;
        return Image(image: provider);
      }).toList(),
    ),
  );
}
