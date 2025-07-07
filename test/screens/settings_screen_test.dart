import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diabetes_kids_app/screens/settings_screen.dart';
import 'package:diabetes_kids_app/utils/localization_helper.dart';
import 'package:diabetes_kids_app/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Lokalisierung laden (de.yaml muss vorhanden sein)
    await LocalizationHelper.init();
    // Settings laden (mocked in memory)
    await SettingsService.instance.loadSettings();
  });

  testWidgets('Settings screen renders and allows toggling', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    // Ladeanzeige abwarten
    await tester.pumpAndSettle();

    // Überprüfen, ob ein bekannter Text erscheint
    expect(find.text(LocalizationHelper.get('settings.title')), findsOneWidget);
    expect(find.text(LocalizationHelper.get('settings.save_button')), findsOneWidget);

    // Optional: Schalter oder Textfeld finden (je nach YAML)
    final toggles = find.byType(SwitchListTile);
    if (toggles.evaluate().isNotEmpty) {
      await tester.tap(toggles.first);
      await tester.pump();
    }

    // Speichern drücken
    await tester.tap(find.text(LocalizationHelper.get('settings.save_button')));
    await tester.pump();

    // SnackBar bestätigen
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
