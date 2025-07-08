/*
 *  settings_screen.dart  (v4 – async-fix)
 *  --------------------------------------------------------------
 *  Dynamischer UI‑Screen basierend auf settings_schema.yaml.
 *  Async/await‑Kompatibilität bei Field‑Settern korrigiert.
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yaml/yaml.dart';
import 'package:diabetes_kids_app/l10n/gen_l10n/app_localizations.dart';

import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: _SettingsAdapter(SettingsService.I),
    child: const _SettingsBody(),
  );
}

/* ---------------- Body ---------------- */

class _SettingsBody extends StatefulWidget {
  const _SettingsBody();

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  late final Map schema;

  @override
  void initState() {
    super.initState();
    schema = loadYaml(
      File('assets/config/settings_schema.yaml').readAsStringSync(),
    ) as Map;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = AppLocalizations.of(context);
    final adapter = context.watch<_SettingsAdapter>();

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          _sectionHeader(l.sectionNightscout, t),
          _textField(l.labelNsUrl, adapter.nsUrl, adapter.setNsUrl),
          _textField(l.labelNsSecret, adapter.nsSecret, adapter.setNsSecret),

          _sectionHeader(l.sectionApiKeys, t),
          _textField(l.labelGpt, adapter.gpt, adapter.setGpt),
          _textField(l.labelWhisper, adapter.whisper, adapter.setWhisper),
          _textField(l.labelVision, adapter.vision, adapter.setVision),

          _sectionHeader(l.sectionModes, t),
          _dropdown(l.labelSpeechMode, adapter.speechMode, adapter.setSpeechMode,
              ['offline', 'hybrid', 'online']),
          _dropdown(l.labelImageMode, adapter.imageMode, adapter.setImageMode,
              ['offline', 'hybrid', 'online']),

          _sectionHeader(l.sectionNotifications, t),
          _boolSwitch(l.labelPush, adapter.push, adapter.setPush),
          _boolSwitch(l.labelSms, adapter.sms, adapter.setSms),
          _boolSwitch(l.labelMute, adapter.mute, adapter.setMute),
          _textField(l.labelPhone, adapter.phone, adapter.setPhone),

          _sectionHeader(l.sectionPoints, t),
          _numberField(l.labelPpMeal, adapter.ppMeal, adapter.setPpMeal),
          _numberField(l.labelPpSnack, adapter.ppSnack, adapter.setPpSnack),
          _numberField(l.labelBonus, adapter.bonus, adapter.setBonusSnacks),

          _sectionHeader(l.sectionHealth, t),
          _numberField(l.labelCarbWarn, adapter.carbWarn, adapter.setCarbWarn),

          _sectionHeader(l.sectionAvatar, t),
          _dropdown(l.labelTheme, adapter.theme, adapter.setTheme,
              SettingsService.defaultThemes),
          ListTile(
            title: Text(l.labelUploadItem),
            trailing: const Icon(Icons.upload_file),
            onTap: () => _pickAvatarItem(context),
          ),

          _sectionHeader(l.sectionInfo, t),
          Center(
            child: TextButton(
              onPressed: () => launchUrl(
                Uri.parse('https://github.com/nightscout/androidaps'),
              ),
              child: Text(l.linkAboutAAPS),
            ),
          ),
        ],
      ),
    );
  }

  /* ---------------- Helper Widgets ---------------- */

  Widget _sectionHeader(String title, ThemeData t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
    child: Text(
      title,
      style:
      t.textTheme.titleMedium!.copyWith(color: t.colorScheme.secondary),
    ),
  );

  Widget _textField(
      String label,
      String val,
      Future<void> Function(String) setter,
      ) =>
      ListTile(
        title: Text(label),
        subtitle: TextFormField(
          initialValue: val,
          onFieldSubmitted: (v) async => await setter(v),
        ),
      );

  Widget _numberField(
      String label,
      int val,
      Future<void> Function(int) setter,
      ) =>
      ListTile(
        title: Text(label),
        subtitle: TextFormField(
          initialValue: '$val',
          keyboardType: TextInputType.number,
          onFieldSubmitted: (v) async =>
          await setter(int.tryParse(v) ?? val),
        ),
      );

  Widget _dropdown(
      String label,
      String current,
      Future<void> Function(String?) onChanged,
      List<String> opts,
      ) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<String>(
        value: current,
        items: opts
            .map((e) => DropdownMenuItem(
          value: e,
          child: Text(e.toUpperCase()),
        ))
            .toList(),
        onChanged: (v) async => await onChanged(v),
      ),
    );
  }

  Widget _boolSwitch(
      String label,
      bool val,
      Future<void> Function(bool) setter,
      ) =>
      SwitchListTile(
        title: Text(label),
        value: val,
        onChanged: (v) async => await setter(v),
      );

  Future<void> _pickAvatarItem(BuildContext ctx) async {
    final l = AppLocalizations.of(ctx);
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img == null) return;

    final bytes = await img.readAsBytes();
    if (bytes.lengthInBytes > 200 * 1024) {
      // Kein async-Zwischenstopp mehr für ctx
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.msgFileTooBig)),
      );
      return;
    }

    await SettingsService.I.applyRemotePayload({
      'type': 'asset_upload',
      'assetType': 'avatarItem',
      'name': img.name,
      'mime': img.mimeType ?? 'image/png',
      'data': base64Encode(bytes),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.msgItemAdded)),
    );
  }

}

/* ---------------- Adapter ---------------- */

class _SettingsAdapter extends ChangeNotifier {
  final SettingsService s;
  _SettingsAdapter(this.s);

  String get nsUrl => s.nightscoutUrl;
  String get nsSecret => s.nightscoutSecretSHA1;
  String get gpt => s.gptApiKey;
  String get whisper => s.whisperApiKey;
  String get vision => s.visionApiKey;

  String get speechMode => s.speechMode;
  String get imageMode => s.imageMode;

  bool get push => s.enablePush;
  bool get sms => s.enableSms;
  bool get mute => s.muteAlarms;
  String get phone => s.parentPhone;

  int get ppMeal => s.pointsPerMeal;
  int get ppSnack => s.pointsPerSnack;
  int get bonus => s.bonusEverySnacks;

  int get carbWarn => s.carbWarnThreshold;

  String get theme => s.childThemeKey;

  Future<void> setNsUrl(String v) => _set(() => s.setNightscoutUrl(v));
  Future<void> setNsSecret(String v) => _set(() => s.setNightscoutSecret(v));
  Future<void> setGpt(String v) => _set(() => s.setGptApiKey(v));
  Future<void> setWhisper(String v) => _set(() => s.setWhisperApiKey(v));
  Future<void> setVision(String v) => _set(() => s.setVisionApiKey(v));

  Future<void> setSpeechMode(String? v) =>
      _set(() => s.setSpeechMode(v ?? s.speechMode));
  Future<void> setImageMode(String? v) =>
      _set(() => s.setImageMode(v ?? s.imageMode));

  Future<void> setPush(bool v) => _set(() => s.setEnablePush(v));
  Future<void> setSms(bool v) => _set(() => s.setEnableSms(v));
  Future<void> setMute(bool v) => _set(() => s.setMuteAlarms(v));
  Future<void> setPhone(String v) => _set(() => s.setParentPhone(v));

  Future<void> setPpMeal(int v) => _set(() => s.setPointsPerMeal(v));
  Future<void> setPpSnack(int v) => _set(() => s.setPointsPerSnack(v));
  Future<void> setBonusSnacks(int v) => _set(() => s.setBonusEverySnacks(v));

  Future<void> setCarbWarn(int v) => _set(() => s.setCarbWarnThreshold(v));

  Future<void> setTheme(String? v) async {
    if (v != null) await _set(() => s.setChildTheme(v));
  }

  Future<void> _set(Future<void> Function() f) async {
    await f();
    notifyListeners();
  }
}
