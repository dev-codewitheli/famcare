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

  /// Checks the phone directly. Returns null when the setting can't be read (OEM settings that
  /// Android doesn't expose); the user then confirms it themselves ("I did this").
  final Future<bool?> Function()? check;

  /// Recommended, but doesn't keep the "finish setup" badge on.
  final bool optional;
}

/// The steps for a brand, most important first.
///
/// Each step covers a different setting; brand battery screens that just mirror Android's
/// "battery optimization" (Xiaomi's "No restrictions", Samsung's "Unrestricted", Transsion's
/// "Don't restrict") are left out because step 3 already sets them.
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
      // One step for "can the ring be heard and seen": the alarm volume, and the "Gate rings"
      // notification settings (whichever channel rings use here: the Silent/DND one when it's on).
      SetupStep(
        id: 'ring_sound',
        icon: Icons.volume_up_rounded,
        title: 'Make sure the ring can be heard',
        detail: 'Keep the alarm volume up (rings play like an alarm clock), and in "Gate rings" keep '
            'Sound, Pop-up and Lock screen on.',
        actionLabel: 'Fix',
        action: () async {
          if (await DeviceSettings.alarmVolumePercent() == 0) return DeviceSettings.openSoundSettings();
          await DeviceSettings.openChannelSettings(await GateNotifications.activeRingChannelId());
        },
        check: () async {
          if (await DeviceSettings.alarmVolumePercent() == 0) return false;
          final channel = await GateNotifications.activeRingChannelId();
          // The Silent/DND channel is silent on purpose: its sound plays at alarm volume instead.
          return await DeviceSettings.ringChannelOk(channel,
                  requireSound: channel != GateNotifications.ringDndChannelId) ??
              true;
        },
      ),
      ..._brandSteps(brand),
    ];

List<SetupStep> _brandSteps(PhoneBrand brand) {
  const lockInRecents = SetupStep(
    id: 'lock_recents',
    icon: Icons.lock_rounded,
    title: 'Lock HomeBell in recent apps',
    detail: 'Open recent apps, long-press (or swipe down on) HomeBell and tap the lock, so "clear all" '
        'and memory cleaners leave it alone.',
    optional: true,
  );

  return switch (brand) {
    PhoneBrand.xiaomi => [
        SetupStep(
          id: 'autostart',
          icon: Icons.restart_alt_rounded,
          title: 'Turn on Autostart',
          detail: 'Switch HomeBell on. Without it, a closed app can\'t wake up for a ring.',
          actionLabel: 'Open Autostart',
          action: DeviceSettings.openAutostartSettings,
          check: () => DeviceSettings.miuiOpAllowed(DeviceSettings.miuiAutostart),
        ),
        // HomeBell no longer shows over the lock screen, so Xiaomi's "Show on Lock screen" isn't
        // needed; background pop-ups still are, for the full-screen alert that wakes the screen.
        SetupStep(
          id: 'xiaomi_popups',
          icon: Icons.screen_lock_portrait_rounded,
          title: 'Allow background pop-ups',
          detail: 'Under "Other permissions", allow "Display pop-up windows while running in the background". '
              'It lets a ring light up the screen.',
          actionLabel: 'Open permissions',
          action: DeviceSettings.openOemPermissions,
          check: () => DeviceSettings.miuiOpAllowed(DeviceSettings.miuiBackgroundPopups),
        ),
        lockInRecents,
      ],
    // ColorOS keeps both switches on the same "Battery usage" page, so they're one step.
    PhoneBrand.oppo || PhoneBrand.realme => [
        const SetupStep(
          id: 'oem_background',
          icon: Icons.battery_alert_rounded,
          title: 'Allow background activity and auto launch',
          detail: 'App info → Battery usage: turn on "Allow background activity" and "Allow auto launch".',
          actionLabel: 'Open app info',
          action: DeviceSettings.openAppSettings,
        ),
        lockInRecents,
      ],
    PhoneBrand.vivo => [
        const SetupStep(
          id: 'autostart',
          icon: Icons.restart_alt_rounded,
          title: 'Turn on Autostart',
          detail: 'Switch HomeBell on. Without it, a closed app can\'t wake up for a ring.',
          actionLabel: 'Open Autostart',
          action: DeviceSettings.openAutostartSettings,
        ),
        const SetupStep(
          id: 'oem_background',
          icon: Icons.battery_alert_rounded,
          title: 'Allow high background power use',
          detail: 'Battery → Background power consumption → allow HomeBell.',
          actionLabel: 'Open battery',
          action: DeviceSettings.openOemBatterySettings,
        ),
        lockInRecents,
      ],
    PhoneBrand.transsion => [
        const SetupStep(
          id: 'autostart',
          icon: Icons.restart_alt_rounded,
          title: 'Turn on Auto-start',
          detail: 'In Phone Master, allow HomeBell to auto-start and exclude it from cleaning.',
          actionLabel: 'Open Auto-start',
          action: DeviceSettings.openAutostartSettings,
        ),
        lockInRecents,
      ],
    // Samsung and stock Android: step 3 ("Unrestricted" battery) covers background running.
    PhoneBrand.samsung => const [lockInRecents],
    PhoneBrand.other => const [],
  };
}

/// The result of checking every step on this phone.
class PhoneSetupStatus {
  PhoneSetupStatus(this.brand, this.steps, this.done, this.manual);

  final PhoneBrand brand;
  final List<SetupStep> steps;
  final Map<String, bool> done;

  /// Steps the phone can't verify, so the user confirms them.
  final Set<String> manual;

  bool isDone(SetupStep step) => done[step.id] ?? false;

  bool isManual(SetupStep step) => manual.contains(step.id);

  /// Required steps still to do; drives the "finish setup" badge.
  int get remaining => steps.where((s) => !s.optional && !isDone(s)).length;

  bool get allGood => remaining == 0;

  static const _manualPrefix = 'setup_done_';

  static Future<PhoneSetupStatus> check() async {
    final brand = PhoneBrand.fromManufacturer(await DeviceSettings.manufacturer());
    final steps = setupStepsFor(brand);
    final prefs = await SharedPreferences.getInstance();
    final done = <String, bool>{};
    final manual = <String>{};
    for (final step in steps) {
      final checked = await step.check?.call();
      if (checked != null) {
        done[step.id] = checked;
      } else {
        manual.add(step.id);
        done[step.id] = prefs.getBool('$_manualPrefix${step.id}') ?? false;
      }
    }
    return PhoneSetupStatus(brand, steps, done, manual);
  }

  /// For steps Android can't verify: the user confirms they changed the setting.
  static Future<void> markManualStep(String id, bool done) async =>
      (await SharedPreferences.getInstance()).setBool('$_manualPrefix$id', done);
}
