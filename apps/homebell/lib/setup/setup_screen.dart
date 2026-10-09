import 'package:flutter/material.dart';

import '../gate/gate_notifications.dart';
import 'phone_setup.dart';

/// Step-by-step setup tailored to this phone's brand, so a ring always gets through.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with WidgetsBindingObserver {
  PhoneSetupStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Most fixes happen in system settings; re-check when the user comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final status = await PhoneSetupStatus.check();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _run(SetupStep step) async {
    await step.action?.call();
    await _check();
  }

  Future<void> _markDone(SetupStep step, bool done) async {
    await PhoneSetupStatus.markManualStep(step.id, done);
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Phone setup')),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                Card(
                  color: status.allGood ? colors.tertiaryContainer : colors.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(status.allGood ? Icons.verified_rounded : Icons.tune_rounded, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                status.allGood ? 'This phone is ready' : 'Make sure rings get through',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Steps for ${status.brand.label} phones. Android may delay or block alerts to save '
                          'battery; each step below prevents that.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: 1 - status.remaining / status.steps.where((s) => !s.optional).length,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(status.allGood ? 'All required steps done' : '${status.remaining} left to do',
                            style: theme.textTheme.labelLarge),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final (index, step) in status.steps.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StepCard(
                      number: index + 1,
                      step: step,
                      done: status.isDone(step),
                      onAction: () => _run(step),
                      onMarkDone: status.isManual(step) ? (done) => _markDone(step, done) : null,
                    ),
                  ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Test the ring', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text('Plays the ring on this phone. Lock the phone within a few seconds to '
                            'check the lock screen too.'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => Future.delayed(const Duration(seconds: 5),
                                    () => GateNotifications.showRing(alertId: 'test', senderName: 'Test')),
                                icon: const Icon(Icons.notifications_active_rounded),
                                label: const Text('Ring in 5 s'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => GateNotifications.cancelRing('test'),
                              child: const Text('Stop'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.step,
    required this.done,
    required this.onAction,
    this.onMarkDone,
  });

  final int number;
  final SetupStep step;
  final bool done;
  final VoidCallback onAction;
  final ValueChanged<bool>? onMarkDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final good = Colors.green.shade600;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: done ? good.withValues(alpha: 0.15) : colors.primaryContainer,
                  child: done
                      ? Icon(Icons.check_rounded, color: good)
                      : Icon(step.icon, size: 20, color: colors.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('$number. ${step.title}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  decoration: done ? TextDecoration.lineThrough : null,
                                )),
                          ),
                          if (step.optional)
                            Text('Recommended', style: theme.textTheme.labelSmall?.copyWith(color: colors.primary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(step.detail, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            if (step.action != null || onMarkDone != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 48),
                  if (step.action != null && !(done && onMarkDone == null))
                    FilledButton.tonal(onPressed: onAction, child: Text(step.actionLabel ?? 'Open')),
                  const Spacer(),
                  if (onMarkDone != null)
                    FilterChip(
                      label: Text(done ? 'Done' : 'I did this'),
                      selected: done,
                      onSelected: onMarkDone,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
