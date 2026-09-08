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
  String get rankingMetricMaxSpeed => 'Top speed';

  @override
  String get rankingMetricDistance => 'Distance';

  @override
  String get rankingMetricTrips => 'Drives';

  @override
  String get rankingMetricZeroToHundred => 'Best 0–100';

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
  String get settingsFriends => 'Friends';

  @override
  String get settingsFriendsSubtitle => 'Compare figures with people you know';

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
