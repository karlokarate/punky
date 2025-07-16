import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// Nachtwächter-Konfiguration
  ///
  /// In de, this message translates to:
  /// **'Nightscout'**
  String get sectionNightscout;

  /// URL zur Nightscout-Instanz
  ///
  /// In de, this message translates to:
  /// **'Nightscout‑URL'**
  String get labelNsUrl;

  /// Nightscout-API-Secret
  ///
  /// In de, this message translates to:
  /// **'API‑Secret (SHA1)'**
  String get labelNsSecret;

  /// Bereich für externe API-Zugänge
  ///
  /// In de, this message translates to:
  /// **'API‑Schlüssel'**
  String get sectionApiKeys;

  /// No description provided for @labelGpt.
  ///
  /// In de, this message translates to:
  /// **'GPT‑Schlüssel'**
  String get labelGpt;

  /// No description provided for @labelWhisper.
  ///
  /// In de, this message translates to:
  /// **'Whisper‑Schlüssel'**
  String get labelWhisper;

  /// No description provided for @labelVision.
  ///
  /// In de, this message translates to:
  /// **'Vision‑Schlüssel'**
  String get labelVision;

  /// Erkennungs- und Betriebsmodi
  ///
  /// In de, this message translates to:
  /// **'Modi'**
  String get sectionModes;

  /// No description provided for @labelSpeechMode.
  ///
  /// In de, this message translates to:
  /// **'Sprachmodus'**
  String get labelSpeechMode;

  /// No description provided for @labelImageMode.
  ///
  /// In de, this message translates to:
  /// **'Bildmodus'**
  String get labelImageMode;

  /// No description provided for @sectionSecurity.
  ///
  /// In de, this message translates to:
  /// **'Security'**
  String get sectionSecurity;

  /// No description provided for @labelParentPin.
  ///
  /// In de, this message translates to:
  /// **'Parent PIN'**
  String get labelParentPin;

  /// Push, SMS & Mute
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get sectionNotifications;

  /// No description provided for @labelPush.
  ///
  /// In de, this message translates to:
  /// **'Push aktivieren'**
  String get labelPush;

  /// No description provided for @labelSms.
  ///
  /// In de, this message translates to:
  /// **'SMS aktivieren'**
  String get labelSms;

  /// No description provided for @labelMute.
  ///
  /// In de, this message translates to:
  /// **'Stumm‑Modus'**
  String get labelMute;

  /// No description provided for @labelPhone.
  ///
  /// In de, this message translates to:
  /// **'Eltern‑Telefonnummer'**
  String get labelPhone;

  /// Gamification-Konfiguration
  ///
  /// In de, this message translates to:
  /// **'Punkte‑System'**
  String get sectionPoints;

  /// No description provided for @labelPpMeal.
  ///
  /// In de, this message translates to:
  /// **'Punkte pro Mahlzeit'**
  String get labelPpMeal;

  /// No description provided for @labelPpSnack.
  ///
  /// In de, this message translates to:
  /// **'Punkte pro Snack'**
  String get labelPpSnack;

  /// No description provided for @labelBonus.
  ///
  /// In de, this message translates to:
  /// **'Snack‑Bonus (X Snacks)'**
  String get labelBonus;

  /// Einstellungen für Warnungen und Schwellenwerte
  ///
  /// In de, this message translates to:
  /// **'Gesundheit'**
  String get sectionHealth;

  /// No description provided for @labelCarbWarn.
  ///
  /// In de, this message translates to:
  /// **'KH‑Warnschwelle (g)'**
  String get labelCarbWarn;

  /// Avatar-Einstellungen
  ///
  /// In de, this message translates to:
  /// **'Avatar'**
  String get sectionAvatar;

  /// No description provided for @labelTheme.
  ///
  /// In de, this message translates to:
  /// **'Avatar‑Thema'**
  String get labelTheme;

  /// No description provided for @labelUploadItem.
  ///
  /// In de, this message translates to:
  /// **'Item hochladen'**
  String get labelUploadItem;

  /// Verweise und Impressum
  ///
  /// In de, this message translates to:
  /// **'Info'**
  String get sectionInfo;

  /// No description provided for @linkAboutAAPS.
  ///
  /// In de, this message translates to:
  /// **'Über AAPS'**
  String get linkAboutAAPS;

  /// Wird gezeigt, wenn das hochgeladene Bild zu groß ist.
  ///
  /// In de, this message translates to:
  /// **'Datei zu groß'**
  String get msgFileTooBig;

  /// Wird gezeigt, wenn ein Avatar-Item erfolgreich hinzugefügt wurde.
  ///
  /// In de, this message translates to:
  /// **'Item hinzugefügt!'**
  String get msgItemAdded;

  /// No description provided for @aiEnabled.
  ///
  /// In de, this message translates to:
  /// **'GPT enable'**
  String get aiEnabled;

  /// No description provided for @aiMaxTokens.
  ///
  /// In de, this message translates to:
  /// **'Token limit'**
  String get aiMaxTokens;

  /// No description provided for @aiModel.
  ///
  /// In de, this message translates to:
  /// **'GPT‑Modell'**
  String get aiModel;

  /// No description provided for @aiOpenaiApiKey.
  ///
  /// In de, this message translates to:
  /// **'OpenAI API key'**
  String get aiOpenaiApiKey;

  /// No description provided for @aiRestrictChild.
  ///
  /// In de, this message translates to:
  /// **'Restrict child usage'**
  String get aiRestrictChild;

  /// No description provided for @aiTitle.
  ///
  /// In de, this message translates to:
  /// **'Artificial Intelligence'**
  String get aiTitle;

  /// No description provided for @alarmsHypoDelta.
  ///
  /// In de, this message translates to:
  /// **'Drop rate‑Alarm (mg/dl)'**
  String get alarmsHypoDelta;

  /// No description provided for @alarmsHypoEnabled.
  ///
  /// In de, this message translates to:
  /// **'Hypo‑Alarm enable'**
  String get alarmsHypoEnabled;

  /// No description provided for @alarmsHypoThreshold.
  ///
  /// In de, this message translates to:
  /// **'Hypo‑Threshold (mg/dl)'**
  String get alarmsHypoThreshold;

  /// No description provided for @alarmsNoDataEnabled.
  ///
  /// In de, this message translates to:
  /// **'Kein‑Daten‑Alarm aktiv'**
  String get alarmsNoDataEnabled;

  /// No description provided for @alarmsNoDataTimeout.
  ///
  /// In de, this message translates to:
  /// **'Timeout bei fehlenden Daten (min)'**
  String get alarmsNoDataTimeout;

  /// No description provided for @alarmsPumpOfflineEnabled.
  ///
  /// In de, this message translates to:
  /// **'Pumpe offline‑Alarm aktiv'**
  String get alarmsPumpOfflineEnabled;

  /// No description provided for @alarmsPumpOfflineTimeout.
  ///
  /// In de, this message translates to:
  /// **'Timeout bei Pumpenverbindung (min)'**
  String get alarmsPumpOfflineTimeout;

  /// No description provided for @alarmsQuietEnd.
  ///
  /// In de, this message translates to:
  /// **'Ruhezeit Ende'**
  String get alarmsQuietEnd;

  /// No description provided for @alarmsQuietStart.
  ///
  /// In de, this message translates to:
  /// **'Ruhezeit Start'**
  String get alarmsQuietStart;

  /// No description provided for @alarmsTitle.
  ///
  /// In de, this message translates to:
  /// **'Alarms & Warningen'**
  String get alarmsTitle;

  /// No description provided for @avatarAccessory.
  ///
  /// In de, this message translates to:
  /// **'Zubehör'**
  String get avatarAccessory;

  /// No description provided for @avatarBackground.
  ///
  /// In de, this message translates to:
  /// **'Hintergrand'**
  String get avatarBackground;

  /// No description provided for @avatarBody.
  ///
  /// In de, this message translates to:
  /// **'Körper'**
  String get avatarBody;

  /// No description provided for @avatarHead.
  ///
  /// In de, this message translates to:
  /// **'Kopf'**
  String get avatarHead;

  /// No description provided for @avatarLayerTitle.
  ///
  /// In de, this message translates to:
  /// **'Avatar'**
  String get avatarLayerTitle;

  /// No description provided for @avatarTitle.
  ///
  /// In de, this message translates to:
  /// **'Avatar'**
  String get avatarTitle;

  /// No description provided for @avatarWeapon.
  ///
  /// In de, this message translates to:
  /// **'Waffe'**
  String get avatarWeapon;

  /// No description provided for @avatarItemLocked.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht freigeschaltet'**
  String get avatarItemLocked;

  /// No description provided for @avatarItemTapToEquip.
  ///
  /// In de, this message translates to:
  /// **'Antippen zum Ausrüsten'**
  String get avatarItemTapToEquip;

  /// No description provided for @avatarItemTapToPreview.
  ///
  /// In de, this message translates to:
  /// **'Lange tippen für Vorschau'**
  String get avatarItemTapToPreview;

  /// No description provided for @avatarItemUpload.
  ///
  /// In de, this message translates to:
  /// **'Eigenes Item hochladen'**
  String get avatarItemUpload;

  /// No description provided for @avatarItemUnlocked.
  ///
  /// In de, this message translates to:
  /// **'Freigeschaltet!'**
  String get avatarItemUnlocked;

  /// No description provided for @avatarPreviewTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Avatar'**
  String get avatarPreviewTitle;

  /// No description provided for @avatarEquipSuccess.
  ///
  /// In de, this message translates to:
  /// **'{item} wurde ausgerüstet!'**
  String avatarEquipSuccess(Object item);

  /// No description provided for @avatarEquipFailed.
  ///
  /// In de, this message translates to:
  /// **'{item} konnte nicht ausgerüstet werden.'**
  String avatarEquipFailed(Object item);

  /// No description provided for @avatarUnlockedNewItem.
  ///
  /// In de, this message translates to:
  /// **'Neues Avatar-Item freigeschaltet: {item}!'**
  String avatarUnlockedNewItem(Object item);

  /// No description provided for @avatarRandomize.
  ///
  /// In de, this message translates to:
  /// **'Zufällig'**
  String get avatarRandomize;

  /// No description provided for @avatarWing.
  ///
  /// In de, this message translates to:
  /// **'Flügel'**
  String get avatarWing;

  /// No description provided for @avatarLocked.
  ///
  /// In de, this message translates to:
  /// **'Gesperrt'**
  String get avatarLocked;

  /// No description provided for @avatarLockedPts.
  ///
  /// In de, this message translates to:
  /// **'Benötigt {points} Punkte'**
  String avatarLockedPts(Object points);

  /// No description provided for @avatarLockedLvl.
  ///
  /// In de, this message translates to:
  /// **'Benötigt Level {level}'**
  String avatarLockedLvl(Object level);

  /// No description provided for @avatarLockedPtsLvl.
  ///
  /// In de, this message translates to:
  /// **'Benötigt {points} Punkte und Level {level}'**
  String avatarLockedPtsLvl(Object points, Object level);

  /// No description provided for @bolusNoteAuto.
  ///
  /// In de, this message translates to:
  /// **'Auto‑Bolus via BolusEngine'**
  String get bolusNoteAuto;

  /// No description provided for @bolusReasonAaps.
  ///
  /// In de, this message translates to:
  /// **'AAPS‑Faktor {ratio} g/IE'**
  String bolusReasonAaps(Object ratio);

  /// No description provided for @bolusReasonManual.
  ///
  /// In de, this message translates to:
  /// **'carbs {carbs} ÷ Faktor {ratio}'**
  String bolusReasonManual(Object carbs, Object ratio);

  /// No description provided for @bolusErrorBridge.
  ///
  /// In de, this message translates to:
  /// **'Insulin-Faktor konnte nicht über AAPS ermittelt werden.'**
  String get bolusErrorBridge;

  /// No description provided for @bolusNoteBridge.
  ///
  /// In de, this message translates to:
  /// **'AAPS-Bolus: {units} Einheiten'**
  String bolusNoteBridge(Object units);

  /// No description provided for @carbAnalysisReasonDefault.
  ///
  /// In de, this message translates to:
  /// **'carbs {carbs} ÷ Faktor {ratio}'**
  String carbAnalysisReasonDefault(Object carbs, Object ratio);

  /// No description provided for @carbAnalysisWarnExcessive.
  ///
  /// In de, this message translates to:
  /// **'Check die Eingabe – carbs wirken ungewöhnlich hoch.'**
  String get carbAnalysisWarnExcessive;

  /// No description provided for @carbAnalysisWarnFuzzy.
  ///
  /// In de, this message translates to:
  /// **'⚠️ Einige Produkte wurden nur unscharf gefanden.'**
  String get carbAnalysisWarnFuzzy;

  /// No description provided for @carbAnalysisWarnHigh.
  ///
  /// In de, this message translates to:
  /// **'Meal enthält viele Kohlenhydrate ({carbs} g).'**
  String carbAnalysisWarnHigh(Object carbs);

  /// No description provided for @commonCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get commonCancel;

  /// No description provided for @commonDetails.
  ///
  /// In de, this message translates to:
  /// **'Details'**
  String get commonDetails;

  /// No description provided for @commonOk.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commParentApprovalBolus.
  ///
  /// In de, this message translates to:
  /// **'Bolus braucht Parentsfreigabe'**
  String get commParentApprovalBolus;

  /// No description provided for @commParentApprovalSnack.
  ///
  /// In de, this message translates to:
  /// **'Snack braucht Parentsfreigabe'**
  String get commParentApprovalSnack;

  /// No description provided for @commPushEnabled.
  ///
  /// In de, this message translates to:
  /// **'Push notifications erlauben'**
  String get commPushEnabled;

  /// No description provided for @commSmsEnabled.
  ///
  /// In de, this message translates to:
  /// **'SMS an Parents erlauben'**
  String get commSmsEnabled;

  /// No description provided for @commSmsNumber.
  ///
  /// In de, this message translates to:
  /// **'Parents Notfallnummer'**
  String get commSmsNumber;

  /// No description provided for @commTitle.
  ///
  /// In de, this message translates to:
  /// **'Communication & Freigabe'**
  String get commTitle;

  /// No description provided for @devicesDexcomActive.
  ///
  /// In de, this message translates to:
  /// **'Dexcom verwenden'**
  String get devicesDexcomActive;

  /// No description provided for @devicesOmnipodActive.
  ///
  /// In de, this message translates to:
  /// **'Omnipod verwenden'**
  String get devicesOmnipodActive;

  /// No description provided for @devicesPodExpiryWarn.
  ///
  /// In de, this message translates to:
  /// **'Pod Ablaufwarnung ab (h)'**
  String get devicesPodExpiryWarn;

  /// No description provided for @devicesPodReservoirWarn.
  ///
  /// In de, this message translates to:
  /// **'Reservoir‑Warning ab (h)'**
  String get devicesPodReservoirWarn;

  /// No description provided for @devicesTitle.
  ///
  /// In de, this message translates to:
  /// **'Verbandene Geräte'**
  String get devicesTitle;

  /// No description provided for @debugEnabled.
  ///
  /// In de, this message translates to:
  /// **'Debugmodus aktiv'**
  String get debugEnabled;

  /// No description provided for @debugTestMode.
  ///
  /// In de, this message translates to:
  /// **'Testmodus aktiv'**
  String get debugTestMode;

  /// No description provided for @debugTitle.
  ///
  /// In de, this message translates to:
  /// **'Debug & Test'**
  String get debugTitle;

  /// No description provided for @gameLevelUpPoints.
  ///
  /// In de, this message translates to:
  /// **'Level‑Up ab Pointsn'**
  String get gameLevelUpPoints;

  /// No description provided for @gameMaxSnacksPerDay.
  ///
  /// In de, this message translates to:
  /// **'Snacks pro Tag (max)'**
  String get gameMaxSnacksPerDay;

  /// No description provided for @gamePointsPerInput.
  ///
  /// In de, this message translates to:
  /// **'Points pro Eintrag'**
  String get gamePointsPerInput;

  /// No description provided for @gameRewardReasonBonus.
  ///
  /// In de, this message translates to:
  /// **'Bonus'**
  String get gameRewardReasonBonus;

  /// No description provided for @gameRewardReasonBolus.
  ///
  /// In de, this message translates to:
  /// **'Bolusgabe'**
  String get gameRewardReasonBolus;

  /// No description provided for @gameRewardReasonGuess.
  ///
  /// In de, this message translates to:
  /// **'carbs‑Schätzspiel (Abweichung: {diff} g)'**
  String gameRewardReasonGuess(Object diff);

  /// No description provided for @gameRewardReasonInput.
  ///
  /// In de, this message translates to:
  /// **'Eingabe'**
  String get gameRewardReasonInput;

  /// No description provided for @gameRewardReasonLevelUp.
  ///
  /// In de, this message translates to:
  /// **'Level‑Up!'**
  String get gameRewardReasonLevelUp;

  /// No description provided for @gameRewardReasonMeal.
  ///
  /// In de, this message translates to:
  /// **'Meal eingetragen'**
  String get gameRewardReasonMeal;

  /// No description provided for @gameRewardReasonPenalty.
  ///
  /// In de, this message translates to:
  /// **'Abzug'**
  String get gameRewardReasonPenalty;

  /// No description provided for @gameRewardReasonSnack.
  ///
  /// In de, this message translates to:
  /// **'Snack eingetragen'**
  String get gameRewardReasonSnack;

  /// No description provided for @gameRewardReasonSnackBonus.
  ///
  /// In de, this message translates to:
  /// **'Snack‑Bonus! {count} Snacks heute'**
  String gameRewardReasonSnackBonus(Object count);

  /// No description provided for @gameRewardReasonSnackPenalty.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Snacks heute!'**
  String get gameRewardReasonSnackPenalty;

  /// No description provided for @gameRewardsEnabled.
  ///
  /// In de, this message translates to:
  /// **'Belohnungen enable'**
  String get gameRewardsEnabled;

  /// No description provided for @gameSnackBonus.
  ///
  /// In de, this message translates to:
  /// **'Snack Bonuspunkte'**
  String get gameSnackBonus;

  /// No description provided for @gameSnackPenalty.
  ///
  /// In de, this message translates to:
  /// **'Snack‑Pointsabzug'**
  String get gameSnackPenalty;

  /// No description provided for @gameTitle.
  ///
  /// In de, this message translates to:
  /// **'Gamification & Points'**
  String get gameTitle;

  /// No description provided for @guessBtnContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get guessBtnContinue;

  /// No description provided for @guessBtnOk.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get guessBtnOk;

  /// No description provided for @guessErrorNoNumber.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine Zahl eingeben!'**
  String get guessErrorNoNumber;

  /// No description provided for @guessFeedbackActual.
  ///
  /// In de, this message translates to:
  /// **'Tatsächliche carbs‑Menge: {actual} g'**
  String guessFeedbackActual(Object actual);

  /// No description provided for @guessFeedbackGuess.
  ///
  /// In de, this message translates to:
  /// **'Deine Schätzung: {guess} g'**
  String guessFeedbackGuess(Object guess);

  /// No description provided for @guessResultFail.
  ///
  /// In de, this message translates to:
  /// **'Das war schon schwierig, oder? Nächstes Mal wird\'\'s besser!'**
  String get guessResultFail;

  /// No description provided for @guessResultGood.
  ///
  /// In de, this message translates to:
  /// **'Gut gemacht! Nur {diff} g daneben. (+2 Points)'**
  String guessResultGood(Object diff);

  /// No description provided for @guessResultGreat.
  ///
  /// In de, this message translates to:
  /// **'Sehr gut! Nur {diff} g daneben! (+5 Points)'**
  String guessResultGreat(Object diff);

  /// No description provided for @guessResultPerfect.
  ///
  /// In de, this message translates to:
  /// **'Wahnsinn! Du hast es super genau geschätzt! (+10 Points)'**
  String get guessResultPerfect;

  /// No description provided for @guessTitle.
  ///
  /// In de, this message translates to:
  /// **'Schätzspiel: Wie viele Kohlenhydrate (g) hat deine Meal?'**
  String get guessTitle;

  /// No description provided for @guessInputLabel.
  ///
  /// In de, this message translates to:
  /// **'Deine Schätzung (g)'**
  String get guessInputLabel;

  /// No description provided for @homeBtnHistory.
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get homeBtnHistory;

  /// No description provided for @homeBtnMeal.
  ///
  /// In de, this message translates to:
  /// **'Meal'**
  String get homeBtnMeal;

  /// No description provided for @homeBtnSnack.
  ///
  /// In de, this message translates to:
  /// **'Snack'**
  String get homeBtnSnack;

  /// No description provided for @homeCob.
  ///
  /// In de, this message translates to:
  /// **'COB'**
  String get homeCob;

  /// No description provided for @homeIob.
  ///
  /// In de, this message translates to:
  /// **'IOB'**
  String get homeIob;

  /// No description provided for @homeLevel.
  ///
  /// In de, this message translates to:
  /// **'Level {level}'**
  String homeLevel(Object level);

  /// No description provided for @homeMsgPoints.
  ///
  /// In de, this message translates to:
  /// **'+{points} Punkte!'**
  String homeMsgPoints(Object points);

  /// No description provided for @btnMeal.
  ///
  /// In de, this message translates to:
  /// **'MAHLZEIT'**
  String get btnMeal;

  /// No description provided for @btnSnack.
  ///
  /// In de, this message translates to:
  /// **'SNACK'**
  String get btnSnack;

  /// No description provided for @btnGuess.
  ///
  /// In de, this message translates to:
  /// **'RATEN'**
  String get btnGuess;

  /// No description provided for @homeLoop.
  ///
  /// In de, this message translates to:
  /// **'Loop'**
  String get homeLoop;

  /// No description provided for @homeMsgPointsAdded.
  ///
  /// In de, this message translates to:
  /// **'🎉 +{points} Points'**
  String homeMsgPointsAdded(Object points);

  /// No description provided for @homePoints.
  ///
  /// In de, this message translates to:
  /// **'{points} P'**
  String homePoints(Object points);

  /// No description provided for @khGameActual.
  ///
  /// In de, this message translates to:
  /// **'carbs‑Analyse'**
  String get khGameActual;

  /// No description provided for @khGameAiGuess.
  ///
  /// In de, this message translates to:
  /// **'ChefBot‑Tipp'**
  String get khGameAiGuess;

  /// No description provided for @khGameClose.
  ///
  /// In de, this message translates to:
  /// **'Fast richtig geraten.'**
  String get khGameClose;

  /// No description provided for @khGameMiss.
  ///
  /// In de, this message translates to:
  /// **'Leider daneben – versuch\'\'s nochmal!'**
  String get khGameMiss;

  /// No description provided for @khGamePerfect.
  ///
  /// In de, this message translates to:
  /// **'Perfekt geschätzt!'**
  String get khGamePerfect;

  /// No description provided for @khGameResultActual.
  ///
  /// In de, this message translates to:
  /// **'Tatsächliche carbs: {value} g'**
  String khGameResultActual(Object value);

  /// No description provided for @khGameResultError.
  ///
  /// In de, this message translates to:
  /// **'Fehlerdifferenz: {value} g'**
  String khGameResultError(Object value);

  /// No description provided for @khGameResultTitle.
  ///
  /// In de, this message translates to:
  /// **'Ergebnis'**
  String get khGameResultTitle;

  /// No description provided for @khGameResultUser.
  ///
  /// In de, this message translates to:
  /// **'Deine Schätzung: {value} g'**
  String khGameResultUser(Object value);

  /// No description provided for @khGameResultXp.
  ///
  /// In de, this message translates to:
  /// **'XP erhalten: {value}'**
  String khGameResultXp(Object value);

  /// No description provided for @khGameStreak.
  ///
  /// In de, this message translates to:
  /// **'Streak: {days} Tage'**
  String khGameStreak(Object days);

  /// No description provided for @khGameSubmit.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get khGameSubmit;

  /// No description provided for @khGameTitle.
  ///
  /// In de, this message translates to:
  /// **'carbs‑Schätz‑Duell'**
  String get khGameTitle;

  /// No description provided for @khGameWin.
  ///
  /// In de, this message translates to:
  /// **'🎉 Du hast ChefBot geschlagen!'**
  String get khGameWin;

  /// No description provided for @limitsBzMax.
  ///
  /// In de, this message translates to:
  /// **'Maximaler BZ‑Wert'**
  String get limitsBzMax;

  /// No description provided for @limitsBzMin.
  ///
  /// In de, this message translates to:
  /// **'Minimaler BZ‑Wert'**
  String get limitsBzMin;

  /// No description provided for @limitsKhWarnLimit.
  ///
  /// In de, this message translates to:
  /// **'carbs‑Warnschwelle (g)'**
  String get limitsKhWarnLimit;

  /// No description provided for @limitsTitle.
  ///
  /// In de, this message translates to:
  /// **'BZ‑ & carbs‑Thresholdn'**
  String get limitsTitle;

  /// No description provided for @mealRevDialogCarbs.
  ///
  /// In de, this message translates to:
  /// **'Kohlenhydrate'**
  String get mealRevDialogCarbs;

  /// No description provided for @mealCarbNoteShort.
  ///
  /// In de, this message translates to:
  /// **'Meal mit {carbs} g KH analysiert'**
  String mealCarbNoteShort(Object carbs);

  /// No description provided for @mealRevDialogConfirm.
  ///
  /// In de, this message translates to:
  /// **'Bolus übernehmen'**
  String get mealRevDialogConfirm;

  /// No description provided for @mealRevDialogNone.
  ///
  /// In de, this message translates to:
  /// **'Keine weiteren Hinweise.'**
  String get mealRevDialogNone;

  /// No description provided for @mealRevDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Bolus‑Empfehlung prüfen'**
  String get mealRevDialogTitle;

  /// No description provided for @mealRevRecommendation.
  ///
  /// In de, this message translates to:
  /// **'Bolus‑Empfehlung'**
  String get mealRevRecommendation;

  /// No description provided for @mealRevRecommendedBy.
  ///
  /// In de, this message translates to:
  /// **'Empfohlen durch AAPS'**
  String get mealRevRecommendedBy;

  /// No description provided for @mealRevSectionAdd.
  ///
  /// In de, this message translates to:
  /// **'Neuer Bestandteil'**
  String get mealRevSectionAdd;

  /// No description provided for @mealRevSectionFinalizeButton.
  ///
  /// In de, this message translates to:
  /// **'Abschließen'**
  String get mealRevSectionFinalizeButton;

  /// No description provided for @mealRevSectionFinalizeInfo.
  ///
  /// In de, this message translates to:
  /// **'Super gemacht! Die Daten werden nun saved and ggf. an Nightscout übertragen.'**
  String get mealRevSectionFinalizeInfo;

  /// No description provided for @mealRevSectionGrams.
  ///
  /// In de, this message translates to:
  /// **'g'**
  String get mealRevSectionGrams;

  /// No description provided for @mealRevSectionLevel.
  ///
  /// In de, this message translates to:
  /// **'Level: {level}'**
  String mealRevSectionLevel(Object level);

  /// No description provided for @mealRevSectionPoints.
  ///
  /// In de, this message translates to:
  /// **'Deine Points: {points}'**
  String mealRevSectionPoints(Object points);

  /// No description provided for @mealRevSectionRecognized.
  ///
  /// In de, this message translates to:
  /// **'Erkannte Bestandteile:'**
  String get mealRevSectionRecognized;

  /// No description provided for @mealRevSectionWarning.
  ///
  /// In de, this message translates to:
  /// **'Warningen'**
  String get mealRevSectionWarning;

  /// No description provided for @mealRevSnackbarSaved.
  ///
  /// In de, this message translates to:
  /// **'Meal saved!'**
  String get mealRevSnackbarSaved;

  /// No description provided for @mealRevTitleChild.
  ///
  /// In de, this message translates to:
  /// **'Meal überprüfen'**
  String get mealRevTitleChild;

  /// No description provided for @mealRevTitleParent.
  ///
  /// In de, this message translates to:
  /// **'Meal ansehen'**
  String get mealRevTitleParent;

  /// No description provided for @mealRevTotalLabel.
  ///
  /// In de, this message translates to:
  /// **'Gesamte carbs‑Menge'**
  String get mealRevTotalLabel;

  /// No description provided for @mealReviewTitle.
  ///
  /// In de, this message translates to:
  /// **'Mealen‑Review'**
  String get mealReviewTitle;

  /// No description provided for @notifApprovalReceived.
  ///
  /// In de, this message translates to:
  /// **'Du darfst jetzt Bolus abgeben.'**
  String get notifApprovalReceived;

  /// No description provided for @notifKhReceivedSms.
  ///
  /// In de, this message translates to:
  /// **'carbs per SMS empfangen: {value} g'**
  String notifKhReceivedSms(Object value);

  /// No description provided for @notifParentConfirmed.
  ///
  /// In de, this message translates to:
  /// **'Parents haben carbs‑Freigabe bestätigt.'**
  String get notifParentConfirmed;

  /// No description provided for @notifPushSent.
  ///
  /// In de, this message translates to:
  /// **'Push gesendet: {type}'**
  String notifPushSent(Object type);

  /// No description provided for @notifSettingChanged.
  ///
  /// In de, this message translates to:
  /// **'{key} = {value}'**
  String notifSettingChanged(Object key, Object value);

  /// No description provided for @notifSettingsUpdated.
  ///
  /// In de, this message translates to:
  /// **'Settings aktualisiert'**
  String get notifSettingsUpdated;

  /// No description provided for @notifSnackLimitChanged.
  ///
  /// In de, this message translates to:
  /// **'Snack‑Limit geändert: {limit}'**
  String notifSnackLimitChanged(Object limit);

  /// No description provided for @notifSyncReceived.
  ///
  /// In de, this message translates to:
  /// **'Settings übernommen!'**
  String get notifSyncReceived;

  /// No description provided for @notifAlarmHypoChild.
  ///
  /// In de, this message translates to:
  /// **'Dein Zucker ist niedrig ({value} mg/dl). Bitte sag einem Erwachsenen Bescheid!'**
  String notifAlarmHypoChild(Object value);

  /// No description provided for @notifAlarmHypoParent.
  ///
  /// In de, this message translates to:
  /// **'Achtung: Blutzucker bei {value} mg/dl! Drop rate: -{delta}.'**
  String notifAlarmHypoParent(Object value, Object delta);

  /// No description provided for @notifAlarmHypoShort.
  ///
  /// In de, this message translates to:
  /// **'Niedriger BZ: {value} mg/dl'**
  String notifAlarmHypoShort(Object value);

  /// No description provided for @notifAlarmHypoTitle.
  ///
  /// In de, this message translates to:
  /// **'ALARM! HYPO'**
  String get notifAlarmHypoTitle;

  /// No description provided for @notifAlarmNoDataText.
  ///
  /// In de, this message translates to:
  /// **'Seit über {minutes} Minuten keine Werte mehr empfangen.'**
  String notifAlarmNoDataText(Object minutes);

  /// No description provided for @notifAlarmNoDataTitle.
  ///
  /// In de, this message translates to:
  /// **'Daten fehlen'**
  String get notifAlarmNoDataTitle;

  /// No description provided for @notifAlarmPumpOfflineText.
  ///
  /// In de, this message translates to:
  /// **'Seit {minutes} Minuten keine Verbindung zur Pumpe.'**
  String notifAlarmPumpOfflineText(Object minutes);

  /// No description provided for @notifAlarmPumpOfflineTitle.
  ///
  /// In de, this message translates to:
  /// **'Pumpe nicht erreichbar'**
  String get notifAlarmPumpOfflineTitle;

  /// No description provided for @nsApiKey.
  ///
  /// In de, this message translates to:
  /// **'API‑Schlüssel'**
  String get nsApiKey;

  /// No description provided for @nsTitle.
  ///
  /// In de, this message translates to:
  /// **'Nightscout'**
  String get nsTitle;

  /// No description provided for @nsUrl.
  ///
  /// In de, this message translates to:
  /// **'Nightscout URL'**
  String get nsUrl;

  /// No description provided for @parserErrorNotLoaded.
  ///
  /// In de, this message translates to:
  /// **'TextParser: YAML nicht geladen. Bitte zuerst \'loadUnitsFromYaml\' aufrufen.'**
  String get parserErrorNotLoaded;

  /// No description provided for @settingsAvatarLabelTheme.
  ///
  /// In de, this message translates to:
  /// **'Thema'**
  String get settingsAvatarLabelTheme;

  /// No description provided for @settingsAvatarLabelUploadItem.
  ///
  /// In de, this message translates to:
  /// **'Avatar‑Item hochladen'**
  String get settingsAvatarLabelUploadItem;

  /// No description provided for @settingsFieldBonusSnacks.
  ///
  /// In de, this message translates to:
  /// **'Snack‑Bonus‑Intervall'**
  String get settingsFieldBonusSnacks;

  /// No description provided for @settingsFieldCarbWarn.
  ///
  /// In de, this message translates to:
  /// **'carbs‑Warnschwelle'**
  String get settingsFieldCarbWarn;

  /// No description provided for @settingsFieldChildThemeKey.
  ///
  /// In de, this message translates to:
  /// **'Avatar‑Thema'**
  String get settingsFieldChildThemeKey;

  /// No description provided for @settingsFieldEnablePush.
  ///
  /// In de, this message translates to:
  /// **'Push aktiviert'**
  String get settingsFieldEnablePush;

  /// No description provided for @settingsFieldEnableSms.
  ///
  /// In de, this message translates to:
  /// **'SMS‑Fallback'**
  String get settingsFieldEnableSms;

  /// No description provided for @settingsFieldGptApiKey.
  ///
  /// In de, this message translates to:
  /// **'ChatGPT‑Schlüssel'**
  String get settingsFieldGptApiKey;

  /// No description provided for @settingsFieldImageMode.
  ///
  /// In de, this message translates to:
  /// **'Bildmodus'**
  String get settingsFieldImageMode;

  /// No description provided for @settingsFieldMuteAlarms.
  ///
  /// In de, this message translates to:
  /// **'Alarms stumm'**
  String get settingsFieldMuteAlarms;

  /// No description provided for @settingsFieldNightscoutSecret.
  ///
  /// In de, this message translates to:
  /// **'API‑Secret'**
  String get settingsFieldNightscoutSecret;

  /// No description provided for @settingsFieldNightscoutUrl.
  ///
  /// In de, this message translates to:
  /// **'Nightscout URL'**
  String get settingsFieldNightscoutUrl;

  /// No description provided for @settingsFieldParentPhone.
  ///
  /// In de, this message translates to:
  /// **'Parents‑Telefon'**
  String get settingsFieldParentPhone;

  /// No description provided for @settingsFieldPointsMeal.
  ///
  /// In de, this message translates to:
  /// **'Points pro Meal'**
  String get settingsFieldPointsMeal;

  /// No description provided for @settingsFieldPointsSnack.
  ///
  /// In de, this message translates to:
  /// **'Points pro Snack'**
  String get settingsFieldPointsSnack;

  /// No description provided for @settingsFieldSpeechMode.
  ///
  /// In de, this message translates to:
  /// **'Sprachmodus'**
  String get settingsFieldSpeechMode;

  /// No description provided for @settingsFieldVisionApiKey.
  ///
  /// In de, this message translates to:
  /// **'Vision‑Schlüssel'**
  String get settingsFieldVisionApiKey;

  /// No description provided for @settingsMsgFileTooBig.
  ///
  /// In de, this message translates to:
  /// **'Datei zu groß'**
  String get settingsMsgFileTooBig;

  /// No description provided for @settingsMsgItemAdded.
  ///
  /// In de, this message translates to:
  /// **'Item hinzugefügt!'**
  String get settingsMsgItemAdded;

  /// No description provided for @settingsNoTime.
  ///
  /// In de, this message translates to:
  /// **'Nicht gesetzt'**
  String get settingsNoTime;

  /// No description provided for @settingsSaveButton.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get settingsSaveButton;

  /// No description provided for @settingsSectionApiKeys.
  ///
  /// In de, this message translates to:
  /// **'API‑Schlüssel'**
  String get settingsSectionApiKeys;

  /// No description provided for @settingsSectionAvatar.
  ///
  /// In de, this message translates to:
  /// **'Avatar'**
  String get settingsSectionAvatar;

  /// No description provided for @settingsSectionHealth.
  ///
  /// In de, this message translates to:
  /// **'Gesandheit'**
  String get settingsSectionHealth;

  /// No description provided for @settingsSectionInfo.
  ///
  /// In de, this message translates to:
  /// **'Info'**
  String get settingsSectionInfo;

  /// No description provided for @settingsSectionModes.
  ///
  /// In de, this message translates to:
  /// **'Betriebsmodi'**
  String get settingsSectionModes;

  /// No description provided for @settingsSectionNightscout.
  ///
  /// In de, this message translates to:
  /// **'Nightscout'**
  String get settingsSectionNightscout;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsSectionPoints.
  ///
  /// In de, this message translates to:
  /// **'Points‑System'**
  String get settingsSectionPoints;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @setupButtonContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter zur App'**
  String get setupButtonContinue;

  /// No description provided for @setupIntroAaps.
  ///
  /// In de, this message translates to:
  /// **'Nightscout‑Daten wurden aus AAPS übernommen.'**
  String get setupIntroAaps;

  /// No description provided for @setupIntroManual.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib deine Nightscout‑Daten ein:'**
  String get setupIntroManual;

  /// No description provided for @setupLabelSecret.
  ///
  /// In de, this message translates to:
  /// **'API‑Secret (SHA1)'**
  String get setupLabelSecret;

  /// No description provided for @setupLabelUrl.
  ///
  /// In de, this message translates to:
  /// **'Nightscout‑URL'**
  String get setupLabelUrl;

  /// No description provided for @setupTitle.
  ///
  /// In de, this message translates to:
  /// **'Ersteinrichtung'**
  String get setupTitle;

  /// No description provided for @setupValidateRequired.
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld'**
  String get setupValidateRequired;

  /// Button-Label: Kind wählen
  ///
  /// In de, this message translates to:
  /// **'Ich bin das Kind'**
  String get startChild;

  /// Button-Label: Elternteil wählen
  ///
  /// In de, this message translates to:
  /// **'Ich bin ein Parentsteil'**
  String get startParent;

  /// Textlink zur Profilauswahl
  ///
  /// In de, this message translates to:
  /// **'Profil wechseln / einrichten'**
  String get startProfile;

  /// Button-Label: Einstellungen
  ///
  /// In de, this message translates to:
  /// **'Settings'**
  String get startSettings;

  /// Begrüßungstitel auf dem Startscreen
  ///
  /// In de, this message translates to:
  /// **'Willkommen!\nWer bist du?'**
  String get startTitle;

  /// No description provided for @speechBtnCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get speechBtnCancel;

  /// No description provided for @speechBtnStart.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme'**
  String get speechBtnStart;

  /// No description provided for @speechBtnStop.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get speechBtnStop;

  /// No description provided for @speechDialogRecord.
  ///
  /// In de, this message translates to:
  /// **'Sprich bitte deutlich in dein Gerät.'**
  String get speechDialogRecord;

  /// No description provided for @speechDialogTitleReady.
  ///
  /// In de, this message translates to:
  /// **'Bereit für Aufnahme?'**
  String get speechDialogTitleReady;

  /// No description provided for @speechDialogTitleRecording.
  ///
  /// In de, this message translates to:
  /// **'Sprich jetzt!'**
  String get speechDialogTitleRecording;

  /// No description provided for @speechDialogInstruction.
  ///
  /// In de, this message translates to:
  /// **'Drücke Aufnahme and sprich dann ins Mikrofon.'**
  String get speechDialogInstruction;

  /// No description provided for @speechErrorApi.
  ///
  /// In de, this message translates to:
  /// **'Fehler bei der Sprachverarbeitung:'**
  String get speechErrorApi;

  /// No description provided for @speechErrorEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Sprache erkannt.'**
  String get speechErrorEmpty;

  /// No description provided for @speechErrorFileMissing.
  ///
  /// In de, this message translates to:
  /// **'Keine Audiodatei gefanden.'**
  String get speechErrorFileMissing;

  /// No description provided for @speechErrorInvalidResponse.
  ///
  /// In de, this message translates to:
  /// **'Unerwartete Antwort von Whisper.'**
  String get speechErrorInvalidResponse;

  /// No description provided for @speechErrorNetwork.
  ///
  /// In de, this message translates to:
  /// **'Keine Netzwerkverbindung.'**
  String get speechErrorNetwork;

  /// No description provided for @speechErrorNoApiKey.
  ///
  /// In de, this message translates to:
  /// **'OpenAI API key fehlt.'**
  String get speechErrorNoApiKey;

  /// No description provided for @speechErrorNoFile.
  ///
  /// In de, this message translates to:
  /// **'Es wurde keine Aufnahme erkannt.'**
  String get speechErrorNoFile;

  /// No description provided for @speechErrorOfflineEngine.
  ///
  /// In de, this message translates to:
  /// **'Offline‑Spracherkennung nicht verfügbar.'**
  String get speechErrorOfflineEngine;

  /// No description provided for @speechErrorPermission.
  ///
  /// In de, this message translates to:
  /// **'Mikrofonberechtigung erforderlich.'**
  String get speechErrorPermission;

  /// No description provided for @speechPluginError.
  ///
  /// In de, this message translates to:
  /// **'Fehler bei Aufnahme über Plugin.'**
  String get speechPluginError;

  /// No description provided for @syncError.
  ///
  /// In de, this message translates to:
  /// **'Netzwerkfehler bei Sync: {error}'**
  String syncError(Object error);

  /// No description provided for @syncFailure.
  ///
  /// In de, this message translates to:
  /// **'Synchronisierung fehlgeschlagen: {type}'**
  String syncFailure(Object type);

  /// No description provided for @syncSuccess.
  ///
  /// In de, this message translates to:
  /// **'Synchronisierung erfolgreich: {type}'**
  String syncSuccess(Object type);

  /// No description provided for @syncUnknownEvent.
  ///
  /// In de, this message translates to:
  /// **'Unbekannter Event vom Server: {type}'**
  String syncUnknownEvent(Object type);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
