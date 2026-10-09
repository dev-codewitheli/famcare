import 'package:family_core/family_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'gate/gate_api.dart';
import 'gate/gate_notifications.dart';
import 'gate/gate_push_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  await GateNotifications.init();

  final AuthService auth;
  if (config.usesFirebase) {
    // Reads android/app/google-services.json (kept out of git).
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(onBackgroundGatePush);
    await _reportCrashes();
    auth = FirebaseAuthService();
  } else {
    auth = DemoAuthService();
  }

  final api = ApiClient(baseUrl: config.apiBaseUrl, token: auth.idToken);
  final familyApi = FamilyApi(api);
  final push = config.usesFirebase ? PushRegistration(familyApi) : null;

  final session = Session(
    auth: auth,
    familyApi: familyApi,
    onReady: (_) async => push?.start(),
    // A signed-out phone must stop ringing for that family.
    beforeSignOut: () async => push?.stop(),
  );
  session.start();

  runApp(HomeBellApp(config: config, session: session, gateApi: GateApi(api)));
}

/// Release builds send crashes to Firebase Crashlytics (no personal data: stack traces only).
Future<void> _reportCrashes() async {
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(kReleaseMode);
  if (!kReleaseMode) return;
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
