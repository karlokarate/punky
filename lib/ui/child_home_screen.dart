/*
 *  child_home_screen.dart  (v5 ‑ FINAL, lokalisiert)
 *  --------------------------------------------------------------
 *  • Live‑Status (IOB/COB/Loop)
 *  • Mini‑Avatar (Doppel‑Tap → AvatarScreen, Long‑Press → Theme‑Cycling)
 *  • Avatar‑Reaktionen (celebrate / sad / preview_item)
 *  • Punktestand & Level‑Anzeige (lokalisiert)
 */

import 'dart:async';
import 'dart:io';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// ⬇️ NEU: Lokalisierung importieren
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_initializer.dart';
import '../events/app_events.dart';
import '../services/aaps_logic_port.dart';
import '../services/avatar_service.dart';
import '../services/settings_service.dart';
import '../services/push_service.dart';
import 'avatar_screen.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});
  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  late final SettingsService _settings;
  late final EventBus _bus;
  late final AvatarService _avatar;

  double _iob = 0, _cob = 0;
  String _loop = '—';
  int _points = 0, _level = 1;

  late Timer _timerStatus;
  late StreamSubscription _avatarSub;
  late StreamSubscription _pushSub;

  String get _theme => _settings.childThemeKey;

  @override
  void initState() {
    super.initState();
    final ctx = (context.findAncestorWidgetOfExactType<KidsApp>() as KidsApp).appCtx;
    _settings = ctx.settings;
    _bus = ctx.eventBus;
    _avatar = AvatarService.I;

    _avatarSub = _avatar.onChanged.listen((_) => setState(() {}));
    _pushSub = _bus.on<PushReceivedEvent>().listen(_onPush);

    _loadGamification();
    _refreshStatus();
    _timerStatus = Timer.periodic(const Duration(minutes: 1), (_) => _refreshStatus());
  }

  @override
  void dispose() {
    _timerStatus.cancel();
    _avatarSub.cancel();
    _pushSub.cancel();
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

  void _loadGamification() {
    _points = _settings.childPoints;
    _level = _settings.childLevel;
  }

  void _onPush(PushReceivedEvent e) {
    final delta = e.message.data['points'] as int?;
    if (delta != null) {
      _settings.addPoints(delta);
      _loadGamification();
      _bus.fire(AvatarCelebrateEvent());
      // ⬇️ LOKALISIERTE Snackbar
      final l = AppLocalizations.of(context)!;
      _showSnack(l.home.msg.points_added.replaceFirst('{points}', '$delta'));
      setState(() {});
    }
  }

  Future<void> _cycleTheme() async {
    final idx = _settings.availableThemes.indexOf(_theme);
    final next = _settings.availableThemes[(idx + 1) % _settings.availableThemes.length];
    await _settings.setChildTheme(next);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.compact(locale: 'de_DE');
    // ⬇️ LOKALISIERUNG HINZUGEFÜGT
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/themes/$_theme/background.png', fit: BoxFit.cover),
        Container(color: Colors.black.withOpacity(0.25)),
        SafeArea(
          child: Column(children: [
            _header(l, nf),
            const SizedBox(height: 8),
            _statusTiles(l, nf),
            const Spacer(),
            _mainButtons(l),
            const SizedBox(height: 32),
          ]),
        ),
      ]),
    );
  }

  // ⬇️ Parameter l ergänzt
  Widget _header(AppLocalizations l, NumberFormat nf) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      GestureDetector(
        onDoubleTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AvatarScreen())),
        onLongPress: _cycleTheme,
        child: _miniAvatar(),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ⬇️ LOKALISIERUNG
          Text(l.home.level.replaceFirst('{level}', '$_level'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          LinearProgressIndicator(
            value: (_points % 100) / 100,
            minHeight: 6,
            color: Colors.amber,
            backgroundColor: Colors.white24,
          ),
          const SizedBox(height: 2),
          Text(l.home.points.replaceFirst('{points}', nf.format(_points)),
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
      IconButton(
        icon: const Icon(Icons.settings, color: Colors.white),
        onPressed: () => _bus.fire(AppNavigationEvent(NavTarget.settings)),
      ),
    ]),
  );

  Widget _miniAvatar() {
    final layers = ['wing', 'body', 'head', 'accessory', 'weapon'];
    final react = _avatar.reaction?.anim;
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(fit: StackFit.expand, children: [
        for (final l in layers)
          if (_avatar.equipped[l] != null)
            Image(image: _imgProvider(_avatar.equipped[l]!)),
        if (react == 'celebrate') const Icon(Icons.star, color: Colors.amber, size: 60),
        if (react == 'sad') const Icon(Icons.cloud, color: Colors.blueGrey, size: 60),
      ]),
    );
  }

  ImageProvider _imgProvider(String key) {
    final it = _avatar.catalog.firstWhere((e) => e.key == key);
    return it.assetPath.startsWith('/')
        ? FileImage(File(it.assetPath))
        : AssetImage(it.assetPath) as ImageProvider;
  }

  // ⬇️ Parameter l ergänzt
  Widget _statusTiles(AppLocalizations l, NumberFormat nf) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(children: [
      _tile(l.home.iob, '${nf.format(_iob)} IE'),
      _tile(l.home.cob, '${nf.format(_cob)} g'),
      _tile(l.home.loop, _loop),
    ]),
  );

  Widget _tile(String l, String v) => Expanded(
    child: Card(
      color: Colors.white70,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(children: [
          Text(l, style: const TextStyle(fontSize: 12)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
    ),
  );

  // ⬇️ Parameter l ergänzt
  Widget _mainButtons(AppLocalizations l) => Wrap(
    spacing: 16,
    runSpacing: 16,
    alignment: WrapAlignment.center,
    children: [
      _bigButton('btn_meal', l.home.btn.meal,
              () => _bus.fire(AppNavigationEvent(NavTarget.addMeal))),
      _bigButton('btn_snack', l.home.btn.snack,
              () => _bus.fire(AppNavigationEvent(NavTarget.addSnack))),
      _bigButton('btn_history', l.home.btn.history,
              () => _bus.fire(AppNavigationEvent(NavTarget.history))),
    ],
  );

  Widget _bigButton(String asset, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Ink(
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Image.asset('assets/themes/$_theme/$asset.png',
                  width: 36, height: 36),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold))
        ]),
      );

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
  );
}
