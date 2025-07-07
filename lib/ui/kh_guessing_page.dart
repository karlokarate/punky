/*
 *  kh_guessing_page.dart  (v2 – i18n)
 *  --------------------------------------------------------------
 *  Großflächige, kindgerechte UI für das KH‑Guessing‑Game.
 *
 *  Highlights
 *    • Punky‑Pankreas‑Avatar (Lottie)
 *    • AI‑Chip mit ChefBot‑Schätzung
 *    • Streak‑Banner
 *    • Riesen‑Number‑Pad mit Quick‑±5‑Buttons
 *    • Reaktives XP‑Overlay bei Erfolg
 *
 *  Abhängigkeiten
 *    • provider
 *    • lottie
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/kh_guessing_controller.dart';
import '../event_bus.dart';
import '../services/localization_helper.dart';

class KhGuessingPage extends StatelessWidget {
  const KhGuessingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: KhGuessingController.I,
      child: const _GuessScaffold(),
    );
  }
}

/* ---------------- Scaffold ---------------- */

class _GuessScaffold extends StatelessWidget {
  const _GuessScaffold();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<KhGuessingController>();
    final nf = NumberFormat.compact(locale: 'de_DE');

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(LocalizationHelper.get('kh_game.title')),
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          /* Avatar Layer */
          Positioned(
            top: 12,
            right: 12,
            child: _PunkyAvatar(error: ctrl.error),
          ),

          /* Main Content */
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 90, 16, 16),
            child: Column(
              children: [
                /* Actual + AI Guess (nur Info) */
                _InfoRow(
                  actual: ctrl.actualCarbs ?? 0,
                  ai: ctrl.aiGuess ?? 0,
                ),
                const SizedBox(height: 12),

                /* Streak Banner */
                _StreakBanner(),

                const SizedBox(height: 8),
                /* Number Pad */
                Expanded(
                  child: _NumberPad(),
                ),

                /* Confirm Button */
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.rocket_launch),
                    label: Text(
                      LocalizationHelper.get('kh_game.submit'),
                      style: const TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: (ctrl.userGuess != null)
                        ? () async {
                      await ctrl.finalizeGuess();
                      _showResultDialog(context);
                    }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext ctx) {
    final c = KhGuessingController.I;
    final nf = NumberFormat.decimalPattern('de_DE');
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(LocalizationHelper.get('kh_game.result.title')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(LocalizationHelper.get('kh_game.result.user',
              placeholders: {'value': nf.format(c.userGuess)})),
          Text(LocalizationHelper.get('kh_game.result.actual',
              placeholders: {'value': nf.format(c.actualCarbs)})),
          const SizedBox(height: 8),
          Text(LocalizationHelper.get('kh_game.result.error',
              placeholders: {'value': nf.format(c.error)})),
          const SizedBox(height: 8),
          Text(LocalizationHelper.get('kh_game.result.xp',
              placeholders: {'value': c.xp.toString()})),
          if (c.duelResult == DuelResult.win)
            Text(LocalizationHelper.get('kh_game.result.win')),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationHelper.get('common.ok')),
          )
        ],
      ),
    );
  }
}

/* ---------------- Widgets ---------------- */

class _InfoRow extends StatelessWidget {
  final double actual;
  final double ai;
  const _InfoRow({required this.actual, required this.ai});
  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.decimalPattern('de_DE');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Chip(
            label: LocalizationHelper.get('kh_game.actual'),
            value: '${nf.format(actual)} g'),
        _Chip(
            label: LocalizationHelper.get('kh_game.ai_guess'),
            value: '${nf.format(ai)} g'),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  const _Chip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Chip(
    labelPadding:
    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    avatar: const Icon(Icons.info, size: 18),
    label: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    ),
  );
}

class _PunkyAvatar extends StatelessWidget {
  final double error;
  const _PunkyAvatar({required this.error});
  @override
  Widget build(BuildContext context) {
    final anim = (error == 0)
        ? 'assets/lottie/punky_happy.json'
        : (error <= 7)
        ? 'assets/lottie/punky_clap.json'
        : (error <= 10)
        ? 'assets/lottie/punky_think.json'
        : 'assets/lottie/punky_sad.json';
    return Lottie.asset(anim, width: 120, repeat: true);
  }
}

class _StreakBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: GamificationService.instance.currentStreak,
      builder: (_, snap) {
        final streak = snap.data ?? 1;
        return Card(
          color: Colors.orange.shade200,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department, color: Colors.red),
                const SizedBox(width: 6),
                Text(LocalizationHelper.get('kh_game.streak',
                    placeholders: {'days': streak.toString()}),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NumberPad extends StatefulWidget {
  @override
  State<_NumberPad> createState() => _NumberPadState();
}

class _NumberPadState extends State<_NumberPad> {
  String _buffer = '';

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<KhGuessingController>();
    final display = _buffer.isEmpty ? '0' : _buffer;

    return Column(
      children: [
        /* Display */
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.centerRight,
          child: Text('$display g',
              style:
              const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        ),
        const Divider(),
        /* Pad */
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            children: [
              for (final n in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                _padBtn(n),
              _padBtn('+5', addFive: true),
              _padBtn('0'),
              _padBtn('⌫', isBack: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _padBtn(String label, {bool addFive = false, bool isBack = false}) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isBack) {
            if (_buffer.isNotEmpty) {
              _buffer = _buffer.substring(0, _buffer.length - 1);
            }
          } else if (addFive) {
            _buffer = (int.tryParse(_buffer) ?? 0 + 5).toString();
          } else {
            _buffer += label;
          }
          final g = double.tryParse(_buffer);
          KhGuessingController.I.setUserGuess(g ?? 0);
        });
      },
      child: Center(
        child: Text(label,
            style:
            const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
