/// Alle nach aussen fuehrenden Adressen an einem Ort.
///
/// Verstreut in den Vorlagen waeren sie beim naechsten Umzug einer Seite
/// nicht wiederzufinden -- und eine tote Adresse in den Einstellungen
/// faellt niemandem auf, bis sich jemand beschwert.
class AppLinks {
  const AppLinks._();

  /// Aus dem App-Store-Eintrag der App.
  static const String appStoreId = '6809726681';

  static const String appStore = 'https://apps.apple.com/app/id$appStoreId';

  /// Oeffnet den Eintrag unmittelbar im Bewertungsformular.
  static const String review = '$appStore?action=write-review';

  static const String help =
      'https://github.com/Code-Sphere-Development/Speedster';

  static const String tip = 'https://paypal.com/coho04';

  /// Basis der Speedster Cloud; der Einladungslink haengt den eigenen
  /// Benutzernamen an.
  static const String cloud = 'https://speedster.code-sphere.de';

  static String invitation(String username) => '$cloud/einladung/$username';
}
