import 'package:flutter/material.dart';

/// One look for the family apps; each app passes its own accent color.
class FamilyTheme {
  FamilyTheme._();

  static ThemeData light(Color seed) => _build(seed, Brightness.light);

  static ThemeData dark(Color seed) => _build(seed, Brightness.dark);

  static ThemeData _build(Color seed, Brightness brightness) {
    final colors = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final base = ThemeData(colorScheme: colors, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48), shape: const StadiumBorder()),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      chipTheme: base.chipTheme.copyWith(shape: const StadiumBorder()),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

/// A round initial avatar with a stable color per person.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.name, this.radius = 22});

  final String name;
  final double radius;

  static const _palette = [
    Color(0xFFE07A1F), Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFF8B5CF6),
    Color(0xFFEF4444), Color(0xFF0EA5E9), Color(0xFFF59E0B), Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    // A small polynomial hash spreads similar names across the palette (a plain sum gave
    // "Papa" and "Ate" the same color).
    final hash = name.toLowerCase().codeUnits.fold(7, (a, b) => (a * 31 + b) & 0x7fffffff);
    final color = _palette[hash % _palette.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.18),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: radius * 0.8),
      ),
    );
  }
}
