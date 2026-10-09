import 'dart:ui';

import 'package:family_core/family_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'gate_api.dart';
import 'gate_notifications.dart';

/// Runs in a background isolate when a push arrives while the app is closed or in the
/// background. Server pushes are data-only + high priority, so this always runs and
/// we decide how to present it (a ringing alarm notification, not a quiet one).
@pragma('vm:entry-point')
Future<void> onBackgroundGatePush(RemoteMessage message) async {
  await GateNotifications.init(inForeground: false);
  await GateNotifications.handlePush(message.data);
}

/// "Coming!" tapped on a ring notification, e.g. on the lock screen: answers without opening
/// (or unlocking) the app. Runs in a background isolate, and the notification is already gone,
/// so the ring stops at once.
@pragma('vm:entry-point')
Future<void> onBackgroundNotificationAction(NotificationResponse response) async {
  final alertId = response.payload;
  if (response.actionId != GateNotifications.comingActionId || alertId == null || alertId == 'test') return;
  DartPluginRegistrant.ensureInitialized();
  try {
    final config = AppConfig.fromEnvironment();
    final AuthService auth;
    if (config.usesFirebase) {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      auth = FirebaseAuthService();
    } else {
      auth = DemoAuthService();
    }
    await auth.restore();
    await GateApi(ApiClient(baseUrl: config.apiBaseUrl, token: auth.idToken)).acknowledge(alertId);
  } on ApiException catch (e) {
    // Someone else answered first, or the person got in: nothing left to do.
    if (e.statusCode != 409 && e.statusCode != 404) await _comingFailed(alertId);
  } catch (_) {
    await _comingFailed(alertId);
  }
}

Future<void> _comingFailed(String alertId) async {
  await GateNotifications.init(inForeground: false);
  await GateNotifications.showComingFailed(alertId);
}
