// -----------------------------------------------------------------------------
//  avatar_screen.dart  (v3 – full‑featured)
//  -----------------------------------------------------------------------------
//  • Tab‑basierter Editor für alle Avatar‑Layer
//  • Sperren‑/Freischalten‑Anzeige inkl. Tooltip für Unlock‑Bedingungen
//  • Auswahl wird live gespeichert (AvatarService)
//  • Unterstützt Custom‑Uploads (lokale PNGs)
//  • Mini‑Gamification: Zufällige Preview‑Würfel‑Action per FAB
//  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diabetes_kids_app/l10n/gen_l10n/app_localizations.dart';
import '../services/avatar_service.dart';

class AvatarScreen extends StatelessWidget {
  const AvatarScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: AvatarService.I,
    child: const _Body(),
  );
}

/* ═══════════════════════════════════ UI‑BODY ═══════════════════════════════ */

class _Body extends StatelessWidget {
  const _Body();

  static const _layers = [
    'background',
    'wing',
    'body',
    'head',
    'accessory',
    'weapon'
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return DefaultTabController(
      length: _layers.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.avatarTitle),
          bottom: TabBar(
              isScrollable: true,
              tabs: _layers.map((e) => Tab(text: _label(l, e))).toList()),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: l.avatarRandomize,
          onPressed: () {
            final rnd = _layers
                .map((layer) {
              final candidates = AvatarService.I
                  .itemsForLayer(layer)
                  .where((i) => AvatarService.I.itemUnlocked(i.key))
                  .toList();
              if (candidates.isEmpty) return null;
              candidates.shuffle();
              return candidates.first;
            })
                .whereType<AvatarItem>()
                .toList();

            for (final i in rnd) {
              AvatarService.I.equip(i.layer, i.key);
            }
          },

          child: const Icon(Icons.shuffle),
        ),
        body: TabBarView(
          children: _layers.map((layer) => _LayerTab(layer)).toList(),
        ),
      ),
    );
  }

  String _label(AppLocalizations l, String layer) {
    switch (layer) {
      case 'background':
        return l.avatarBackground;
      case 'wing':
        return l.avatarWing;
      case 'body':
        return l.avatarBody;
      case 'head':
        return l.avatarHead;
      case 'accessory':
        return l.avatarAccessory;
      case 'weapon':
        return l.avatarWeapon;
      default:
        return layer;
    }
  }
}

/* ══════════════════════════════════ LAYER TAB ══════════════════════════════ */

class _LayerTab extends StatelessWidget {
  const _LayerTab(this.layer);
  final String layer;

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<AvatarService>();
    final items = svc.itemsForLayer(layer);

    return Column(
      children: [
        const SizedBox(height: 16),
        const _AvatarPreview(),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, childAspectRatio: .9),
            itemCount: items.length,
            itemBuilder: (_, i) => _ItemTile(layer: layer, item: items[i]),
          ),
        ),
      ],
    );
  }
}

/* ══════════════════════════════════ ITEM TILE ══════════════════════════════ */

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.layer, required this.item});

  final String layer;
  final AvatarItem item;

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<AvatarService>();
    final unlocked = svc.itemUnlocked(item.key);
    final selected = svc.selectedItem(layer) == item.key;

    final imgProvider = item.assetPath.startsWith('/')
        ? FileImage(File(item.assetPath))
        : AssetImage(item.assetPath) as ImageProvider;

    return GestureDetector(
      onTap: unlocked ? () => svc.equip(layer, item.key) : null,
      child: Tooltip(
        message: unlocked
            ? item.name
            : _lockedMsg(context, item.unlock, AppLocalizations.of(context)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(
                    color: selected ? Colors.amber : Colors.grey,
                    width: selected ? 3 : 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image(image: imgProvider, fit: BoxFit.contain),
            ),
            if (!unlocked)
              const Icon(Icons.lock, size: 28, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  String _lockedMsg(BuildContext ctx, UnlockCondition? c, AppLocalizations l) {
    if (c == null) return l.avatarLocked;
    final pts = c.minPoints;
    final lvl = c.minLevel;
    if (pts != null && lvl != null) {
      return l.avatarLockedPtsLvl(pts, lvl);
    } else if (pts != null) {
      return l.avatarLockedPts(pts);
    } else if (lvl != null) {
      return l.avatarLockedLvl(lvl);
    }
    return l.avatarLocked;
  }
}

/* ══════════════════════════════════ PREVIEW ════════════════════════════════ */

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview();

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<AvatarService>();
    final imgPaths = svc.getImagePaths();

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: imgPaths.map((p) {
          final provider =
          p.startsWith('/') ? FileImage(File(p)) : AssetImage(p) as ImageProvider;
          return Image(image: provider);
        }).toList(),
      ),
    );
  }
}
