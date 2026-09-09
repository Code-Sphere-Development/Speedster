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
/// import 'generated/app_localizations.dart';
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
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Speedster'**
  String get appTitle;

  /// No description provided for @tabHeatmap.
  ///
  /// In de, this message translates to:
  /// **'Heatmap'**
  String get tabHeatmap;

  /// No description provided for @tabLive.
  ///
  /// In de, this message translates to:
  /// **'Live'**
  String get tabLive;

  /// No description provided for @tabTrips.
  ///
  /// In de, this message translates to:
  /// **'Fahrten'**
  String get tabTrips;

  /// No description provided for @tabRanking.
  ///
  /// In de, this message translates to:
  /// **'Ranking'**
  String get tabRanking;

  /// No description provided for @tabSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get tabSettings;

  /// No description provided for @commonCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get commonSave;

  /// No description provided for @commonError.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {message}'**
  String commonError(String message);

  /// No description provided for @commonNoConnection.
  ///
  /// In de, this message translates to:
  /// **'Das hat nicht geklappt. Besteht eine Verbindung?'**
  String get commonNoConnection;

  /// No description provided for @tripsEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Fahrten aufgezeichnet.'**
  String get tripsEmpty;

  /// No description provided for @tripNoRoute.
  ///
  /// In de, this message translates to:
  /// **'Keine Streckendaten. Ältere Fahrten liegen nur in der Cloud — ihre Karte braucht eine Verbindung.'**
  String get tripNoRoute;

  /// No description provided for @tripMapUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Karte nicht verfügbar: {message}'**
  String tripMapUnavailable(String message);

  /// No description provided for @tripPurpose.
  ///
  /// In de, this message translates to:
  /// **'Zweck'**
  String get tripPurpose;

  /// No description provided for @tripPurposeNone.
  ///
  /// In de, this message translates to:
  /// **'Kein Zweck'**
  String get tripPurposeNone;

  /// No description provided for @tripPurposePrivate.
  ///
  /// In de, this message translates to:
  /// **'Privat'**
  String get tripPurposePrivate;

  /// No description provided for @tripPurposeCommute.
  ///
  /// In de, this message translates to:
  /// **'Arbeitsweg'**
  String get tripPurposeCommute;

  /// No description provided for @tripPurposeBusiness.
  ///
  /// In de, this message translates to:
  /// **'Geschäftlich'**
  String get tripPurposeBusiness;

  /// No description provided for @tripNote.
  ///
  /// In de, this message translates to:
  /// **'Notiz'**
  String get tripNote;

  /// No description provided for @tripPurposeSaved.
  ///
  /// In de, this message translates to:
  /// **'Zweck gespeichert.'**
  String get tripPurposeSaved;

  /// No description provided for @metricMax.
  ///
  /// In de, this message translates to:
  /// **'Max'**
  String get metricMax;

  /// No description provided for @metricAverage.
  ///
  /// In de, this message translates to:
  /// **'Ø'**
  String get metricAverage;

  /// No description provided for @metricDistance.
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get metricDistance;

  /// No description provided for @metricDuration.
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get metricDuration;

  /// No description provided for @metricZeroToHundred.
  ///
  /// In de, this message translates to:
  /// **'0–100'**
  String get metricZeroToHundred;

  /// No description provided for @metricElevation.
  ///
  /// In de, this message translates to:
  /// **'Höhenmeter'**
  String get metricElevation;

  /// No description provided for @heatmapEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Strecken aufgezeichnet'**
  String get heatmapEmpty;

  /// No description provided for @heatmapRangeAll.
  ///
  /// In de, this message translates to:
  /// **'Alles'**
  String get heatmapRangeAll;

  /// No description provided for @heatmapRange12m.
  ///
  /// In de, this message translates to:
  /// **'12 Monate'**
  String get heatmapRange12m;

  /// No description provided for @heatmapRange3m.
  ///
  /// In de, this message translates to:
  /// **'3 Monate'**
  String get heatmapRange3m;

  /// No description provided for @heatmapLegendRare.
  ///
  /// In de, this message translates to:
  /// **'selten'**
  String get heatmapLegendRare;

  /// No description provided for @heatmapLegendOften.
  ///
  /// In de, this message translates to:
  /// **'oft'**
  String get heatmapLegendOften;

  /// No description provided for @liveSpeed.
  ///
  /// In de, this message translates to:
  /// **'Geschwindigkeit'**
  String get liveSpeed;

  /// No description provided for @liveWaiting.
  ///
  /// In de, this message translates to:
  /// **'Warte auf Fahrtbeginn …'**
  String get liveWaiting;

  /// No description provided for @liveDistance.
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get liveDistance;

  /// No description provided for @liveDuration.
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get liveDuration;

  /// No description provided for @driverTitle.
  ///
  /// In de, this message translates to:
  /// **'Selbst gefahren?'**
  String get driverTitle;

  /// No description provided for @driverBody.
  ///
  /// In de, this message translates to:
  /// **'Warst du der Fahrer? Nur eigene Fahrten werden behalten. Als Beifahrer aufgezeichnete Fahrten kannst du verwerfen.'**
  String get driverBody;

  /// No description provided for @driverKeep.
  ///
  /// In de, this message translates to:
  /// **'Behalten'**
  String get driverKeep;

  /// No description provided for @driverDiscard.
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get driverDiscard;

  /// No description provided for @rankingScopeWorld.
  ///
  /// In de, this message translates to:
  /// **'Welt'**
  String get rankingScopeWorld;

  /// No description provided for @rankingScopeCountry.
  ///
  /// In de, this message translates to:
  /// **'Land'**
  String get rankingScopeCountry;

  /// No description provided for @rankingScopeFriends.
  ///
  /// In de, this message translates to:
  /// **'Freunde'**
  String get rankingScopeFriends;

  /// No description provided for @rankingScopeVehicle.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeug'**
  String get rankingScopeVehicle;

  /// No description provided for @rankingPeriodWeek.
  ///
  /// In de, this message translates to:
  /// **'Woche'**
  String get rankingPeriodWeek;

  /// No description provided for @rankingPeriodMonth.
  ///
  /// In de, this message translates to:
  /// **'Monat'**
  String get rankingPeriodMonth;

  /// No description provided for @rankingPeriodAll.
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get rankingPeriodAll;

  /// No description provided for @rankingNoVehicle.
  ///
  /// In de, this message translates to:
  /// **'Für diese Wertung fehlt dein Standardfahrzeug. Lege es in der Garage an und wähle ein Modell — verglichen wird mit allen, die dasselbe Modell fahren.'**
  String get rankingNoVehicle;

  /// No description provided for @rankingMetricMaxSpeed.
  ///
  /// In de, this message translates to:
  /// **'Max Speed'**
  String get rankingMetricMaxSpeed;

  /// No description provided for @rankingMetricDistance.
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get rankingMetricDistance;

  /// No description provided for @rankingMetricTrips.
  ///
  /// In de, this message translates to:
  /// **'Fahrten'**
  String get rankingMetricTrips;

  /// No description provided for @rankingMetricZeroToHundred.
  ///
  /// In de, this message translates to:
  /// **'Beste 0–100'**
  String get rankingMetricZeroToHundred;

  /// No description provided for @rankingSpeedNotice.
  ///
  /// In de, this message translates to:
  /// **'Es gilt immer die StVO. Diese Wertung ist kein Grund, eine Geschwindigkeitsbegrenzung zu überschreiten.'**
  String get rankingSpeedNotice;

  /// No description provided for @rankingYourRank.
  ///
  /// In de, this message translates to:
  /// **'Dein Rang'**
  String get rankingYourRank;

  /// No description provided for @rankingEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einträge.'**
  String get rankingEmpty;

  /// No description provided for @rankingCloudOffTitle.
  ///
  /// In de, this message translates to:
  /// **'Das Ranking vergleicht dich mit anderen Fahrern und lebt deshalb von der Speedster Cloud. Ohne Cloud-Sync gibt es niemanden, mit dem sich vergleichen liesse.'**
  String get rankingCloudOffTitle;

  /// No description provided for @rankingCloudOffHint.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Sync findest du in den Einstellungen.'**
  String get rankingCloudOffHint;

  /// No description provided for @rankingSignInNeeded.
  ///
  /// In de, this message translates to:
  /// **'Für das Ranking musst du in der Speedster Cloud angemeldet sein.'**
  String get rankingSignInNeeded;

  /// No description provided for @rankingStatusUnknown.
  ///
  /// In de, this message translates to:
  /// **'Der Anmeldestatus liess sich nicht prüfen.'**
  String get rankingStatusUnknown;

  /// No description provided for @authSignIn.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get authSignIn;

  /// No description provided for @authRegister.
  ///
  /// In de, this message translates to:
  /// **'Registrieren'**
  String get authRegister;

  /// No description provided for @authCreateAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellen'**
  String get authCreateAccount;

  /// No description provided for @authName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get authName;

  /// No description provided for @authUsername.
  ///
  /// In de, this message translates to:
  /// **'Benutzername'**
  String get authUsername;

  /// No description provided for @authEmail.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get authPassword;

  /// No description provided for @authUsernameHint.
  ///
  /// In de, this message translates to:
  /// **'3–30 Zeichen: a–z, 0–9 und _'**
  String get authUsernameHint;

  /// No description provided for @authUsernameRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen Benutzernamen angeben.'**
  String get authUsernameRequired;

  /// No description provided for @authUsernameFormat.
  ///
  /// In de, this message translates to:
  /// **'Benutzername: 3 bis 30 Zeichen, nur Kleinbuchstaben, Ziffern und Unterstrich (_).'**
  String get authUsernameFormat;

  /// No description provided for @authHaveAccount.
  ///
  /// In de, this message translates to:
  /// **'Schon ein Konto? Anmelden'**
  String get authHaveAccount;

  /// No description provided for @authNoAccount.
  ///
  /// In de, this message translates to:
  /// **'Neu hier? Konto erstellen'**
  String get authNoAccount;

  /// No description provided for @authWithApple.
  ///
  /// In de, this message translates to:
  /// **'Mit Apple anmelden'**
  String get authWithApple;

  /// No description provided for @authWithGoogle.
  ///
  /// In de, this message translates to:
  /// **'Mit Google anmelden'**
  String get authWithGoogle;

  /// No description provided for @authSocialSoon.
  ///
  /// In de, this message translates to:
  /// **'{provider}-Login folgt in Kürze.'**
  String authSocialSoon(String provider);

  /// No description provided for @friendsTitle.
  ///
  /// In de, this message translates to:
  /// **'Freunde'**
  String get friendsTitle;

  /// No description provided for @friendsLead.
  ///
  /// In de, this message translates to:
  /// **'Freunde sehen voneinander nur Kennzahlen — keine einzelnen Fahrten und keine Strecken.'**
  String get friendsLead;

  /// No description provided for @friendsUsernameLabel.
  ///
  /// In de, this message translates to:
  /// **'Benutzername'**
  String get friendsUsernameLabel;

  /// No description provided for @friendsUsernameHint.
  ///
  /// In de, this message translates to:
  /// **'Die eindeutige Kennung, kein Anzeigename'**
  String get friendsUsernameHint;

  /// No description provided for @friendsRequest.
  ///
  /// In de, this message translates to:
  /// **'Anfragen'**
  String get friendsRequest;

  /// No description provided for @friendsCopyInvite.
  ///
  /// In de, this message translates to:
  /// **'Einladungslink kopieren'**
  String get friendsCopyInvite;

  /// No description provided for @friendsInviteCopied.
  ///
  /// In de, this message translates to:
  /// **'Einladungslink kopiert.'**
  String get friendsInviteCopied;

  /// No description provided for @friendsIncoming.
  ///
  /// In de, this message translates to:
  /// **'Offene Anfragen an dich'**
  String get friendsIncoming;

  /// No description provided for @friendsOutgoing.
  ///
  /// In de, this message translates to:
  /// **'Von dir verschickt'**
  String get friendsOutgoing;

  /// No description provided for @friendsAccept.
  ///
  /// In de, this message translates to:
  /// **'Annehmen'**
  String get friendsAccept;

  /// No description provided for @friendsDecline.
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get friendsDecline;

  /// No description provided for @friendsRemove.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get friendsRemove;

  /// No description provided for @friendsWithdraw.
  ///
  /// In de, this message translates to:
  /// **'Zurückziehen'**
  String get friendsWithdraw;

  /// No description provided for @friendsEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch niemand.'**
  String get friendsEmpty;

  /// No description provided for @friendsEmptyHint.
  ///
  /// In de, this message translates to:
  /// **'Teile deinen Einladungslink oder füge jemanden über seinen Benutzernamen hinzu.'**
  String get friendsEmptyHint;

  /// No description provided for @friendsLoadFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Freundesliste konnte nicht geladen werden.'**
  String get friendsLoadFailed;

  /// No description provided for @friendsRequestSent.
  ///
  /// In de, this message translates to:
  /// **'Anfrage verschickt.'**
  String get friendsRequestSent;

  /// No description provided for @friendsNowFriends.
  ///
  /// In de, this message translates to:
  /// **'Ihr seid jetzt befreundet.'**
  String get friendsNowFriends;

  /// No description provided for @friendsDeclined.
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt.'**
  String get friendsDeclined;

  /// No description provided for @friendsRemoved.
  ///
  /// In de, this message translates to:
  /// **'Entfernt.'**
  String get friendsRemoved;

  /// No description provided for @friendsWithdrawn.
  ///
  /// In de, this message translates to:
  /// **'Zurückgezogen.'**
  String get friendsWithdrawn;

  /// No description provided for @settingsUnitTitle.
  ///
  /// In de, this message translates to:
  /// **'Einheit: Meilen (mph)'**
  String get settingsUnitTitle;

  /// No description provided for @settingsUnitSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Aus = km/h'**
  String get settingsUnitSubtitle;

  /// No description provided for @settingsPauseTitle.
  ///
  /// In de, this message translates to:
  /// **'Tracking pausieren'**
  String get settingsPauseTitle;

  /// No description provided for @settingsPauseSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Keine automatische Fahrterkennung'**
  String get settingsPauseSubtitle;

  /// No description provided for @settingsCloudTitle.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Sync aktivieren'**
  String get settingsCloudTitle;

  /// No description provided for @settingsCloudSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Fahrten in die Cloud sichern (Backup + Rankings). Aus = alles bleibt nur auf dem Gerät.'**
  String get settingsCloudSubtitle;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Account löschen'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountBody.
  ///
  /// In de, this message translates to:
  /// **'Dein Cloud-Konto und alle hochgeladenen Fahrten werden gelöscht.'**
  String get settingsDeleteAccountBody;

  /// No description provided for @settingsDeleteAll.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten löschen'**
  String get settingsDeleteAll;

  /// No description provided for @settingsDeleteAllTitle.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten löschen?'**
  String get settingsDeleteAllTitle;

  /// No description provided for @settingsDeleteAllBody.
  ///
  /// In de, this message translates to:
  /// **'Alle aufgezeichneten Fahrten werden unwiderruflich gelöscht.'**
  String get settingsDeleteAllBody;

  /// No description provided for @settingsUsername.
  ///
  /// In de, this message translates to:
  /// **'Benutzername'**
  String get settingsUsername;

  /// No description provided for @settingsUsernameMissing.
  ///
  /// In de, this message translates to:
  /// **'Noch keiner vergeben — im Web nachholen'**
  String get settingsUsernameMissing;

  /// No description provided for @settingsUsernameChangeTitle.
  ///
  /// In de, this message translates to:
  /// **'Benutzername ändern'**
  String get settingsUsernameChangeTitle;

  /// No description provided for @settingsUsernameChangeLead.
  ///
  /// In de, this message translates to:
  /// **'Unter diesem Namen findet man dich in der Bestenliste und über Einladungslinks. Nach einem Wechsel bleibt dein alter Name eine Zeit lang für dich reserviert, und du kannst erst danach wieder wechseln.'**
  String get settingsUsernameChangeLead;

  /// No description provided for @settingsUsernameLocked.
  ///
  /// In de, this message translates to:
  /// **'Wechsel wieder möglich am {date}'**
  String settingsUsernameLocked(String date);

  /// No description provided for @settingsUsernameSaved.
  ///
  /// In de, this message translates to:
  /// **'Benutzername geändert.'**
  String get settingsUsernameSaved;

  /// No description provided for @settingsFriends.
  ///
  /// In de, this message translates to:
  /// **'Freunde'**
  String get settingsFriends;

  /// No description provided for @settingsFriendsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Kennzahlen mit Bekannten vergleichen'**
  String get settingsFriendsSubtitle;

  /// No description provided for @settingsGarage.
  ///
  /// In de, this message translates to:
  /// **'Garage'**
  String get settingsGarage;

  /// No description provided for @garageTitle.
  ///
  /// In de, this message translates to:
  /// **'Garage'**
  String get garageTitle;

  /// No description provided for @garageLead.
  ///
  /// In de, this message translates to:
  /// **'Neue Fahrten werden dem Standardfahrzeug zugeordnet. Das Modell bestimmt, mit wem du in der Fahrzeugwertung verglichen wirst.'**
  String get garageLead;

  /// No description provided for @garageEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Fahrzeug angelegt.'**
  String get garageEmpty;

  /// No description provided for @garageAdd.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeug anlegen'**
  String get garageAdd;

  /// No description provided for @garageName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get garageName;

  /// No description provided for @garageNameHint.
  ///
  /// In de, this message translates to:
  /// **'Wie du es nennst — „Der Golf“'**
  String get garageNameHint;

  /// No description provided for @garageModel.
  ///
  /// In de, this message translates to:
  /// **'Modell'**
  String get garageModel;

  /// No description provided for @garageModelSearch.
  ///
  /// In de, this message translates to:
  /// **'Modell suchen'**
  String get garageModelSearch;

  /// No description provided for @garageModelNone.
  ///
  /// In de, this message translates to:
  /// **'Kein Modell zugeordnet'**
  String get garageModelNone;

  /// No description provided for @garageModelHint.
  ///
  /// In de, this message translates to:
  /// **'Ohne Modell erscheint das Fahrzeug nicht in der Fahrzeugwertung.'**
  String get garageModelHint;

  /// No description provided for @garageNoModels.
  ///
  /// In de, this message translates to:
  /// **'Kein Modell gefunden.'**
  String get garageNoModels;

  /// No description provided for @garageYear.
  ///
  /// In de, this message translates to:
  /// **'Baujahr'**
  String get garageYear;

  /// No description provided for @garagePower.
  ///
  /// In de, this message translates to:
  /// **'Leistung (PS)'**
  String get garagePower;

  /// No description provided for @garageOdometer.
  ///
  /// In de, this message translates to:
  /// **'Tachostand'**
  String get garageOdometer;

  /// No description provided for @garageOdometerEstimate.
  ///
  /// In de, this message translates to:
  /// **'ca. {km} km'**
  String garageOdometerEstimate(String km);

  /// No description provided for @garageOdometerBasis.
  ///
  /// In de, this message translates to:
  /// **'Geschätzt aus {km} km vom {date}, plus {tracked} km seither aufgezeichnet.'**
  String garageOdometerBasis(String km, String date, String tracked);

  /// No description provided for @garageOdometerNone.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Tachostand eingetragen.'**
  String get garageOdometerNone;

  /// No description provided for @garageOdometerAdd.
  ///
  /// In de, this message translates to:
  /// **'Tachostand eintragen'**
  String get garageOdometerAdd;

  /// No description provided for @garageOdometerKm.
  ///
  /// In de, this message translates to:
  /// **'Kilometerstand'**
  String get garageOdometerKm;

  /// No description provided for @garageOdometerSaved.
  ///
  /// In de, this message translates to:
  /// **'Tachostand gespeichert.'**
  String get garageOdometerSaved;

  /// No description provided for @garageOdometerDeviation.
  ///
  /// In de, this message translates to:
  /// **'Die Schätzung lag {km} km daneben — so viel hat die App nicht mitbekommen.'**
  String garageOdometerDeviation(String km);

  /// No description provided for @garageMaintenance.
  ///
  /// In de, this message translates to:
  /// **'Wartung'**
  String get garageMaintenance;

  /// No description provided for @garageMaintenanceAdd.
  ///
  /// In de, this message translates to:
  /// **'Wartung eintragen'**
  String get garageMaintenanceAdd;

  /// No description provided for @garageMaintenanceTitle.
  ///
  /// In de, this message translates to:
  /// **'Was'**
  String get garageMaintenanceTitle;

  /// No description provided for @garageMaintenanceTitleHint.
  ///
  /// In de, this message translates to:
  /// **'HU, Inspektion, Ölwechsel …'**
  String get garageMaintenanceTitleHint;

  /// No description provided for @garageMaintenanceDueKm.
  ///
  /// In de, this message translates to:
  /// **'Fällig bei km'**
  String get garageMaintenanceDueKm;

  /// No description provided for @garageMaintenanceDueOn.
  ///
  /// In de, this message translates to:
  /// **'Fällig am'**
  String get garageMaintenanceDueOn;

  /// No description provided for @garageMaintenanceNone.
  ///
  /// In de, this message translates to:
  /// **'Keine Wartung eingetragen.'**
  String get garageMaintenanceNone;

  /// No description provided for @garageMaintenanceDone.
  ///
  /// In de, this message translates to:
  /// **'Erledigt'**
  String get garageMaintenanceDone;

  /// No description provided for @garageMaintenanceInDays.
  ///
  /// In de, this message translates to:
  /// **'in {count} Tagen'**
  String garageMaintenanceInDays(int count);

  /// No description provided for @garageMaintenanceOverdueDays.
  ///
  /// In de, this message translates to:
  /// **'seit {count} Tagen überfällig'**
  String garageMaintenanceOverdueDays(int count);

  /// No description provided for @garageMaintenanceToday.
  ///
  /// In de, this message translates to:
  /// **'heute fällig'**
  String get garageMaintenanceToday;

  /// No description provided for @garageMaintenanceInKm.
  ///
  /// In de, this message translates to:
  /// **'in ca. {km} km'**
  String garageMaintenanceInKm(String km);

  /// No description provided for @garageMaintenanceOverdueKm.
  ///
  /// In de, this message translates to:
  /// **'ca. {km} km überfällig'**
  String garageMaintenanceOverdueKm(String km);

  /// No description provided for @garageMaintenanceKmUnknown.
  ///
  /// In de, this message translates to:
  /// **'bei {km} km — Tachostand unbekannt'**
  String garageMaintenanceKmUnknown(String km);

  /// No description provided for @garageMaintenanceNeedsDue.
  ///
  /// In de, this message translates to:
  /// **'Bitte ein Datum oder einen Kilometerstand angeben.'**
  String get garageMaintenanceNeedsDue;

  /// No description provided for @garageDefault.
  ///
  /// In de, this message translates to:
  /// **'Standard'**
  String get garageDefault;

  /// No description provided for @garageMakeDefault.
  ///
  /// In de, this message translates to:
  /// **'Zum Standard machen'**
  String get garageMakeDefault;

  /// No description provided for @garageDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get garageDelete;

  /// No description provided for @garageEdit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get garageEdit;

  /// No description provided for @garageSavedEdit.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeug geändert.'**
  String get garageSavedEdit;

  /// No description provided for @garageDeleteConfirm.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeug löschen? Die Fahrten bleiben erhalten, verlieren aber ihre Zuordnung.'**
  String get garageDeleteConfirm;

  /// No description provided for @garageSaved.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeug gespeichert.'**
  String get garageSaved;

  /// No description provided for @garageNeedsCloud.
  ///
  /// In de, this message translates to:
  /// **'Die Garage gehört zum Cloud-Konto. Aktiviere die Cloud-Synchronisierung in den Einstellungen.'**
  String get garageNeedsCloud;

  /// No description provided for @settingsHelp.
  ///
  /// In de, this message translates to:
  /// **'Hilfe'**
  String get settingsHelp;

  /// No description provided for @settingsHelpSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Dokumentation und Fehlermeldungen auf GitHub'**
  String get settingsHelpSubtitle;

  /// No description provided for @settingsRate.
  ///
  /// In de, this message translates to:
  /// **'Bewerte die App'**
  String get settingsRate;

  /// No description provided for @settingsFeedback.
  ///
  /// In de, this message translates to:
  /// **'Feedback'**
  String get settingsFeedback;

  /// No description provided for @settingsFeedbackSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Im App Store'**
  String get settingsFeedbackSubtitle;

  /// No description provided for @settingsTip.
  ///
  /// In de, this message translates to:
  /// **'Trinkgeld'**
  String get settingsTip;

  /// No description provided for @settingsTipSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Die Entwicklung unterstützen'**
  String get settingsTipSubtitle;

  /// No description provided for @settingsImprint.
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get settingsImprint;

  /// No description provided for @settingsPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get settingsPrivacy;

  /// No description provided for @settingsContact.
  ///
  /// In de, this message translates to:
  /// **'Entwickler kontaktieren'**
  String get settingsContact;

  /// No description provided for @settingsContactSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Per E-Mail'**
  String get settingsContactSubtitle;

  /// No description provided for @settingsVersion.
  ///
  /// In de, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsLinkFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Link liess sich nicht öffnen.'**
  String get settingsLinkFailed;

  /// No description provided for @settingsDisclaimer.
  ///
  /// In de, this message translates to:
  /// **'Fahre stets verantwortungsvoll. Es gilt die StVO. Die Nutzung erfolgt auf eigene Gefahr. Ohne aktivierte Cloud-Synchronisierung bleiben alle Daten auf deinem Gerät.'**
  String get settingsDisclaimer;

  /// No description provided for @consentTitle.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei Speedster'**
  String get consentTitle;

  /// No description provided for @consentAccept.
  ///
  /// In de, this message translates to:
  /// **'Verstanden und einverstanden'**
  String get consentAccept;

  /// No description provided for @liveRecording.
  ///
  /// In de, this message translates to:
  /// **'Fahrt wird aufgezeichnet'**
  String get liveRecording;

  /// No description provided for @liveSpeedNotice.
  ///
  /// In de, this message translates to:
  /// **'Fahr vorausschauend — es gilt immer die zulässige Höchstgeschwindigkeit.'**
  String get liveSpeedNotice;

  /// No description provided for @liveReady.
  ///
  /// In de, this message translates to:
  /// **'Bereit.\nDeine Fahrt wird automatisch erkannt.'**
  String get liveReady;

  /// No description provided for @liveUnit.
  ///
  /// In de, this message translates to:
  /// **'Einheit: {unit}'**
  String liveUnit(String unit);

  /// No description provided for @heatmapUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Heatmap nicht verfügbar'**
  String get heatmapUnavailable;

  /// No description provided for @heatmapLoading.
  ///
  /// In de, this message translates to:
  /// **'Heatmap wird geladen …'**
  String get heatmapLoading;

  /// No description provided for @consentBody.
  ///
  /// In de, this message translates to:
  /// **'Speedster zeichnet Geschwindigkeit und Route deiner Fahrten auf.\n\nBitte fahre stets verantwortungsvoll. Es gilt immer die Straßenverkehrsordnung (StVO). Auf Streckenabschnitten ohne Tempolimit (z. B. Teile deutscher Autobahnen) gilt die Richtgeschwindigkeit — passe deine Geschwindigkeit stets an Verkehr, Wetter und Sicht an.\n\nDie Nutzung erfolgt auf eigene Gefahr. Speedster fordert nicht zu überhöhter Geschwindigkeit auf.\n\nDatenschutz: Deine Fahrten werden auf dem Gerät gespeichert. Erst wenn du die Cloud-Synchronisierung in den Einstellungen aktivierst, werden sie samt Streckenverlauf auf unseren Server übertragen. Du kannst deine Daten jederzeit in den Einstellungen löschen.'**
  String get consentBody;

  /// No description provided for @consentAcceptShort.
  ///
  /// In de, this message translates to:
  /// **'Akzeptieren'**
  String get consentAcceptShort;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In de, this message translates to:
  /// **'Account löschen?'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @friendsPendingTitle.
  ///
  /// In de, this message translates to:
  /// **'Freundschaftsanfragen'**
  String get friendsPendingTitle;

  /// No description provided for @friendsPendingLead.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Eine Person möchte sich mit dir verbinden.} other{{count} Personen möchten sich mit dir verbinden.}}'**
  String friendsPendingLead(int count);

  /// No description provided for @friendsPendingLater.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get friendsPendingLater;

  /// No description provided for @friendsPendingManage.
  ///
  /// In de, this message translates to:
  /// **'Alle ansehen'**
  String get friendsPendingManage;
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
    'that was used.',
  );
}
