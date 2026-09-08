import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/links.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/friend_repository.dart';

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
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(friendOverviewProvider);
      _report(success);
    } on FriendException catch (e) {
      _report(e.message);
    } catch (_) {
      _report('Das hat nicht geklappt. Besteht eine Verbindung?');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final name = _username.text.trim().toLowerCase();
    if (name.isEmpty) return;
    await _run(
      () => ref.read(friendRepositoryProvider).request(name),
      'Anfrage verschickt.',
    );
    _username.clear();
  }

  Future<void> _copyInvite() async {
    final name = widget.username;
    if (name == null) return;
    await Clipboard.setData(ClipboardData(text: AppLinks.invitation(name)));
    _report('Einladungslink kopiert.');
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(friendOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Freunde')),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Die Freundesliste konnte nicht geladen werden.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Freunde sehen voneinander nur Kennzahlen — keine einzelnen '
              'Fahrten und keine Strecken.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _username,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(
                      labelText: 'Benutzername',
                      helperText: 'Die eindeutige Kennung, kein Anzeigename',
                    ),
                    onSubmitted: (_) => _busy ? null : _add(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _busy ? null : _add,
                  child: const Text('Anfragen'),
                ),
              ],
            ),
            if (widget.username != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _copyInvite,
                icon: const Icon(Icons.link),
                label: const Text('Einladungslink kopieren'),
              ),
            ],
            if (data.incoming.isNotEmpty)
              _Section(
                title: 'Offene Anfragen an dich',
                children: [
                  for (final f in data.incoming)
                    ListTile(
                      title: Text('@${f.username}'),
                      subtitle: Text(f.displayName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Annehmen',
                            icon: const Icon(Icons.check),
                            onPressed: _busy
                                ? null
                                : () => _run(
                                      () => ref
                                          .read(friendRepositoryProvider)
                                          .accept(f.id),
                                      'Ihr seid jetzt befreundet.',
                                    ),
                          ),
                          IconButton(
                            tooltip: 'Ablehnen',
                            icon: const Icon(Icons.close),
                            onPressed: _busy
                                ? null
                                : () => _run(
                                      () => ref
                                          .read(friendRepositoryProvider)
                                          .remove(f.id),
                                      'Abgelehnt.',
                                    ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            _Section(
              title: 'Freunde',
              children: data.friends.isEmpty
                  ? [
                      const ListTile(
                        title: Text('Noch niemand.'),
                        subtitle: Text(
                          'Teile deinen Einladungslink oder füge jemanden '
                          'über seinen Benutzernamen hinzu.',
                        ),
                      ),
                    ]
                  : [
                      for (final f in data.friends)
                        ListTile(
                          title: Text('@${f.username}'),
                          subtitle: Text(f.displayName),
                          trailing: IconButton(
                            tooltip: 'Entfernen',
                            icon: const Icon(Icons.person_remove),
                            onPressed: _busy
                                ? null
                                : () => _run(
                                      () => ref
                                          .read(friendRepositoryProvider)
                                          .remove(f.id),
                                      'Entfernt.',
                                    ),
                          ),
                        ),
                    ],
            ),
            if (data.outgoing.isNotEmpty)
              _Section(
                title: 'Von dir verschickt',
                children: [
                  for (final f in data.outgoing)
                    ListTile(
                      title: Text('@${f.username}'),
                      trailing: IconButton(
                        tooltip: 'Zurückziehen',
                        icon: const Icon(Icons.undo),
                        onPressed: _busy
                            ? null
                            : () => _run(
                                  () => ref
                                      .read(friendRepositoryProvider)
                                      .remove(f.id),
                                  'Zurückgezogen.',
                                ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        ...children,
      ],
    );
  }
}
