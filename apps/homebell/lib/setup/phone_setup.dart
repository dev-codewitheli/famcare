import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../gate/gate_notifications.dart';
import 'device_settings.dart';

/// Phone makers that change how Android treats background apps, grouped by their software.
enum PhoneBrand {
  xiaomi('Xiaomi / Redmi / POCO'),
  oppo('OPPO / OnePlus'),
  realme('realme'),
  vivo('vivo / iQOO'),
  samsung('Samsung'),
  transsion('Infinix / Tecno / itel'),
  other('Android');

  const PhoneBrand(this.label);

  final String label;

  static PhoneBrand fromManufacturer(String manufacturer) => switch (manufacturer.toLowerCase().trim()) {
        'xiaomi' || 'redmi' || 'poco' => xiaomi,
        'oppo' || 'oneplus' => oppo,
        'realme' => realme,
        'vivo' || 'iqoo' => vivo,
        'samsung' => samsung,
        'infinix' || 'tecno' || 'itel' => transsion,
        _ => other,
      };
}

/// One thing to get right so a gate ring reaches this phone.
class SetupStep {
  const SetupStep({
    required this.id,
    required this.icon,
    required this.title,
    required this.detail,
    this.actionLabel,
    this.action,
    this.check,
    this.optional = false,
  });

  final String id;
  final IconData icon;
  final String title;
  final String detail;
  final String? actionLabel;
  final Future<void> Function()? action;

  /// Verifiable steps check the phone directly. Steps without a check are confirmed by
  /// the user ("I did this"), because Android doesn't expose those OEM settings.
  final Future<bool> Function()? check;

  /// Recommended, but doesn't keep the "finish setup" badge on.
  final bool optional;

  bool get isManual => check == null;
}

/// The steps for a brand, most important first. Pure data, so it's unit-testable.
List<SetupStep> setupStepsFor(PhoneBrand brand) => [
      SetupStep(
        id: 'notifications',
        icon: Icons.notifications_active_rounded,
        title: 'Allow notifications',
        detail: 'Without this, rings are dropped silently.',
        actionLabel: 'Allow',
        action: () async {
          if (!await GateNotifications.requestPermission()) await DeviceSettings.openAppSettings();
        },
        check: GateNotifications.areEnabled,
      ),
      const SetupStep(
        id: 'fullscreen',
        icon: Icons.fullscreen_rounded,
        title: 'Allow full-screen alerts',
        detail: 'Lets a ring light up a locked screen, like an incoming call.',
        actionLabel: 'Allow',
        action: GateNotifications.requestFullScreenPermission,
        check: DeviceSettings.canUseFullScreenIntent,
      ),
      const SetupStep(
        id: 'battery',
        icon: Icons.battery_charging_full_rounded,
        title: 'Turn off battery optimization',
        detail: 'Stops Android from putting HomeBell to sleep.',
        actionLabel: 'Allow',
        action: DeviceSettings.requestIgnoreBatteryOptimizations,
        check: DeviceSettings.isIgnoringBatteryOptimizations,
      ),
      SetupStep(
        id: 'alarm_volume',
        icon: Icons.volume_up_rounded,
        title: 'Turn up the alarm volume',
        detail: 'Rings play at alarm volume, like an alarm clock.',
        actionLabel: 'Sound settings',
        action: DeviceSettings.openSoundSettings,
        check: () async => await DeviceSettings.alarmVolumePercent() > 0,
      ),
      SetupStep(
        id: 'ring_channel',
        icon: Icons.lock_clock_rounded,
        title: 'Ring sound, pop-up and lock screen',
        detail: 'In "Gate rings", make sure Sound, Pop-up / Floating and Lock screen are all on.',
        actionLabel: 'Open',
        action: () => DeviceSettings.openChannelSettings(GateNotifications.ringChannelId),
      ),
      ..._brandSteps(brand),
    ];

List<SetupStep> _brandSteps(PhoneBrand brand) {
  const autostart = SetupStep(
    id: 'autostart',
    icon: Icons.restart_alt_rounded,
    title: 'Turn on Autostart',
    detail: 'Find HomeBell in the list and switch it on. Without it, a closed app can\'t wake up for a ring.',
    actionLabel: 'Open Autostart',
    action: DeviceSettings.openAutostartSettings,
  );
  const lockInRecents = SetupStep(
    id: 'lock_recents',
    icon: Icons.lock_rounded,
    title: 'Lock HomeBell in recent apps',
    detail: 'Open recent apps, long-press (or swipe down on) HomeBell and tap the lock, so "clear all" '
        'and memory cleaners leave it alone.',
    optional: true,
  );
  SetupStep batteryNoRestrictions(String detail) => SetupStep(
        id: 'oem_battery',
        icon: Icons.battery_alert_rounded,
        title: 'Remove background limits',
        detail: detail,
        actionLabel: 'Open app settings',
        action: DeviceSettings.openAppSettings,
      );

  return switch (brand) {
    PhoneBrand.xiaomi => [
        autostart,
        const SetupStep(
          id: 'xiaomi_lock_screen',
          icon: Icons.screen_lock_portrait_rounded,
          title: 'Allow showing on the lock screen',
          detail: 'Under "Other permissions", allow "Show on Lock screen" and '
              '"Display pop-up windows while running in the background".',
          actionLabel: 'Open permissions',
          action: DeviceSettings.openOemPermissions,
        ),
        batteryNoRestrictions('Battery saver → "No restrictions".'),
        lockInRecents,
      ],
    PhoneBrand.oppo || PhoneBrand.realme => [
        autostart,
        batteryNoRestrictions('Battery → allow "Background activity" (or "Allow background running"), '
            'and turn off "Optimize battery use" for HomeBell.'),
        lockInRecents,
      ],
    PhoneBrand.vivo => [
        autostart,
        const SetupStep(
          id: 'oem_battery',
          icon: Icons.battery_alert_rounded,
          title: 'Allow high background power use',
          detail: 'Battery → Background power consumption → allow HomeBell.',
          actionLabel: 'Open battery',
          action: DeviceSettings.openOemBatterySettings,
        ),
        lockInRecents,
      ],
    PhoneBrand.samsung => [
        const SetupStep(
          id: 'oem_battery',
          icon: Icons.battery_alert_rounded,
          title: 'Add to "Never sleeping apps"',
          detail: 'Battery → Background usage limits → Never sleeping apps → add HomeBell. '
              'Also set HomeBell\'s app battery to "Unrestricted".',
          actionLabel: 'Open battery',
          action: DeviceSettings.openOemBatterySettings,
        ),
        lockInRecents,
      ],
    PhoneBrand.transsion => [
        autostart,
        batteryNoRestrictions('Battery → "Don\'t restrict" (or "No restrictions"). In Phone Master, '
            'exclude HomeBell from cleaning.'),
        lockInRecents,
      ],
    PhoneBrand.other => [
        batteryNoRestrictions('Battery → "Unrestricted" (or "Allow background activity").'),
      ],
  };
}

/// The result of checking every step on this phone.
class PhoneSetupStatus {
  PhoneSetupStatus(this.brand, this.steps, this.done);

  final PhoneBrand brand;
  final List<SetupStep> steps;
  final Map<String, bool> done;

  bool isDone(SetupStep step) => done[step.id] ?? false;

  /// Required steps still to do; drives the "finish setup" badge.
  int get remaining => steps.where((s) => !s.optional && !isDone(s)).length;

  bool get allGood => remaining == 0;

  static const _manualPrefix = 'setup_done_';

  static Future<PhoneSetupStatus> check() async {
    final brand = PhoneBrand.fromManufacturer(await DeviceSettings.manufacturer());
    final steps = setupStepsFor(brand);
    final prefs = await SharedPreferences.getInstance();
    final done = <String, bool>{};
    for (final step in steps) {
      done[step.id] = step.check != null ? await step.check!() : prefs.getBool('$_manualPrefix${step.id}') ?? false;
    }
    return PhoneSetupStatus(brand, steps, done);
  }

  /// For steps Android can't verify: the user confirms they changed the setting.
  static Future<void> markManualStep(String id, bool done) async =>
      (await SharedPreferences.getInstance()).setBool('$_manualPrefix$id', done);
}
