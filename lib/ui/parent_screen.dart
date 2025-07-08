// lib/ui/parent_screen.dart
//
// v5 – Cockpit mit Chart, GPT‑Analyse, Profil‑Patch, PIN‑Guard,
//      Verlauf **und** dynamischem Tages‑Durchschnitt (ab 06:00)
//
// ➊  Kleines Info‑Kästchen zeigt immer den Durchschnitt ab 06:00 Uhr bis jetzt.
// ➋  Doppel‑Tap öffnet Kalender‑ & Uhr‑Dialoge zur freien Zeit­raum‑Anpassung.
// ➌  Berechnet Average live aus ns.cachedEntries.
//
// --------------------------------------------------------------------------

import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../event_bus.dart';
import '../models/app_events.dart';
import '../services/gpt_analysis_service.dart';
import '../services/nightscout_service.dart';
import '../services/recommendation_history_service.dart';
import '../services/settings_service.dart';
import '../widgets/pin_guard.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({Key? key}) : super(key: key);

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  late StreamSubscription _logSub;
  late StreamSubscription _recSub;

  String? _gptAdvice;
  bool _isAnalyzing = false;

  List<Map<String, dynamic>> _latestRecs = [];

  /// ⏱ Zeitraum für Durchschnitt
  late DateTime _avgFrom;
  late DateTime _avgTo;

  @override
  void initState() {
    super.initState();

    // Default: Heute 06:00 → Jetzt
    final now = DateTime.now();
    _avgFrom = DateTime(now.year, now.month, now.day, 6);
    _avgTo   = now;

    // Parent‑Log
    _logSub = eventBus.on<ParentLogEvent>().listen((_) {
      if (mounted) setState(() {});
    });

    // Empfehlungen
    _recSub = eventBus.on<NightscoutAnalysisAvailableEvent>().listen((evt) {
      setState(() => _latestRecs = evt.recommendations);
    });

    // letzte gespeicherte Empfehlung
    final hist = RecommendationHistoryService.i.getHistory();
    if (hist.isNotEmpty) {
      _latestRecs = List<Map<String, dynamic>>.from(hist.last['recs']);
    }
  }

  @override
  void dispose() {
    _logSub.cancel();
    _recSub.cancel();
    super.dispose();
  }

  /* ───────────────────────── Durchschnitt ────────────────────────── */

  double? _calcAverage(List<GlucoseEntry> entries) {
    final sub = entries.where((e) =>
        !e.date.isBefore(_avgFrom) && !e.date.isAfter(_avgTo) && e.sgv != null);
    if (sub.isEmpty) return null;
    final sum = sub.fold<int>(0, (acc, e) => acc + e.sgv!.round());
    return sum / sub.length;
  }

  Future<void> _pickAvgRange(BuildContext ctx) async {
    final initRange = DateTimeRange(start: _avgFrom, end: _avgTo);

    final pickedRange = await showDateRangePicker(
      context: ctx,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate : DateTime.now(),
      initialDateRange: initRange,
    );
    if (pickedRange == null) return;

    // Start‑Zeit wählen
    final startTime = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(_avgFrom),
    );
    if (startTime == null) return;

    // End‑Zeit
    final endTime = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(_avgTo),
    );
    if (endTime == null) return;

    setState(() {
      _avgFrom = DateTime(pickedRange.start.year, pickedRange.start.month,
          pickedRange.start.day, startTime.hour, startTime.minute);
      _avgTo = DateTime(pickedRange.end.year, pickedRange.end.month,
          pickedRange.end.day, endTime.hour, endTime.minute);
    });
  }

  /* ─────────────────────  GPT‑Analyse (manuell)  ───────────────────── */

  Future<void> _runGptAnalysis(BuildContext context) async {
    setState(() => _isAnalyzing = true);

    final nightscout = context.read<NightscoutService>();
    final history    = await nightscout.getRecentEntries(limit: 288); // 24 h
    final gpt        = context.read<GptAnalysisService>();
    final advice     = await gpt.analyzeNightscout(history);

    setState(() {
      _gptAdvice   = advice?.suggestion ?? 'Keine Empfehlung erhalten.';
      _isAnalyzing = false;
    });

    eventBus.fire(GPTRecommendationEvent(advice));
  }

  /* ─────────────────────  Profil‑Patch übernehmen  ─────────────────── */

  Future<void> _applyRecommendations(BuildContext ctx) async {
    if (_latestRecs.isEmpty) return;
    if (!await PinGuard.require(ctx)) return;

    final patch = <String, dynamic>{};
    for (final r in _latestRecs) {
      final p = r['profile_patch'] as Map<String, dynamic>? ?? {};
      patch.addAll(p);
    }

    final ns  = ctx.read<NightscoutService>();
    final ok  = await ns.uploadProfilePatch(patch);
    final msg = ok ? 'Profil angepasst' : 'Upload fehlgeschlagen';
    if (!mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }

  /* ─────────────────────  Bolus‑Freigabe  ──────────────────────────── */

  Future<void> _authorizeBolus(BuildContext context) async {
    final ns  = context.read<NightscoutService>();
    final ok  = await ns.authorizePendingBolus();
    final msg = ok ? 'Bolus freigegeben' : 'Freigabe fehlgeschlagen';
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /* ─────────────────────  UI  ──────────────────────────────────────── */

  @override
  Widget build(BuildContext context) {
    final ns       = context.watch<NightscoutService>();
    final sgv      = ns.currentEntry;
    final entries  = ns.cachedEntries;
    final settings = context.watch<SettingsService>();
    final avg      = _calcAverage(entries);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eltern‑Cockpit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ns.refresh(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /*  ------------- Aktuell + Durchschnitt ------------- */
          Row(
            children: [
              Expanded(child: _CurrentGlucoseTile(entry: sgv)),
              const SizedBox(width: 8),
              _AverageBox(
                avg: avg,
                from: _avgFrom,
                to: _avgTo,
                onDoubleTap: () => _pickAvgRange(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _GlucoseChart(entries: entries),
          const SizedBox(height: 16),

          /* --------- Karte: Aktuelle Therapie‑Empfehlung --------- */
          if (_latestRecs.isNotEmpty) Card(
            color: Colors.amber[50],
            child: ListTile(
              leading: const Icon(Icons.lightbulb),
              title  : const Text('Therapie‑Empfehlung'),
              subtitle: Text(
                _latestRecs
                    .map((r) => '• ${r['change']} (${r['reason']})')
                    .join('\n'),
              ),
              trailing: ElevatedButton(
                onPressed: () => _applyRecommendations(context),
                child: const Text('Übernehmen'),
              ),
            ),
          ),

          /*  ----- Verlaufs‑Liste (aus RecommendationHistory) ----- */
          if (RecommendationHistoryService.i.getHistory().isNotEmpty)
            ExpansionTile(
              title: const Text('Vergangene Empfehlungen'),
              children: RecommendationHistoryService.i
                  .getHistory()
                  .reversed
                  .map<Widget>((h) => ListTile(
                        title: Text(
                          DateFormat.yMMMd()
                              .add_Hm()
                              .format(DateTime.parse(h['ts'])),
                        ),
                        subtitle: Text((h['recs'] as List)
                            .map((r) => '• ${r['change']} (${r['reason']})')
                            .join('\n')),
                      ))
                  .toList(),
            ),

          const Divider(),

          /*  --------- Manuelle GPT‑Analyse (24 h) --------- */
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title  : Text(_gptAdvice ?? 'GPT‑Analyse starten (24 h Verlauf)'),
            trailing: _isAnalyzing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child:
                        CircularProgressIndicator(strokeWidth: 3),
                  )
                : IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _runGptAnalysis(context),
                  ),
          ),

          const Divider(),

          /*  --------- Bolus‑Freigabe --------- */
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title  : const Text('Bolus‑Abgabe freigeben'),
            subtitle: Text(
                'Max ${settings.maxBolusUnits.toStringAsFixed(1)} U'),
            trailing: ElevatedButton(
              onPressed: () => _authorizeBolus(context),
              child: const Text('Freigeben'),
            ),
          ),

          const Divider(),

          /*  --------- Ereignis‑Log --------- */
          Text('Ereignis‑Log', style: Theme.of(context).textTheme.titleLarge),
          ...List<ParentLogEvent>.from(ns.parentLog)
              .reversed
              .take(50)
              .map(_eventTile),
        ],
      ),
    );
  }

  Widget _eventTile(ParentLogEvent e) {
    final fmt = DateFormat.Hm();
    return ListTile(
      leading: const Icon(Icons.event_note),
      title  : Text(e.message),
      subtitle: Text(fmt.format(e.timestamp)),
    );
  }
}

/* ─────────────────────  Widgets  ───────────────────────────────────── */

class _CurrentGlucoseTile extends StatelessWidget {
  final GlucoseEntry? entry;
  const _CurrentGlucoseTile({this.entry});

  @override
  Widget build(BuildContext context) {
    final value = entry?.sgv?.toStringAsFixed(0) ?? '—';
    final trend = entry?.trendArrow ?? ' ';
    final time  = entry != null
        ? DateFormat.Hm().format(entry!.date)
        : 'Keine Daten';

    return Card(
      child: ListTile(
        leading : const Icon(Icons.opacity),
        title   : Text('$value mg/dl $trend',
            style: Theme.of(context).textTheme.headlineMedium),
        subtitle: Text('aktualisiert $time'),
      ),
    );
  }
}

class _AverageBox extends StatelessWidget {
  final double? avg;
  final DateTime from;
  final DateTime to;
  final VoidCallback onDoubleTap;

  const _AverageBox({
    required this.avg,
    required this.from,
    required this.to,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final txt = avg != null ? avg!.toStringAsFixed(0) : '—';
    final subtitle =
        '${DateFormat.Hm().format(from)}–${DateFormat.Hm().format(to)}';

    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Card(
        color: Colors.blueGrey.shade50,
        child: SizedBox(
          width: 110,
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Ø mg/dl', style: TextStyle(fontSize: 12)),
              Text(txt,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlucoseChart extends StatelessWidget {
  final List<GlucoseEntry> entries;
  const _GlucoseChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('Keine Verlaufsdaten'));
    }

    final spots = entries
        .map((e) => FlSpot(e.date.millisecondsSinceEpoch.toDouble(),
            e.sgv?.toDouble() ?? 0.0))
        .toList();

    final minX = spots.first.x;
    final maxX = spots.last.x;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: 40,
          maxY: 400,
          titlesData: FlTitlesData(show: false),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
