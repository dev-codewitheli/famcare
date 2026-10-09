import 'package:family_core/family_core.dart';
import 'package:flutter/material.dart';

import 'gate/gate_api.dart';
import 'home/home_screen.dart';
import 'settings/theme_preference.dart';

class HomeBellApp extends StatelessWidget {
  const HomeBellApp({super.key, required this.config, required this.session, required this.gateApi});

  final AppConfig config;
  final Session session;
  final GateApi gateApi;

  static const _brand = Color(0xFFE07A1F);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ThemePreference.instance,
      builder: (context, themeMode, _) => _app(themeMode),
    );
  }

  Widget _app(ThemeMode themeMode) {
    return MaterialApp(
      title: 'HomeBell',
      debugShowCheckedModeBanner: false,
      theme: FamilyTheme.light(_brand),
      darkTheme: FamilyTheme.dark(_brand),
      themeMode: themeMode,
      // Phones fill the screen; on tablets, keep a readable column instead of stretching.
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: child),
        ),
      ),
      home: ListenableBuilder(
        listenable: session,
        builder: (context, _) => switch (session.status) {
          // Continues the native splash (orange, white bell) while the session loads.
          SessionStatus.loading => const Scaffold(
              backgroundColor: _brand,
              body: Center(child: Icon(Icons.notifications_active_rounded, size: 96, color: Colors.white)),
            ),
          SessionStatus.signedOut => SignInScreen(
              session: session,
              appName: 'HomeBell',
              tagline: "Ring the family when you're at the gate.",
              icon: Icons.notifications_active_rounded,
              highlights: const [
                SignInHighlight(Icons.ring_volume_rounded, "One tap rings the family's phones, even locked"),
                SignInHighlight(Icons.directions_run_rounded, 'See who\'s coming to open the gate'),
                SignInHighlight(Icons.lock_rounded, 'Private: your family only sees a nickname'),
              ],
            ),
          SessionStatus.needsFamily => OnboardingScreen(session: session),
          SessionStatus.ready => HomeScreen(
              // A new key per family/member resets the screen's state after switching accounts.
              key: ValueKey(session.family!.me.id),
              session: session,
              gateApi: gateApi,
              usesPush: config.usesFirebase,
            ),
          SessionStatus.error => _ErrorScreen(message: session.error!, onRetry: session.refresh),
        },
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
