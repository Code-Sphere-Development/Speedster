import 'package:flutter/material.dart';
import 'package:speedster/app/spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/friend_repository.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/ui/friends_screen.dart';

/// Fragt offene Freundschaftsanfragen beim Öffnen der App ab.
///
/// Angenommen wird unmittelbar hier: wer eine Anfrage bekommt, soll nicht
/// erst durch die Einstellungen navigieren müssen. Ablehnen geht ebenso,
/// und "Später" lässt alles unberührt -- eine Anfrage verschwindet nie
/// ungefragt.
class FriendRequestsPrompt extends ConsumerStatefulWidget {
  const FriendRequestsPrompt({super.key, required this.requests});

  final List<Friend> requests;

  /// Zeigt den Dialog, wenn es etwas zu zeigen gibt.
  ///
  /// Gibt zurück, ob er erschienen ist -- der Aufrufer merkt sich das,
  /// damit er beim nächsten Aufbau nicht erneut aufpoppt.
  static Future<bool> maybeShow(
    BuildContext context,
    List<Friend> requests,
  ) async {
    if (requests.isEmpty) return false;
    await showDialog<void>(
      context: context,
      builder: (_) => FriendRequestsPrompt(requests: requests),
    );

    return true;
  }

  @override
  ConsumerState<FriendRequestsPrompt> createState() =>
      _FriendRequestsPromptState();
}

class _FriendRequestsPromptState extends ConsumerState<FriendRequestsPrompt> {
  /// Bereits bearbeitete Anfragen bleiben stehen, verschwinden aber aus
  /// der Liste: den Dialog mitten im Lesen neu aufzubauen wäre unruhig.
  final _handled = <int>{};
  bool _busy = false;

  Future<void> _act(Friend friend, Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      setState(() => _handled.add(friend.id));
      ref.invalidate(friendOverviewProvider);
    } catch (_) {
      // Ohne Verbindung bleibt die Anfrage offen; sie erscheint beim
      // nächsten Öffnen wieder.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final open = widget.requests
        .where((f) => !_handled.contains(f.id))
        .toList(growable: false);

    return AlertDialog(
      title: Text(l.friendsPendingTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.friendsPendingLead(open.length)),
          const SizedBox(height: Insets.s),
          for (final f in open)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('@${f.username}'),
              subtitle: f.displayName.isEmpty ? null : Text(f.displayName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l.friendsAccept,
                    icon: const Icon(Icons.check),
                    onPressed: _busy
                        ? null
                        : () => _act(
                              f,
                              () => ref
                                  .read(friendRepositoryProvider)
                                  .accept(f.id),
                            ),
                  ),
                  IconButton(
                    tooltip: l.friendsDecline,
                    icon: const Icon(Icons.close),
                    onPressed: _busy
                        ? null
                        : () => _act(
                              f,
                              () => ref
                                  .read(friendRepositoryProvider)
                                  .remove(f.id),
                            ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.friendsPendingLater),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => FriendsScreen(
                  username: ref.read(cloudAccountProvider).asData?.value?.username,
                ),
              ),
            );
          },
          child: Text(l.friendsPendingManage),
        ),
      ],
    );
  }
}
