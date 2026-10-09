import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light, dark, or follow the phone's setting (the default). Stored on this phone only.
class ThemePreference extends ValueNotifier<ThemeMode> {
  ThemePreference._() : super(ThemeMode.system);

  static final instance = ThemePreference._();

  static const _key = 'theme_mode';

  /// Reads the saved choice; called once at startup, before the first frame.
  Future<void> load() async {
    final saved = (await SharedPreferences.getInstance()).getString(_key);
    value = ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
  }

  Future<void> set(ThemeMode mode) async {
    value = mode;
    await (await SharedPreferences.getInstance()).setString(_key, mode.name);
  }
}
