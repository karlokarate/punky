import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../services/nightscout_service.dart';
import '../services/gpt_analysis_service.dart';
import '../services/settings_service.dart';
import '../models/app_events.dart';
import '../services/push_service.dart';
import '../event_bus.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({Key? key}) : super(key: key);

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  late StreamSubscription _eventSub;
  String? _gptAdvice;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _eventSub = eventBus.on<ParentLogEvent>().listen((event) {
      // Trigger rebuild to show new events
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _eventSub.cancel();
    super.dispose();
  }

  Future<void> _runGptAnalysis(BuildContext context) async {
    setState(() => _isAnalyzing = true);
    final nightscout = context.read<NightscoutService>();
    final history = await nightscout.getRecentEntries(limit: 288); // 24 h
    final gpt = context.read<GptAnalysisService>();
    final advice = await gpt.analyzeNightscout(history);
    setState(() {
      _gptAdvice = advice?.suggestion ?? 'Keine Empfehlung erhalten.';
      _isAnalyzing = false;
    });
    eventBus.fire(GPTRecommendationEvent(advice));
  }

  Future<void> _authorizeBolus(BuildContext context) async {
    final ns = context.read<NightscoutService>();
    final ok = await ns.authorizePendingBolus();
    final msg = ok ? 'Bolus freigegeben' : 'Freigabe fehlgeschlagen';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final ns = context.watch<NightscoutService>();
    final sgv = ns.currentEntry;
    final entries = ns.cachedEntries;
    final settings = context.watch<SettingsService>();

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
          // Aktueller Wert + Trend
          _CurrentGlucoseTile(entry: sgv),
          const SizedBox(height: 16),
          // Chart
          _GlucoseChart(entries: entries),
          const SizedBox(height: 16),
          // GPT‑Analyse
          ListTile(
            leading: const Icon(Icons.analytics),
            title: Text(_gptAdvice ?? 'GPT‑Analyse starten'),
            trailing: _isAnalyzing
                ? const CircularProgressIndicator.adaptive()
                : IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _runGptAnalysis(context),
            ),
          ),
          const Divider(),
          // Bolus‑Freigabe
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('Bolus‑Abgabe freigeben'),
            subtitle: Text(
              'Max ${settings.maxBolusUnits.toStringAsFixed(1)} U',
            ),
            trailing: ElevatedButton(
              onPressed: () => _authorizeBolus(context),
              child: const Text('Freigeben'),
            ),
          ),
          const Divider(),
          // Event‑Log
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
      title: Text(e.message),
      subtitle: Text(fmt.format(e.timestamp)),
    );
  }
}

class _CurrentGlucoseTile extends StatelessWidget {
  final GlucoseEntry? entry;
  const _CurrentGlucoseTile({this.entry});

  @override
  Widget build(BuildContext context) {
    final value = entry?.sgv?.toStringAsFixed(0) ?? '—';
    final trend = entry?.trendArrow ?? ' ';
    final time = entry != null
        ? DateFormat.Hm().format(entry!.date)
        : 'Keine Daten';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.opacity),
        title: Text('$value mg/dl $trend',
            style: Theme.of(context).textTheme.headlineMedium),
        subtitle: Text('aktualisiert $time'),
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
        .map((e) =>
        FlSpot(e.date.millisecondsSinceEpoch.toDouble(), e.sgv ?? 0))
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
