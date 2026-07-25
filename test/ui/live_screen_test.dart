import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/domain/sample.dart';
import 'package:speedster/recording/trip_recorder.dart';
import 'package:speedster/settings/settings_controller.dart';
import 'package:speedster/ui/live_screen.dart';

void main() {
  testWidgets('shows current speed while driving', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          recorderStateProvider.overrideWith(
            (ref) => Stream.value(
              RecorderState(
                isDriving: true,
                activeTripId: 1,
                last: Sample(
                  lat: 50,
                  lng: 6,
                  speed: 10,
                  altitude: 100,
                  accuracy: 3,
                  timestamp: DateTime(2026),
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: LiveScreen()),
      ),
    );
    await tester.pump();
    expect(find.textContaining('36 km/h'), findsOneWidget);
  });
}
