import 'package:flutter/material.dart';

import '../auth.dart';
import '../session.dart';

/// A selling point shown on the sign-in screen.
class SignInHighlight {
  const SignInHighlight(this.icon, this.text);

  final IconData icon;
  final String text;
}

/// Branded sign-in: the native Google account picker (Firebase mode) or a demo user id.
class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.session,
    required this.appName,
    required this.tagline,
    required this.icon,
    this.highlights = const [],
  });

  final Session session;
  final String appName;
  final String tagline;
  final IconData icon;
  final List<SignInHighlight> highlights;

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
    if (_busy) return; // one attempt at a time
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = widget.session.auth;
      var signedIn = true;
      if (auth is FirebaseAuthService) {
        signedIn = await auth.signInWithGoogle();
      } else if (auth is DemoAuthService) {
        await auth.signIn(_demoId.text);
      }
      if (signedIn) await widget.session.refresh();
    } catch (e) {
      debugPrint('Sign-in failed: $e');
      if (mounted) setState(() => _error = "Couldn't sign in. Check your connection and try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDemo = widget.session.auth is DemoAuthService;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.primaryContainer.withValues(alpha: 0.7), colors.surface],
            stops: const [0, 0.55],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: colors.primary.withValues(alpha: 0.35), blurRadius: 32, spreadRadius: 4),
                            ],
                          ),
                          child: Icon(widget.icon, size: 56, color: colors.onPrimary),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(widget.appName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(widget.tagline,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant)),
                      const SizedBox(height: 32),
                      for (final h in widget.highlights)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: colors.primaryContainer,
                                child: Icon(h.icon, size: 18, color: colors.onPrimaryContainer),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Text(h.text, style: theme.textTheme.bodyLarge)),
                            ],
                          ),
                        ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      if (isDemo) ...[
                        TextField(
                          controller: _demoId,
                          decoration: const InputDecoration(
                            labelText: 'Demo user id',
                            helperText: 'Demo mode: any id works, e.g. "papa" or "ate"',
                          ),
                          textInputAction: TextInputAction.go,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (value) => value.trim().isEmpty ? null : _signIn(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      FilledButton.icon(
                        onPressed: _busy || (isDemo && _demoId.text.trim().isEmpty) ? null : _signIn,
                        icon: _busy
                            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                            : Icon(isDemo ? Icons.login : Icons.account_circle),
                        label: Text(_busy ? 'Signing in…' : (isDemo ? 'Continue' : 'Continue with Google')),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error ?? 'Your family only sees the nickname you choose.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: _error == null ? colors.onSurfaceVariant : colors.error),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
