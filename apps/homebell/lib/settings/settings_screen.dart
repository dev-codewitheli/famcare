import 'package:family_core/family_core.dart';
import 'package:flutter/material.dart';

import '../gate/gate_notifications.dart';
import '../gate/ring_settings.dart';
import '../setup/device_settings.dart';
import '../setup/phone_setup.dart';
import '../setup/setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.session});

  final Session session;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _ringThroughDnd = false;
  bool _waitingForDndAccess = false;
  int _alarmVolume = 100;
  PhoneSetupStatus? _setup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    var throughDnd = await RingSettings.ringThroughDnd();
    final hasAccess = await GateNotifications.hasDndAccess();
    if (_waitingForDndAccess) {
      // Back from the system's DND-access screen: finish turning the switch on, or explain.
      _waitingForDndAccess = false;
      if (hasAccess) {
        await GateNotifications.ensureDndChannel();
        await RingSettings.setRingThroughDnd(true);
        throughDnd = true;
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('HomeBell needs "Do Not Disturb access" to ring through Silent / DND.')));
      }
    } else if (throughDnd && !hasAccess) {
      // Access was revoked in system settings: reflect reality.
      await RingSettings.setRingThroughDnd(false);
      throughDnd = false;
    }
    final volume = await DeviceSettings.alarmVolumePercent();
    final setup = await PhoneSetupStatus.check();
    if (!mounted) return;
    setState(() {
      _ringThroughDnd = throughDnd;
      _alarmVolume = volume;
      _setup = setup;
    });
  }

  Future<void> _toggleDnd(bool on) async {
    if (!on) {
      await RingSettings.setRingThroughDnd(false);
      setState(() => _ringThroughDnd = false);
      return;
    }
    if (await GateNotifications.hasDndAccess()) {
      await GateNotifications.ensureDndChannel();
      await RingSettings.setRingThroughDnd(true);
      setState(() => _ringThroughDnd = true);
      return;
    }
    if (!mounted) return;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.do_not_disturb_off_rounded),
        title: const Text('Ring through Silent / DND?'),
        content: const Text('Android will open "Do Not Disturb access". Find HomeBell, switch it on, '
            'then come back. Only gate rings will get through; nothing else changes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    );
    if (proceed != true) return;
    _waitingForDndAccess = true;
    await GateNotifications.requestDndAccess();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final setup = _setup;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _SectionTitle('Ringing on this phone'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.do_not_disturb_off_rounded),
                  title: const Text('Ring even on Silent / Do Not Disturb'),
                  subtitle: const Text('For whoever usually opens the gate. Off: a silenced phone stays quiet, '
                      'and the rest of the family still gets the ring.'),
                  value: _ringThroughDnd,
                  onChanged: _toggleDnd,
                ),
                if (_alarmVolume == 0)
                  ListTile(
                    leading: Icon(Icons.volume_off_rounded, color: colors.error),
                    title: const Text('Alarm volume is off'),
                    subtitle: const Text('Rings play at alarm volume, so this phone won\'t make a sound.'),
                    trailing: TextButton(onPressed: DeviceSettings.openSoundSettings, child: const Text('Fix')),
                  ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded),
                  title: const Text('Test the ring'),
                  subtitle: const Text('Rings this phone in 5 seconds'),
                  onTap: () => Future.delayed(const Duration(seconds: 5),
                      () => GateNotifications.showRing(alertId: 'test', senderName: 'Test')),
                  trailing: TextButton(
                      onPressed: () => GateNotifications.cancelRing('test'), child: const Text('Stop')),
                ),
              ],
            ),
          ),
          _SectionTitle('This phone'),
          Card(
            child: ListTile(
              leading: Icon(
                setup?.allGood ?? true ? Icons.verified_rounded : Icons.warning_amber_rounded,
                color: setup?.allGood ?? true ? Colors.green.shade600 : colors.error,
              ),
              title: const Text('Phone setup'),
              subtitle: Text(setup == null
                  ? 'Checking…'
                  : setup.allGood
                      ? 'Ready for ${setup.brand.label}'
                      : '${setup.remaining} steps left for ${setup.brand.label}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const SetupScreen()))
                  .then((_) => _load()),
            ),
          ),
          _SectionTitle('Family'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.groups_rounded),
                  title: const Text('Members and invite code'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => FamilyScreen(session: widget.session))),
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Sign out'),
                  onTap: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    widget.session.signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
        child: Text(text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}
