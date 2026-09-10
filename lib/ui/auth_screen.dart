import 'package:flutter/material.dart';
import 'package:speedster/ui/components/gradient_header.dart';
import 'package:speedster/app/spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/auth_repository.dart';
import 'package:speedster/cloud/username.dart';
import 'package:speedster/l10n/generated/app_localizations.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Vorab prüfen, damit ein Formatfehler nicht erst nach dem
    // Netzwerk-Roundtrip als 422 zurückkommt. Über die Eindeutigkeit
    // entscheidet weiterhin nur der Server.
    if (_register) {
      final problem = validateUsername(_username.text);
      if (problem != null) {
        // Den Text waehlt die Oberflaeche: validateUsername kennt die
        // Sprache nicht, in der die App gerade laeuft.
        final l = AppLocalizations.of(context);
        setState(() => _error = switch (problem) {
              UsernameProblem.empty => l.authUsernameRequired,
              UsernameProblem.format => l.authUsernameFormat,
            });
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authRepositoryProvider);
    try {
      if (_register) {
        await auth.register(
          name: _name.text.trim(),
          username: normaliseUsername(_username.text),
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await auth.login(_email.text.trim(), _password.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _socialSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).authSocialSoon(provider)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: _register ? l.authRegister : l.authSignIn,
            showBack: true,
          ),
          Expanded(
            child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.screen,
          Insets.xl,
          Insets.screen,
          Insets.xl,
        ),
        children: [
          if (_register) ...[
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l.authName),
            ),
            const SizedBox(height: Insets.m),
            TextField(
              controller: _username,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: l.authUsername,
                helperText: l.authUsernameHint,
              ),
            ),
            const SizedBox(height: Insets.m),
          ],
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l.authEmail),
          ),
          const SizedBox(height: Insets.m),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: l.authPassword),
          ),
          if (_error != null) ...[
            const SizedBox(height: Insets.m),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: Insets.xl),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_register ? l.authCreateAccount : l.authSignIn),
          ),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _register = !_register),
            child: Text(_register ? l.authHaveAccount : l.authNoAccount),
          ),
          const Divider(height: Insets.xxl),
          OutlinedButton.icon(
            onPressed: () => _socialSoon('Apple'),
            icon: const Icon(Icons.apple),
            label: Text(l.authWithApple),
          ),
          const SizedBox(height: Insets.s),
          OutlinedButton.icon(
            onPressed: () => _socialSoon('Google'),
            icon: const Icon(Icons.g_mobiledata),
            label: Text(l.authWithGoogle),
          ),
        ],
      ),
          ),
        ],
      )
    );
  }
}
