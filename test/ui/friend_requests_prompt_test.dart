import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/friend_repository.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/ui/friend_requests_prompt.dart';

class MockFriends extends Mock implements FriendRepository {}

Friend request(int id, String username) => Friend(
      id: id,
      status: 'pending',
      username: username,
      displayName: 'Anzeige $username',
    );

Future<void> pumpPrompt(
  WidgetTester tester,
  List<Friend> requests, {
  FriendRepository? repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repo != null) friendRepositoryProvider.overrideWithValue(repo),
        friendOverviewProvider.overrideWith((ref) async => FriendOverview(
              friends: const [],
              incoming: requests,
              outgoing: const [],
            )),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: FriendRequestsPrompt(requests: requests)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('listet die offenen Anfragen', (tester) async {
    await pumpPrompt(tester, [request(1, 'anna'), request(2, 'bert')]);

    expect(find.text('@anna'), findsOneWidget);
    expect(find.text('@bert'), findsOneWidget);
    expect(find.textContaining('2 Personen'), findsOneWidget);
  });

  testWidgets('spricht bei einer Anfrage in der Einzahl', (tester) async {
    await pumpPrompt(tester, [request(1, 'anna')]);

    expect(find.textContaining('Eine Person'), findsOneWidget);
  });

  testWidgets('nimmt eine Anfrage unmittelbar an', (tester) async {
    final repo = MockFriends();
    when(() => repo.accept(any())).thenAnswer((_) async {});
    await pumpPrompt(tester, [request(7, 'anna'), request(8, 'bert')],
        repo: repo);

    await tester.tap(find.byTooltip('Annehmen').first);
    await tester.pumpAndSettle();

    verify(() => repo.accept(7)).called(1);
    // Die bearbeitete Anfrage verschwindet, die andere bleibt stehen.
    expect(find.text('@anna'), findsNothing);
    expect(find.text('@bert'), findsOneWidget);
  });

  testWidgets('lehnt eine Anfrage ab', (tester) async {
    final repo = MockFriends();
    when(() => repo.remove(any())).thenAnswer((_) async {});
    await pumpPrompt(tester, [request(9, 'anna')], repo: repo);

    await tester.tap(find.byTooltip('Ablehnen').first);
    await tester.pumpAndSettle();

    verify(() => repo.remove(9)).called(1);
  });

  testWidgets('laesst die Anfrage bei einem Fehler stehen', (tester) async {
    final repo = MockFriends();
    when(() => repo.accept(any())).thenThrow(Exception('kein Netz'));
    await pumpPrompt(tester, [request(3, 'anna')], repo: repo);

    await tester.tap(find.byTooltip('Annehmen').first);
    await tester.pumpAndSettle();

    // Ohne Verbindung darf sie nicht verschwinden -- sie erscheint beim
    // naechsten Oeffnen wieder.
    expect(find.text('@anna'), findsOneWidget);
  });

  testWidgets('zeigt ohne Anfragen keinen Dialog', (tester) async {
    late bool shown;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              shown = await FriendRequestsPrompt.maybeShow(context, const []);
            },
            child: const Text('los'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('los'));
    await tester.pumpAndSettle();

    expect(shown, isFalse);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
