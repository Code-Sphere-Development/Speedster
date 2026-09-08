import 'package:flutter/material.dart';
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
        setState(() => _error = problem);
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
      appBar: AppBar(title: Text(_register ? l.authRegister : l.authSignIn)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_register) ...[
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l.authName),
            ),
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
          ],
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l.authEmail),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: l.authPassword),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_register ? l.authCreateAccount : l.authSignIn),
          ),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _register = !_register),
            child: Text(_register ? l.authHaveAccount : l.authNoAccount),
          ),
          const Divider(height: 32),
          OutlinedButton.icon(
            onPressed: () => _socialSoon('Apple'),
            icon: const Icon(Icons.apple),
            label: Text(l.authWithApple),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _socialSoon('Google'),
            icon: const Icon(Icons.g_mobiledata),
            label: Text(l.authWithGoogle),
          ),
        ],
      ),
    );
  }
}
