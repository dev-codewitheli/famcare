import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api_client.dart';
import '../models.dart';
import '../session.dart';
import 'family_theme.dart';

/// Members and the invite code. Everyone can change their nickname; the family's creator can
/// also rename the family and remove members.
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final family = session.family;
        if (family == null) return const Scaffold(); // signed out or removed meanwhile
        return _FamilyView(session: session, family: family);
      },
    );
  }
}

class _FamilyView extends StatelessWidget {
  const _FamilyView({required this.session, required this.family});

  final Session session;
  final Family family;

  Future<void> _renameMe(BuildContext context) async {
    final name = await _askForText(context,
        title: 'Your nickname', label: 'What does the family call you?', initial: family.me.displayName, maxLength: 40);
    if (name != null && context.mounted) {
      await _attempt(context, () => session.renameMe(name), done: 'Nickname updated');
    }
  }

  Future<void> _renameFamily(BuildContext context) async {
    final name = await _askForText(context,
        title: 'Family name', label: 'Family name', initial: family.name, maxLength: 80);
    if (name != null && context.mounted) {
      await _attempt(context, () => session.renameFamily(name), done: 'Family renamed');
    }
  }

  Future<void> _remove(BuildContext context, Member member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.person_remove_rounded),
        title: Text('Remove ${member.displayName}?'),
        content: Text('${member.displayName} will stop getting gate rings and heads-ups. '
            'They can join again later with the invite code.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _attempt(context, () => session.removeMember(member.id), done: '${member.displayName} was removed');
    }
  }

  Future<void> _resetCode(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.refresh_rounded),
        title: const Text('Get a new invite code?'),
        content: const Text('The current code stops working. Members already in the family stay in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('New code')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _attempt(context, session.resetInviteCode, done: 'New invite code ready');
    }
  }

  static Future<void> _attempt(BuildContext context, Future<void> Function() action, {required String done}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text("Can't reach the server. Check your connection.")));
    }
  }

  static Future<String?> _askForText(BuildContext context,
          {required String title, required String label, required String initial, required int maxLength}) =>
      showDialog<String>(
        context: context,
        builder: (_) => _TextPromptDialog(title: title, label: label, initial: initial, maxLength: maxLength),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isCreator = session.isCreator;

    return Scaffold(
      appBar: AppBar(
        title: Text(family.name),
        actions: [
          if (isCreator)
            IconButton(
              tooltip: 'Rename family',
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _renameFamily(context),
            ),
        ],
      ),
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
                    if (isCreator)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _resetCode(context),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Get a new code'),
                        ),
                      ),
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
                    _MemberTile(
                      member: member,
                      isMe: member.id == family.me.id,
                      onRenameMe: () => _renameMe(context),
                      onRemove: isCreator && member.id != family.me.id ? () => _remove(context, member) : null,
                    ),
                ],
              ),
            ),
            if (!isCreator) ...[
              const SizedBox(height: 12),
              Text('Only the person who set up the family can rename it or remove members.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
            ],
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

/// Owns its text controller, so it's disposed after the closing animation, not during it.
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({required this.title, required this.label, required this.initial, required this.maxLength});

  final String title;
  final String label;
  final String initial;
  final int maxLength;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.isMe, required this.onRenameMe, this.onRemove});

  final Member member;
  final bool isMe;
  final VoidCallback onRenameMe;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: MemberAvatar(name: member.displayName),
      title: Text(isMe ? '${member.displayName} (you)' : member.displayName),
      subtitle: member.role == MemberRole.parent ? const Text('Set up the family') : null,
      trailing: isMe
          ? IconButton(tooltip: 'Change nickname', icon: const Icon(Icons.edit_rounded), onPressed: onRenameMe)
          : onRemove == null
              ? null
              : IconButton(
                  tooltip: 'Remove from family',
                  icon: Icon(Icons.person_remove_rounded, color: Theme.of(context).colorScheme.error),
                  onPressed: onRemove,
                ),
      onTap: isMe ? onRenameMe : null,
    );
  }
}
