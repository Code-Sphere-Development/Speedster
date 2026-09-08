import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedster/app/providers.dart';
import 'package:speedster/cloud/auth_repository.dart';
import 'package:speedster/cloud/username.dart';

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
      SnackBar(content: Text('$provider-Login folgt in Kürze.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_register ? 'Registrieren' : 'Anmelden')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_register) ...[
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _username,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                labelText: 'Benutzername',
                helperText: '3–30 Zeichen: a–z, 0–9 und _',
              ),
            ),
          ],
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-Mail'),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Passwort'),
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
            child: Text(_register ? 'Konto erstellen' : 'Anmelden'),
          ),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _register = !_register),
            child: Text(_register
                ? 'Schon ein Konto? Anmelden'
                : 'Neu hier? Konto erstellen'),
          ),
          const Divider(height: 32),
          OutlinedButton.icon(
            onPressed: () => _socialSoon('Apple'),
            icon: const Icon(Icons.apple),
            label: const Text('Mit Apple anmelden'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _socialSoon('Google'),
            icon: const Icon(Icons.g_mobiledata),
            label: const Text('Mit Google anmelden'),
          ),
        ],
      ),
    );
  }
}
