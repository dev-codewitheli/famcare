import 'package:flutter/services.dart';

/// Native checks implemented in MainActivity.kt.
class DeviceSettings {
  DeviceSettings._();

  static const _channel = MethodChannel('homebell/device_settings');

  static Future<bool> canUseFullScreenIntent() async =>
      await _channel.invokeMethod<bool>('canUseFullScreenIntent') ?? false;

  static Future<bool> isIgnoringBatteryOptimizations() async =>
      await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;

  static Future<String> manufacturer() async =>
      (await _channel.invokeMethod<String>('manufacturer') ?? '').toLowerCase();

  /// Opens the system dialog; re-check [isIgnoringBatteryOptimizations] when the app resumes.
  static Future<void> requestIgnoreBatteryOptimizations() =>
      _channel.invokeMethod('requestIgnoreBatteryOptimizations');

  static Future<void> openAppSettings() => _channel.invokeMethod('openAppSettings');

  /// Opens the brand's autostart screen (Xiaomi, Oppo/Realme, Vivo, Infinix/Tecno), or the
  /// app's settings if this phone doesn't have one we know.
  static Future<void> openAutostartSettings() => _channel.invokeMethod('openAutostartSettings');
}
