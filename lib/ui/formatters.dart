import 'package:intl/intl.dart';

/// Display helpers shared across trip screens.
class Formatters {
  static final _date = DateFormat('dd.MM.yyyy HH:mm');

  static String dateTime(DateTime dt) => _date.format(dt);

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
}
