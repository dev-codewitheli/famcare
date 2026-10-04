import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'family_api.dart';

/// Keeps the server's copy of this phone's FCM token current, so family pushes reach it.
class PushRegistration {
  PushRegistration(this._familyApi);

  final FamilyApi _familyApi;
  StreamSubscription<String>? _refreshes;

  Future<void> start() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _register(token);
    _refreshes ??= FirebaseMessaging.instance.onTokenRefresh.listen(_register);
  }

  Future<void> stop() async {
    await _refreshes?.cancel();
    _refreshes = null;
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
