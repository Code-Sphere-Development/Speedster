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

  static const int heatmapTab = 0;
  static const int liveTab = 1;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = HomeShell.heatmapTab;

  /// Verhindert, dass ein erneutes isDriving-Ereignis derselben Fahrt die
  /// Ansicht wieder wegzieht, nachdem der Nutzer weggewechselt hat.
  bool _switchedForCurrentDrive = false;

  static const _tabs = [
    HeatmapScreen(),
    LiveScreen(),
    TripListScreen(),
    RankingScreen(),
    SettingsScreen(),
  ];
  static const _titles = [
    'Heatmap',
    'Live',
    'Fahrten',
    'Ranking',
    'Einstellungen',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTracking());
  }

  Future<void> _maybeStartTracking() async {
    if (ref.read(settingsControllerProvider).trackingPaused) return;
    final granted = await ref.read(permissionGateProvider).ensure();
    if (!granted) return;
    // Fire-and-forget: the sample stream is long-lived.
    unawaited(ref.read(recorderProvider).start());
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
        setState(() => _index = HomeShell.liveTab);
      } else if (!driving) {
        _switchedForCurrentDrive = false;
      }

      final id = state?.awaitingConfirmationTripId;
      if (id != null) {
        ref.invalidate(keptTripsProvider);
        showDialog<void>(
          context: context,
          builder: (_) => DriverPrompt(tripId: id),
        );
      }
    });

    // Auto verbunden heisst: der Nutzer sitzt im Wagen, auch wenn die
    // Fahrterkennung noch nicht angesprungen ist.
    ref.listen(carConnectedProvider, (prev, next) {
      if (next.asData?.value == true && _index == HomeShell.heatmapTab) {
        setState(() => _index = HomeShell.liveTab);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_fire_department),
            label: 'Heatmap',
          ),
          NavigationDestination(icon: Icon(Icons.speed), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Fahrten'),
          NavigationDestination(
            icon: Icon(Icons.leaderboard),
            label: 'Ranking',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Einstellungen',
          ),
        ],
      ),
    );
  }
}
