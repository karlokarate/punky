/*
 *  start_screen.dart  (v2 – lokalisiert, korrigiert)
 *  --------------------------------------------------------------
 *  Auswahl-Screen nach SetupWizard.
 *  © 2025 Kids Diabetes Companion – GPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:diabetes_kids_app/l10n/gen_l10n/app_localizations.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

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
                l.startTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.child_care),
                label: Text(l.startChild),
                onPressed: () {
                  Navigator.pushNamed(context, '/child');
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.family_restroom),
                label: Text(l.startParent),
                onPressed: () {
                  Navigator.pushNamed(context, '/parent');
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: Text(l.startSettings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/profile_select'),
                child: Text(l.startProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
