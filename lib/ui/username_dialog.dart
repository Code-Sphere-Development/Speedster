import 'package:flutter/material.dart';
import 'package:speedster/app/spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/account_repository.dart';
import 'package:speedster/cloud/username.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';

/// Wechsel des Benutzernamens.
///
/// Der Name steht oeffentlich in der Bestenliste und in Einladungslinks,
/// deshalb die Sperrfrist. Sie wird hier nur angezeigt -- durchgesetzt
/// wird sie am Server, der als Einziger weiss, wann zuletzt gewechselt
/// wurde.
class UsernameDialog extends ConsumerStatefulWidget {
  const UsernameDialog({required this.account, super.key});

  final CloudAccount account;

  @override
  ConsumerState<UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends ConsumerState<UsernameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.account.username);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _problemText(AppLocalizations l, UsernameProblem problem) =>
      switch (problem) {
        UsernameProblem.empty => l.authUsernameRequired,
        UsernameProblem.format => l.authUsernameFormat,
      };

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);

    // Vorab pruefen, damit ein Tippfehler nicht erst nach dem
    // Netzwerk-Roundtrip auffaellt. Ueber Eindeutigkeit und Sperrfrist
    // entscheidet weiterhin nur der Server.
    final problem = validateUsername(_controller.text);
    if (problem != null) {
      setState(() => _error = _problemText(l, problem));
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(accountRepositoryProvider)
          .changeUsername(normaliseUsername(_controller.text));
      // Der Benutzername steckt in mehreren Ansichten -- Einstellungen,
      // Freunde, Einladungslink. Ein Neuladen der Quelle ist billiger als
      // jede davon einzeln nachzuziehen.
      ref.invalidate(cloudAccountProvider);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l.settingsUsernameSaved)),
      );
    } on AccountException catch (e) {
      // Die Meldung des Servers woertlich: er unterscheidet "vergeben"
      // von "erst kuerzlich gewechselt", und er antwortet in der Sprache
      // der Anfrage.
      setState(() {
        _error = e.message ?? l.commonNoConnection;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locked = widget.account.usernameChangeableAt;
    final open = widget.account.canChangeUsername;

    return AlertDialog(
      title: Text(l.settingsUsernameChangeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.settingsUsernameChangeLead,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Insets.l),
          TextField(
            controller: _controller,
            enabled: open && !_busy,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              labelText: l.settingsUsername,
              helperText: l.authUsernameHint,
              errorText: _error,
              prefixText: '@',
            ),
            onSubmitted: (_) => open && !_busy ? _submit() : null,
          ),
          if (!open && locked != null) ...[
            const SizedBox(height: Insets.m),
            // Ein gesperrtes Feld ohne Begruendung liest sich wie ein
            // Fehler.
            Text(
              l.settingsUsernameLocked(
                DateFormat.yMMMMd(
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(locked),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: open && !_busy ? _submit : null,
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}
