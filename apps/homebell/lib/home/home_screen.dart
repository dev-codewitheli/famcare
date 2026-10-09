import 'dart:async';

import 'package:family_core/family_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../gate/gate_api.dart';
import '../gate/gate_controller.dart';
import '../gate/gate_notifications.dart';
import '../gate/ring_settings.dart';
import '../settings/settings_screen.dart';
import '../setup/phone_setup.dart';
import '../setup/setup_screen.dart';
import 'activity_controller.dart';
import 'home_widgets.dart';

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
  late final String _myId = widget.session.family!.me.id;
  late final GateController _gate = GateController(api: widget.gateApi, myMemberId: _myId);
  late final ActivityController _activity = ActivityController(api: widget.gateApi, myMemberId: _myId);
  Timer? _poll;
  int _ticks = 0;
  StreamSubscription<RemoteMessage>? _pushes;
  bool _setupNeeded = false;

  /// Who "I'm at the gate" leaves out; remembered on this phone.
  Set<String> _leftOut = const {};

  List<Member> get _others {
    final family = widget.session.family!;
    return family.members.where((m) => m.id != family.me.id).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    GateNotifications.responses.addListener(_onNotificationResponse);
    _gate.addListener(_stopRingWhenAlertEnds);
    if (widget.usesPush) {
      // In the foreground, pushes come here instead of the background handler.
      _pushes = FirebaseMessaging.onMessage.listen((m) async {
        if (m.data['type'] == 'MEMBER_REMOVED') {
          // Back to the join screen; the session sees NOT_IN_FAMILY.
          await widget.session.refresh();
          return;
        }
        await GateNotifications.handlePush(m.data);
        await Future.wait([_gate.refresh(), _activity.refresh()]);
      });
    }
    _startPolling();
    RingSettings.leftOut().then((ids) {
      if (mounted) setState(() => _leftOut = ids);
    });
    _askForNotificationsThenCheckSetup();
    GateNotifications.launchResponse().then(_handleResponse);
  }

  /// Without this permission (Android 13+) every ring is silently dropped, so ask up front
  /// instead of waiting for the user to find the setup screen. Android itself stops showing the
  /// prompt after it's been denied twice; the setup screen then links to settings.
  Future<void> _askForNotificationsThenCheckSetup() async {
    if (!await GateNotifications.areEnabled()) await GateNotifications.requestPermission();
    await _checkSetup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GateNotifications.responses.removeListener(_onNotificationResponse);
    _gate.removeListener(_stopRingWhenAlertEnds);
    _poll?.cancel();
    _pushes?.cancel();
    _gate.dispose();
    _activity.dispose();
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
  /// The activity list changes slowly, so it refreshes every third tick.
  void _startPolling() {
    _poll?.cancel();
    _gate.refresh();
    _activity.refresh();
    _poll = Timer.periodic(Duration(seconds: widget.usesPush ? 10 : 3), (_) {
      _gate.refresh();
      if (++_ticks % 3 == 0) _activity.refresh();
    });
  }

  Future<void> _checkSetup() async {
    final status = await PhoneSetupStatus.check();
    if (mounted) setState(() => _setupNeeded = !status.allGood);
  }

  void _onNotificationResponse() => _handleResponse(GateNotifications.responses.value);

  /// Backup for a late or lost "stop ringing" push: once polling shows the alert this phone
  /// was ringing for has ended (answered, cancelled, or expired), silence it locally.
  String? _ringingFor;

  void _stopRingWhenAlertEnds() {
    final state = _gate.state;
    final current = state is SomeoneAtGate ? state.alert.id : null;
    final previous = _ringingFor;
    if (previous != null && previous != current) {
      GateNotifications.cancelRing(previous);
      _activity.refresh();
    }
    _ringingFor = current;
  }

  /// A tap on the ring notification (after unlocking), or the app opened by the full-screen
  /// alert. Opening the app must NOT stop the ring: like an incoming call, it keeps ringing
  /// while the screen shows "… is at the gate" until someone actually answers.
  Future<void> _handleResponse(NotificationResponse? response) async {
    final payload = response?.payload;
    if (payload == null || payload == 'test') return;
    final action = response!.actionId;

    // "On my way" heads-up from someone else: "Got it".
    if (payload.startsWith(GateNotifications.headsUpPayloadPrefix)) {
      if (action == GateNotifications.gotItActionId) {
        await _gotIt(payload.substring(GateNotifications.headsUpPayloadPrefix.length));
      }
      return _activity.refresh();
    }
    // My "time's up" reminder: ring now, add time, or not coming.
    if (payload.startsWith(GateNotifications.duePayloadPrefix)) {
      await GateNotifications.cancelDueReminder();
      if (action == GateNotifications.ringNowActionId) {
        await _ring();
      } else if (action == GateNotifications.addTimeActionId) {
        await _announce(GateNotifications.addTimeMinutes);
      } else if (action == GateNotifications.notComingActionId) {
        await _cancelHeadsUp();
      }
      return _activity.refresh();
    }
    // A gate ring.
    if (action == GateNotifications.comingActionId) {
      await _answer(payload);
    } else {
      await _gate.refresh();
    }
  }

  Future<void> _gotIt(String noticeId) async {
    final arrival = _activity.othersOnTheWay.where((a) => a.id == noticeId).firstOrNull;
    final error = await _activity.markSeen(noticeId);
    if (arrival != null) await GateNotifications.cancelHeadsUp(arrival.member.displayName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? '${arrival?.member.displayName ?? 'They'} will know you saw it'),
    ));
  }

  /// "Coming!" The server tells everyone else to stop ringing; this phone stops its own ring.
  Future<void> _answer(String alertId) async {
    await _gate.coming(alertId);
    if (_gate.error == null) await GateNotifications.cancelRing(alertId);
    await _activity.refresh();
  }

  Future<void> _ring() async {
    await GateNotifications.cancelDueReminder();
    await _gate.ring(recipientIds: ringRecipientIds(_others, _leftOut));
    await _activity.refresh();
  }

  Future<void> _chooseRecipients() async {
    final leftOut = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => RecipientsSheet(others: _others, leftOut: _leftOut),
    );
    if (leftOut == null) return;
    await RingSettings.setLeftOut(leftOut);
    if (mounted) setState(() => _leftOut = leftOut);
  }

  Future<void> _cancelHeadsUp() async {
    await GateNotifications.cancelDueReminder();
    final error = await _activity.cancelMine();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'Heads-up cancelled. The family was told you\'re not coming.'),
    ));
  }

  Future<void> _announce(int minutes) async {
    final result = await _activity.announce(minutes);
    if (!mounted) return;
    final arrival = result.arrival;
    if (arrival == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    await showDialog<void>(context: context, builder: (_) => HeadsUpSentDialog(arrival: arrival));
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((_) => _checkSetup());

  @override
  Widget build(BuildContext context) {
    final family = widget.session.family!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_gate, _activity]),
          builder: (context, _) {
            final state = _gate.state;
            final canAnnounce = state is Idle || state is Outcome;
            return RefreshIndicator(
              onRefresh: () => Future.wait([_gate.refresh(), _activity.refresh()]),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hi, ${family.me.displayName}',
                                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                            Text(family.name, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Settings',
                        icon: Badge(isLabelVisible: _setupNeeded, child: const Icon(Icons.settings_rounded)),
                        onPressed: () => _open(SettingsScreen(session: widget.session)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FamilyStrip(
                    members: _others,
                    onTap: () => _open(FamilyScreen(session: widget.session)),
                  ),
                  if (_setupNeeded) ...[
                    const SizedBox(height: 16),
                    SetupBanner(onTap: () => _open(const SetupScreen())),
                  ],
                  if (_gate.error != null) ...[
                    const SizedBox(height: 12),
                    Text(_gate.error!, style: TextStyle(color: colors.error)),
                  ],
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: switch (state) {
                      Idle() => GateButtonCard(
                          key: const ValueKey('idle'),
                          busy: _gate.busy,
                          onRing: _ring,
                          ringing: switch (ringRecipientIds(_others, _leftOut)) {
                            null => null,
                            final ids => [for (final m in _others) if (ids.contains(m.id)) m],
                          },
                          onChooseRecipients: _others.isEmpty ? null : _chooseRecipients),
                      Ringing(:final alert) => RingingCard(
                          key: const ValueKey('ringing'),
                          alert: alert,
                          busy: _gate.busy,
                          onCancel: () => _gate.cancel(alert.id)),
                      SomeoneAtGate(:final alert) => SomeoneAtGateCard(
                          key: const ValueKey('someone'),
                          alert: alert,
                          busy: _gate.busy,
                          ringsMe: alert.rings(_myId),
                          onComing: () => _answer(alert.id)),
                      Outcome(:final alert) => OutcomeCard(
                          key: const ValueKey('outcome'), alert: alert, onDone: _gate.dismissOutcome),
                    },
                  ),
                  for (final arrival in _activity.othersOnTheWay) ...[
                    const SizedBox(height: 12),
                    OnTheWayCard(
                      arrival: arrival,
                      seenByMe: arrival.seenByMember(_myId),
                      onGotIt: () => _gotIt(arrival.id),
                    ),
                  ],
                  if (canAnnounce) ...[
                    const SizedBox(height: 20),
                    OnMyWayCard(
                      myArrival: _activity.myArrival,
                      busy: _activity.announcing || _gate.busy,
                      onAnnounce: _announce,
                      onCancel: _cancelHeadsUp,
                    ),
                  ],
                  const SizedBox(height: 24),
                  RecentActivity(alerts: _activity.recent, myMemberId: _myId),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
