import 'dart:async';

import 'package:family_core/family_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../gate/gate_api.dart';
import '../gate/gate_controller.dart';
import '../gate/gate_notifications.dart';
import '../setup/reliability_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.session, required this.gateApi, required this.usesPush});

  final Session session;
  final GateApi gateApi;

  /// False in demo mode: no FCM, so the screen polls more often while open.
  final bool usesPush;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final GateController _gate =
      GateController(api: widget.gateApi, myMemberId: widget.session.family!.me.id);
  Timer? _poll;
  StreamSubscription<RemoteMessage>? _pushes;
  bool _setupNeeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    GateNotifications.responses.addListener(_onNotificationResponse);
    if (widget.usesPush) {
      // In the foreground, pushes come here instead of the background handler.
      _pushes = FirebaseMessaging.onMessage.listen((m) async {
        await GateNotifications.handlePush(m.data);
        await _gate.refresh();
      });
    }
    _startPolling();
    _checkSetup();
    GateNotifications.launchResponse().then(_handleResponse);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GateNotifications.responses.removeListener(_onNotificationResponse);
    _poll?.cancel();
    _pushes?.cancel();
    _gate.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      _checkSetup();
    } else if (state == AppLifecycleState.paused) {
      _poll?.cancel();
    }
  }

  /// Polling backs up push while the app is open (and is the only channel in demo mode).
  void _startPolling() {
    _poll?.cancel();
    _gate.refresh();
    _poll = Timer.periodic(Duration(seconds: widget.usesPush ? 10 : 3), (_) => _gate.refresh());
  }

  Future<void> _checkSetup() async {
    final status = await ReliabilityStatus.check();
    if (mounted) setState(() => _setupNeeded = !status.allGood);
  }

  void _onNotificationResponse() => _handleResponse(GateNotifications.responses.value);

  Future<void> _handleResponse(NotificationResponse? response) async {
    final alertId = response?.payload;
    if (alertId == null || alertId == 'test') return;
    await GateNotifications.cancelRing(alertId);
    if (response!.actionId == GateNotifications.comingActionId) {
      await _gate.coming(alertId);
    } else {
      await _gate.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeBell'),
        actions: [
          IconButton(
            tooltip: 'Reliability checklist',
            icon: Badge(isLabelVisible: _setupNeeded, child: const Icon(Icons.verified_user_outlined)),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ReliabilityScreen()))
                .then((_) => _checkSetup()),
          ),
          IconButton(
            tooltip: 'Family',
            icon: const Icon(Icons.groups_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => FamilyScreen(session: widget.session))),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _gate,
          builder: (context, _) => Column(
            children: [
              if (_setupNeeded)
                MaterialBanner(
                  content: const Text('Finish setup so you never miss a ring.'),
                  leading: const Icon(Icons.warning_amber),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const ReliabilityScreen()))
                          .then((_) => _checkSetup()),
                      child: const Text('Fix now'),
                    ),
                  ],
                ),
              if (_gate.error != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(_gate.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: switch (_gate.state) {
                      Idle() => _GateButton(busy: _gate.busy, onPressed: _gate.ring),
                      Ringing(:final alert) => _RingingView(
                          alert: alert, busy: _gate.busy, onCancel: () => _gate.cancel(alert.id)),
                      SomeoneAtGate(:final alert) => _SomeoneAtGateView(
                          alert: alert, busy: _gate.busy, onComing: () => _gate.coming(alert.id)),
                      Outcome(:final alert) => _OutcomeView(alert: alert, onDone: _gate.dismissOutcome),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The big "I'm at the gate" button.
class _GateButton extends StatelessWidget {
  const _GateButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 240,
          child: FilledButton(
            onPressed: busy ? null : onPressed,
            style: FilledButton.styleFrom(shape: const CircleBorder(), elevation: 6),
            child: busy
                ? CircularProgressIndicator(color: colors.onPrimary)
                : const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_active, size: 72),
                      SizedBox(height: 12),
                      Text("I'm at the gate", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Rings everyone at home until someone answers.',
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _RingingView extends StatelessWidget {
  const _RingingView({required this.alert, required this.busy, required this.onCancel});

  final GateAlert alert;
  final bool busy;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.ring_volume, size: 96, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('Ringing the family…', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Ring ${alert.ringCount} · waiting for someone to tap "Coming!"', textAlign: TextAlign.center),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: busy ? null : onCancel,
          icon: const Icon(Icons.close),
          label: const Text('Cancel, I got in'),
        ),
      ],
    );
  }
}

class _SomeoneAtGateView extends StatelessWidget {
  const _SomeoneAtGateView({required this.alert, required this.busy, required this.onComing});

  final GateAlert alert;
  final bool busy;
  final VoidCallback onComing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.door_front_door, size: 96, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text('${alert.sender.displayName} is at the gate',
            textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: busy ? null : onComing,
          icon: const Icon(Icons.directions_run, size: 32),
          label: const Text('Coming!', style: TextStyle(fontSize: 24)),
          style: FilledButton.styleFrom(minimumSize: const Size(240, 72)),
        ),
      ],
    );
  }
}

class _OutcomeView extends StatelessWidget {
  const _OutcomeView({required this.alert, required this.onDone});

  final GateAlert alert;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answered = alert.status == GateAlertStatus.acknowledged;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(answered ? Icons.check_circle : Icons.phone_missed,
            size: 96, color: answered ? Colors.green.shade600 : theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(
          answered ? '${alert.acknowledgedBy?.displayName ?? 'Someone'} is coming!' : 'Nobody answered',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(answered ? 'Hang tight, the gate will be opened soon.' : 'Try calling someone at home.',
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
        FilledButton.tonal(onPressed: onDone, child: const Text('OK')),
      ],
    );
  }
}
