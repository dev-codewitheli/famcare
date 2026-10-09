import 'package:family_core/family_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'ring_settings.dart';

/// Turns gate pushes into what each phone should do: ring like an alarm, tell the
/// sender who's coming, show an "on my way" heads-up, or go quiet. Runs in the app and in
/// the background push isolate.
class GateNotifications {
  GateNotifications._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const comingActionId = 'coming';
  static const gotItActionId = 'got_it';
  static const ringNowActionId = 'ring_now';
  static const addTimeActionId = 'add_time';
  static const notComingActionId = 'not_coming';

  /// How much "+ time" the reminder's button adds.
  static const addTimeMinutes = 5;

  /// Notification payloads: a gate ring carries just its alert id; heads-ups carry a prefix.
  static const headsUpPayloadPrefix = 'arrival:';
  static const duePayloadPrefix = 'arrival-due:';

  /// Notification taps and "Coming!" presses while the app is running; HomeScreen consumes them.
  static final responses = ValueNotifier<NotificationResponse?>(null);

  // Android fixes a channel's sound, audio usage and DND behavior when it's first created,
  // so changing them later needs a new channel id.
  static const ringChannelId = 'gate_ring_v1';
  static const ringDndChannelId = 'gate_ring_dnd_v1';
  static const _updatesChannelId = 'gate_updates_v1';
  static const _arrivalsChannelId = 'arrivals_v1';

  static final _alarmSound = UriAndroidNotificationSound('content://settings/system/alarm_alert');
  static final _vibration = Int64List.fromList([0, 800, 400, 800, 400, 800]);

  /// Android's FLAG_INSISTENT: repeat the sound until the notification is answered or dismissed.
  static const _flagInsistent = 4;

  static Future<void> init({bool inForeground = true}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_bell'),
      ),
      onDidReceiveNotificationResponse: inForeground ? (r) => responses.value = r : null,
    );
    final android = _android;
    await android?.createNotificationChannel(_ringChannel(ringChannelId, bypassDnd: false));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _updatesChannelId,
      'Gate updates',
      description: "Who's coming to open the gate",
      importance: Importance.high,
    ));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _arrivalsChannelId,
      'On my way',
      description: 'A family member will be at the gate soon',
      importance: Importance.high,
    ));
  }

  static AndroidNotificationChannel _ringChannel(String id, {required bool bypassDnd}) =>
      AndroidNotificationChannel(
        id,
        bypassDnd ? 'Gate rings (through Silent / DND)' : 'Gate rings',
        description: 'Someone in the family is waiting at the gate',
        importance: Importance.max,
        bypassDnd: bypassDnd,
        sound: _alarmSound,
        vibrationPattern: _vibration,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

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

  /// "Do Not Disturb access": lets a channel be marked as allowed through DND.
  static Future<bool> hasDndAccess() async => await _android?.hasNotificationPolicyAccess() ?? false;

  /// Opens the system's DND-access list; the user switches HomeBell on there.
  static Future<void> requestDndAccess() async => _android?.requestNotificationPolicyAccess();

  /// Creates the DND-bypassing ring channel. Android only honors "bypass DND" for a channel
  /// created while the app has DND access, so this runs right after access is granted.
  static Future<void> ensureDndChannel() async {
    if (await hasDndAccess()) {
      await _android?.createNotificationChannel(_ringChannel(ringDndChannelId, bypassDnd: true));
    }
  }

  /// Handles a data push from the server (see PushMessage on the server side).
  static Future<void> handlePush(Map<String, dynamic> data) async {
    final type = data['type'];
    switch (type) {
      case 'ARRIVAL_HEADS_UP':
        return _showArrival(data);
      case 'ARRIVAL_SEEN':
        return _showSeen(data);
      case 'ARRIVAL_DUE':
        return _showDue(data);
      case 'ARRIVAL_CANCELLED':
        return cancelHeadsUp(data['senderName'] as String? ?? '');
      case 'MEMBER_REMOVED':
        return _showUpdate('removed', 'You were removed from the family',
            'You won\'t get gate rings anymore. Ask for the invite code to join again.');
    }

    final alertId = data['alertId'] as String?;
    if (alertId == null) return;
    final isSender = data['senderId'] == await Session.storedMemberId();

    switch (type) {
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

  static Future<void> showRing({required String alertId, required String senderName}) async {
    final throughDnd = await RingSettings.ringThroughDnd() && await hasDndAccess();
    final channelId = throughDnd ? ringDndChannelId : ringChannelId;
    return _plugin.show(
      id: _id(alertId),
      title: '$senderName is at the gate',
      body: 'Tap "Coming!" so they know someone is on the way.',
      payload: alertId,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          throughDnd ? 'Gate rings (through Silent / DND)' : 'Gate rings',
          importance: Importance.max,
          priority: Priority.max,
          channelBypassDnd: throughDnd,
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

  static Future<void> _showArrival(Map<String, dynamic> data) {
    final name = data['senderName'] as String? ?? 'Someone';
    final minutes = data['etaMinutes'] as String? ?? '?';
    return _plugin.show(
      // One heads-up per person: a newer ETA replaces the older notification.
      id: _id('$headsUpPayloadPrefix$name'),
      title: '$name is on the way',
      body: 'About $minutes min away. Get ready to open the gate.',
      payload: '$headsUpPayloadPrefix${data['noticeId']}',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _arrivalsChannelId,
          'On my way',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.status,
          actions: [AndroidNotificationAction(gotItActionId, 'Got it', showsUserInterface: true)],
        ),
      ),
    );
  }

  /// To the person on their way: someone tapped "Got it".
  static Future<void> _showSeen(Map<String, dynamic> data) {
    final name = data['seenByName'] as String? ?? 'Someone';
    return _plugin.show(
      id: _id('seen:${data['noticeId']}:$name'),
      title: '$name saw your heads-up',
      body: 'They know you\'re on your way.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(_arrivalsChannelId, 'On my way',
            importance: Importance.high, priority: Priority.high, category: AndroidNotificationCategory.status),
      ),
    );
  }

  /// To the person on their way, at the time they gave: ring now, or add time if delayed.
  static Future<void> _showDue(Map<String, dynamic> data) {
    return _plugin.show(
      id: _id('due'),
      title: 'Time\'s up. Are you at the gate?',
      body: 'Ring the family, add $addTimeMinutes minutes if you\'re running late, or let them know '
          'you\'re not coming.',
      payload: '$duePayloadPrefix${data['noticeId']}',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _arrivalsChannelId,
          'On my way',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          // Three buttons fit; ringing from here saves opening the app at the gate.
          actions: [
            AndroidNotificationAction(ringNowActionId, 'I\'m here', showsUserInterface: true),
            AndroidNotificationAction(addTimeActionId, '+$addTimeMinutes min', showsUserInterface: true),
            AndroidNotificationAction(notComingActionId, 'Not coming', showsUserInterface: true),
          ],
          // Gone on its own once the heads-up expires.
          timeoutAfter: 10 * 60 * 1000,
        ),
      ),
    );
  }

  static Future<void> cancelDueReminder() => _plugin.cancel(id: _id('due'));

  /// Clears a heads-up notification after "Got it", whichever person it was from.
  static Future<void> cancelHeadsUp(String senderName) => _plugin.cancel(id: _id('$headsUpPayloadPrefix$senderName'));

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

  static int _id(String key) => key.hashCode & 0x7fffffff;
}
