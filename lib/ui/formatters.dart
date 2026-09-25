import 'package:intl/intl.dart';
import 'package:speedster/settings/unit_system.dart';

/// Display helpers shared across trip screens.
class Formatters {
  static final _date = DateFormat('dd.MM.yyyy HH:mm');

  static String dateTime(DateTime dt) => _date.format(dt);

  /// Wochentag, Datum und Uhrzeit in der Schreibweise der Sprache -- "Mo.,
  /// 17. Aug. \u00b7 17:42" bzw. "Mon, Aug 17 \u00b7 17:42".
  ///
  /// [dateTime] bleibt daneben bestehen: in der Titelleiste der
  /// Detailansicht steht das volle Datum mit Jahr.
  static String dayAndTime(DateTime dt, String locale) =>
      '${DateFormat.MMMEd(locale).format(dt)} '
      '\u00b7 ${DateFormat.Hm(locale).format(dt)}';

  /// Seconds -> "1h 05m" / "12m 03s".
  static String duration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  static String seconds(double? value) =>
      value == null ? '–' : '${value.toStringAsFixed(1)} s';

  static String meters(double m) => '${m.round()} m';

  /// Sekunden als Stunden mit einer Nachkommastelle -- "312,7 h".
  ///
  /// Fuer Ranglisten, nicht fuer eine einzelne Fahrt: dort steht
  /// "40m 10s" (siehe [duration]). Eine Rangliste wird ueberflogen, und
  /// "312,7" vergleicht sich schneller als "312h 42m".
  static Measure hoursParts(double seconds) =>
      (value: _oneDecimal.format(seconds / 3600), unit: 'h');

  static final _oneDecimal = NumberFormat('#,##0.0');

  /// Wie [seconds], aber mit getrennter Einheit.
  ///
  /// Ohne Wert bleibt der Gedankenstrich allein stehen -- "– s" laese
  /// sich wie eine Messung von null Sekunden.
  static Measure secondsParts(double? value) => value == null
      ? (value: '–', unit: '')
      : (value: value.toStringAsFixed(1), unit: 's');

  /// Start und Ziel als eine Zeile -- "Koeln \u203a Duesseldorf".
  ///
  /// Gleicher Ort an beiden Enden: nur der Name. Eine Runde durch die
  /// Stadt als "Koeln \u203a Koeln" zu schreiben sagt nichts und liest
  /// sich wie ein Fehler.
  ///
  /// Ist nur ein Ende bekannt, steht auf der anderen Seite die Ellipse:
  /// "\u2026 \u203a Duesseldorf" heisst "irgendwoher nach Duesseldorf",
  /// der Name allein hiesse "innerhalb von Duesseldorf". Das sind
  /// verschiedene Aussagen.
  ///
  /// `null`, wenn kein Ende bekannt ist -- dann steht wie bisher das
  /// Datum allein.
  static String? route(String? start, String? end) {
    if (start == null && end == null) return null;
    if (start == end) return start;

    // Der Winkel und nicht der Pfeil U+2192: das Roboto, das Flutter als
    // Rueckfallschrift mitbringt, hat den Pfeil nicht, und dort stuende
    // ein leeres Kaestchen. Aufgefallen an den Screenshots fuer den App
    // Store, die genau diese Schrift verwenden.
    return '${start ?? '\u2026'} \u203a ${end ?? '\u2026'}';
  }

  /// Wie [meters], aber mit getrennter Einheit.
  static Measure metersParts(double m) => (value: '${m.round()}', unit: 'm');
}
