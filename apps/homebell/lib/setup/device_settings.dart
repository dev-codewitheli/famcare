import 'package:flutter/services.dart';

/// Native checks and settings screens implemented in MainActivity.kt.
class DeviceSettings {
  DeviceSettings._();

  static const _channel = MethodChannel('homebell/device_settings');

  static Future<bool> canUseFullScreenIntent() async =>
      await _channel.invokeMethod<bool>('canUseFullScreenIntent') ?? false;

  static Future<bool> isIgnoringBatteryOptimizations() async =>
      await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;

  static Future<String> manufacturer() async =>
      (await _channel.invokeMethod<String>('manufacturer') ?? '').toLowerCase();

  /// 0–100. Gate rings play at alarm volume, so 0 means a silent ring.
  static Future<int> alarmVolumePercent() async =>
      await _channel.invokeMethod<int>('alarmVolumePercent') ?? 100;

  /// Whether the ring channel still has sound and pop-up on (null if it doesn't exist yet).
  static Future<bool?> ringChannelOk(String channelId, {bool requireSound = true}) =>
      _channel.invokeMethod<bool>('ringChannelOk', {'channelId': channelId, 'requireSound': requireSound});

  /// Xiaomi app-op codes for settings outside standard Android.
  static const miuiAutostart = 10008;
  static const miuiBackgroundPopups = 10021;

  /// Best effort on Xiaomi; null when it can't be read (other brands, or the OS hides it).
  static Future<bool?> miuiOpAllowed(int op) => _channel.invokeMethod<bool>('miuiOpAllowed', {'op': op});

  /// Opens the system dialog; re-check [isIgnoringBatteryOptimizations] when the app resumes.
  static Future<void> requestIgnoreBatteryOptimizations() =>
      _channel.invokeMethod('requestIgnoreBatteryOptimizations');

  static Future<void> openAppSettings() => _channel.invokeMethod('openAppSettings');

  static Future<void> openSoundSettings() => _channel.invokeMethod('openSoundSettings');

  /// The settings page of one notification channel (sound, lock screen, pop-up).
  static Future<void> openChannelSettings(String channelId) =>
      _channel.invokeMethod('openChannelSettings', {'channelId': channelId});

  /// The brand's autostart screen (Xiaomi, Oppo/Realme/OnePlus, Vivo/iQOO, Infinix/Tecno).
  static Future<void> openAutostartSettings() => _channel.invokeMethod('openAutostartSettings');

  /// Xiaomi's "Other permissions" (Show on Lock screen, background pop-ups).
  static Future<void> openOemPermissions() => _channel.invokeMethod('openOemPermissions');

  /// The brand's background-battery screen (e.g. Samsung "Never sleeping apps").
  static Future<void> openOemBatterySettings() => _channel.invokeMethod('openOemBatterySettings');
}
