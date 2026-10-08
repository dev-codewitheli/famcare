import 'package:shared_preferences/shared_preferences.dart';

/// Per-phone ring preferences. Stored on the device (not the server) because they describe
/// this phone, and the background push handler has to read them without network access.
class RingSettings {
  RingSettings._();

  static const _ringThroughDndKey = 'ring_through_dnd';

  /// "Ring even on Silent / Do Not Disturb". Off by default: someone may silence their phone
  /// on purpose (e.g. at night), and another family member can still open the gate.
  static Future<bool> ringThroughDnd() async =>
      (await SharedPreferences.getInstance()).getBool(_ringThroughDndKey) ?? false;

  static Future<void> setRingThroughDnd(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_ringThroughDndKey, value);
}
