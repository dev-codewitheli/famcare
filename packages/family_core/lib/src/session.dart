import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'auth.dart';
import 'family_api.dart';
import 'models.dart';

enum SessionStatus { loading, signedOut, needsFamily, ready, error }

/// App-wide sign-in and family state. The apps route on [status].
class Session extends ChangeNotifier {
  Session({required this.auth, required this.familyApi, this.onReady});

  final AuthService auth;
  final FamilyApi familyApi;

  /// Runs each time the family loads, e.g. to register for pushes.
  final Future<void> Function(Family family)? onReady;

  SessionStatus _status = SessionStatus.loading;
  Family? _family;
  String? _error;

  SessionStatus get status => _status;
  Family? get family => _family;
  String? get error => _error;

  static const _memberIdKey = 'member_id';

  /// This phone's member id, readable from push handlers in a background isolate.
  static Future<String?> storedMemberId() async =>
      (await SharedPreferences.getInstance()).getString(_memberIdKey);

  Future<void> start() async {
    await auth.restore();
    await refresh();
  }

  Future<void> refresh() async {
    if (auth.uid == null) return _set(SessionStatus.signedOut);
    try {
      await _ready(await familyApi.mine());
    } on ApiException catch (e) {
      if (e.code == 'NOT_IN_FAMILY') return _set(SessionStatus.needsFamily);
      if (e.statusCode == 401) return signOut();
      _set(SessionStatus.error, e.message);
    } catch (e) {
      debugPrint('Session refresh failed: $e');
      _set(SessionStatus.error, "Can't reach the server. Check your connection.");
    }
  }

  Future<void> createFamily({required String familyName, required String displayName}) async =>
      _ready(await familyApi.create(familyName: familyName, displayName: displayName));

  Future<void> joinFamily({required String inviteCode, required String displayName}) async =>
      _ready(await familyApi.join(inviteCode: inviteCode, displayName: displayName));

  Future<void> signOut() async {
    await auth.signOut();
    await (await SharedPreferences.getInstance()).remove(_memberIdKey);
    _family = null;
    _set(SessionStatus.signedOut);
  }

  Future<void> _ready(Family family) async {
    _family = family;
    await (await SharedPreferences.getInstance()).setString(_memberIdKey, family.me.id);
    _set(SessionStatus.ready);
    await onReady?.call(family);
  }

  void _set(SessionStatus status, [String? error]) {
    _status = status;
    _error = error;
    notifyListeners();
  }
}
