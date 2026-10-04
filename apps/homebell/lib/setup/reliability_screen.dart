import 'package:flutter/material.dart';

import '../gate/gate_notifications.dart';
import 'device_settings.dart';

/// Results of the checks that decide whether a gate ring actually reaches this phone.
class ReliabilityStatus {
  const ReliabilityStatus({
    required this.notifications,
    required this.fullScreen,
    required this.battery,
    required this.manufacturer,
  });

  final bool notifications;
  final bool fullScreen;
  final bool battery;
  final String manufacturer;

  bool get allGood => notifications && fullScreen && battery;

  static Future<ReliabilityStatus> check() async => ReliabilityStatus(
        notifications: await GateNotifications.areEnabled(),
        fullScreen: await DeviceSettings.canUseFullScreenIntent(),
        battery: await DeviceSettings.isIgnoringBatteryOptimizations(),
        manufacturer: await DeviceSettings.manufacturer(),
      );
}

/// Brands that stop background apps aggressively, with what to switch on. Very common in the
/// Philippines, and the #1 reason pushes arrive late or not at all. See dontkillmyapp.com.
const _brandTips = <String, String>{
  'xiaomi': 'Settings → Apps → HomeBell: turn on Autostart, set Battery saver to "No restrictions", and under Other permissions allow "Show on Lock screen" and "Display pop-up windows while running in the background".',
  'redmi': 'Settings → Apps → HomeBell: turn on Autostart, set Battery saver to "No restrictions", and under Other permissions allow "Show on Lock screen" and "Display pop-up windows while running in the background".',
  'poco': 'Settings → Apps → HomeBell: turn on Autostart, set Battery saver to "No restrictions", and under Other permissions allow "Show on Lock screen" and "Display pop-up windows while running in the background".',
  'oppo': 'Settings → Apps → HomeBell → Battery: allow background activity and auto launch. Under Notifications, allow lock screen notifications.',
  'realme': 'Settings → Apps → HomeBell → Battery: allow background activity and auto launch. Under Notifications, allow lock screen notifications.',
  'oneplus': 'Settings → Apps → HomeBell → Battery: allow background activity.',
  'vivo': 'Settings → Battery → Background power consumption: allow HomeBell. Also enable Autostart.',
  'infinix': 'Phone Master → Auto-start management: allow HomeBell. Lock it in recent apps.',
  'tecno': 'Phone Master → Auto-start management: allow HomeBell. Lock it in recent apps.',
  'huawei': 'Settings → Battery → App launch: set HomeBell to "Manage manually" and allow all.',
  'honor': 'Settings → Battery → App launch: set HomeBell to "Manage manually" and allow all.',
  'samsung': 'Settings → Battery → Background usage limits: add HomeBell to "Never sleeping apps".',
};

class ReliabilityScreen extends StatefulWidget {
  const ReliabilityScreen({super.key});

  @override
  State<ReliabilityScreen> createState() => _ReliabilityScreenState();
}

class _ReliabilityScreenState extends State<ReliabilityScreen> with WidgetsBindingObserver {
  ReliabilityStatus? _status;

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
    final status = await ReliabilityStatus.check();
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final brandTip = status == null ? null : _brandTips[status.manufacturer];

    return Scaffold(
      appBar: AppBar(title: const Text('Never miss a ring')),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Android may delay or block alerts to save battery. '
                  'Fix each item below so a gate ring always gets through.',
                ),
                const SizedBox(height: 16),
                _CheckTile(
                  ok: status.notifications,
                  title: 'Notifications allowed',
                  detail: 'Needed to show gate alerts at all.',
                  onFix: () async {
                    await GateNotifications.requestPermission();
                    await _check();
                  },
                ),
                _CheckTile(
                  ok: status.fullScreen,
                  title: 'Full-screen alerts allowed',
                  detail: 'Lets a ring light up the screen like an incoming call.',
                  onFix: GateNotifications.requestFullScreenPermission,
                ),
                _CheckTile(
                  ok: status.battery,
                  title: 'Battery optimization off',
                  detail: 'Stops Android from putting HomeBell to sleep.',
                  onFix: () async {
                    await DeviceSettings.requestIgnoreBatteryOptimizations();
                    await _check();
                  },
                ),
                if (brandTip != null)
                  Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Extra step for ${status.manufacturer[0].toUpperCase()}${status.manufacturer.substring(1)} phones',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(brandTip),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: DeviceSettings.openAutostartSettings,
                                icon: const Icon(Icons.restart_alt),
                                label: const Text('Open Autostart settings'),
                              ),
                              TextButton.icon(
                                onPressed: DeviceSettings.openAppSettings,
                                icon: const Icon(Icons.settings),
                                label: const Text('Open HomeBell settings'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => GateNotifications.showRing(alertId: 'test', senderName: 'Test'),
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Test the alarm on this phone'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => GateNotifications.cancelRing('test'),
                  child: const Text('Stop test alarm'),
                ),
              ],
            ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.ok, required this.title, required this.detail, required this.onFix});

  final bool ok;
  final String title;
  final String detail;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(ok ? Icons.check_circle : Icons.error,
          color: ok ? Colors.green.shade600 : colors.error),
      title: Text(title),
      subtitle: Text(detail),
      trailing: ok ? null : FilledButton.tonal(onPressed: onFix, child: const Text('Fix')),
    );
  }
}
