import 'package:flutter/material.dart';
import 'package:speedster/ui/components/gradient_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/links.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/friend_repository.dart';
import 'package:speedster/app/spacing.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';
import 'package:speedster/ui/components/empty_state.dart';
import 'package:speedster/ui/components/card_section.dart';

/// Freunde verwalten: hinzufuegen, annehmen, entfernen.
///
/// Zeigt bewusst keine Kennzahlen -- die stehen im Ranking-Tab unter
/// "Freunde". Zwei Orte fuer dieselben Zahlen liefen auseinander.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key, required this.username});

  /// Der eigene Benutzername; er bildet den Einladungslink.
  final String? username;

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _username = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  void _report(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    // Die Texte vor dem Warten holen: danach ist nicht gesichert, dass der
    // Kontex noch zu einem eingehaengten Widget gehoert.
    final fallback = AppLocalizations.of(context).commonNoConnection;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(friendOverviewProvider);
      _report(success);
    } on FriendException catch (e) {
      _report(e.message);
    } catch (_) {
      _report(fallback);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final name = _username.text.trim().toLowerCase();
    if (name.isEmpty) return;
    await _run(
      () => ref.read(friendRepositoryProvider).request(name),
      AppLocalizations.of(context).friendsRequestSent,
    );
    _username.clear();
  }

  Future<void> _copyInvite() async {
    final name = widget.username;
    if (name == null) return;
    final message = AppLocalizations.of(context).friendsInviteCopied;
    await Clipboard.setData(ClipboardData(text: AppLinks.invitation(name)));
    _report(message);
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(friendOverviewProvider);
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(title: l.friendsTitle, showBack: true),
          Expanded(
            child: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.cloud_off,
          message: l.friendsLoadFailed,
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.only(bottom: Insets.xl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.screen,
                Insets.l,
                Insets.screen,
                0,
              ),
              child: Text(
                l.friendsLead,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: Insets.l),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
              child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _username,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.none,
                    decoration: InputDecoration(
                      labelText: l.friendsUsernameLabel,
                      helperText: l.friendsUsernameHint,
                    ),
                    onSubmitted: (_) => _busy ? null : _add(),
                  ),
                ),
                const SizedBox(width: Insets.m),
                FilledButton(
                  onPressed: _busy ? null : _add,
                  child: Text(l.friendsRequest),
                ),
              ],
              ),
            ),
            if (widget.username != null) ...[
              const SizedBox(height: Insets.m),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
                child: OutlinedButton.icon(
                  onPressed: _copyInvite,
                  icon: const Icon(Icons.link),
                  label: Text(l.friendsCopyInvite),
                ),
              ),
            ],
            if (data.incoming.isNotEmpty)
              _Section(
                title: l.friendsIncoming,
                children: [
                  for (final f in data.incoming)
                    ListTile(
                      title: Text('@${f.username}'),
                      subtitle: Text(f.displayName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l.friendsAccept,
                            icon: const Icon(Icons.check),
                            onPressed: _busy
                                ? null
                                : () => _run(
                                      () => ref
                                          .read(friendRepositoryProvider)
                                          .accept(f.id),
                                      l.friendsNowFriends,
                                    ),
                          ),
                          IconButton(
                            tooltip: l.friendsDecline,
                            icon: const Icon(Icons.close),
                            onPressed: _busy
                                ? null
                                : () => _run(
                                      () => ref
                                          .read(friendRepositoryProvider)
                                          .remove(f.id),
                                      l.friendsDeclined,
                                    ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            _Section(
              title: l.friendsTitle,
              children: data.friends.isEmpty
                  ? [
                      ListTile(
                        title: Text(l.friendsEmpty),
                        subtitle: Text(l.friendsEmptyHint),
                      ),
                    ]
                  : [
                      for (final f in data.friends)
                        ListTile(
                          title: Text('@${f.username}'),
                          subtitle: Text(f.displayName),
                          trailing: IconButton(
                            tooltip: l.friendsRemove,
                            icon: const Icon(Icons.person_remove),
                            onPressed: _busy
                                ? null
                                : () => _run(
                                      () => ref
                                          .read(friendRepositoryProvider)
                                          .remove(f.id),
                                      l.friendsRemoved,
                                    ),
                          ),
                        ),
                    ],
            ),
            if (data.outgoing.isNotEmpty)
              _Section(
                title: l.friendsOutgoing,
                children: [
                  for (final f in data.outgoing)
                    ListTile(
                      title: Text('@${f.username}'),
                      trailing: IconButton(
                        tooltip: l.friendsWithdraw,
                        icon: const Icon(Icons.undo),
                        onPressed: _busy
                            ? null
                            : () => _run(
                                  () => ref
                                      .read(friendRepositoryProvider)
                                      .remove(f.id),
                                  l.friendsWithdrawn,
                                ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
          ),
        ],
      )
    );
  }
}

/// Ein Abschnitt der Freundesliste.
///
/// Duenne Huelle um [CardSection], damit die drei Aufrufstellen nicht
/// jeweils dasselbe Symbol mitschleppen muessen.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => CardSection(
        title: title,
        icon: Icons.people_outline,
        children: children,
      );
}
