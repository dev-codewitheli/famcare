import 'package:flutter/services.dart';

/// Plays the gate ring on the alarm stream, like an alarm clock: Silent and vibrate modes don't
/// mute it (a notification's own sound is muted there, whatever its channel says). Runs as an
/// Android foreground service, so it keeps ringing while the app is in the background and stops
/// by itself after [maxDuration].
///
/// Works from any isolate (app, push handler, notification actions): they share one service.
class RingAlarm {
  RingAlarm._();

  static const _channel = MethodChannel('homebell/ring_alarm');

  /// Safety net if the "stop" push is lost; the server gives up on a ring after about 2 minutes.
  static const maxDuration = Duration(minutes: 3);

  /// Starts ringing (no-op if already ringing). [title] shows in the service's notification.
  static Future<void> start({required String title}) =>
      _channel.invokeMethod('start', {'title': title, 'maxMillis': maxDuration.inMilliseconds});

  static Future<void> stop() => _channel.invokeMethod('stop');
}
