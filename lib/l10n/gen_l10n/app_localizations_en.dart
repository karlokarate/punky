// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get sectionNightscout => 'Nightscout';

  @override
  String get labelNsUrl => 'Nightscout‑URL';

  @override
  String get labelNsSecret => 'API‑Secret (SHA1)';

  @override
  String get sectionApiKeys => 'API‑Schlüssel';

  @override
  String get labelGpt => 'GPT‑Schlüssel';

  @override
  String get labelWhisper => 'Whisper‑Schlüssel';

  @override
  String get labelVision => 'Vision‑Schlüssel';

  @override
  String get sectionModes => 'Modi';

  @override
  String get labelSpeechMode => 'Sprachmodus';

  @override
  String get labelImageMode => 'Bildmodus';

  @override
  String get sectionSecurity => 'Security';

  @override
  String get labelParentPin => 'Parent PIN';

  @override
  String get sectionNotifications => 'Benachrichtigungen';

  @override
  String get labelPush => 'Push aktivieren';

  @override
  String get labelSms => 'SMS aktivieren';

  @override
  String get labelMute => 'Stumm‑Modus';

  @override
  String get labelPhone => 'Eltern‑Telefonnummer';

  @override
  String get sectionPoints => 'Punkte‑System';

  @override
  String get labelPpMeal => 'Punkte pro Mahlzeit';

  @override
  String get labelPpSnack => 'Punkte pro Snack';

  @override
  String get labelBonus => 'Snack‑Bonus (X Snacks)';

  @override
  String get sectionHealth => 'Gesundheit';

  @override
  String get labelCarbWarn => 'KH‑Warnschwelle (g)';

  @override
  String get sectionAvatar => 'Avatar';

  @override
  String get labelTheme => 'Avatar‑Thema';

  @override
  String get labelUploadItem => 'Item hochladen';

  @override
  String get sectionInfo => 'Info';

  @override
  String get linkAboutAAPS => 'Über AAPS';

  @override
  String get msgFileTooBig => 'Datei zu groß';

  @override
  String get msgItemAdded => 'Item hinzugefügt!';

  @override
  String get aiEnabled => 'GPT enable';

  @override
  String get aiMaxTokens => 'Token limit';

  @override
  String get aiModel => 'GPT‑Modell';

  @override
  String get aiOpenaiApiKey => 'OpenAI API key';

  @override
  String get aiRestrictChild => 'Restrict child usage';

  @override
  String get aiTitle => 'Artificial Intelligence';

  @override
  String get alarmsHypoDelta => 'Drop rate‑Alarm (mg/dl)';

  @override
  String get alarmsHypoEnabled => 'Hypo‑Alarm enable';

  @override
  String get alarmsHypoThreshold => 'Hypo‑Threshold (mg/dl)';

  @override
  String get alarmsNoDataEnabled => 'Kein‑Daten‑Alarm aktiv';

  @override
  String get alarmsNoDataTimeout => 'Timeout bei fehlenden Daten (min)';

  @override
  String get alarmsPumpOfflineEnabled => 'Pumpe offline‑Alarm aktiv';

  @override
  String get alarmsPumpOfflineTimeout => 'Timeout bei Pumpenverbindung (min)';

  @override
  String get alarmsQuietEnd => 'Ruhezeit Ende';

  @override
  String get alarmsQuietStart => 'Ruhezeit Start';

  @override
  String get alarmsTitle => 'Alarms & Warningen';

  @override
  String get avatarAccessory => 'Zubehör';

  @override
  String get avatarBackground => 'Hintergrand';

  @override
  String get avatarBody => 'Körper';

  @override
  String get avatarHead => 'Kopf';

  @override
  String get avatarLayerTitle => 'Avatar';

  @override
  String get avatarTitle => 'Avatar';

  @override
  String get avatarWeapon => 'Waffe';

  @override
  String get avatarItemLocked => 'Noch nicht freigeschaltet';

  @override
  String get avatarItemTapToEquip => 'Antippen zum Ausrüsten';

  @override
  String get avatarItemTapToPreview => 'Lange tippen für Vorschau';

  @override
  String get avatarItemUpload => 'Eigenes Item hochladen';

  @override
  String get avatarItemUnlocked => 'Freigeschaltet!';

  @override
  String get avatarPreviewTitle => 'Dein Avatar';

  @override
  String avatarEquipSuccess(Object item) {
    return '$item wurde ausgerüstet!';
  }

  @override
  String avatarEquipFailed(Object item) {
    return '$item konnte nicht ausgerüstet werden.';
  }

  @override
  String avatarUnlockedNewItem(Object item) {
    return 'Neues Avatar-Item freigeschaltet: $item!';
  }

  @override
  String get avatarRandomize => 'Zufällig';

  @override
  String get avatarWing => 'Flügel';

  @override
  String get avatarLocked => 'Gesperrt';

  @override
  String avatarLockedPts(Object points) {
    return 'Benötigt $points Punkte';
  }

  @override
  String avatarLockedLvl(Object level) {
    return 'Benötigt Level $level';
  }

  @override
  String avatarLockedPtsLvl(Object points, Object level) {
    return 'Benötigt $points Punkte und Level $level';
  }

  @override
  String get bolusNoteAuto => 'Auto‑Bolus via BolusEngine';

  @override
  String bolusReasonAaps(Object ratio) {
    return 'AAPS‑Faktor $ratio g/IE';
  }

  @override
  String bolusReasonManual(Object carbs, Object ratio) {
    return 'carbs $carbs ÷ Faktor $ratio';
  }

  @override
  String get bolusErrorBridge =>
      'Insulin-Faktor konnte nicht über AAPS ermittelt werden.';

  @override
  String bolusNoteBridge(Object units) {
    return 'AAPS-Bolus: $units Einheiten';
  }

  @override
  String carbAnalysisReasonDefault(Object carbs, Object ratio) {
    return 'carbs $carbs ÷ Faktor $ratio';
  }

  @override
  String get carbAnalysisWarnExcessive =>
      'Check die Eingabe – carbs wirken ungewöhnlich hoch.';

  @override
  String get carbAnalysisWarnFuzzy =>
      '⚠️ Einige Produkte wurden nur unscharf gefanden.';

  @override
  String carbAnalysisWarnHigh(Object carbs) {
    return 'Meal enthält viele Kohlenhydrate ($carbs g).';
  }

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDetails => 'Details';

  @override
  String get commonOk => 'OK';

  @override
  String get commParentApprovalBolus => 'Bolus braucht Parentsfreigabe';

  @override
  String get commParentApprovalSnack => 'Snack braucht Parentsfreigabe';

  @override
  String get commPushEnabled => 'Push notifications erlauben';

  @override
  String get commSmsEnabled => 'SMS an Parents erlauben';

  @override
  String get commSmsNumber => 'Parents Notfallnummer';

  @override
  String get commTitle => 'Communication & Freigabe';

  @override
  String get devicesDexcomActive => 'Dexcom verwenden';

  @override
  String get devicesOmnipodActive => 'Omnipod verwenden';

  @override
  String get devicesPodExpiryWarn => 'Pod Ablaufwarnung ab (h)';

  @override
  String get devicesPodReservoirWarn => 'Reservoir‑Warning ab (h)';

  @override
  String get devicesTitle => 'Verbandene Geräte';

  @override
  String get debugEnabled => 'Debugmodus aktiv';

  @override
  String get debugTestMode => 'Testmodus aktiv';

  @override
  String get debugTitle => 'Debug & Test';

  @override
  String get gameLevelUpPoints => 'Level‑Up ab Pointsn';

  @override
  String get gameMaxSnacksPerDay => 'Snacks pro Tag (max)';

  @override
  String get gamePointsPerInput => 'Points pro Eintrag';

  @override
  String get gameRewardReasonBonus => 'Bonus';

  @override
  String get gameRewardReasonBolus => 'Bolusgabe';

  @override
  String gameRewardReasonGuess(Object diff) {
    return 'carbs‑Schätzspiel (Abweichung: $diff g)';
  }

  @override
  String get gameRewardReasonInput => 'Eingabe';

  @override
  String get gameRewardReasonLevelUp => 'Level‑Up!';

  @override
  String get gameRewardReasonMeal => 'Meal eingetragen';

  @override
  String get gameRewardReasonPenalty => 'Abzug';

  @override
  String get gameRewardReasonSnack => 'Snack eingetragen';

  @override
  String gameRewardReasonSnackBonus(Object count) {
    return 'Snack‑Bonus! $count Snacks heute';
  }

  @override
  String get gameRewardReasonSnackPenalty => 'Zu viele Snacks heute!';

  @override
  String get gameRewardsEnabled => 'Belohnungen enable';

  @override
  String get gameSnackBonus => 'Snack Bonuspunkte';

  @override
  String get gameSnackPenalty => 'Snack‑Pointsabzug';

  @override
  String get gameTitle => 'Gamification & Points';

  @override
  String get guessBtnContinue => 'Weiter';

  @override
  String get guessBtnOk => 'OK';

  @override
  String get guessErrorNoNumber => 'Bitte eine Zahl eingeben!';

  @override
  String guessFeedbackActual(Object actual) {
    return 'Tatsächliche carbs‑Menge: $actual g';
  }

  @override
  String guessFeedbackGuess(Object guess) {
    return 'Deine Schätzung: $guess g';
  }

  @override
  String get guessResultFail =>
      'Das war schon schwierig, oder? Nächstes Mal wird\'\'s besser!';

  @override
  String guessResultGood(Object diff) {
    return 'Gut gemacht! Nur $diff g daneben. (+2 Points)';
  }

  @override
  String guessResultGreat(Object diff) {
    return 'Sehr gut! Nur $diff g daneben! (+5 Points)';
  }

  @override
  String get guessResultPerfect =>
      'Wahnsinn! Du hast es super genau geschätzt! (+10 Points)';

  @override
  String get guessTitle =>
      'Schätzspiel: Wie viele Kohlenhydrate (g) hat deine Meal?';

  @override
  String get guessInputLabel => 'Deine Schätzung (g)';

  @override
  String get homeBtnHistory => 'Verlauf';

  @override
  String get homeBtnMeal => 'Meal';

  @override
  String get homeBtnSnack => 'Snack';

  @override
  String get homeCob => 'COB';

  @override
  String get homeIob => 'IOB';

  @override
  String homeLevel(Object level) {
    return 'Level $level';
  }

  @override
  String get homeMsgSpeechSuccess => 'Sprache erfolgreich erkannt.';

  @override
  String homeMsgPoints(Object points) {
    return '+$points Punkte!';
  }

  @override
  String get btnMeal => 'MAHLZEIT';

  @override
  String get btnSnack => 'SNACK';

  @override
  String get btnGuess => 'RATEN';

  @override
  String get homeLoop => 'Loop';

  @override
  String homeMsgPointsAdded(Object points) {
    return '🎉 +$points Points';
  }

  @override
  String homePoints(Object points) {
    return '$points P';
  }

  @override
  String get khGameActual => 'carbs‑Analyse';

  @override
  String get khGameAiGuess => 'ChefBot‑Tipp';

  @override
  String get khGameClose => 'Fast richtig geraten.';

  @override
  String get khGameMiss => 'Leider daneben – versuch\'\'s nochmal!';

  @override
  String get khGamePerfect => 'Perfekt geschätzt!';

  @override
  String khGameResultActual(Object value) {
    return 'Tatsächliche carbs: $value g';
  }

  @override
  String khGameResultError(Object value) {
    return 'Fehlerdifferenz: $value g';
  }

  @override
  String get khGameResultTitle => 'Ergebnis';

  @override
  String khGameResultUser(Object value) {
    return 'Deine Schätzung: $value g';
  }

  @override
  String khGameResultXp(Object value) {
    return 'XP erhalten: $value';
  }

  @override
  String khGameStreak(Object days) {
    return 'Streak: $days Tage';
  }

  @override
  String get khGameSubmit => 'Bestätigen';

  @override
  String get khGameTitle => 'carbs‑Schätz‑Duell';

  @override
  String get khGameWin => '🎉 Du hast ChefBot geschlagen!';

  @override
  String get limitsBzMax => 'Maximaler BZ‑Wert';

  @override
  String get limitsBzMin => 'Minimaler BZ‑Wert';

  @override
  String get limitsKhWarnLimit => 'carbs‑Warnschwelle (g)';

  @override
  String get limitsTitle => 'BZ‑ & carbs‑Thresholdn';

  @override
  String get mealRevDialogCarbs => 'Kohlenhydrate';

  @override
  String mealCarbNoteShort(Object carbs) {
    return 'Meal mit $carbs g KH analysiert';
  }

  @override
  String get mealRevDialogConfirm => 'Bolus übernehmen';

  @override
  String get mealRevDialogNone => 'Keine weiteren Hinweise.';

  @override
  String get mealRevDialogTitle => 'Bolus‑Empfehlung prüfen';

  @override
  String get mealRevRecommendation => 'Bolus‑Empfehlung';

  @override
  String get mealRevRecommendedBy => 'Empfohlen durch AAPS';

  @override
  String get mealRevSectionAdd => 'Neuer Bestandteil';

  @override
  String get mealRevSectionFinalizeButton => 'Abschließen';

  @override
  String get mealRevSectionFinalizeInfo =>
      'Super gemacht! Die Daten werden nun saved and ggf. an Nightscout übertragen.';

  @override
  String get mealRevSectionGrams => 'g';

  @override
  String mealRevSectionLevel(Object level) {
    return 'Level: $level';
  }

  @override
  String mealRevSectionPoints(Object points) {
    return 'Deine Points: $points';
  }

  @override
  String get mealRevSectionRecognized => 'Erkannte Bestandteile:';

  @override
  String get mealRevSectionWarning => 'Warningen';

  @override
  String get mealRevSnackbarSaved => 'Meal saved!';

  @override
  String get mealRevTitleChild => 'Meal überprüfen';

  @override
  String get mealRevTitleParent => 'Meal ansehen';

  @override
  String get mealRevTotalLabel => 'Gesamte carbs‑Menge';

  @override
  String get mealReviewTitle => 'Mealen‑Review';

  @override
  String get notifApprovalReceived => 'Du darfst jetzt Bolus abgeben.';

  @override
  String notifKhReceivedSms(Object value) {
    return 'carbs per SMS empfangen: $value g';
  }

  @override
  String get notifParentConfirmed => 'Parents haben carbs‑Freigabe bestätigt.';

  @override
  String notifPushSent(Object type) {
    return 'Push gesendet: $type';
  }

  @override
  String notifSettingChanged(Object key, Object value) {
    return '$key = $value';
  }

  @override
  String get notifSettingsUpdated => 'Settings aktualisiert';

  @override
  String notifSnackLimitChanged(Object limit) {
    return 'Snack‑Limit geändert: $limit';
  }

  @override
  String get notifSyncReceived => 'Settings übernommen!';

  @override
  String notifAlarmHypoChild(Object value) {
    return 'Dein Zucker ist niedrig ($value mg/dl). Bitte sag einem Erwachsenen Bescheid!';
  }

  @override
  String notifAlarmHypoParent(Object value, Object delta) {
    return 'Achtung: Blutzucker bei $value mg/dl! Drop rate: -$delta.';
  }

  @override
  String notifAlarmHypoShort(Object value) {
    return 'Niedriger BZ: $value mg/dl';
  }

  @override
  String get notifAlarmHypoTitle => 'ALARM! HYPO';

  @override
  String notifAlarmNoDataText(Object minutes) {
    return 'Seit über $minutes Minuten keine Werte mehr empfangen.';
  }

  @override
  String get notifAlarmNoDataTitle => 'Daten fehlen';

  @override
  String notifAlarmPumpOfflineText(Object minutes) {
    return 'Seit $minutes Minuten keine Verbindung zur Pumpe.';
  }

  @override
  String get notifAlarmPumpOfflineTitle => 'Pumpe nicht erreichbar';

  @override
  String get nsApiKey => 'API‑Schlüssel';

  @override
  String get nsTitle => 'Nightscout';

  @override
  String get nsUrl => 'Nightscout URL';

  @override
  String get parserErrorNotLoaded =>
      'TextParser: YAML nicht geladen. Bitte zuerst \'loadUnitsFromYaml\' aufrufen.';

  @override
  String get settingsAvatarLabelTheme => 'Thema';

  @override
  String get settingsAvatarLabelUploadItem => 'Avatar‑Item hochladen';

  @override
  String get settingsFieldBonusSnacks => 'Snack‑Bonus‑Intervall';

  @override
  String get settingsFieldCarbWarn => 'carbs‑Warnschwelle';

  @override
  String get settingsFieldChildThemeKey => 'Avatar‑Thema';

  @override
  String get settingsFieldEnablePush => 'Push aktiviert';

  @override
  String get settingsFieldEnableSms => 'SMS‑Fallback';

  @override
  String get settingsFieldGptApiKey => 'ChatGPT‑Schlüssel';

  @override
  String get settingsFieldImageMode => 'Bildmodus';

  @override
  String get settingsFieldMuteAlarms => 'Alarms stumm';

  @override
  String get settingsFieldNightscoutSecret => 'API‑Secret';

  @override
  String get settingsFieldNightscoutUrl => 'Nightscout URL';

  @override
  String get settingsFieldParentPhone => 'Parents‑Telefon';

  @override
  String get settingsFieldPointsMeal => 'Points pro Meal';

  @override
  String get settingsFieldPointsSnack => 'Points pro Snack';

  @override
  String get settingsFieldSpeechMode => 'Sprachmodus';

  @override
  String get settingsFieldVisionApiKey => 'Vision‑Schlüssel';

  @override
  String get settingsMsgFileTooBig => 'Datei zu groß';

  @override
  String get settingsMsgItemAdded => 'Item hinzugefügt!';

  @override
  String get settingsNoTime => 'Nicht gesetzt';

  @override
  String get settingsSaveButton => 'Speichern';

  @override
  String get settingsSectionApiKeys => 'API‑Schlüssel';

  @override
  String get settingsSectionAvatar => 'Avatar';

  @override
  String get settingsSectionHealth => 'Gesandheit';

  @override
  String get settingsSectionInfo => 'Info';

  @override
  String get settingsSectionModes => 'Betriebsmodi';

  @override
  String get settingsSectionNightscout => 'Nightscout';

  @override
  String get settingsSectionNotifications => 'Benachrichtigungen';

  @override
  String get settingsSectionPoints => 'Points‑System';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get setupButtonContinue => 'Weiter zur App';

  @override
  String get setupIntroAaps => 'Nightscout‑Daten wurden aus AAPS übernommen.';

  @override
  String get setupIntroManual => 'Bitte gib deine Nightscout‑Daten ein:';

  @override
  String get setupLabelSecret => 'API‑Secret (SHA1)';

  @override
  String get setupLabelUrl => 'Nightscout‑URL';

  @override
  String get setupTitle => 'Ersteinrichtung';

  @override
  String get setupValidateRequired => 'Pflichtfeld';

  @override
  String get startChild => 'Ich bin das Kind';

  @override
  String get startParent => 'Ich bin ein Parentsteil';

  @override
  String get startProfile => 'Profil wechseln / einrichten';

  @override
  String get startSettings => 'Settings';

  @override
  String get startTitle => 'Willkommen!\nWer bist du?';

  @override
  String get speechBtnCancel => 'Abbrechen';

  @override
  String get speechBtnStart => 'Aufnahme';

  @override
  String get speechBtnStop => 'Fertig';

  @override
  String get speechDialogRecord => 'Sprich bitte deutlich in dein Gerät.';

  @override
  String get speechDialogTitleReady => 'Bereit für Aufnahme?';

  @override
  String get speechDialogTitleRecording => 'Sprich jetzt!';

  @override
  String get speechDialogInstruction =>
      'Drücke Aufnahme and sprich dann ins Mikrofon.';

  @override
  String get speechErrorApi => 'Fehler bei der Sprachverarbeitung:';

  @override
  String get speechErrorEmpty => 'Keine Sprache erkannt.';

  @override
  String get speechErrorFileMissing => 'Keine Audiodatei gefanden.';

  @override
  String get speechErrorInvalidResponse => 'Unerwartete Antwort von Whisper.';

  @override
  String get speechErrorNetwork => 'Keine Netzwerkverbindung.';

  @override
  String get speechErrorNoApiKey => 'OpenAI API key fehlt.';

  @override
  String get speechErrorNoFile => 'Es wurde keine Aufnahme erkannt.';

  @override
  String get speechErrorOfflineEngine =>
      'Offline‑Spracherkennung nicht verfügbar.';

  @override
  String get speechErrorPermission => 'Mikrofonberechtigung erforderlich.';

  @override
  String get speechPluginError => 'Fehler bei Aufnahme über Plugin.';

  @override
  String syncError(Object error) {
    return 'Netzwerkfehler bei Sync: $error';
  }

  @override
  String syncFailure(Object type) {
    return 'Synchronisierung fehlgeschlagen: $type';
  }

  @override
  String syncSuccess(Object type) {
    return 'Synchronisierung erfolgreich: $type';
  }

  @override
  String syncUnknownEvent(Object type) {
    return 'Unbekannter Event vom Server: $type';
  }
}
