/*
 *  start_screen.dart  (v1 – PROTOTYP, lokalisiert)
 *  --------------------------------------------------------------
 *  Auswahl-Screen nach SetupWizard.
 */

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                l.start.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.child_care),
                label: Text(l.start.child),
                onPressed: () {
                  Navigator.pushNamed(context, '/child');
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.family_restroom),
                label: Text(l.start.parent),
                onPressed: () {
                  Navigator.pushNamed(context, '/parent');
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: Text(l.start.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/profile_select'),
                child: Text(l.start.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
