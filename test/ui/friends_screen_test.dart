import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/friend_repository.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/ui/friends_screen.dart';

Friend friend(int id, String username, String status) => Friend(
      id: id,
      status: status,
      username: username,
      displayName: 'Anzeige $username',
    );

Widget wrap(FriendOverview overview, {String? username = 'ich'}) =>
    ProviderScope(
      overrides: [
        friendOverviewProvider.overrideWith((ref) async => overview),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: FriendsScreen(username: username)),
    );

void main() {
  testWidgets('zeigt Freunde und beide Anfragerichtungen getrennt',
      (tester) async {
    await tester.pumpWidget(wrap(FriendOverview(
      friends: [friend(1, 'freund', 'accepted')],
      incoming: [friend(2, 'fragtan', 'pending')],
      outgoing: [friend(3, 'angefragt', 'pending')],
    )));
    await tester.pump();

    expect(find.text('Offene Anfragen an dich'), findsOneWidget);
    expect(find.text('@fragtan'), findsOneWidget);
    expect(find.text('@freund'), findsOneWidget);
    expect(find.text('Von dir verschickt'), findsOneWidget);
    expect(find.text('@angefragt'), findsOneWidget);
  });

  testWidgets('blendet leere Abschnitte aus statt sie leer zu zeigen',
      (tester) async {
    await tester.pumpWidget(wrap(FriendOverview.empty));
    await tester.pump();

    expect(find.text('Offene Anfragen an dich'), findsNothing);
    expect(find.text('Von dir verschickt'), findsNothing);
    // Statt einer leeren Liste ein Hinweis, was zu tun ist.
    expect(find.text('Noch niemand.'), findsOneWidget);
  });

  testWidgets('zeigt keine Kennzahlen', (tester) async {
    // Die stehen im Ranking-Tab unter "Freunde". Zwei Orte fuer dieselben
    // Zahlen liefen auseinander.
    await tester.pumpWidget(wrap(FriendOverview(
      friends: [friend(1, 'freund', 'accepted')],
      incoming: const [],
      outgoing: const [],
    )));
    await tester.pump();

    expect(find.textContaining('km/h'), findsNothing);
    expect(find.textContaining('km'), findsNothing);
  });

  testWidgets('bietet den Einladungslink nur mit eigenem Benutzernamen an',
      (tester) async {
    await tester.pumpWidget(wrap(FriendOverview.empty, username: null));
    await tester.pump();
    expect(find.text('Einladungslink kopieren'), findsNothing);

    await tester.pumpWidget(wrap(FriendOverview.empty));
    await tester.pump();
    expect(find.text('Einladungslink kopieren'), findsOneWidget);
  });
}
