import 'package:firebase_messaging/firebase_messaging.dart';

import 'gate_notifications.dart';

/// Runs in a background isolate when a push arrives while the app is closed or in the
/// background. Server pushes are data-only + high priority, so this always runs and
/// we decide how to present it (a ringing full-screen alarm, not a quiet notification).
@pragma('vm:entry-point')
Future<void> onBackgroundGatePush(RemoteMessage message) async {
  await GateNotifications.init(inForeground: false);
  await GateNotifications.handlePush(message.data);
}
