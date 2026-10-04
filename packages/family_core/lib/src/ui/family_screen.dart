import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../session.dart';

/// Members and the invite code to share with relatives who haven't joined yet.
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final family = session.family!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(family.name)),
      body: RefreshIndicator(
        onRefresh: session.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.vpn_key),
                title: const Text('Invite code'),
                subtitle: Text(family.inviteCode,
                    style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 4)),
                trailing: IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: family.inviteCode));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Invite code copied')));
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Members', style: theme.textTheme.titleMedium),
            for (final member in family.members)
              ListTile(
                leading: CircleAvatar(child: Text(member.displayName.characters.first.toUpperCase())),
                title: Text(member.id == family.me.id ? '${member.displayName} (you)' : member.displayName),
                subtitle: member.role == MemberRole.parent ? const Text('Set up the family') : null,
              ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                session.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
