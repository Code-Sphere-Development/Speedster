import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/app/theme.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/consent_screen.dart';
import 'package:speedster/ui/garage_screen.dart';
import 'package:speedster/ui/heatmap_screen.dart';
import 'package:speedster/ui/tour_screen.dart';
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
      // Zahlen werden ueber intl formatiert, und das liest die Sprache
      // aus einer globalen Vorgabe. Sie hier zu setzen ist die einzige
      // Stelle, an der die aufgeloeste Sprache bekannt ist, ohne sie
      // durch jede Formatierungsfunktion zu reichen.
      builder: (context, child) {
        Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();

        return child ?? const SizedBox.shrink();
      },
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
  garage(Icons.garage_outlined),
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
        AppTab.garage => l.tabGarage,
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
    GarageScreen(),
    RankingScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _maybeStartTracking();
      _refreshTripCache();
      _publishWidgets();
      // Der Rundgang zuerst und abgewartet: sonst legte sich der
      // Anfragen-Dialog darueber, und man beantwortete etwas, das man
      // noch gar nicht einordnen kann.
      await _maybeShowTour();
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
  /// Zeigt beim ersten Start einen kurzen Rundgang.
  ///
  /// Nach der Einwilligung, weil die Pflicht ist und der Rundgang ein
  /// Angebot -- und vor dem Anfragen-Dialog, damit sich nicht zwei
  /// Ansichten uebereinanderlegen.
  Future<void> _maybeShowTour() async {
    if (ref.read(settingsControllerProvider).tourSeen) return;
    if (!mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const TourScreen(),
      ),
    );
  }

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
    // Faellt der aktive Reiter weg -- "Live" nach dem Fahrtende, die
    // Garage bei Fahrtbeginn --, muss die Auswahl irgendwohin. Zurueck
    // auf die Heatmap: die ist die Startansicht und zeigt die eben
    // gefahrene Strecke.
    final tab = visible.contains(_tab) ? _tab : AppTab.heatmap;

    final l = AppLocalizations.of(context);

    return Scaffold(
      // Keine Titelleiste: sie wiederholte nur das Wort, das unten in der
      // Leiste ohnehin markiert ist, und nahm dafuer eine Zeile Hoehe.
      // Die Ueberschrift traegt jetzt der Inhalt (siehe ScreenHeader) und
      // scrollt mit.
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: tab.index, children: _screens),
      ),
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

  /// "Live" erscheint nur waehrend der Fahrt -- und verdraengt dann die
  /// Garage.
  ///
  /// Fuenf Reiter sind das Aeusserste, was in die Leiste passt: bei
  /// sechs bricht schon "Einstellungen" um. Welcher der beiden weichen
  /// muss, entscheidet die Lage: Fahrzeuge verwaltet man im Stand, das
  /// Tempo schaut man waehrend der Fahrt an. Beide sind situativ, also
  /// teilen sie sich einen Platz.
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

    final onTheRoad = driving || inCar;

    return [
      for (final t in AppTab.values)
        if (t == AppTab.live ? onTheRoad : t != AppTab.garage || !onTheRoad) t,
    ];
  }
}
