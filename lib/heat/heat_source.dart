import 'package:speedster/heat/heat_map.dart';

/// Woher die Heatmap kommt. Lokal wird der Zeitfilter ignoriert, die Cloud
/// wertet ihn aus.
abstract class HeatSource {
  Future<HeatMap> load(HeatQuery query);
}
