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

  /// Wie [seconds], aber mit getrennter Einheit.
  ///
  /// Ohne Wert bleibt der Gedankenstrich allein stehen -- "– s" laese
  /// sich wie eine Messung von null Sekunden.
  static Measure secondsParts(double? value) => value == null
      ? (value: '–', unit: '')
      : (value: value.toStringAsFixed(1), unit: 's');

  /// Wie [meters], aber mit getrennter Einheit.
  static Measure metersParts(double m) => (value: '${m.round()}', unit: 'm');
}
