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
    if (!_formKey.currentState!.validate()) return;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your family'),
        actions: [
          TextButton(onPressed: widget.session.signOut, child: const Text('Sign out')),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Join'), icon: Icon(Icons.group_add)),
                  ButtonSegment(value: false, label: Text('Start new'), icon: Icon(Icons.home)),
                ],
                selected: {_joining},
                onSelectionChanged: (s) => setState(() => _joining = s.first),
              ),
              const SizedBox(height: 24),
              Text(
                _joining
                    ? 'Ask whoever set up the family for the 6-letter invite code.'
                    : "You'll get an invite code to share with the rest of the family.",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (_joining)
                TextFormField(
                  controller: _inviteCode,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  decoration: const InputDecoration(
                      labelText: 'Invite code', border: OutlineInputBorder()),
                  validator: (v) => (v ?? '').trim().length == 6 ? null : 'Enter all 6 characters',
                )
              else
                TextFormField(
                  controller: _familyName,
                  maxLength: 80,
                  decoration: const InputDecoration(
                      labelText: 'Family name', hintText: 'e.g. Centeno Family',
                      border: OutlineInputBorder()),
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
                  border: OutlineInputBorder(),
                ),
                validator: _required,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: Text(_joining ? 'Join family' : 'Create family'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
