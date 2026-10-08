import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../session.dart';
import 'family_theme.dart';

/// Members and the invite code to share with relatives who haven't joined yet.
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final family = session.family!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(family.name)),
      body: RefreshIndicator(
        onRefresh: session.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invite code', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(family.inviteCode,
                              style: theme.textTheme.displaySmall
                                  ?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w800)),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Copy',
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: family.inviteCode));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Invite code copied')));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Share it with family members so they can join from their phones.',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('${family.members.length} members', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final member in family.members)
                    ListTile(
                      leading: MemberAvatar(name: member.displayName),
                      title: Text(member.id == family.me.id ? '${member.displayName} (you)' : member.displayName),
                      subtitle: member.role == MemberRole.parent ? const Text('Set up the family') : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                session.signOut();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
