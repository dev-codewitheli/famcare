import 'package:flutter/material.dart';

import '../api_client.dart';
import '../auth.dart';
import '../session.dart';

/// First run after sign-in: start a family, or join one with an invite code.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.session});

  final Session session;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _familyName = TextEditingController();
  final _inviteCode = TextEditingController();
  bool _joining = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = widget.session.auth;
    if (auth is FirebaseAuthService) _nickname.text = auth.suggestedName ?? '';
  }

  @override
  void dispose() {
    _nickname.dispose();
    _familyName.dispose();
    _inviteCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_joining) {
        await widget.session.joinFamily(
            inviteCode: _inviteCode.text.trim(), displayName: _nickname.text.trim());
      } else {
        await widget.session.createFamily(
            familyName: _familyName.text.trim(), displayName: _nickname.text.trim());
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Can't reach the server. Check your connection.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        actions: [TextButton(onPressed: widget.session.signOut, child: const Text('Sign out'))],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              Text('Set up your family', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Everyone in the family uses the same group.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceCard(
                      selected: _joining,
                      icon: Icons.group_add_rounded,
                      title: 'Join',
                      subtitle: 'I have an invite code',
                      onTap: () => setState(() => _joining = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChoiceCard(
                      selected: !_joining,
                      icon: Icons.home_rounded,
                      title: 'Start new',
                      subtitle: "I'm the first one",
                      onTap: () => setState(() => _joining = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_joining)
                TextFormField(
                  controller: _inviteCode,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    labelText: 'Invite code',
                    helperText: 'Ask whoever set up the family for the 6-letter code',
                    prefixIcon: Icon(Icons.vpn_key_rounded),
                  ),
                  validator: (v) => (v ?? '').trim().length == 6 ? null : 'Enter all 6 characters',
                )
              else
                TextFormField(
                  controller: _familyName,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Family name',
                    hintText: 'e.g. Centeno Family',
                    prefixIcon: Icon(Icons.house_rounded),
                  ),
                  validator: _required,
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nickname,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'What does the family call you?',
                  hintText: 'e.g. Papa, Ate, Eli',
                  helperText: 'Only this nickname is shown to your family',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
                validator: _required,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: _busy
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(_joining ? 'Join family' : 'Create family'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: colors.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? colors.primary : Colors.transparent, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? colors.primary : colors.onSurfaceVariant, size: 28),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
