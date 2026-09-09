import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/app/theme.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/consent_screen.dart';
import 'package:speedster/ui/garage_screen.dart';
import 'package:speedster/ui/heatmap_screen.dart';
import 'package:speedster/ui/driver_prompt.dart';
import 'package:speedster/ui/friend_requests_prompt.dart';
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
      // Deutsch zuerst: die Oberflaeche wurde darin geschrieben, Englisch
      // ist die Uebersetzung. Welche Sprache greift, entscheidet das
      // Geraet -- eine eigene Auswahl in der App waere eine zweite
      // Einstellung neben der des Systems, die auseinanderlaufen kann.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
  heatmap(Icons.local_fire_department),
  live(Icons.speed),
  trips(Icons.list),
  ranking(Icons.leaderboard),
  settings(Icons.settings);

  const AppTab(this.icon);

  final IconData icon;

  /// Die Beschriftung kommt aus den Sprachdateien, nicht aus der
  /// Aufzaehlung: eine Konstante liesse sich nicht uebersetzen.
  String title(AppLocalizations l) => switch (this) {
        AppTab.heatmap => l.tabHeatmap,
        AppTab.live => l.tabLive,
        AppTab.trips => l.tabTrips,
        AppTab.ranking => l.tabRanking,
        AppTab.settings => l.tabSettings,
      };
}

class _HomeShellState extends ConsumerState<HomeShell> {
  AppTab _tab = AppTab.heatmap;

  /// Verhindert, dass ein erneutes isDriving-Ereignis derselben Fahrt die
  /// Ansicht wieder wegzieht, nachdem der Nutzer weggewechselt hat.
  bool _switchedForCurrentDrive = false;

  /// Offene Anfragen werden einmal je App-Start gezeigt. Ohne diese Sperre
  /// poppte der Dialog nach jedem Neuladen der Liste erneut auf -- auch
  /// waehrend der Fahrt.
  bool _askedAboutFriends = false;

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
      _askAboutFriendRequests();
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

  /// Zeigt offene Freundschaftsanfragen beim Oeffnen der App.
  ///
  /// Beim Start und nicht laufend: ein Dialog, der mitten in der Fahrt
  /// aufspringt, ist im Auto das Letzte, was jemand gebrauchen kann.
  Future<void> _askAboutFriendRequests() async {
    if (_askedAboutFriends) return;
    // Erst die Anmeldung pruefen, dann fragen: ohne Konto gibt es keine
    // Anfragen, und die Abfrage waere eine Netzrunde bei jedem Start, die
    // zwangslaeufig in einem 401 endet.
    if (await ref.read(cloudActiveProvider.future) != true) return;
    try {
      final overview = await ref.read(friendOverviewProvider.future);
      if (!mounted || overview.incoming.isEmpty) return;
      _askedAboutFriends = true;
      await FriendRequestsPrompt.maybeShow(context, overview.incoming);
    } catch (_) {
      // Ohne Cloud, ohne Anmeldung oder ohne Netz gibt es nichts zu
      // fragen. Die Anfragen bleiben offen und erscheinen spaeter.
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

    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tab.title(l)),
        // Die Garage haengt an den Fahrten, nicht an den Einstellungen:
        // eine Fahrt hat ein Fahrzeug. Ein eigener Reiter kaeme bei fuenf
        // bis sechs Reitern zu eng, und zwei Wege zum selben Bildschirm
        // stiften nur Verwirrung -- deshalb genau hier und sonst nirgends.
        actions: [
          if (tab == AppTab.trips)
            IconButton(
              icon: const Icon(Icons.garage_outlined),
              tooltip: l.settingsGarage,
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const GarageScreen()),
              ),
            ),
        ],
      ),
      body: IndexedStack(index: tab.index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: visible.indexOf(tab),
        onDestinationSelected: (i) => setState(() => _tab = visible[i]),
        destinations: [
          for (final t in visible)
            NavigationDestination(icon: Icon(t.icon), label: t.title(l)),
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
