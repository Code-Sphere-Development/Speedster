// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Speedster';

  @override
  String get tabHeatmap => 'Heatmap';

  @override
  String get tabLive => 'Live';

  @override
  String get tabTrips => 'Fahrten';

  @override
  String get tabGarage => 'Garage';

  @override
  String tripsSummary(int count, String distance) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fahrten',
      one: 'Eine Fahrt',
    );
    return '$_temp0 · $distance';
  }

  @override
  String rankingSummary(String scope, String period) {
    return '$scope · $period';
  }

  @override
  String garageSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fahrzeuge',
      one: 'Ein Fahrzeug',
      zero: 'Noch kein Fahrzeug',
    );
    return '$_temp0';
  }

  @override
  String get tabRanking => 'Ranking';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonSave => 'Speichern';

  @override
  String commonError(String message) {
    return 'Fehler: $message';
  }

  @override
  String get commonNoConnection =>
      'Das hat nicht geklappt. Besteht eine Verbindung?';

  @override
  String get tripsEmpty => 'Noch keine Fahrten aufgezeichnet.';

  @override
  String get tripNoRoute =>
      'Keine Streckendaten. Ältere Fahrten liegen nur in der Cloud — ihre Karte braucht eine Verbindung.';

  @override
  String tripMapUnavailable(String message) {
    return 'Karte nicht verfügbar: $message';
  }

  @override
  String get tripPurpose => 'Zweck';

  @override
  String get tripPurposeNone => 'Kein Zweck';

  @override
  String get tripPurposePrivate => 'Privat';

  @override
  String get tripPurposeCommute => 'Arbeitsweg';

  @override
  String get tripPurposeBusiness => 'Geschäftlich';

  @override
  String get tripNote => 'Notiz';

  @override
  String get tripPurposeSaved => 'Zweck gespeichert.';

  @override
  String get metricMax => 'Max';

  @override
  String get metricAverage => 'Ø';

  @override
  String get metricDistance => 'Distanz';

  @override
  String get metricDuration => 'Dauer';

  @override
  String get metricZeroToHundred => '0–100';

  @override
  String get metricElevation => 'Höhenmeter';

  @override
  String get heatmapEmpty => 'Noch keine Strecken aufgezeichnet';

  @override
  String get heatmapRangeAll => 'Alles';

  @override
  String get heatmapRange12m => '12 Monate';

  @override
  String get heatmapRange3m => '3 Monate';

  @override
  String get heatmapLegendRare => 'selten';

  @override
  String get heatmapLegendOften => 'oft';

  @override
  String get liveSpeed => 'Geschwindigkeit';

  @override
  String get liveWaiting => 'Warte auf Fahrtbeginn …';

  @override
  String get liveDistance => 'Distanz';

  @override
  String get liveDuration => 'Dauer';

  @override
  String get rankingScopeWorld => 'Welt';

  @override
  String get rankingScopeCountry => 'Land';

  @override
  String get rankingScopeFriends => 'Freunde';

  @override
  String get rankingScopeVehicle => 'Fahrzeug';

  @override
  String get rankingPeriodWeek => 'Woche';

  @override
  String get rankingPeriodMonth => 'Monat';

  @override
  String get rankingPeriodAll => 'Gesamt';

  @override
  String get rankingNoVehicle =>
      'Für diese Wertung fehlt dein Standardfahrzeug. Lege es in der Garage an und wähle ein Modell — verglichen wird mit allen, die dasselbe Modell fahren.';

  @override
  String get rankingMetricMaxSpeed => 'Max Speed';

  @override
  String get rankingMetricDistance => 'Distanz';

  @override
  String get rankingMetricTrips => 'Fahrten';

  @override
  String get rankingMetricZeroToHundred => 'Beste 0–100';

  @override
  String get rankingSpeedNotice =>
      'Es gilt immer die StVO. Diese Wertung ist kein Grund, eine Geschwindigkeitsbegrenzung zu überschreiten.';

  @override
  String get rankingYourRank => 'Dein Rang';

  @override
  String get rankingEmpty => 'Noch keine Einträge.';

  @override
  String get rankingSignInNeeded =>
      'Für das Ranking musst du in der Speedster Cloud angemeldet sein.';

  @override
  String get rankingStatusUnknown =>
      'Der Anmeldestatus liess sich nicht prüfen.';

  @override
  String get authSignIn => 'Anmelden';

  @override
  String get authRegister => 'Registrieren';

  @override
  String get authCreateAccount => 'Konto erstellen';

  @override
  String get authName => 'Name';

  @override
  String get authUsername => 'Benutzername';

  @override
  String get authEmail => 'E-Mail';

  @override
  String get authPassword => 'Passwort';

  @override
  String get authUsernameHint => '3–30 Zeichen: a–z, 0–9 und _';

  @override
  String get authUsernameRequired => 'Bitte einen Benutzernamen angeben.';

  @override
  String get authUsernameFormat =>
      'Benutzername: 3 bis 30 Zeichen, nur Kleinbuchstaben, Ziffern und Unterstrich (_).';

  @override
  String get authHaveAccount => 'Schon ein Konto? Anmelden';

  @override
  String get authNoAccount => 'Neu hier? Konto erstellen';

  @override
  String get authWithApple => 'Mit Apple anmelden';

  @override
  String get authWithGoogle => 'Mit Google anmelden';

  @override
  String authSocialSoon(String provider) {
    return '$provider-Login folgt in Kürze.';
  }

  @override
  String get friendsTitle => 'Freunde';

  @override
  String get friendsLead =>
      'Freunde sehen voneinander nur Kennzahlen — keine einzelnen Fahrten und keine Strecken.';

  @override
  String get friendsUsernameLabel => 'Benutzername';

  @override
  String get friendsUsernameHint => 'Die eindeutige Kennung, kein Anzeigename';

  @override
  String get friendsRequest => 'Anfragen';

  @override
  String get friendsCopyInvite => 'Einladungslink kopieren';

  @override
  String get friendsInviteCopied => 'Einladungslink kopiert.';

  @override
  String get friendsIncoming => 'Offene Anfragen an dich';

  @override
  String get friendsOutgoing => 'Von dir verschickt';

  @override
  String get friendsAccept => 'Annehmen';

  @override
  String get friendsDecline => 'Ablehnen';

  @override
  String get friendsRemove => 'Entfernen';

  @override
  String get friendsWithdraw => 'Zurückziehen';

  @override
  String get friendsEmpty => 'Noch niemand.';

  @override
  String get friendsEmptyHint =>
      'Teile deinen Einladungslink oder füge jemanden über seinen Benutzernamen hinzu.';

  @override
  String get friendsLoadFailed =>
      'Die Freundesliste konnte nicht geladen werden.';

  @override
  String get friendsRequestSent => 'Anfrage verschickt.';

  @override
  String get friendsNowFriends => 'Ihr seid jetzt befreundet.';

  @override
  String get friendsDeclined => 'Abgelehnt.';

  @override
  String get friendsRemoved => 'Entfernt.';

  @override
  String get friendsWithdrawn => 'Zurückgezogen.';

  @override
  String get notificationChannelName => 'Fahrtaufzeichnung';

  @override
  String get notificationChannelNameAudible => 'Fahrtaufzeichnung mit Ton';

  @override
  String get notificationTripStartedTitle => 'Aufzeichnung läuft';

  @override
  String get notificationTripStartedBody =>
      'Speedster zeichnet deine Fahrt auf.';

  @override
  String get settingsNotifyTitle => 'Fahrtbeginn melden';

  @override
  String get settingsNotifySubtitle =>
      'Kurze Mitteilung, auch auf der Apple Watch — im Auto mit Ton';

  @override
  String get settingsNotifyDenied =>
      'Dafür braucht Speedster die Erlaubnis für Mitteilungen. Du kannst sie in den Systemeinstellungen erteilen.';

  @override
  String get settingsSectionRecording => 'Aufzeichnung';

  @override
  String get settingsSectionAccount => 'Konto';

  @override
  String get settingsSectionData => 'Daten';

  @override
  String get settingsSectionHelp => 'Hilfe';

  @override
  String get settingsSectionLegal => 'Rechtliches';

  @override
  String get settingsUnitTitle => 'Einheit: Meilen (mph)';

  @override
  String get settingsUnitSubtitle => 'Aus = km/h';

  @override
  String get settingsPauseTitle => 'Tracking pausieren';

  @override
  String get settingsPauseSubtitle => 'Keine automatische Fahrterkennung';

  @override
  String get settingsCloudTitle => 'Cloud-Sync aktivieren';

  @override
  String get settingsCloudSubtitle =>
      'Fahrten in die Cloud sichern (Backup + Rankings). Aus = alles bleibt nur auf dem Gerät.';

  @override
  String get settingsDeleteAccount => 'Cloud-Account löschen';

  @override
  String get settingsDeleteAccountBody =>
      'Dein Cloud-Konto und alle hochgeladenen Fahrten werden gelöscht.';

  @override
  String get settingsDeleteAll => 'Alle Daten löschen';

  @override
  String get settingsDeleteAllTitle => 'Alle Daten löschen?';

  @override
  String get settingsDeleteAllBody =>
      'Alle aufgezeichneten Fahrten werden unwiderruflich gelöscht.';

  @override
  String get settingsUsername => 'Benutzername';

  @override
  String get settingsUsernameMissing =>
      'Noch keiner vergeben — im Web nachholen';

  @override
  String get settingsUsernameChangeTitle => 'Benutzername ändern';

  @override
  String get settingsUsernameChangeLead =>
      'Unter diesem Namen findet man dich in der Bestenliste und über Einladungslinks. Nach einem Wechsel bleibt dein alter Name eine Zeit lang für dich reserviert, und du kannst erst danach wieder wechseln.';

  @override
  String settingsUsernameLocked(String date) {
    return 'Wechsel wieder möglich am $date';
  }

  @override
  String get settingsUsernameSaved => 'Benutzername geändert.';

  @override
  String get settingsBackup => 'Sicherung';

  @override
  String get settingsBackupSubtitle =>
      'Fahrten in eine Datei schreiben oder zurücklesen';

  @override
  String get settingsPending => 'Warten auf Upload';

  @override
  String settingsPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fahrten warten',
      one: 'Eine Fahrt wartet',
      zero: 'Alle Fahrten sind in der Cloud',
    );
    return '$_temp0';
  }

  @override
  String get settingsPendingAction => 'Jetzt hochladen';

  @override
  String settingsPendingDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fahrten hochgeladen',
      one: 'Eine Fahrt hochgeladen',
      zero: 'Nichts zu tun',
    );
    return '$_temp0';
  }

  @override
  String settingsPendingRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fahrten wurden abgewiesen',
      one: 'Eine Fahrt wurde abgewiesen',
    );
    return '$_temp0 und bleibt liegen.';
  }

  @override
  String get settingsPendingFailed =>
      'Kein Upload möglich — besteht eine Verbindung?';

  @override
  String settingsPendingServerError(int status) {
    return 'Der Server hat mit $status geantwortet. Am Netz liegt es nicht.';
  }

  @override
  String get settingsPendingLoggedOut =>
      'Nicht angemeldet — schalte die Cloud-Synchronisierung oben ein.';

  @override
  String get tourSkip => 'Überspringen';

  @override
  String get tourNext => 'Weiter';

  @override
  String get tourDone => 'Los geht\'s';

  @override
  String get tourWelcomeTitle => 'Willkommen bei Speedster';

  @override
  String get tourWelcomeBody =>
      'Ein kurzer Rundgang: vier Bildschirme, und wo du was findest. Du kannst ihn jederzeit überspringen und in den Einstellungen erneut aufrufen.';

  @override
  String get tourHeatmapTitle => 'Heatmap';

  @override
  String get tourHeatmapBody =>
      'Jede Straße, die du gefahren bist. Je öfter du sie fährst, desto heller brennt sie. Das ist auch der Bildschirm, mit dem die App startet.';

  @override
  String get tourTripsTitle => 'Fahrten';

  @override
  String get tourTripsBody =>
      'Jede aufgezeichnete Fahrt mit Strecke, Tempo und Dauer. Oben rechts liegt die Garage: deine Fahrzeuge, der Tachostand und fällige Wartungen.';

  @override
  String get tourRankingTitle => 'Bestenliste';

  @override
  String get tourRankingBody =>
      'Weltweit, im eigenen Land, unter Freunden oder nach Fahrzeug — für die Woche, den Monat oder gesamt. Dafür brauchst du ein Cloud-Konto.';

  @override
  String get tourSettingsTitle => 'Einstellungen';

  @override
  String get tourSettingsBody =>
      'Cloud-Synchronisierung, Freunde, Sicherung deiner Fahrten, Einheiten und alles Rechtliche.';

  @override
  String get tourLiveTitle => 'Live';

  @override
  String get tourLiveBody =>
      'Während einer Fahrt kommt ein fünfter Bildschirm dazu: dein Tempo in Echtzeit. Er erscheint von selbst, sobald du losfährst — die Aufzeichnung startet ohne Knopfdruck.';

  @override
  String get settingsTour => 'Rundgang';

  @override
  String get settingsTourSubtitle => 'Zeigt dir noch einmal, wo was liegt';

  @override
  String get backupTitle => 'Sicherung';

  @override
  String get backupLead =>
      'Ohne Cloud liegen deine Fahrten nur auf diesem Gerät. Eine Sicherung nimmst du beim Wechsel des Telefons mit.';

  @override
  String get backupExport => 'Sicherung schreiben';

  @override
  String backupExportDone(int count) {
    return '$count Fahrten gesichert. Die Datei liegt in der Dateien-App unter „Auf meinem iPhone → Speedster“.';
  }

  @override
  String get backupImport => 'Einlesen';

  @override
  String backupImportDone(int imported, int skipped) {
    return '$imported Fahrten eingelesen, $skipped übersprungen (gab es schon).';
  }

  @override
  String get backupImportFailed =>
      'Die Datei ließ sich nicht lesen — ist es eine Speedster-Sicherung?';

  @override
  String get backupNone =>
      'Keine Sicherung gefunden. Lege eine Datei über die Dateien-App im Ordner „Speedster“ ab, dann erscheint sie hier.';

  @override
  String get backupFiles => 'Vorhandene Sicherungen';

  @override
  String get settingsFriends => 'Freunde';

  @override
  String get settingsFriendsSubtitle => 'Kennzahlen mit Bekannten vergleichen';

  @override
  String get garageLead =>
      'Neue Fahrten werden dem Standardfahrzeug zugeordnet. Das Modell bestimmt, mit wem du in der Fahrzeugwertung verglichen wirst.';

  @override
  String get garageEmpty => 'Noch kein Fahrzeug angelegt.';

  @override
  String get garageAdd => 'Fahrzeug anlegen';

  @override
  String get garageName => 'Name';

  @override
  String get garageNameHint => 'Wie du es nennst — „Der Golf“';

  @override
  String get garageModel => 'Modell';

  @override
  String get garageModelSearch => 'Modell suchen';

  @override
  String get garageModelNone => 'Kein Modell zugeordnet';

  @override
  String get garageModelHint =>
      'Ohne Modell erscheint das Fahrzeug nicht in der Fahrzeugwertung.';

  @override
  String get garageNoModels => 'Kein Modell gefunden.';

  @override
  String get garageYear => 'Baujahr';

  @override
  String get garagePower => 'Leistung (PS)';

  @override
  String get garagePowerUnit => 'PS';

  @override
  String get garageOdometer => 'Tachostand';

  @override
  String garageOdometerEstimate(String km) {
    return 'ca. $km km';
  }

  @override
  String get garageOdometerApprox => 'geschätzt';

  @override
  String garageOdometerBasis(String km, String date, String tracked) {
    return 'Geschätzt aus $km km vom $date, plus $tracked km seither aufgezeichnet.';
  }

  @override
  String get garageOdometerNone => 'Noch kein Tachostand eingetragen.';

  @override
  String get garageOdometerAdd => 'Tachostand eintragen';

  @override
  String get garageOdometerKm => 'Kilometerstand';

  @override
  String get garageOdometerSaved => 'Tachostand gespeichert.';

  @override
  String garageOdometerDeviation(String km) {
    return 'Die Schätzung lag $km km daneben — so viel hat die App nicht mitbekommen.';
  }

  @override
  String get garageMaintenance => 'Wartung';

  @override
  String get garageMaintenanceAdd => 'Wartung eintragen';

  @override
  String get garageMaintenanceTitle => 'Was';

  @override
  String get garageMaintenanceTitleHint => 'HU, Inspektion, Ölwechsel …';

  @override
  String get garageMaintenanceDueKm => 'Fällig bei km';

  @override
  String get garageMaintenanceModeAt => 'Bei Kilometerstand';

  @override
  String get garageMaintenanceModeIn => 'In x Kilometern';

  @override
  String get garageMaintenanceDueInKm => 'In km';

  @override
  String get garageMaintenanceNeedsOdometer =>
      'Für „in x km“ fehlt der Tachostand — trage ihn ein oder gib den Zielstand an.';

  @override
  String get garageMaintenanceDueOn => 'Fällig am';

  @override
  String get garageMaintenanceNone => 'Keine Wartung eingetragen.';

  @override
  String get garageMaintenanceDone => 'Erledigt';

  @override
  String garageMaintenanceInDays(int count) {
    return 'in $count Tagen';
  }

  @override
  String garageMaintenanceOverdueDays(int count) {
    return 'seit $count Tagen überfällig';
  }

  @override
  String get garageMaintenanceToday => 'heute fällig';

  @override
  String garageMaintenanceInKm(String km) {
    return 'in ca. $km km';
  }

  @override
  String garageMaintenanceOverdueKm(String km) {
    return 'ca. $km km überfällig';
  }

  @override
  String garageMaintenanceKmUnknown(String km) {
    return 'bei $km km — Tachostand unbekannt';
  }

  @override
  String get garageMaintenanceNeedsDue =>
      'Bitte ein Datum oder einen Kilometerstand angeben.';

  @override
  String get garageDefault => 'Standard';

  @override
  String get garageMakeDefault => 'Zum Standard machen';

  @override
  String get garageDelete => 'Löschen';

  @override
  String get garageEdit => 'Bearbeiten';

  @override
  String get garageSavedEdit => 'Fahrzeug geändert.';

  @override
  String get garageDeleteConfirm =>
      'Fahrzeug löschen? Die Fahrten bleiben erhalten, verlieren aber ihre Zuordnung.';

  @override
  String get garageSaved => 'Fahrzeug gespeichert.';

  @override
  String get garageNeedsCloud =>
      'Die Garage gehört zum Cloud-Konto. Aktiviere die Cloud-Synchronisierung in den Einstellungen.';

  @override
  String get settingsHelp => 'Hilfe';

  @override
  String get settingsHelpSubtitle =>
      'Dokumentation und Fehlermeldungen auf GitHub';

  @override
  String get settingsRate => 'Bewerte die App';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsFeedbackSubtitle => 'Im App Store';

  @override
  String get settingsTip => 'Trinkgeld';

  @override
  String get settingsTipSubtitle => 'Die Entwicklung unterstützen';

  @override
  String get settingsImprint => 'Impressum';

  @override
  String get settingsPrivacy => 'Datenschutz';

  @override
  String get settingsContact => 'Entwickler kontaktieren';

  @override
  String get settingsContactSubtitle => 'Per E-Mail';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLinkFailed => 'Der Link liess sich nicht öffnen.';

  @override
  String get settingsDisclaimer =>
      'Fahre stets verantwortungsvoll. Es gilt die StVO. Die Nutzung erfolgt auf eigene Gefahr. Ohne aktivierte Cloud-Synchronisierung bleiben alle Daten auf deinem Gerät.';

  @override
  String get consentTitle => 'Willkommen bei Speedster';

  @override
  String get consentAccept => 'Verstanden und einverstanden';

  @override
  String get liveRecording => 'Fahrt wird aufgezeichnet';

  @override
  String get liveSpeedNotice =>
      'Fahr vorausschauend — es gilt immer die zulässige Höchstgeschwindigkeit.';

  @override
  String get liveReady => 'Bereit.\nDeine Fahrt wird automatisch erkannt.';

  @override
  String liveUnit(String unit) {
    return 'Einheit: $unit';
  }

  @override
  String get heatmapUnavailable => 'Heatmap nicht verfügbar';

  @override
  String get heatmapLoading => 'Heatmap wird geladen …';

  @override
  String get consentBody =>
      'Speedster zeichnet Geschwindigkeit und Route deiner Fahrten auf.\n\nBitte fahre stets verantwortungsvoll. Es gilt immer die Straßenverkehrsordnung (StVO). Auf Streckenabschnitten ohne Tempolimit (z. B. Teile deutscher Autobahnen) gilt die Richtgeschwindigkeit — passe deine Geschwindigkeit stets an Verkehr, Wetter und Sicht an.\n\nDie Nutzung erfolgt auf eigene Gefahr. Speedster fordert nicht zu überhöhter Geschwindigkeit auf.\n\nDatenschutz: Deine Fahrten werden auf dem Gerät gespeichert. Erst wenn du die Cloud-Synchronisierung in den Einstellungen aktivierst, werden sie samt Streckenverlauf auf unseren Server übertragen. Du kannst deine Daten jederzeit in den Einstellungen löschen.';

  @override
  String get consentAcceptShort => 'Akzeptieren';

  @override
  String get settingsDeleteAccountTitle => 'Account löschen?';

  @override
  String get friendsPendingTitle => 'Freundschaftsanfragen';

  @override
  String friendsPendingLead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen möchten sich mit dir verbinden.',
      one: 'Eine Person möchte sich mit dir verbinden.',
    );
    return '$_temp0';
  }

  @override
  String get friendsPendingLater => 'Später';

  @override
  String get friendsPendingManage => 'Alle ansehen';
}
