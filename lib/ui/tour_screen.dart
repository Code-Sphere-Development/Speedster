import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/app.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';

/// Eine Station des Rundgangs.
class TourStop {
  const TourStop({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

/// Die Stationen, in der Reihenfolge der Reiter.
///
/// Die Symbole kommen aus AppTab und damit aus derselben Quelle wie die
/// Reiterleiste selbst -- sonst zeigte der Rundgang irgendwann auf ein
/// Symbol, das es nicht mehr gibt.
List<TourStop> tourStops(AppLocalizations l) => [
      TourStop(
        icon: Icons.waving_hand_outlined,
        title: l.tourWelcomeTitle,
        body: l.tourWelcomeBody,
      ),
      TourStop(
        icon: AppTab.heatmap.icon,
        title: l.tourHeatmapTitle,
        body: l.tourHeatmapBody,
      ),
      TourStop(
        icon: AppTab.trips.icon,
        title: l.tourTripsTitle,
        body: l.tourTripsBody,
      ),
      TourStop(
        icon: AppTab.ranking.icon,
        title: l.tourRankingTitle,
        body: l.tourRankingBody,
      ),
      TourStop(
        icon: AppTab.settings.icon,
        title: l.tourSettingsTitle,
        body: l.tourSettingsBody,
      ),
      // Zuletzt, weil dieser Reiter beim ersten Start gar nicht da ist --
      // ihn zwischen den anderen zu zeigen, waere verwirrend.
      TourStop(
        icon: AppTab.live.icon,
        title: l.tourLiveTitle,
        body: l.tourLiveBody,
      ),
    ];

/// Kurzer Rundgang beim ersten Start: welcher Reiter wofuer da ist.
///
/// Bewusst kein Overlay mit Sprechblasen auf der laufenden Oberflaeche:
/// das braeuchte ein weiteres Paket, haengt an den Bildschirmpositionen
/// und geht kaputt, sobald sich ein Reiter verschiebt. Sechs Seiten sagen
/// dasselbe und altern nicht.
///
/// Wird nach der Einwilligung gezeigt, nicht davor: die Einwilligung ist
/// Pflicht, der Rundgang ein Angebot.
class TourScreen extends ConsumerStatefulWidget {
  const TourScreen({super.key});

  @override
  ConsumerState<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends ConsumerState<TourScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final navigator = Navigator.of(context);
    // Auch beim Ueberspringen: wer ihn wegwischt, will ihn nicht beim
    // naechsten Start wiederhaben.
    await ref.read(settingsControllerProvider.notifier).setTourSeen(true);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final stops = tourStops(l);
    final scheme = Theme.of(context).colorScheme;
    final last = _index == stops.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: Text(l.tourSkip)),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: stops.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(stops[i].icon, size: 72, color: scheme.primary),
                      const SizedBox(height: 24),
                      Text(
                        stops[i].title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        stops[i].body,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < stops.length; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: last
                      ? _finish
                      : () => _pages.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                  child: Text(last ? l.tourDone : l.tourNext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
