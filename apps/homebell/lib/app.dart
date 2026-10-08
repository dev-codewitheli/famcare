import 'package:family_core/family_core.dart';
import 'package:flutter/material.dart';

import 'gate/gate_api.dart';
import 'home/home_screen.dart';

class HomeBellApp extends StatelessWidget {
  const HomeBellApp({super.key, required this.config, required this.session, required this.gateApi});

  final AppConfig config;
  final Session session;
  final GateApi gateApi;

  static const _brand = Color(0xFFE07A1F);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeBell',
      debugShowCheckedModeBanner: false,
      theme: FamilyTheme.light(_brand),
      darkTheme: FamilyTheme.dark(_brand),
      home: ListenableBuilder(
        listenable: session,
        builder: (context, _) => switch (session.status) {
          SessionStatus.loading => const Scaffold(body: Center(child: CircularProgressIndicator())),
          SessionStatus.signedOut => SignInScreen(
              session: session,
              appName: 'HomeBell',
              tagline: "Ring the family when you're at the gate.",
              icon: Icons.notifications_active_rounded,
              highlights: const [
                SignInHighlight(Icons.ring_volume_rounded, 'One tap rings every phone at home, even locked'),
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
