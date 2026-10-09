import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'auth.dart';
import 'family_api.dart';
import 'models.dart';

enum SessionStatus { loading, signedOut, needsFamily, ready, error }

/// App-wide sign-in and family state. The apps route on [status].
class Session extends ChangeNotifier {
  Session({required this.auth, required this.familyApi, this.onReady, this.beforeSignOut});

  final AuthService auth;
  final FamilyApi familyApi;

  /// Runs each time the family loads, e.g. to register for pushes.
  final Future<void> Function(Family family)? onReady;

  /// Runs while still signed in, e.g. so this phone stops getting the family's pushes.
  final Future<void> Function()? beforeSignOut;

  SessionStatus _status = SessionStatus.loading;
  Family? _family;
  String? _error;

  SessionStatus get status => _status;
  Family? get family => _family;
  String? get error => _error;

  static const _memberIdKey = 'member_id';

  /// This phone's member id, readable from push handlers in a background isolate. Reloads first:
  /// each isolate caches preferences, and the app may have changed it since.
  static Future<String?> storedMemberId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString(_memberIdKey);
  }

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

  /// Re-reads the family (someone joined, left or was renamed) without leaving the screen on a
  /// network error; only a removal or expired sign-in goes through the full [refresh].
  Future<void> refreshQuietly() async {
    if (_family == null) return;
    try {
      _update(await familyApi.mine());
    } on ApiException catch (e) {
      if (e.code == 'NOT_IN_FAMILY' || e.statusCode == 401) await refresh();
    } catch (_) {
      // Offline: keep what we have.
    }
  }

  Future<void> createFamily({required String familyName, required String displayName}) async =>
      _ready(await familyApi.create(familyName: familyName, displayName: displayName));

  Future<void> joinFamily({required String inviteCode, required String displayName}) async =>
      _ready(await familyApi.join(inviteCode: inviteCode, displayName: displayName));

  /// Change what the family calls me and/or my icon (an empty [avatar] goes back to my initial).
  Future<void> updateMe({String? displayName, String? avatar}) async =>
      _update(await familyApi.updateMe(displayName: displayName, avatar: avatar));

  /// Family creator only; the server answers 403 for anyone else.
  Future<void> renameFamily(String familyName) async => _update(await familyApi.renameFamily(familyName));

  /// Family creator only.
  Future<void> removeMember(String memberId) async => _update(await familyApi.removeMember(memberId));

  /// Whether I'm the one who set up the family (and may rename it or remove members).
  bool get isCreator => _family?.me.role == MemberRole.parent;

  void _update(Family family) {
    _family = family;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_family != null) await beforeSignOut?.call();
    await _signOutLocally();
  }

  /// Leave the family but stay signed in (back to the join/create screen).
  Future<void> leaveFamily() async {
    await familyApi.leave();
    await (await SharedPreferences.getInstance()).remove(_memberIdKey);
    _family = null;
    _set(SessionStatus.needsFamily);
  }

  /// Family creator only.
  Future<void> resetInviteCode() async => _update(await familyApi.resetInviteCode());

  /// Deletes the account on the server (which also forgets this phone), then signs out here.
  Future<void> deleteAccount() async {
    await familyApi.deleteAccount();
    await _signOutLocally();
  }

  Future<void> _signOutLocally() async {
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
