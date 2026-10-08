import 'package:family_core/family_core.dart';
import 'package:flutter/material.dart';

import '../gate/gate_api.dart';

/// The other family members, at a glance.
class FamilyStrip extends StatelessWidget {
  const FamilyStrip({super.key, required this.members, required this.onTap});

  final List<Member> members;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (members.isEmpty)
                Expanded(
                  child: Text('Invite your family so they get the ring',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                )
              else ...[
                SizedBox(
                  width: 28.0 * members.take(4).length + 16,
                  height: 40,
                  child: Stack(
                    children: [
                      for (final (i, m) in members.take(4).indexed)
                        Positioned(
                          left: i * 28.0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.surface,
                            child: MemberAvatar(name: m.displayName, radius: 18),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _names(members),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  static String _names(List<Member> members) {
    final names = members.map((m) => m.displayName).toList();
    if (names.length <= 3) return '${names.join(', ')} will be rung';
    return '${names.take(2).join(', ')} and ${names.length - 2} more will be rung';
  }
}

class SetupBanner extends StatelessWidget {
  const SetupBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer),
        title: Text('Finish phone setup', style: TextStyle(color: colors.onErrorContainer, fontWeight: FontWeight.w700)),
        subtitle: Text('So you never miss a ring', style: TextStyle(color: colors.onErrorContainer)),
        trailing: Icon(Icons.chevron_right_rounded, color: colors.onErrorContainer),
        onTap: onTap,
      ),
    );
  }
}

/// A soft, repeating halo: draws the eye to the gate button, and signals "ringing" later.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.color, required this.size, required this.child, this.fast = false});

  final Color color;
  final double size;
  final Widget child;
  final bool fast;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.fast ? 1200 : 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size * 1.45,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            for (final offset in [0.0, 0.5])
              Builder(builder: (context) {
                final t = (_controller.value + offset) % 1;
                return Container(
                  width: widget.size * (1 + 0.45 * t),
                  height: widget.size * (1 + 0.45 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.28 * (1 - t)),
                  ),
                );
              }),
            child!,
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// The big "I'm at the gate" button.
class GateButtonCard extends StatelessWidget {
  const GateButtonCard({super.key, required this.busy, required this.onRing});

  final bool busy;
  final VoidCallback onRing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        _Pulse(
          color: colors.primary,
          size: 210,
          child: SizedBox.square(
            dimension: 210,
            child: FilledButton(
              onPressed: busy ? null : onRing,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                elevation: 8,
                shadowColor: colors.primary.withValues(alpha: 0.5),
                padding: EdgeInsets.zero,
              ),
              child: busy
                  ? SizedBox.square(dimension: 40, child: CircularProgressIndicator(color: colors.onPrimary))
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_active_rounded, size: 64),
                        SizedBox(height: 10),
                        Text("I'm at the gate", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ),
        Text('Tap when you arrive. Everyone at home gets the ring.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
      ],
    );
  }
}

class RingingCard extends StatelessWidget {
  const RingingCard({super.key, required this.alert, required this.busy, required this.onCancel});

  final GateAlert alert;
  final bool busy;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            _Pulse(
              color: colors.primary,
              size: 110,
              fast: true,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: colors.primary,
                child: Icon(Icons.ring_volume_rounded, size: 52, color: colors.onPrimary),
              ),
            ),
            Text('Ringing the family…', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              alert.ringCount <= 1 ? 'Waiting for someone to tap "Coming!"' : 'Ring ${alert.ringCount}: still waiting…',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: busy ? null : onCancel,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancel, I got in'),
            ),
          ],
        ),
      ),
    );
  }
}

class SomeoneAtGateCard extends StatelessWidget {
  const SomeoneAtGateCard({super.key, required this.alert, required this.busy, required this.onComing});

  final GateAlert alert;
  final bool busy;
  final VoidCallback onComing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const red = Color(0xFFD7263D);
    return Card(
      color: red,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          children: [
            _Pulse(
              color: Colors.white,
              size: 100,
              fast: true,
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(Icons.door_front_door_rounded, size: 48, color: red),
              ),
            ),
            Text('${alert.sender.displayName} is at the gate',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Let them know someone is on the way',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: busy ? null : onComing,
              icon: const Icon(Icons.directions_run_rounded, size: 30),
              label: const Text('Coming!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: red,
                minimumSize: const Size.fromHeight(64),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OutcomeCard extends StatelessWidget {
  const OutcomeCard({super.key, required this.alert, required this.onDone});

  final GateAlert alert;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answered = alert.status == GateAlertStatus.acknowledged;
    final color = answered ? Colors.green.shade600 : theme.colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(answered ? Icons.check_rounded : Icons.phone_missed_rounded, size: 48, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              answered ? '${alert.acknowledgedBy?.displayName ?? 'Someone'} is coming!' : 'Nobody answered',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(answered ? 'Hang tight, the gate will be opened soon.' : 'Try calling someone at home.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.tonal(onPressed: onDone, child: const Text('OK')),
          ],
        ),
      ),
    );
  }
}

/// Someone else told the family they're on their way.
class OnTheWayCard extends StatelessWidget {
  const OnTheWayCard({super.key, required this.arrival, required this.seenByMe, required this.onGotIt});

  final Arrival arrival;
  final bool seenByMe;
  final VoidCallback onGotIt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = arrival.minutesLeft(DateTime.now());
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            MemberAvatar(name: arrival.member.displayName),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${arrival.member.displayName} is on the way',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(minutes == 0
                      ? 'Should be at the gate any moment'
                      : 'About $minutes min away, around ${formatClock(context, arrival.expectedAt)}'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            seenByMe
                ? Chip(avatar: const Icon(Icons.check_rounded, size: 18), label: const Text('Seen'))
                : FilledButton.tonalIcon(
                    onPressed: onGotIt,
                    icon: const Icon(Icons.thumb_up_alt_rounded, size: 18),
                    label: const Text('Got it'),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  ),
          ],
        ),
      ),
    );
  }
}

/// "Not home yet?" Tell the family roughly when you'll arrive; when the time is up, ring or
/// add time if you're delayed.
class OnMyWayCard extends StatelessWidget {
  const OnMyWayCard({
    super.key,
    required this.myArrival,
    required this.busy,
    required this.onAnnounce,
    required this.onRingNow,
  });

  final Arrival? myArrival;
  final bool busy;
  final ValueChanged<int> onAnnounce;
  final VoidCallback onRingNow;

  static const _options = [5, 10, 15, 30];
  static const _delayOptions = [5, 10];

  @override
  Widget build(BuildContext context) {
    final mine = myArrival;
    if (mine != null && mine.isDue(DateTime.now())) return _timesUp(context, mine);

    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text('On your way home?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              mine == null
                  ? 'Give the family a heads-up so someone can head to the gate before you arrive. '
                      'We\'ll remind you when the time is up.'
                  : 'You told the family you\'d arrive around ${formatClock(context, mine.expectedAt)}. '
                      'Tap a time to update it.',
              style: theme.textTheme.bodyMedium,
            ),
            if (mine != null) ...[
              const SizedBox(height: 8),
              _SeenBy(arrival: mine),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in _options)
                  ActionChip(
                    avatar: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text('~$minutes min'),
                    onPressed: busy ? null : () => onAnnounce(minutes),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timesUp(BuildContext context, Arrival mine) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alarm_rounded, color: colors.onTertiaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Time\'s up. Are you at the gate?',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('You said you\'d arrive around ${formatClock(context, mine.expectedAt)}. '
                'Running late? Add time and the family will be updated.'),
            const SizedBox(height: 8),
            _SeenBy(arrival: mine),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onRingNow,
                    icon: const Icon(Icons.notifications_active_rounded),
                    label: const Text('I\'m at the gate'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final minutes in _delayOptions)
                  ActionChip(
                    avatar: const Icon(Icons.more_time_rounded, size: 18),
                    label: Text('+$minutes min'),
                    onPressed: busy ? null : () => onAnnounce(minutes),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Seen by Papa, Mama" or "Not seen yet".
class _SeenBy extends StatelessWidget {
  const _SeenBy({required this.arrival});

  final Arrival arrival;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seen = arrival.seenBy;
    return Row(
      children: [
        Icon(seen.isEmpty ? Icons.schedule_send_rounded : Icons.done_all_rounded,
            size: 18, color: seen.isEmpty ? theme.colorScheme.outline : Colors.green.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            seen.isEmpty ? 'Sent, not seen yet' : 'Seen by ${seen.map((m) => m.displayName).join(', ')}',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Shown right after "On my way": who was told, and when the reminder will come.
class HeadsUpSentDialog extends StatelessWidget {
  const HeadsUpSentDialog({super.key, required this.arrival});

  final Arrival arrival;

  @override
  Widget build(BuildContext context) {
    final names = arrival.notified.map((m) => m.displayName).toList();
    final time = formatClock(context, arrival.expectedAt);
    return AlertDialog(
      icon: Icon(Icons.mark_email_read_rounded, color: Colors.green.shade600, size: 36),
      title: const Text('Heads-up sent'),
      content: Text(names.isEmpty
          ? 'Nobody else is in your family yet. Share the invite code so they get your heads-ups.'
          : '${_joinNames(names)} ${names.length == 1 ? 'was' : 'were'} told you\'re about '
              '${arrival.etaMinutes} min away.\n\nWe\'ll remind you around $time to tap '
              '"I\'m at the gate", and you\'ll be notified when someone sees it.'),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    );
  }

  static String _joinNames(List<String> names) =>
      names.length <= 1 ? names.join() : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key, required this.alerts, required this.myMemberId});

  final List<GateAlert> alerts;
  final String myMemberId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Recent', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        Card(
          child: Column(
            children: [
              for (final alert in alerts)
                ListTile(
                  leading: _statusIcon(context, alert.status),
                  title: Text(alert.sender.id == myMemberId ? 'You rang' : '${alert.sender.displayName} rang'),
                  subtitle: Text(_outcome(alert)),
                  trailing: Text(formatWhen(context, alert.createdAt), style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusIcon(BuildContext context, GateAlertStatus status) {
    final (icon, color) = switch (status) {
      GateAlertStatus.acknowledged => (Icons.check_circle_rounded, Colors.green.shade600),
      GateAlertStatus.expired => (Icons.phone_missed_rounded, Theme.of(context).colorScheme.error),
      GateAlertStatus.cancelled => (Icons.cancel_rounded, Theme.of(context).colorScheme.outline),
      GateAlertStatus.ringing => (Icons.ring_volume_rounded, Theme.of(context).colorScheme.primary),
    };
    return Icon(icon, color: color);
  }

  String _outcome(GateAlert alert) => switch (alert.status) {
        GateAlertStatus.acknowledged =>
          '${alert.acknowledgedBy?.displayName ?? 'Someone'} answered${_after(alert.answeredAfter)}',
        GateAlertStatus.expired => 'Nobody answered',
        GateAlertStatus.cancelled => 'Cancelled',
        GateAlertStatus.ringing => 'Ringing',
      };

  static String _after(Duration? d) {
    if (d == null) return '';
    if (d.inSeconds < 60) return ' in ${d.inSeconds} s';
    return ' in ${d.inMinutes} min';
  }
}

/// "6:12 PM" in the phone's own 12/24-hour style.
String formatClock(BuildContext context, DateTime time) =>
    MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(time),
        alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat);

/// Today: "6:12 PM". Yesterday: "Yesterday". Older: "Oct 3".
String formatWhen(BuildContext context, DateTime time) {
  final now = DateTime.now();
  final day = DateTime(time.year, time.month, time.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = today.difference(day).inDays;
  if (days == 0) return formatClock(context, time);
  if (days == 1) return 'Yesterday';
  return MaterialLocalizations.of(context).formatShortMonthDay(time);
}
