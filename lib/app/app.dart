import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/consent_screen.dart';
import 'package:speedster/ui/driver_prompt.dart';
import 'package:speedster/ui/live_screen.dart';
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: consented ? const HomeShell() : const ConsentScreen(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _tabs = [LiveScreen(), TripListScreen(), SettingsScreen()];
  static const _titles = ['Live', 'Fahrten', 'Einstellungen'];

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
      final id = next.asData?.value.awaitingConfirmationTripId;
      if (id != null) {
        ref.invalidate(keptTripsProvider);
        showDialog<void>(
          context: context,
          builder: (_) => DriverPrompt(tripId: id),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.speed), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Fahrten'),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Einstellungen',
          ),
        ],
      ),
    );
  }
}
