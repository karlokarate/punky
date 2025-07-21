/*
 *  setup_wizard.dart  (v4 – FINAL)
 *  --------------------------------------------------------------
 *  Initialer Einrichtungsassistent bei App‑Start.
 *  Erkennt aktive AAPS-Verbindung über AapsLogicPort.
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'package:diabetes_kids_app/core/app_context.dart';
import 'package:flutter/material.dart';
import 'package:diabetes_kids_app/l10n/gen_l10n/app_localizations.dart';

import '../services/settings_service.dart';
import '../services/aaps_logic_port.dart';

class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key, required AppContext appContext});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  bool useAAPS = false;
  bool loading = true;
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _apiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAAPS();
  }

  Future<void> _checkAAPS() async {
    final profile = await AapsLogicPort.getActiveProfile();
    if (!mounted) return;
    setState(() {
      useAAPS = profile != null;
      loading = false;
      if (useAAPS) {
        _urlController.text = profile?['nsUrl'] ?? '';
        _apiController.text = '✓ via AAPS';
      }
    });
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (!mounted) return;

    if (_formKey.currentState?.validate() ?? false) {
      await SettingsService.I.setNightscoutUrl(_urlController.text);
      if (!useAAPS) {
        await SettingsService.I.setNightscoutSecret(_apiController.text);
      }
      await SettingsService.I.setInitialSetupDone(true);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/start');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.setupValidateRequired)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.setupTitle)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                useAAPS ? l.setupIntroAaps : l.setupIntroManual,
                style: t.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(labelText: l.setupLabelUrl),
                validator: (v) =>
                (v == null || v.isEmpty) ? l.setupValidateRequired : null,
              ),
              if (!useAAPS) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _apiController,
                  decoration:
                  InputDecoration(labelText: l.setupLabelSecret),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? l.setupValidateRequired : null,
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(l.setupButtonContinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiController.dispose();
    super.dispose();
  }
}