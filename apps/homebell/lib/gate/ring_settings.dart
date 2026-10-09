import 'package:family_core/family_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-phone ring preferences. Stored on the device (not the server) because they describe
/// this phone, and the background push handler has to read them without network access.
class RingSettings {
  RingSettings._();

  static const _ringThroughDndKey = 'ring_through_dnd';
  static const _leftOutKey = 'ring_left_out';

  /// "Ring even on Silent / Do Not Disturb". Off by default: someone may silence their phone
  /// on purpose (e.g. at night), and another family member can still open the gate.
  static Future<bool> ringThroughDnd() async =>
      (await SharedPreferences.getInstance()).getBool(_ringThroughDndKey) ?? false;

  static Future<void> setRingThroughDnd(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_ringThroughDndKey, value);

  /// Who "I'm at the gate" leaves out (e.g. someone at school or work). Stores who's left out
  /// rather than who's rung, so a family member who joins later is rung by default.
  static Future<Set<String>> leftOut() async =>
      ((await SharedPreferences.getInstance()).getStringList(_leftOutKey) ?? const []).toSet();

  static Future<void> setLeftOut(Set<String> memberIds) async =>
      (await SharedPreferences.getInstance()).setStringList(_leftOutKey, memberIds.toList());
}

/// The member ids to ring: everyone in [others] who isn't left out, or null (everyone) when
/// nobody is, so the server also includes anyone this phone doesn't know about yet.
List<String>? ringRecipientIds(List<Member> others, Set<String> leftOut) {
  if (!others.any((m) => leftOut.contains(m.id))) return null;
  return [for (final m in others) if (!leftOut.contains(m.id)) m.id];
}

/// "Mama", "Mama and Papa", "Mama, Papa and Ate".
String joinNames(List<String> names) => switch (names.length) {
      0 => '',
      1 => names.single,
      _ => '${names.take(names.length - 1).join(', ')} and ${names.last}',
    };
