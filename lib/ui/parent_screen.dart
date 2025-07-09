// lib/ui/parent_screen.dart
//
// v5 – Cockpit mit Chart, GPT‑Analyse, Profil‑Patch, PIN‑Guard,
//      Verlauf **und** dynamischem Tages‑Durchschnitt (ab 06:00)

import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../event_bus.dart';
import '../events/app_events.dart';
import '../services/gpt_analysis_service.dart';
import '../services/nightscout_service.dart';
import '../recommendation_history_service.dart';
import '../services/settings_service.dart';
import '../widgets/pin_guard.dart';
import '../services/nightscout_models.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  late final StreamSubscription _logSub;
  late final StreamSubscription _recSub;

  String? _gptAdvice;
  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _latestRecs = [];
  late DateTime _avgFrom;
  late DateTime _avgTo;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _avgFrom = DateTime(now.year, now.month, now.day, 6);
    _avgTo = now;

    _logSub = eventBus.on<ParentLogEvent>().listen((_) {
      if (!mounted) return;
      setState(() {});
    });

    _recSub = eventBus.on<NightscoutAnalysisAvailableEvent>().listen((evt) {
      if (!mounted) return;
      setState(() => _latestRecs = evt.recommendations);
    });

    final hist = RecommendationHistoryService.i.latest;
    if (hist != null) {
      _latestRecs = List<Map<String, dynamic>>.from(hist['recs']);
    }
  }

  @override
  void dispose() {
    _logSub.cancel();
    _recSub.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Helfer
  // -------------------------------------------------------------------------

  double? _calcAverage(List<GlucoseEntry> entries) {
    final sub = entries
        .where((e) => e.date.isAfter(_avgFrom) && e.date.isBefore(_avgTo))
        .toList();

    if (sub.isEmpty) return null;

    final sum = sub.fold<int>(0, (acc, e) => acc + e.sgv.round());
    return sum / sub.length;
  }

  // -------------------------------------------------------------------------
  // Zeitraum‑Picker für Durchschnitt
  // -------------------------------------------------------------------------

  Future<void> _pickAvgRange(BuildContext context) async {
    if (!context.mounted) return;

    final initRange = DateTimeRange(start: _avgFrom, end: _avgTo);

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      initialDateRange: initRange,
    );
    if (pickedRange == null || !context.mounted) return;

    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_avgFrom),
    );
    if (startTime == null || !context.mounted) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_avgTo),
    );
    if (endTime == null || !context.mounted) return;

    if (!context.mounted) return;
    setState(() {
      _avgFrom = DateTime(
        pickedRange.start.year,
        pickedRange.start.month,
        pickedRange.start.day,
        startTime.hour,
        startTime.minute,
      );
      _avgTo = DateTime(
        pickedRange.end.year,
        pickedRange.end.month,
        pickedRange.end.day,
        endTime.hour,
        endTime.minute,
      );
    });
  }

  // -------------------------------------------------------------------------
  // GPT‑Analyse
  // -------------------------------------------------------------------------

  Future<void> _runGptAnalysis(BuildContext context) async {
    if (!context.mounted) return;
    setState(() => _isAnalyzing = true);

    final nightscout = context.read<NightscoutService>();
    final gpt = context.read<GptAnalysisService>();

    final history = await nightscout.getRecentEntries(limit: 288);
    final advice = await gpt.analyzeNightscout(history);

    if (!context.mounted) return;
    setState(() {
      _gptAdvice = advice?.suggestion ?? 'Keine Empfehlung erhalten.';
      _isAnalyzing = false;
    });

    eventBus.fire(GPTRecommendationEvent(advice));
  }

  // -------------------------------------------------------------------------
  // Empfehlungen anwenden
  // -------------------------------------------------------------------------

  Future<void> _applyRecommendations(BuildContext context) async {
    if (!context.mounted || _latestRecs.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final ns = context.read<NightscoutService>();

    if (!await PinGuard.require(context)) return;

    final patch = <String, dynamic>{};
    for (final r in _latestRecs) {
      final p = r['profile_patch'] as Map<String, dynamic>? ?? {};
      patch.addAll(p);
    }

    final ok = await ns.uploadProfilePatch(patch);
    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(content: Text(ok ? 'Profil angepasst' : 'Upload fehlgeschlagen')),
    );
  }

  // -------------------------------------------------------------------------
  // Bolus freigeben
  // -------------------------------------------------------------------------

  Future<void> _authorizeBolus(BuildContext context) async {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ns = context.read<NightscoutService>();

    final ok = await ns.authorizePendingBolus();
    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Bolus freigegeben' : 'Freigabe fehlgeschlagen'),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build‑Methode
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ns = context.watch<NightscoutService>();
    final sgv = ns.currentEntry;
    final entries = ns.cachedEntries;
    final settings = context.watch<SettingsService>();
    final avg = _calcAverage(entries);
    final history = RecommendationHistoryService.i.getHistory();

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
          if (_latestRecs.isNotEmpty)
            Card(
              color: Colors.amber[50],
              child: ListTile(
                leading: const Icon(Icons.lightbulb),
                title: const Text('Therapie‑Empfehlung'),
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
          if (history.isNotEmpty) _HistoryPopover(history: history),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: Text(_gptAdvice ?? 'GPT‑Analyse starten (24 h Verlauf)'),
            trailing: _isAnalyzing
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
                : IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _runGptAnalysis(context),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Bolus‑Abgabe freigeben'),
            subtitle: Text('Max ${settings.maxBolusUnits.toStringAsFixed(1)} U'),
            trailing: ElevatedButton(
              onPressed: () => _authorizeBolus(context),
              child: const Text('Freigeben'),
            ),
          ),
          const Divider(),
          Text('Ereignis‑Log', style: Theme.of(context).textTheme.titleLarge),
          ...List<ParentLogEvent>.from(ns.parentLog)
              .reversed
              .take(50)
              .map(_eventTile),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Log‑Tile
  // -------------------------------------------------------------------------

  Widget _eventTile(ParentLogEvent e) {
    final fmt = DateFormat.Hm();
    return ListTile(
      leading: const Icon(Icons.event_note),
      title: Text(e.message),
      subtitle: Text(fmt.format(e.timestamp)),
    );
  }
}

// ---------------------------------------------------------------------------
// UI‑Bausteine
// ---------------------------------------------------------------------------

class _CurrentGlucoseTile extends StatelessWidget {
  final GlucoseEntry? entry;
  const _CurrentGlucoseTile({this.entry});

  @override
  Widget build(BuildContext context) {
    final value = entry?.sgv.toStringAsFixed(0) ?? '—';
    final trend = entry?.trendArrow ?? ' ';
    final time = entry?.date != null
        ? DateFormat.Hm().format(entry!.date)
        : 'Keine Daten';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.opacity),
        title: Text('$value mg/dl $trend',
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
    final txt = avg?.toStringAsFixed(0) ?? '—';
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
              Text(
                txt,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
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
        .map((e) => FlSpot(
      e.date.millisecondsSinceEpoch.toDouble(),
      e.sgv.toDouble(),
    ))
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

class _HistoryPopover extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const _HistoryPopover({required this.history});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Vergangene Empfehlungen'),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Verlauf löschen',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);

              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Verlauf löschen?'),
                  content: const Text('Der gesamte Verlauf wird gelöscht.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Abbrechen'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Löschen'),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              await RecommendationHistoryService.i.clear();
              messenger.showSnackBar(
                const SnackBar(content: Text('Verlauf gelöscht')),
              );
            },
          ),
        ],
      ),
      children: history
          .reversed
          .map(
            (h) => ListTile(
          title: Text(
            DateFormat.yMMMd().add_Hm().format(DateTime.parse(h['ts'])),
          ),
          subtitle: Text(
            (h['recs'] as List)
                .map((r) => '• ${r['change']} (${r['reason']})')
                .join('\n'),
          ),
        ),
      )
          .toList(),
    );
  }
}
