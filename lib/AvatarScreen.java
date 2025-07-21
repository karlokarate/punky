/*
 *  avatar_screen.dart
 *  --------------------------------------------------------------
 *  Vollbild‑Editor:
 *    – Zeigt aktuellen Avatar (zusammengesetzte PNG‑Layer)
 *    – Listen‑Tabs je Layer (Body, Head, Accessory, Weapon, Wing)
 *    – Lock‑Icon für Items, die noch nicht freigeschaltet sind
 *    – Eltern können im Eltern‑Profil neue PNGs hochladen
 *
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/avatar_service.dart';
import '../services/settings_service.dart';

class AvatarScreen extends StatelessWidget {
  const AvatarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final a = AvatarService.I;

    return ChangeNotifierProvider.value(
      value: _AvatarAdapter(a),
      child: const _AvatarBody(),
    );
  }
}

class _AvatarBody extends StatelessWidget {
  const _AvatarBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final a = Provider.of<_AvatarAdapter>(context);
    final layers = ['background', 'wing', 'body', 'head', 'accessory', 'weapon'];

    return DefaultTabController(
      length: layers.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Avatar'),
          bottom: TabBar(
            isScrollable: true,
            tabs: layers.map((l) => Tab(text: l.toUpperCase())).toList(),
          ),
        ),
        body: TabBarView(
          children: layers.map((layer) => _layerTab(layer, a)).toList(),
        ),
      ),
    );
  }

  Widget _layerTab(String layer, _AvatarAdapter a) {
    final items = a.itemsForLayer(layer);
    return Column(
      children: [
        const SizedBox(height: 12),
        _AvatarPreview(a),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.count(
            crossAxisCount: 4,
            children: items.map((it) {
              final unlocked = a.unlocked(it.key);
              final selected = a.isSelected(layer, it.key);
              return GestureDetector(
                onTap: unlocked
                    ? () => a.equip(layer, it.key)
                    : () {},
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selected ? Colors.amber : Colors.grey,
                          width: selected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image(
                        image: it.assetPath.startsWith('/')
                            ? FileImage(File(it.assetPath))
                            : AssetImage(it.assetPath) as ImageProvider,
                      ),
                    ),
                    if (!unlocked)
                      const Icon(Icons.lock, color: Colors.red, size: 24),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  final _AvatarAdapter a;
  const _AvatarPreview(this.a);
  @override
  Widget build(BuildContext context) {
    final layers = ['wing', 'body', 'head', 'accessory', 'weapon'];
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        fit: StackFit.expand,
        children: layers.map((layer) {
          final itemKey = a.selectedItem(layer);
          if (itemKey == null) return const SizedBox.shrink();
          final item = a.byKey(itemKey)!;
          final img = item.assetPath.startsWith('/')
              ? FileImage(File(item.assetPath))
              : AssetImage(item.assetPath) as ImageProvider;
          return Image(image: img);
        }).toList(),
      ),
    );
  }
}

/* ---------------- Adapter ---------------- */

class _AvatarAdapter extends ChangeNotifier {
  final AvatarService _a;
  _AvatarAdapter(this._a);

  List<AvatarItem> itemsForLayer(String layer) =>
      _a.catalog.where((e) => e.layer == layer).toList();

  bool unlocked(String key) => _a.itemUnlocked(key);

  bool isSelected(String layer, String key) =>
      _a.state.equipped[layer] == key;

  String? selectedItem(String layer) => _a.state.equipped[layer];

  AvatarItem? byKey(String key) =>
      _a.catalog.firstWhere((e) => e.key == key, orElse: () => null);

  Future<void> equip(String layer, String key) async {
    await _a.equip(layer, key);
    notifyListeners();
  }
}