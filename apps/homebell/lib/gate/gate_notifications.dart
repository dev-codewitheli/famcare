import 'package:family_core/family_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Turns gate pushes into what each phone should do: ring like an alarm, tell the
/// sender who's coming, or go quiet. Runs in the app and in the background push isolate.
class GateNotifications {
  GateNotifications._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const comingActionId = 'coming';

  /// Notification taps and "Coming!" presses while the app is running; HomeScreen consumes them.
  static final responses = ValueNotifier<NotificationResponse?>(null);

  // Android fixes a channel's sound and audio usage when it's first created, so changing
  // them later needs a new channel id.
  static const _ringChannelId = 'gate_ring_v1';
  static const _updatesChannelId = 'gate_updates_v1';

  static final _alarmSound = UriAndroidNotificationSound('content://settings/system/alarm_alert');
  static final _vibration = Int64List.fromList([0, 800, 400, 800, 400, 800]);

  /// Android's FLAG_INSISTENT: repeat the sound until the notification is answered or dismissed.
  static const _flagInsistent = 4;

  static Future<void> init({bool inForeground = true}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: inForeground ? (r) => responses.value = r : null,
    );
    final android = _android;
    await android?.createNotificationChannel(AndroidNotificationChannel(
      _ringChannelId,
      'Gate rings',
      description: 'Someone in the family is waiting at the gate',
      importance: Importance.max,
      sound: _alarmSound,
      vibrationPattern: _vibration,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _updatesChannelId,
      'Gate updates',
      description: "Who's coming to open the gate",
      importance: Importance.high,
    ));
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// The tap that launched the app from a terminated state, if any.
  static Future<NotificationResponse?> launchResponse() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true ? details!.notificationResponse : null;
  }

  static Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  static Future<bool> areEnabled() async => await _android?.areNotificationsEnabled() ?? false;

  static Future<void> requestFullScreenPermission() async =>
      _android?.requestFullScreenIntentPermission();

  /// Handles a data push from the server (see PushMessage on the server side).
  static Future<void> handlePush(Map<String, dynamic> data) async {
    final alertId = data['alertId'] as String?;
    if (alertId == null) return;
    final isSender = data['senderId'] == await Session.storedMemberId();

    switch (data['type']) {
      case 'GATE_RING':
        if (!isSender) await showRing(alertId: alertId, senderName: data['senderName'] as String? ?? 'Someone');
      case 'GATE_ACKNOWLEDGED':
        await _cancel(alertId);
        if (isSender) {
          await _showUpdate(alertId, '${data['acknowledgedByName'] ?? 'Someone'} is coming!',
              'Hang tight, the gate will be opened soon.');
        }
      case 'GATE_EXPIRED':
        await _cancel(alertId);
        if (isSender) await _showUpdate(alertId, 'Nobody answered', 'Try calling someone at home.');
      case 'GATE_CANCELLED':
        await _cancel(alertId);
    }
  }

  static Future<void> showRing({required String alertId, required String senderName}) {
    return _plugin.show(
      id: _id(alertId),
      title: '$senderName is at the gate',
      body: 'Tap "Coming!" so they know someone is on the way.',
      payload: alertId,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _ringChannelId,
          'Gate rings',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          sound: _alarmSound,
          vibrationPattern: _vibration,
          additionalFlags: Int32List.fromList([_flagInsistent]),
          ongoing: true,
          autoCancel: false,
          visibility: NotificationVisibility.public,
          // Safety net in case the "stop ringing" push is lost: the server gives up after ~2 minutes.
          timeoutAfter: const Duration(minutes: 3).inMilliseconds,
          actions: const [
            AndroidNotificationAction(comingActionId, 'Coming!', showsUserInterface: true),
          ],
        ),
      ),
    );
  }

  static Future<void> _showUpdate(String alertId, String title, String body) {
    return _plugin.show(
      // Same id as the ring, so it replaces any leftover ring notification.
      id: _id(alertId),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(_updatesChannelId, 'Gate updates',
            importance: Importance.high, priority: Priority.high),
      ),
    );
  }

  static Future<void> cancelRing(String alertId) => _cancel(alertId);

  static Future<void> _cancel(String alertId) => _plugin.cancel(id: _id(alertId));

  static int _id(String alertId) => alertId.hashCode & 0x7fffffff;
}
