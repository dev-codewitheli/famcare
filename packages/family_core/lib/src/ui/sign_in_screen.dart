import 'package:flutter/material.dart';

import '../auth.dart';
import '../session.dart';

/// Branded sign-in: Google (Firebase mode) or a demo user id (demo mode).
class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.session,
    required this.appName,
    required this.tagline,
    required this.icon,
  });

  final Session session;
  final String appName;
  final String tagline;
  final IconData icon;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _demoId = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _demoId.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = widget.session.auth;
      if (auth is FirebaseAuthService) {
        await auth.signInWithGoogle();
      } else if (auth is DemoAuthService) {
        await auth.signIn(_demoId.text);
      }
      await widget.session.refresh();
    } catch (e) {
      setState(() => _error = 'Sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDemo = widget.session.auth is DemoAuthService;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(widget.icon, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(widget.appName,
                  textAlign: TextAlign.center, style: theme.textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(widget.tagline,
                  textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              const Spacer(),
              if (isDemo) ...[
                TextField(
                  controller: _demoId,
                  decoration: const InputDecoration(
                    labelText: 'Demo user id',
                    helperText: 'Demo mode — any id works, e.g. "papa" or "ate"',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: _busy || (isDemo && _demoId.text.trim().isEmpty) ? null : _signIn,
                icon: Icon(isDemo ? Icons.login : Icons.account_circle),
                label: Text(isDemo ? 'Continue' : 'Sign in with Google'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
