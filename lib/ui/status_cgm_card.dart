/*
 *  status_cgm_card.dart  (v1)
 *  --------------------------------------------------------------
 *  Reusable CGM‑Status‑Widget mit
 *    • BG‑Wert & Trend‑Icon
 *    • Mini‑Labels IOB/COB/Loop
 */

import 'package:flutter/material.dart';

class StatusCgmCard extends StatelessWidget {
  const StatusCgmCard({
    super.key,
    required this.bg,
    required this.trend,
    required this.iob,
    required this.cob,
    required this.loopState,
    required this.onTap,
  });

  final double? bg;
  final String trend;
  final double iob;
  final double cob;
  final String loopState;
  final VoidCallback onTap;

  Color _loopColor() =>
      loopState == '😊' ? Colors.greenAccent : Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    final bgStr = bg == null ? '—' : bg!.toStringAsFixed(0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(bgStr,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 36)),
                const SizedBox(width: 6),
                Text(trend,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 28,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _mini('IOB', iob.toStringAsFixed(1)),
                _mini('COB', cob.toStringAsFixed(0)),
                _mini('Loop', loopState,
                    color: _loopColor(), fontSize: 14, width: 56),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(String label, String value,
      {Color? color, double fontSize = 12, double width = 48}) =>
      Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
            Text(value,
                style: TextStyle(
                    color: color ?? Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
