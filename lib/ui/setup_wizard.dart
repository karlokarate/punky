/*
 *  setup_wizard.dart  (v1 – SETUP FLOW, lokalisiert)
 *  --------------------------------------------------------------
 *  Initialer Einrichtungsassistent bei App-Start (wenn nicht konfiguriert).
 *  © 2025 Kids Diabetes Companion – GPL‑3.0‑or‑later
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/settings_service.dart';
import '../services/aaps_logic_port.dart';

class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  bool useAAPS = false;
  bool setupComplete = false;

  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _apiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    useAAPS = AAPSLogicPort.isConnected;
    if (useAAPS) {
      _urlController.text = AAPSLogicPort.nightscoutUrl ?? '';
      _apiController.text = '✓ via AAPS';
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await SettingsService.I.setNightscoutUrl(_urlController.text);
      if (!useAAPS) {
        await SettingsService.I.setNightscoutSecret(_apiController.text);
      }
      await SettingsService.I.setInitialSetupDone();
      setState(() => setupComplete = true);
      if (mounted) Navigator.pushReplacementNamed(context, '/start');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.setup.title)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                useAAPS ? l.setup.intro_aaps : l.setup.intro_manual,
                style: t.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(labelText: l.setup.label_url),
                validator: (v) =>
                (v == null || v.isEmpty) ? l.setup.validate_required : null,
              ),
              if (!useAAPS)
                TextFormField(
                  controller: _apiController,
                  decoration: InputDecoration(labelText: l.setup.label_secret),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? l.setup.validate_required : null,
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submit,
                child: Text(l.setup.button_continue),
              )
            ],
          ),
        ),
      ),
    );
  }
}
