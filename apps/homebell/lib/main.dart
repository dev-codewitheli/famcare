import 'package:family_core/family_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  );
  session.start();

  runApp(HomeBellApp(config: config, session: session, gateApi: GateApi(api)));
}
