import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'family_api.dart';

/// Keeps the server's copy of this phone's FCM token current, so family pushes reach it.
class PushRegistration {
  PushRegistration(this._familyApi);

  final FamilyApi _familyApi;
  StreamSubscription<String>? _refreshes;

  /// Never throws: a push problem must not lock the user out of the app (it still works
  /// while open, by polling). Failures are logged, and the next start or refresh retries.
  Future<void> start() async {
    _refreshes ??= FirebaseMessaging.instance.onTokenRefresh.listen(_register);
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(token);
    } catch (e) {
      debugPrint('Push token unavailable: $e');
    }
  }

  /// Before signing out: this phone stops getting the family's pushes. Best effort (offline
  /// sign-out still works; the server then drops the token the next time FCM rejects it).
  Future<void> stop() async {
    await _refreshes?.cancel();
    _refreshes = null;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _familyApi.unregisterDevice(token);
    } catch (e) {
      debugPrint('Push token unregistration failed: $e');
    }
  }

  Future<void> _register(String token) async {
    try {
      await _familyApi.registerDevice(token);
    } catch (e) {
      // Not fatal: the next app start or token refresh registers again.
      debugPrint('Push token registration failed: $e');
    }
  }
}
