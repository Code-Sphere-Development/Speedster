import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/app/theme.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/consent_screen.dart';
import 'package:speedster/ui/heatmap_screen.dart';
import 'package:speedster/ui/driver_prompt.dart';
import 'package:speedster/ui/live_screen.dart';
import 'package:speedster/ui/ranking_screen.dart';
import 'package:speedster/ui/settings_screen.dart';
import 'package:speedster/ui/trip_list_screen.dart';

class SpeedsterApp extends ConsumerWidget {
  const SpeedsterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consented =
        ref.watch(settingsControllerProvider.select((s) => s.consentAccepted));
    return MaterialApp(
      title: 'Speedster',
      theme: SpeedsterTheme.light,
      darkTheme: SpeedsterTheme.dark,
      // Ohne darkTheme faellt ThemeMode.system stillschweigend auf das helle
      // Theme zurueck -- genau das war vorher der Fall.
      themeMode: ThemeMode.system,
      home: consented ? const HomeShell() : const ConsentScreen(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

/// Die Reiter der App.
///
/// Eine Aufzaehlung statt einer Zahl, weil "Live" nur waehrend der Fahrt
/// erscheint und sich die Positionen dadurch verschieben. Ueber einen
/// Index gewaehlt spraenge die Auswahl beim Auftauchen und Verschwinden
/// des Reiters auf einen fremden Inhalt.
enum AppTab {
  heatmap('Heatmap', Icons.local_fire_department),
  live('Live', Icons.speed),
  trips('Fahrten', Icons.list),
  ranking('Ranking', Icons.leaderboard),
  settings('Einstellungen', Icons.settings);

  const AppTab(this.title, this.icon);

  final String title;
  final IconData icon;
}

class _HomeShellState extends ConsumerState<HomeShell> {
  AppTab _tab = AppTab.heatmap;

  /// Verhindert, dass ein erneutes isDriving-Ereignis derselben Fahrt die
  /// Ansicht wieder wegzieht, nachdem der Nutzer weggewechselt hat.
  bool _switchedForCurrentDrive = false;

  /// Alle Ansichten, immer und in fester Reihenfolge.
  ///
  /// Der IndexedStack behaelt sie deshalb ueber das Ein- und Ausblenden
  /// von "Live" hinweg. Wuerde die Liste selbst waechseln, verloere die
  /// Heatmap bei jedem Fahrtbeginn ihre Kameraposition und die
  /// Fahrtenliste ihre Blaetterstelle.
  static const _screens = [
    HeatmapScreen(),
    LiveScreen(),
    TripListScreen(),
    RankingScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartTracking();
      _refreshTripCache();
      _publishWidgets();
    });
  }

  /// Holt beim Start den lokalen Vorrat der zuletzt gefahrenen Strecken
  /// auf Stand und raeumt aeltere, bestaetigt hochgeladene Fahrten weg.
  ///
  /// Ohne Cloud tut der Dienst nichts -- dann ist die lokale Datenbank
  /// kein Vorrat, sondern der einzige Bestand.
  Future<void> _refreshTripCache() async {
    final result = await ref.read(tripCacheServiceProvider).refresh();
    // Nur neu laden, wenn sich lokal etwas geaendert hat: die Liste selbst
    // kommt bei aktiver Cloud ohnehin vom Server, aber die nachgetragenen
    // lokalen Ids entscheiden, welche Detailansicht ohne Netz auskommt.
    if (!mounted || (result.cached == 0 && result.evicted == 0)) return;
    ref.invalidate(keptTripsProvider);
  }

  Future<void> _maybeStartTracking() async {
    if (ref.read(settingsControllerProvider).trackingPaused) return;
    final granted = await ref.read(permissionGateProvider).ensure();
    if (!granted) return;
    // Fire-and-forget: the sample stream is long-lived.
    unawaited(ref.read(recorderProvider).start());
  }

  /// Legt die Werte fuer die Widgets ab.
  ///
  /// Beim Start und nach jeder Fahrt -- oefter waere Arbeit, die niemand
  /// sieht: das System zeichnet Widgets nur wenige Male pro Stunde neu.
  /// Fehler bleiben folgenlos, die Widgets zeigen dann den letzten Stand.
  Future<void> _publishWidgets() async {
    try {
      await ref.read(widgetPublisherProvider).publish();
    } catch (_) {
      // Widgets sind Beiwerk.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(recorderStateProvider, (prev, next) {
      final state = next.asData?.value;

      // Fahrtbeginn: einmalig auf Live wechseln. Kein Ruecksprung bei
      // Fahrtende — dem Nutzer die Ansicht unter dem Finger wegzuziehen
      // waere stoerend.
      final driving = state?.isDriving ?? false;
      if (driving && !_switchedForCurrentDrive) {
        _switchedForCurrentDrive = true;
        setState(() => _tab = AppTab.live);
      } else if (!driving) {
        _switchedForCurrentDrive = false;
      }

      final id = state?.awaitingConfirmationTripId;
      if (id != null) {
        ref.invalidate(keptTripsProvider);
        _publishWidgets();
        showDialog<void>(
          context: context,
          builder: (_) => DriverPrompt(tripId: id),
        );
      }
    });

    // Auto verbunden heisst: der Nutzer sitzt im Wagen, auch wenn die
    // Fahrterkennung noch nicht angesprungen ist.
    ref.listen(carConnectedProvider, (prev, next) {
      if (next.asData?.value == true && _tab == AppTab.heatmap) {
        setState(() => _tab = AppTab.live);
      }
    });

    final visible = _visibleTabs();
    // Faellt der aktive Reiter weg -- "Live" nach dem Fahrtende --, muss
    // die Auswahl irgendwohin. Zurueck auf die Heatmap: die ist die
    // Startansicht und zeigt die eben gefahrene Strecke.
    final tab = visible.contains(_tab) ? _tab : AppTab.heatmap;

    return Scaffold(
      appBar: AppBar(title: Text(tab.title)),
      body: IndexedStack(index: tab.index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: visible.indexOf(tab),
        onDestinationSelected: (i) => setState(() => _tab = visible[i]),
        destinations: [
          for (final t in visible)
            NavigationDestination(icon: Icon(t.icon), label: t.title),
        ],
      ),
    );
  }

  /// "Live" erscheint nur, solange tatsaechlich gefahren wird.
  ///
  /// Eine Tachoansicht im Stand zeigt eine Null und nimmt dauerhaft einen
  /// von fuenf Plaetzen ein. Als "gefahren" gilt dabei auch eine
  /// bestehende Verbindung zu CarPlay oder Android Auto -- dieselbe
  /// Auslegung wie in der Fahrterkennung, wo eine Verbindung das
  /// Fahrtende unterdrueckt: wer verbunden ist, sitzt im Auto.
  List<AppTab> _visibleTabs() {
    final driving =
        ref.watch(recorderStateProvider).asData?.value.isDriving ?? false;
    final inCar = ref.watch(carConnectedProvider).asData?.value ?? false;

    return [
      for (final t in AppTab.values)
        if (t != AppTab.live || driving || inCar) t,
    ];
  }
}
