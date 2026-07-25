import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/settings/settings_controller.dart';

/// First-launch disclaimer + consent. Data stays local (GDPR).
class ConsentScreen extends ConsumerWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Willkommen bei Speedster')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'Speedster zeichnet Geschwindigkeit und Route deiner Fahrten auf.\n\n'
                  'Bitte fahre stets verantwortungsvoll. Es gilt immer die '
                  'Straßenverkehrsordnung (StVO). Auf Streckenabschnitten ohne '
                  'Tempolimit (z. B. Teile deutscher Autobahnen) gilt die '
                  'Richtgeschwindigkeit — passe deine Geschwindigkeit stets an '
                  'Verkehr, Wetter und Sicht an.\n\n'
                  'Die Nutzung erfolgt auf eigene Gefahr. Speedster fordert nicht '
                  'zu überhöhter Geschwindigkeit auf.\n\n'
                  'Datenschutz: Alle Daten bleiben lokal auf deinem Gerät. Es '
                  'findet kein Upload statt. Du kannst deine Daten jederzeit in '
                  'den Einstellungen löschen.',
                  style: TextStyle(height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    ref.read(settingsControllerProvider.notifier).acceptConsent(),
                child: const Text('Akzeptieren'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
