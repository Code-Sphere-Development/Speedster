// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Speedster';

  @override
  String get tabHeatmap => 'Heatmap';

  @override
  String get tabLive => 'Live';

  @override
  String get tabTrips => 'Drives';

  @override
  String get tabRanking => 'Ranking';

  @override
  String get tabSettings => 'Settings';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String commonError(String message) {
    return 'Error: $message';
  }

  @override
  String get commonNoConnection => 'That did not work. Are you connected?';

  @override
  String get tripsEmpty => 'No drives recorded yet.';

  @override
  String get tripNoRoute =>
      'No route data. Older drives live only in the cloud — their map needs a connection.';

  @override
  String tripMapUnavailable(String message) {
    return 'Map unavailable: $message';
  }

  @override
  String get tripPurpose => 'Purpose';

  @override
  String get tripPurposeNone => 'No purpose';

  @override
  String get tripPurposePrivate => 'Private';

  @override
  String get tripPurposeCommute => 'Commute';

  @override
  String get tripPurposeBusiness => 'Business';

  @override
  String get tripNote => 'Note';

  @override
  String get tripPurposeSaved => 'Purpose saved.';

  @override
  String get metricMax => 'Max';

  @override
  String get metricAverage => 'Ø';

  @override
  String get metricDistance => 'Distance';

  @override
  String get metricDuration => 'Duration';

  @override
  String get metricZeroToHundred => '0–100';

  @override
  String get metricElevation => 'Elevation';

  @override
  String get heatmapEmpty => 'No routes recorded yet';

  @override
  String get heatmapRangeAll => 'All time';

  @override
  String get heatmapRange12m => '12 months';

  @override
  String get heatmapRange3m => '3 months';

  @override
  String get heatmapLegendRare => 'rare';

  @override
  String get heatmapLegendOften => 'often';

  @override
  String get liveSpeed => 'Speed';

  @override
  String get liveWaiting => 'Waiting for the drive to start …';

  @override
  String get liveDistance => 'Distance';

  @override
  String get liveDuration => 'Duration';

  @override
  String get driverTitle => 'Were you driving?';

  @override
  String get driverBody =>
      'Were you the driver? Only your own drives are kept. Drives recorded as a passenger can be discarded.';

  @override
  String get driverKeep => 'Keep';

  @override
  String get driverDiscard => 'Discard';

  @override
  String get rankingScopeWorld => 'World';

  @override
  String get rankingScopeCountry => 'Country';

  @override
  String get rankingScopeFriends => 'Friends';

  @override
  String get rankingScopeVehicle => 'Vehicle';

  @override
  String get rankingPeriodWeek => 'Week';

  @override
  String get rankingPeriodMonth => 'Month';

  @override
  String get rankingPeriodAll => 'All time';

  @override
  String get rankingNoVehicle =>
      'This ranking needs your default vehicle. Add it in the garage and pick a model — you are compared with everyone driving the same model.';

  @override
  String get rankingMetricMaxSpeed => 'Top speed';

  @override
  String get rankingMetricDistance => 'Distance';

  @override
  String get rankingMetricTrips => 'Drives';

  @override
  String get rankingMetricZeroToHundred => 'Best 0–100';

  @override
  String get rankingSpeedNotice =>
      'Road traffic law always applies. This ranking is no reason to exceed a speed limit.';

  @override
  String get rankingYourRank => 'Your rank';

  @override
  String get rankingEmpty => 'No entries yet.';

  @override
  String get rankingCloudOffTitle =>
      'The ranking compares you with other drivers and therefore depends on Speedster Cloud. Without cloud sync there is nobody to compare with.';

  @override
  String get rankingCloudOffHint => 'You will find cloud sync in the settings.';

  @override
  String get rankingSignInNeeded =>
      'To use the ranking you need to be signed in to Speedster Cloud.';

  @override
  String get rankingStatusUnknown => 'The sign-in status could not be checked.';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authRegister => 'Register';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authName => 'Name';

  @override
  String get authUsername => 'Username';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authUsernameHint => '3–30 characters: a–z, 0–9 and _';

  @override
  String get authUsernameRequired => 'Please choose a username.';

  @override
  String get authUsernameFormat =>
      'Username: 3 to 30 characters, lowercase letters, digits and underscore (_) only.';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get authNoAccount => 'New here? Create an account';

  @override
  String get authWithApple => 'Sign in with Apple';

  @override
  String get authWithGoogle => 'Sign in with Google';

  @override
  String authSocialSoon(String provider) {
    return '$provider sign-in is coming soon.';
  }

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsLead =>
      'Friends only see each other’s figures — no individual drives and no routes.';

  @override
  String get friendsUsernameLabel => 'Username';

  @override
  String get friendsUsernameHint => 'The unique handle, not the display name';

  @override
  String get friendsRequest => 'Request';

  @override
  String get friendsCopyInvite => 'Copy invitation link';

  @override
  String get friendsInviteCopied => 'Invitation link copied.';

  @override
  String get friendsIncoming => 'Requests waiting for you';

  @override
  String get friendsOutgoing => 'Sent by you';

  @override
  String get friendsAccept => 'Accept';

  @override
  String get friendsDecline => 'Decline';

  @override
  String get friendsRemove => 'Remove';

  @override
  String get friendsWithdraw => 'Withdraw';

  @override
  String get friendsEmpty => 'Nobody yet.';

  @override
  String get friendsEmptyHint =>
      'Share your invitation link or add someone by their username.';

  @override
  String get friendsLoadFailed => 'The friends list could not be loaded.';

  @override
  String get friendsRequestSent => 'Request sent.';

  @override
  String get friendsNowFriends => 'You are friends now.';

  @override
  String get friendsDeclined => 'Declined.';

  @override
  String get friendsRemoved => 'Removed.';

  @override
  String get friendsWithdrawn => 'Withdrawn.';

  @override
  String get settingsUnitTitle => 'Unit: miles (mph)';

  @override
  String get settingsUnitSubtitle => 'Off = km/h';

  @override
  String get settingsPauseTitle => 'Pause tracking';

  @override
  String get settingsPauseSubtitle => 'No automatic drive detection';

  @override
  String get settingsCloudTitle => 'Enable cloud sync';

  @override
  String get settingsCloudSubtitle =>
      'Back drives up to the cloud (backup + rankings). Off = everything stays on the device.';

  @override
  String get settingsDeleteAccount => 'Delete cloud account';

  @override
  String get settingsDeleteAccountBody =>
      'Your cloud account and all uploaded drives will be deleted.';

  @override
  String get settingsDeleteAll => 'Delete all data';

  @override
  String get settingsDeleteAllTitle => 'Delete all data?';

  @override
  String get settingsDeleteAllBody =>
      'All recorded drives will be deleted irreversibly.';

  @override
  String get settingsUsername => 'Username';

  @override
  String get settingsUsernameMissing => 'None chosen yet — set it on the web';

  @override
  String get settingsUsernameChangeTitle => 'Change username';

  @override
  String get settingsUsernameChangeLead =>
      'This is the name people find you under in the leaderboard and through invitation links. After a change your old name stays reserved for you for a while, and you can only change again after that.';

  @override
  String settingsUsernameLocked(String date) {
    return 'You can change again on $date';
  }

  @override
  String get settingsUsernameSaved => 'Username changed.';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsBackupSubtitle =>
      'Write your drives to a file or read them back';

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupLead =>
      'Without the cloud your drives live only on this device. A backup is what you take with you when you switch phones.';

  @override
  String get backupExport => 'Write backup';

  @override
  String backupExportDone(int count) {
    return '$count drives backed up. The file is in the Files app under “On My iPhone → Speedster”.';
  }

  @override
  String get backupImport => 'Read in';

  @override
  String backupImportDone(int imported, int skipped) {
    return '$imported drives read in, $skipped skipped (already there).';
  }

  @override
  String get backupImportFailed =>
      'The file could not be read — is it a Speedster backup?';

  @override
  String get backupNone =>
      'No backup found. Put a file into the “Speedster” folder using the Files app and it will show up here.';

  @override
  String get backupFiles => 'Available backups';

  @override
  String get settingsFriends => 'Friends';

  @override
  String get settingsFriendsSubtitle => 'Compare figures with people you know';

  @override
  String get settingsGarage => 'Garage';

  @override
  String get garageTitle => 'Garage';

  @override
  String get garageLead =>
      'New drives are assigned to your default vehicle. The model decides who you are compared with in the vehicle ranking.';

  @override
  String get garageEmpty => 'No vehicle added yet.';

  @override
  String get garageAdd => 'Add vehicle';

  @override
  String get garageName => 'Name';

  @override
  String get garageNameHint => 'Whatever you call it — “the Golf”';

  @override
  String get garageModel => 'Model';

  @override
  String get garageModelSearch => 'Search model';

  @override
  String get garageModelNone => 'No model assigned';

  @override
  String get garageModelHint =>
      'Without a model the vehicle does not appear in the vehicle ranking.';

  @override
  String get garageNoModels => 'No model found.';

  @override
  String get garageYear => 'Year';

  @override
  String get garagePower => 'Power (hp)';

  @override
  String get garageOdometer => 'Odometer';

  @override
  String garageOdometerEstimate(String km) {
    return 'approx. $km km';
  }

  @override
  String garageOdometerBasis(String km, String date, String tracked) {
    return 'Estimated from $km km on $date, plus $tracked km recorded since.';
  }

  @override
  String get garageOdometerNone => 'No odometer reading yet.';

  @override
  String get garageOdometerAdd => 'Add odometer reading';

  @override
  String get garageOdometerKm => 'Kilometres';

  @override
  String get garageOdometerSaved => 'Odometer reading saved.';

  @override
  String garageOdometerDeviation(String km) {
    return 'The estimate was off by $km km — that much the app did not see.';
  }

  @override
  String get garageMaintenance => 'Maintenance';

  @override
  String get garageMaintenanceAdd => 'Add maintenance';

  @override
  String get garageMaintenanceTitle => 'What';

  @override
  String get garageMaintenanceTitleHint => 'Inspection, service, oil change …';

  @override
  String get garageMaintenanceDueKm => 'Due at km';

  @override
  String get garageMaintenanceDueOn => 'Due on';

  @override
  String get garageMaintenanceNone => 'No maintenance entered.';

  @override
  String get garageMaintenanceDone => 'Done';

  @override
  String garageMaintenanceInDays(int count) {
    return 'in $count days';
  }

  @override
  String garageMaintenanceOverdueDays(int count) {
    return '$count days overdue';
  }

  @override
  String get garageMaintenanceToday => 'due today';

  @override
  String garageMaintenanceInKm(String km) {
    return 'in approx. $km km';
  }

  @override
  String garageMaintenanceOverdueKm(String km) {
    return 'approx. $km km overdue';
  }

  @override
  String garageMaintenanceKmUnknown(String km) {
    return 'at $km km — odometer unknown';
  }

  @override
  String get garageMaintenanceNeedsDue => 'Please give a date or a mileage.';

  @override
  String get garageDefault => 'Default';

  @override
  String get garageMakeDefault => 'Make default';

  @override
  String get garageDelete => 'Delete';

  @override
  String get garageEdit => 'Edit';

  @override
  String get garageSavedEdit => 'Vehicle updated.';

  @override
  String get garageDeleteConfirm =>
      'Delete this vehicle? Your drives are kept but lose their assignment.';

  @override
  String get garageSaved => 'Vehicle saved.';

  @override
  String get garageNeedsCloud =>
      'The garage belongs to your cloud account. Enable cloud sync in the settings.';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsHelpSubtitle => 'Documentation and issues on GitHub';

  @override
  String get settingsRate => 'Rate the app';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsFeedbackSubtitle => 'In the App Store';

  @override
  String get settingsTip => 'Tip jar';

  @override
  String get settingsTipSubtitle => 'Support the development';

  @override
  String get settingsImprint => 'Legal notice';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsContact => 'Contact the developer';

  @override
  String get settingsContactSubtitle => 'By email';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLinkFailed => 'The link could not be opened.';

  @override
  String get settingsDisclaimer =>
      'Always drive responsibly. Road traffic regulations apply. Use at your own risk. Without cloud sync enabled, all data stays on your device.';

  @override
  String get consentTitle => 'Welcome to Speedster';

  @override
  String get consentAccept => 'Understood and agreed';

  @override
  String get liveRecording => 'Recording your drive';

  @override
  String get liveSpeedNotice =>
      'Drive with foresight — the legal speed limit always applies.';

  @override
  String get liveReady => 'Ready.\nYour drive is detected automatically.';

  @override
  String liveUnit(String unit) {
    return 'Unit: $unit';
  }

  @override
  String get heatmapUnavailable => 'Heatmap unavailable';

  @override
  String get heatmapLoading => 'Loading the heatmap …';

  @override
  String get consentBody =>
      'Speedster records the speed and route of your drives.\n\nPlease always drive responsibly. Road traffic regulations always apply. On sections without a speed limit (for example parts of German motorways) the advisory speed applies — always adapt your speed to traffic, weather and visibility.\n\nUse is at your own risk. Speedster does not encourage excessive speed.\n\nPrivacy: your drives are stored on the device. Only when you enable cloud sync in the settings are they transferred, including their routes, to our server. You can delete your data at any time in the settings.';

  @override
  String get consentAcceptShort => 'Accept';

  @override
  String get settingsDeleteAccountTitle => 'Delete account?';

  @override
  String get friendsPendingTitle => 'Friend requests';

  @override
  String friendsPendingLead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people would like to connect with you.',
      one: 'Someone would like to connect with you.',
    );
    return '$_temp0';
  }

  @override
  String get friendsPendingLater => 'Later';

  @override
  String get friendsPendingManage => 'See all';
}
