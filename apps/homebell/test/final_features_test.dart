import 'package:family_core/family_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homebell/home/home_widgets.dart';
import 'package:homebell/settings/theme_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('"Other" minutes: step and send any value from 1 to 60', (tester) async {
    int? sent;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => sent = await showDialog<int>(
            context: context,
            builder: (_) => const MinutesDialog(title: 'How many minutes away?', initial: 59),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('1 minute more'));
    await tester.pump();
    expect(find.text('60 min'), findsOneWidget);
    // Can't go past the server's limit.
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add_rounded)).onPressed, isNull);

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(sent, 60);
  });

  test('theme choice is remembered, and defaults to following the phone', () async {
    SharedPreferences.setMockInitialValues({});
    await ThemePreference.instance.load();
    expect(ThemePreference.instance.value, ThemeMode.system);

    await ThemePreference.instance.set(ThemeMode.dark);
    await ThemePreference.instance.load();
    expect(ThemePreference.instance.value, ThemeMode.dark);
  });

  testWidgets('a member icon replaces the initial; unknown icons fall back to it', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Column(children: [
        MemberAvatar(name: 'Mama', avatar: 'mother'),
        MemberAvatar(name: 'Kuya', avatar: 'from-a-newer-app'),
      ]),
    ));
    expect(find.text('👩'), findsOneWidget);
    expect(find.text('K'), findsOneWidget);
  });
}
