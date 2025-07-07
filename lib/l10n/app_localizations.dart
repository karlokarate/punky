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
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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

  /// No description provided for @aiEnabled.
  ///
  /// In en, this message translates to:
  /// **'GPT enable'**
  String get aiEnabled;

  /// No description provided for @aiMaxTokens.
  ///
  /// In en, this message translates to:
  /// **'Token limit'**
  String get aiMaxTokens;

  /// No description provided for @aiModel.
  ///
  /// In en, this message translates to:
  /// **'GPT‑Modell'**
  String get aiModel;

  /// No description provided for @aiOpenaiApiKey.
  ///
  /// In en, this message translates to:
  /// **'OpenAI API key'**
  String get aiOpenaiApiKey;

  /// No description provided for @aiRestrictChild.
  ///
  /// In en, this message translates to:
  /// **'Restrict child usage'**
  String get aiRestrictChild;

  /// No description provided for @aiTitle.
  ///
  /// In en, this message translates to:
  /// **'Artificial Intelligence'**
  String get aiTitle;

  /// No description provided for @alarmsHypoDelta.
  ///
  /// In en, this message translates to:
  /// **'Drop rate‑Alarm (mg/dl)'**
  String get alarmsHypoDelta;

  /// No description provided for @alarmsHypoEnabled.
  ///
  /// In en, this message translates to:
  /// **'Hypo‑Alarm enable'**
  String get alarmsHypoEnabled;

  /// No description provided for @alarmsHypoThreshold.
  ///
  /// In en, this message translates to:
  /// **'Hypo‑Threshold (mg/dl)'**
  String get alarmsHypoThreshold;

  /// No description provided for @alarmsNoDataEnabled.
  ///
  /// In en, this message translates to:
  /// **'Kein‑Daten‑Alarm aktiv'**
  String get alarmsNoDataEnabled;

  /// No description provided for @alarmsNoDataTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout bei fehlenden Daten (min)'**
  String get alarmsNoDataTimeout;

  /// No description provided for @alarmsPumpOfflineEnabled.
  ///
  /// In en, this message translates to:
  /// **'Pumpe offline‑Alarm aktiv'**
  String get alarmsPumpOfflineEnabled;

  /// No description provided for @alarmsPumpOfflineTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout bei Pumpenverbindung (min)'**
  String get alarmsPumpOfflineTimeout;

  /// No description provided for @alarmsQuietEnd.
  ///
  /// In en, this message translates to:
  /// **'Ruhezeit Ende'**
  String get alarmsQuietEnd;

  /// No description provided for @alarmsQuietStart.
  ///
  /// In en, this message translates to:
  /// **'Ruhezeit Start'**
  String get alarmsQuietStart;

  /// No description provided for @alarmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarms & Warningen'**
  String get alarmsTitle;

  /// No description provided for @avatarAccessory.
  ///
  /// In en, this message translates to:
  /// **'Zubehör'**
  String get avatarAccessory;

  /// No description provided for @avatarBackground.
  ///
  /// In en, this message translates to:
  /// **'Hintergrand'**
  String get avatarBackground;

  /// No description provided for @avatarBody.
  ///
  /// In en, this message translates to:
  /// **'Körper'**
  String get avatarBody;

  /// No description provided for @avatarHead.
  ///
  /// In en, this message translates to:
  /// **'Kopf'**
  String get avatarHead;

  /// No description provided for @avatarLayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatarLayerTitle;

  /// No description provided for @avatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatarTitle;

  /// No description provided for @avatarWeapon.
  ///
  /// In en, this message translates to:
  /// **'Waffe'**
  String get avatarWeapon;

  /// No description provided for @bolusNoteAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto‑Bolus via BolusEngine'**
  String get bolusNoteAuto;

  /// No description provided for @bolusReasonAaps.
  ///
  /// In en, this message translates to:
  /// **'AAPS‑Faktor {ratio} g/IE'**
  String bolusReasonAaps(Object ratio);

  /// No description provided for @bolusReasonManual.
  ///
  /// In en, this message translates to:
  /// **'carbs {carbs} ÷ Faktor {ratio}'**
  String bolusReasonManual(Object carbs, Object ratio);

  /// No description provided for @carbAnalysisReasonDefault.
  ///
  /// In en, this message translates to:
  /// **'carbs {carbs} ÷ Faktor {ratio}'**
  String carbAnalysisReasonDefault(Object carbs, Object ratio);

  /// No description provided for @carbAnalysisWarnExcessive.
  ///
  /// In en, this message translates to:
  /// **'Check die Eingabe – carbs wirken ungewöhnlich hoch.'**
  String get carbAnalysisWarnExcessive;

  /// No description provided for @carbAnalysisWarnFuzzy.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Einige Produkte wurden nur unscharf gefanden.'**
  String get carbAnalysisWarnFuzzy;

  /// No description provided for @carbAnalysisWarnHigh.
  ///
  /// In en, this message translates to:
  /// **'Meal enthält viele Kohlenhydrate ({carbs} g).'**
  String carbAnalysisWarnHigh(Object carbs);

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Abbrechen'**
  String get commonCancel;

  /// No description provided for @commonDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get commonDetails;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commParentApprovalBolus.
  ///
  /// In en, this message translates to:
  /// **'Bolus braucht Parentsfreigabe'**
  String get commParentApprovalBolus;

  /// No description provided for @commParentApprovalSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack braucht Parentsfreigabe'**
  String get commParentApprovalSnack;

  /// No description provided for @commPushEnabled.
  ///
  /// In en, this message translates to:
  /// **'Push notifications erlauben'**
  String get commPushEnabled;

  /// No description provided for @commSmsEnabled.
  ///
  /// In en, this message translates to:
  /// **'SMS an Parents erlauben'**
  String get commSmsEnabled;

  /// No description provided for @commSmsNumber.
  ///
  /// In en, this message translates to:
  /// **'Parents Notfallnummer'**
  String get commSmsNumber;

  /// No description provided for @commTitle.
  ///
  /// In en, this message translates to:
  /// **'Communication & Freigabe'**
  String get commTitle;

  /// No description provided for @devicesDexcomActive.
  ///
  /// In en, this message translates to:
  /// **'Dexcom verwenden'**
  String get devicesDexcomActive;

  /// No description provided for @devicesOmnipodActive.
  ///
  /// In en, this message translates to:
  /// **'Omnipod verwenden'**
  String get devicesOmnipodActive;

  /// No description provided for @devicesPodExpiryWarn.
  ///
  /// In en, this message translates to:
  /// **'Pod Ablaufwarnung ab (h)'**
  String get devicesPodExpiryWarn;

  /// No description provided for @devicesPodReservoirWarn.
  ///
  /// In en, this message translates to:
  /// **'Reservoir‑Warning ab (h)'**
  String get devicesPodReservoirWarn;

  /// No description provided for @devicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Verbandene Geräte'**
  String get devicesTitle;

  /// No description provided for @debugEnabled.
  ///
  /// In en, this message translates to:
  /// **'Debugmodus aktiv'**
  String get debugEnabled;

  /// No description provided for @debugTestMode.
  ///
  /// In en, this message translates to:
  /// **'Testmodus aktiv'**
  String get debugTestMode;

  /// No description provided for @debugTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug & Test'**
  String get debugTitle;

  /// No description provided for @gameLevelUpPoints.
  ///
  /// In en, this message translates to:
  /// **'Level‑Up ab Pointsn'**
  String get gameLevelUpPoints;

  /// No description provided for @gameMaxSnacksPerDay.
  ///
  /// In en, this message translates to:
  /// **'Snacks pro Tag (max)'**
  String get gameMaxSnacksPerDay;

  /// No description provided for @gamePointsPerInput.
  ///
  /// In en, this message translates to:
  /// **'Points pro Eintrag'**
  String get gamePointsPerInput;

  /// No description provided for @gameRewardReasonBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get gameRewardReasonBonus;

  /// No description provided for @gameRewardReasonBolus.
  ///
  /// In en, this message translates to:
  /// **'Bolusgabe'**
  String get gameRewardReasonBolus;

  /// No description provided for @gameRewardReasonGuess.
  ///
  /// In en, this message translates to:
  /// **'carbs‑Schätzspiel (Abweichung: {diff} g)'**
  String gameRewardReasonGuess(Object diff);

  /// No description provided for @gameRewardReasonInput.
  ///
  /// In en, this message translates to:
  /// **'Eingabe'**
  String get gameRewardReasonInput;

  /// No description provided for @gameRewardReasonLevelUp.
  ///
  /// In en, this message translates to:
  /// **'Level‑Up!'**
  String get gameRewardReasonLevelUp;

  /// No description provided for @gameRewardReasonMeal.
  ///
  /// In en, this message translates to:
  /// **'Meal eingetragen'**
  String get gameRewardReasonMeal;

  /// No description provided for @gameRewardReasonPenalty.
  ///
  /// In en, this message translates to:
  /// **'Abzug'**
  String get gameRewardReasonPenalty;

  /// No description provided for @gameRewardReasonSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack eingetragen'**
  String get gameRewardReasonSnack;

  /// No description provided for @gameRewardReasonSnackBonus.
  ///
  /// In en, this message translates to:
  /// **'Snack‑Bonus! {count} Snacks heute'**
  String gameRewardReasonSnackBonus(Object count);

  /// No description provided for @gameRewardReasonSnackPenalty.
  ///
  /// In en, this message translates to:
  /// **'Zu viele Snacks heute!'**
  String get gameRewardReasonSnackPenalty;

  /// No description provided for @gameRewardsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Belohnungen enable'**
  String get gameRewardsEnabled;

  /// No description provided for @gameSnackBonus.
  ///
  /// In en, this message translates to:
  /// **'Snack Bonuspunkte'**
  String get gameSnackBonus;

  /// No description provided for @gameSnackPenalty.
  ///
  /// In en, this message translates to:
  /// **'Snack‑Pointsabzug'**
  String get gameSnackPenalty;

  /// No description provided for @gameTitle.
  ///
  /// In en, this message translates to:
  /// **'Gamification & Points'**
  String get gameTitle;

  /// No description provided for @guessBtnContinue.
  ///
  /// In en, this message translates to:
  /// **'Weiter'**
  String get guessBtnContinue;

  /// No description provided for @guessBtnOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get guessBtnOk;

  /// No description provided for @guessErrorNoNumber.
  ///
  /// In en, this message translates to:
  /// **'Bitte eine Zahl eingeben!'**
  String get guessErrorNoNumber;

  /// No description provided for @guessFeedbackActual.
  ///
  /// In en, this message translates to:
  /// **'Tatsächliche carbs‑Menge: {actual} g'**
  String guessFeedbackActual(Object actual);

  /// No description provided for @guessFeedbackGuess.
  ///
  /// In en, this message translates to:
  /// **'Deine Schätzung: {guess} g'**
  String guessFeedbackGuess(Object guess);

  /// No description provided for @guessResultFail.
  ///
  /// In en, this message translates to:
  /// **'Das war schon schwierig, oder? Nächstes Mal wird\'\'s besser!'**
  String get guessResultFail;

  /// No description provided for @guessResultGood.
  ///
  /// In en, this message translates to:
  /// **'Gut gemacht! Nur {diff} g daneben. (+2 Points)'**
  String guessResultGood(Object diff);

  /// No description provided for @guessResultGreat.
  ///
  /// In en, this message translates to:
  /// **'Sehr gut! Nur {diff} g daneben! (+5 Points)'**
  String guessResultGreat(Object diff);

  /// No description provided for @guessResultPerfect.
  ///
  /// In en, this message translates to:
  /// **'Wahnsinn! Du hast es super genau geschätzt! (+10 Points)'**
  String get guessResultPerfect;

  /// No description provided for @guessTitle.
  ///
  /// In en, this message translates to:
  /// **'Schätzspiel: Wie viele Kohlenhydrate (g) hat deine Meal?'**
  String get guessTitle;

  /// No description provided for @guessInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Deine Schätzung (g)'**
  String get guessInputLabel;

  /// No description provided for @homeBtnHistory.
  ///
  /// In en, this message translates to:
  /// **'Verlauf'**
  String get homeBtnHistory;

  /// No description provided for @homeBtnMeal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get homeBtnMeal;

  /// No description provided for @homeBtnSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get homeBtnSnack;

  /// No description provided for @homeCob.
  ///
  /// In en, this message translates to:
  /// **'COB'**
  String get homeCob;

  /// No description provided for @homeIob.
  ///
  /// In en, this message translates to:
  /// **'IOB'**
  String get homeIob;

  /// No description provided for @homeLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String homeLevel(Object level);

  /// No description provided for @homeLoop.
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get homeLoop;

  /// No description provided for @homeMsgPointsAdded.
  ///
  /// In en, this message translates to:
  /// **'🎉 +{points} Points'**
  String homeMsgPointsAdded(Object points);

  /// No description provided for @homePoints.
  ///
  /// In en, this message translates to:
  /// **'{points} P'**
  String homePoints(Object points);

  /// No description provided for @khGameActual.
  ///
  /// In en, this message translates to:
  /// **'carbs‑Analyse'**
  String get khGameActual;

  /// No description provided for @khGameAiGuess.
  ///
  /// In en, this message translates to:
  /// **'ChefBot‑Tipp'**
  String get khGameAiGuess;

  /// No description provided for @khGameClose.
  ///
  /// In en, this message translates to:
  /// **'Fast richtig geraten.'**
  String get khGameClose;

  /// No description provided for @khGameMiss.
  ///
  /// In en, this message translates to:
  /// **'Leider daneben – versuch\'\'s nochmal!'**
  String get khGameMiss;

  /// No description provided for @khGamePerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfekt geschätzt!'**
  String get khGamePerfect;

  /// No description provided for @khGameResultActual.
  ///
  /// In en, this message translates to:
  /// **'Tatsächliche carbs: {value} g'**
  String khGameResultActual(Object value);

  /// No description provided for @khGameResultError.
  ///
  /// In en, this message translates to:
  /// **'Fehlerdifferenz: {value} g'**
  String khGameResultError(Object value);

  /// No description provided for @khGameResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Ergebnis'**
  String get khGameResultTitle;

  /// No description provided for @khGameResultUser.
  ///
  /// In en, this message translates to:
  /// **'Deine Schätzung: {value} g'**
  String khGameResultUser(Object value);

  /// No description provided for @khGameResultXp.
  ///
  /// In en, this message translates to:
  /// **'XP erhalten: {value}'**
  String khGameResultXp(Object value);

  /// No description provided for @khGameStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak: {days} Tage'**
  String khGameStreak(Object days);

  /// No description provided for @khGameSubmit.
  ///
  /// In en, this message translates to:
  /// **'Bestätigen'**
  String get khGameSubmit;

  /// No description provided for @khGameTitle.
  ///
  /// In en, this message translates to:
  /// **'carbs‑Schätz‑Duell'**
  String get khGameTitle;

  /// No description provided for @khGameWin.
  ///
  /// In en, this message translates to:
  /// **'🎉 Du hast ChefBot geschlagen!'**
  String get khGameWin;

  /// No description provided for @limitsBzMax.
  ///
  /// In en, this message translates to:
  /// **'Maximaler BZ‑Wert'**
  String get limitsBzMax;

  /// No description provided for @limitsBzMin.
  ///
  /// In en, this message translates to:
  /// **'Minimaler BZ‑Wert'**
  String get limitsBzMin;

  /// No description provided for @limitsKhWarnLimit.
  ///
  /// In en, this message translates to:
  /// **'carbs‑Warnschwelle (g)'**
  String get limitsKhWarnLimit;

  /// No description provided for @limitsTitle.
  ///
  /// In en, this message translates to:
  /// **'BZ‑ & carbs‑Thresholdn'**
  String get limitsTitle;

  /// No description provided for @mealRevDialogCarbs.
  ///
  /// In en, this message translates to:
  /// **'Kohlenhydrate'**
  String get mealRevDialogCarbs;

  /// No description provided for @mealRevDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Bolus übernehmen'**
  String get mealRevDialogConfirm;

  /// No description provided for @mealRevDialogNone.
  ///
  /// In en, this message translates to:
  /// **'Keine weiteren Hinweise.'**
  String get mealRevDialogNone;

  /// No description provided for @mealRevDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Bolus‑Empfehlung prüfen'**
  String get mealRevDialogTitle;

  /// No description provided for @mealRevRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Bolus‑Empfehlung'**
  String get mealRevRecommendation;

  /// No description provided for @mealRevRecommendedBy.
  ///
  /// In en, this message translates to:
  /// **'Empfohlen durch AAPS'**
  String get mealRevRecommendedBy;

  /// No description provided for @mealRevSectionAdd.
  ///
  /// In en, this message translates to:
  /// **'Neuer Bestandteil'**
  String get mealRevSectionAdd;

  /// No description provided for @mealRevSectionFinalizeButton.
  ///
  /// In en, this message translates to:
  /// **'Abschließen'**
  String get mealRevSectionFinalizeButton;

  /// No description provided for @mealRevSectionFinalizeInfo.
  ///
  /// In en, this message translates to:
  /// **'Super gemacht! Die Daten werden nun saved and ggf. an Nightscout übertragen.'**
  String get mealRevSectionFinalizeInfo;

  /// No description provided for @mealRevSectionGrams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get mealRevSectionGrams;

  /// No description provided for @mealRevSectionLevel.
  ///
  /// In en, this message translates to:
  /// **'Level: {level}'**
  String mealRevSectionLevel(Object level);

  /// No description provided for @mealRevSectionPoints.
  ///
  /// In en, this message translates to:
  /// **'Deine Points: {points}'**
  String mealRevSectionPoints(Object points);

  /// No description provided for @mealRevSectionRecognized.
  ///
  /// In en, this message translates to:
  /// **'Erkannte Bestandteile:'**
  String get mealRevSectionRecognized;

  /// No description provided for @mealRevSectionWarning.
  ///
  /// In en, this message translates to:
  /// **'Warningen'**
  String get mealRevSectionWarning;

  /// No description provided for @mealRevSnackbarSaved.
  ///
  /// In en, this message translates to:
  /// **'Meal saved!'**
  String get mealRevSnackbarSaved;

  /// No description provided for @mealRevTitleChild.
  ///
  /// In en, this message translates to:
  /// **'Meal überprüfen'**
  String get mealRevTitleChild;

  /// No description provided for @mealRevTitleParent.
  ///
  /// In en, this message translates to:
  /// **'Meal ansehen'**
  String get mealRevTitleParent;

  /// No description provided for @mealRevTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Gesamte carbs‑Menge'**
  String get mealRevTotalLabel;

  /// No description provided for @mealReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Mealen‑Review'**
  String get mealReviewTitle;

  /// No description provided for @notifApprovalReceived.
  ///
  /// In en, this message translates to:
  /// **'Du darfst jetzt Bolus abgeben.'**
  String get notifApprovalReceived;

  /// No description provided for @notifKhReceivedSms.
  ///
  /// In en, this message translates to:
  /// **'carbs per SMS empfangen: {value} g'**
  String notifKhReceivedSms(Object value);

  /// No description provided for @notifParentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Parents haben carbs‑Freigabe bestätigt.'**
  String get notifParentConfirmed;

  /// No description provided for @notifPushSent.
  ///
  /// In en, this message translates to:
  /// **'Push gesendet: {type}'**
  String notifPushSent(Object type);

  /// No description provided for @notifSettingChanged.
  ///
  /// In en, this message translates to:
  /// **'{key} = {value}'**
  String notifSettingChanged(Object key, Object value);

  /// No description provided for @notifSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings aktualisiert'**
  String get notifSettingsUpdated;

  /// No description provided for @notifSnackLimitChanged.
  ///
  /// In en, this message translates to:
  /// **'Snack‑Limit geändert: {limit}'**
  String notifSnackLimitChanged(Object limit);

  /// No description provided for @notifSyncReceived.
  ///
  /// In en, this message translates to:
  /// **'Settings übernommen!'**
  String get notifSyncReceived;

  /// No description provided for @notifAlarmHypoChild.
  ///
  /// In en, this message translates to:
  /// **'Dein Zucker ist niedrig ({value} mg/dl). Bitte sag einem Erwachsenen Bescheid!'**
  String notifAlarmHypoChild(Object value);

  /// No description provided for @notifAlarmHypoParent.
  ///
  /// In en, this message translates to:
  /// **'Achtung: Blutzucker bei {value} mg/dl! Drop rate: -{delta}.'**
  String notifAlarmHypoParent(Object value, Object delta);

  /// No description provided for @notifAlarmHypoShort.
  ///
  /// In en, this message translates to:
  /// **'Niedriger BZ: {value} mg/dl'**
  String notifAlarmHypoShort(Object value);

  /// No description provided for @notifAlarmHypoTitle.
  ///
  /// In en, this message translates to:
  /// **'ALARM! HYPO'**
  String get notifAlarmHypoTitle;

  /// No description provided for @notifAlarmNoDataText.
  ///
  /// In en, this message translates to:
  /// **'Seit über {minutes} Minuten keine Werte mehr empfangen.'**
  String notifAlarmNoDataText(Object minutes);

  /// No description provided for @notifAlarmNoDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Daten fehlen'**
  String get notifAlarmNoDataTitle;

  /// No description provided for @notifAlarmPumpOfflineText.
  ///
  /// In en, this message translates to:
  /// **'Seit {minutes} Minuten keine Verbindung zur Pumpe.'**
  String notifAlarmPumpOfflineText(Object minutes);

  /// No description provided for @notifAlarmPumpOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Pumpe nicht erreichbar'**
  String get notifAlarmPumpOfflineTitle;

  /// No description provided for @nsApiKey.
  ///
  /// In en, this message translates to:
  /// **'API‑Schlüssel'**
  String get nsApiKey;

  /// No description provided for @nsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nightscout'**
  String get nsTitle;

  /// No description provided for @nsUrl.
  ///
  /// In en, this message translates to:
  /// **'Nightscout URL'**
  String get nsUrl;

  /// No description provided for @parserErrorNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'TextParser: YAML nicht geladen. Bitte zuerst \'loadUnitsFromYaml\' aufrufen.'**
  String get parserErrorNotLoaded;

  /// No description provided for @settingsAvatarLabelTheme.
  ///
  /// In en, this message translates to:
  /// **'Thema'**
  String get settingsAvatarLabelTheme;

  /// No description provided for @settingsAvatarLabelUploadItem.
  ///
  /// In en, this message translates to:
  /// **'Avatar‑Item hochladen'**
  String get settingsAvatarLabelUploadItem;

  /// No description provided for @settingsFieldBonusSnacks.
  ///
  /// In en, this message translates to:
  /// **'Snack‑Bonus‑Intervall'**
  String get settingsFieldBonusSnacks;

  /// No description provided for @settingsFieldCarbWarn.
  ///
  /// In en, this message translates to:
  /// **'carbs‑Warnschwelle'**
  String get settingsFieldCarbWarn;

  /// No description provided for @settingsFieldChildThemeKey.
  ///
  /// In en, this message translates to:
  /// **'Avatar‑Thema'**
  String get settingsFieldChildThemeKey;

  /// No description provided for @settingsFieldEnablePush.
  ///
  /// In en, this message translates to:
  /// **'Push aktiviert'**
  String get settingsFieldEnablePush;

  /// No description provided for @settingsFieldEnableSms.
  ///
  /// In en, this message translates to:
  /// **'SMS‑Fallback'**
  String get settingsFieldEnableSms;

  /// No description provided for @settingsFieldGptApiKey.
  ///
  /// In en, this message translates to:
  /// **'ChatGPT‑Schlüssel'**
  String get settingsFieldGptApiKey;

  /// No description provided for @settingsFieldImageMode.
  ///
  /// In en, this message translates to:
  /// **'Bildmodus'**
  String get settingsFieldImageMode;

  /// No description provided for @settingsFieldMuteAlarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms stumm'**
  String get settingsFieldMuteAlarms;

  /// No description provided for @settingsFieldNightscoutSecret.
  ///
  /// In en, this message translates to:
  /// **'API‑Secret'**
  String get settingsFieldNightscoutSecret;

  /// No description provided for @settingsFieldNightscoutUrl.
  ///
  /// In en, this message translates to:
  /// **'Nightscout URL'**
  String get settingsFieldNightscoutUrl;

  /// No description provided for @settingsFieldParentPhone.
  ///
  /// In en, this message translates to:
  /// **'Parents‑Telefon'**
  String get settingsFieldParentPhone;

  /// No description provided for @settingsFieldPointsMeal.
  ///
  /// In en, this message translates to:
  /// **'Points pro Meal'**
  String get settingsFieldPointsMeal;

  /// No description provided for @settingsFieldPointsSnack.
  ///
  /// In en, this message translates to:
  /// **'Points pro Snack'**
  String get settingsFieldPointsSnack;

  /// No description provided for @settingsFieldSpeechMode.
  ///
  /// In en, this message translates to:
  /// **'Sprachmodus'**
  String get settingsFieldSpeechMode;

  /// No description provided for @settingsFieldVisionApiKey.
  ///
  /// In en, this message translates to:
  /// **'Vision‑Schlüssel'**
  String get settingsFieldVisionApiKey;

  /// No description provided for @settingsMsgFileTooBig.
  ///
  /// In en, this message translates to:
  /// **'Datei zu groß'**
  String get settingsMsgFileTooBig;

  /// No description provided for @settingsMsgItemAdded.
  ///
  /// In en, this message translates to:
  /// **'Item hinzugefügt!'**
  String get settingsMsgItemAdded;

  /// No description provided for @settingsNoTime.
  ///
  /// In en, this message translates to:
  /// **'Nicht gesetzt'**
  String get settingsNoTime;

  /// No description provided for @settingsSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Speichern'**
  String get settingsSaveButton;

  /// No description provided for @settingsSectionApiKeys.
  ///
  /// In en, this message translates to:
  /// **'API‑Schlüssel'**
  String get settingsSectionApiKeys;

  /// No description provided for @settingsSectionAvatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get settingsSectionAvatar;

  /// No description provided for @settingsSectionHealth.
  ///
  /// In en, this message translates to:
  /// **'Gesandheit'**
  String get settingsSectionHealth;

  /// No description provided for @settingsSectionInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get settingsSectionInfo;

  /// No description provided for @settingsSectionModes.
  ///
  /// In en, this message translates to:
  /// **'Betriebsmodi'**
  String get settingsSectionModes;

  /// No description provided for @settingsSectionNightscout.
  ///
  /// In en, this message translates to:
  /// **'Nightscout'**
  String get settingsSectionNightscout;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Benachrichtigungen'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsSectionPoints.
  ///
  /// In en, this message translates to:
  /// **'Points‑System'**
  String get settingsSectionPoints;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @setupButtonContinue.
  ///
  /// In en, this message translates to:
  /// **'Weiter zur App'**
  String get setupButtonContinue;

  /// No description provided for @setupIntroAaps.
  ///
  /// In en, this message translates to:
  /// **'Nightscout‑Daten wurden aus AAPS übernommen.'**
  String get setupIntroAaps;

  /// No description provided for @setupIntroManual.
  ///
  /// In en, this message translates to:
  /// **'Bitte gib deine Nightscout‑Daten ein:'**
  String get setupIntroManual;

  /// No description provided for @setupLabelSecret.
  ///
  /// In en, this message translates to:
  /// **'API‑Secret (SHA1)'**
  String get setupLabelSecret;

  /// No description provided for @setupLabelUrl.
  ///
  /// In en, this message translates to:
  /// **'Nightscout‑URL'**
  String get setupLabelUrl;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Ersteinrichtung'**
  String get setupTitle;

  /// No description provided for @setupValidateRequired.
  ///
  /// In en, this message translates to:
  /// **'Pflichtfeld'**
  String get setupValidateRequired;

  /// No description provided for @startChild.
  ///
  /// In en, this message translates to:
  /// **'Ich bin das Kind'**
  String get startChild;

  /// No description provided for @startParent.
  ///
  /// In en, this message translates to:
  /// **'Ich bin ein Parentsteil'**
  String get startParent;

  /// No description provided for @startProfile.
  ///
  /// In en, this message translates to:
  /// **'Profil wechseln / einrichten'**
  String get startProfile;

  /// No description provided for @startSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get startSettings;

  /// No description provided for @startTitle.
  ///
  /// In en, this message translates to:
  /// **'Willkommen!\nWer bist du?'**
  String get startTitle;

  /// No description provided for @speechBtnCancel.
  ///
  /// In en, this message translates to:
  /// **'Abbrechen'**
  String get speechBtnCancel;

  /// No description provided for @speechBtnStart.
  ///
  /// In en, this message translates to:
  /// **'Aufnahme'**
  String get speechBtnStart;

  /// No description provided for @speechBtnStop.
  ///
  /// In en, this message translates to:
  /// **'Fertig'**
  String get speechBtnStop;

  /// No description provided for @speechDialogRecord.
  ///
  /// In en, this message translates to:
  /// **'Sprich bitte deutlich in dein Gerät.'**
  String get speechDialogRecord;

  /// No description provided for @speechDialogTitleReady.
  ///
  /// In en, this message translates to:
  /// **'Bereit für Aufnahme?'**
  String get speechDialogTitleReady;

  /// No description provided for @speechDialogTitleRecording.
  ///
  /// In en, this message translates to:
  /// **'Sprich jetzt!'**
  String get speechDialogTitleRecording;

  /// No description provided for @speechDialogInstruction.
  ///
  /// In en, this message translates to:
  /// **'Drücke Aufnahme and sprich dann ins Mikrofon.'**
  String get speechDialogInstruction;

  /// No description provided for @speechErrorApi.
  ///
  /// In en, this message translates to:
  /// **'Fehler bei der Sprachverarbeitung:'**
  String get speechErrorApi;

  /// No description provided for @speechErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Keine Sprache erkannt.'**
  String get speechErrorEmpty;

  /// No description provided for @speechErrorFileMissing.
  ///
  /// In en, this message translates to:
  /// **'Keine Audiodatei gefanden.'**
  String get speechErrorFileMissing;

  /// No description provided for @speechErrorInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Unerwartete Antwort von Whisper.'**
  String get speechErrorInvalidResponse;

  /// No description provided for @speechErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Keine Netzwerkverbindung.'**
  String get speechErrorNetwork;

  /// No description provided for @speechErrorNoApiKey.
  ///
  /// In en, this message translates to:
  /// **'OpenAI API key fehlt.'**
  String get speechErrorNoApiKey;

  /// No description provided for @speechErrorNoFile.
  ///
  /// In en, this message translates to:
  /// **'Es wurde keine Aufnahme erkannt.'**
  String get speechErrorNoFile;

  /// No description provided for @speechErrorOfflineEngine.
  ///
  /// In en, this message translates to:
  /// **'Offline‑Spracherkennung nicht verfügbar.'**
  String get speechErrorOfflineEngine;

  /// No description provided for @speechErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'Mikrofonberechtigung erforderlich.'**
  String get speechErrorPermission;

  /// No description provided for @speechPluginError.
  ///
  /// In en, this message translates to:
  /// **'Fehler bei Aufnahme über Plugin.'**
  String get speechPluginError;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Netzwerkfehler bei Sync: {error}'**
  String syncError(Object error);

  /// No description provided for @syncFailure.
  ///
  /// In en, this message translates to:
  /// **'Synchronisierung fehlgeschlagen: {type}'**
  String syncFailure(Object type);

  /// No description provided for @syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Synchronisierung erfolgreich: {type}'**
  String syncSuccess(Object type);

  /// No description provided for @syncUnknownEvent.
  ///
  /// In en, this message translates to:
  /// **'Unbekannter Event vom Server: {type}'**
  String syncUnknownEvent(Object type);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
