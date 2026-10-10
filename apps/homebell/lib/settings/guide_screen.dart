import 'package:flutter/material.dart';

/// "How HomeBell works": a short in-app guide for the whole family.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  static const _sections = [
    _Section(
      Icons.notifications_active_rounded,
      'Ring the family from the gate',
      'Tap "I\'m at the gate". The family\'s phones ring like an incoming call, with sound and '
          'vibration, until someone taps "Coming!". If nobody answers, HomeBell rings again every '
          '30 seconds, up to 4 times, then tells you to try calling.',
    ),
    _Section(
      Icons.group_rounded,
      'Choose who gets rung',
      'Under the big button, tap "Rings everyone" and uncheck anyone who\'s out, like at school or '
          'work. Your phone remembers the choice until you change it. People you left out can still '
          'see the ring in the app and answer it.',
    ),
    _Section(
      Icons.directions_run_rounded,
      'Answer with "Coming!"',
      'When your phone rings, tap "Coming!" right on the notification, even on the lock screen: '
          'no need to unlock or open the app. The person at the gate sees who\'s coming, and the '
          'other phones stop ringing.',
    ),
    _Section(
      Icons.directions_car_rounded,
      'On your way home? Send a heads-up',
      'Pick about how many minutes away you are (or set your own). The family gets a quiet '
          'notification and can tap "Got it" so you know they saw it. When the time is up, HomeBell '
          'asks if you\'re at the gate: ring, add more time, or say you\'re not coming.',
    ),
    _Section(
      Icons.do_not_disturb_off_rounded,
      'Silent and Do Not Disturb',
      'By default, a phone on Silent or Do Not Disturb stays quiet. Whoever usually opens the gate '
          'can turn on "Ring even on Silent / Do Not Disturb" in Settings: the ring then plays at alarm '
          'volume, like an alarm clock, with a "Stop sound" button in its notification.',
    ),
    _Section(
      Icons.verified_rounded,
      'Make sure rings get through',
      'Some phones put apps to sleep to save battery. Settings → Phone setup lists what to switch on '
          'for your phone\'s brand and ticks each step off by itself once it\'s done. Finish with '
          '"Test the ring" there.',
    ),
    _Section(
      Icons.groups_rounded,
      'Your family',
      'Share the invite code so others can join from their phones. Tap yourself in the family list '
          'to change your nickname or pick an icon. Whoever set up the family can rename it and '
          'remove members.',
    ),
    _Section(
      Icons.lock_rounded,
      'Private by design',
      'Your family sees only your nickname and icon. Gate activity is deleted after 90 days, and '
          'you can delete your account anytime in Settings.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('How HomeBell works')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final section = _sections[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Icon(section.icon, color: colors.onPrimaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(section.body, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Section {
  const _Section(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}
