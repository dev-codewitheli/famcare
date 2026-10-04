import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Who is signed in on this phone. Works in background isolates too (push handlers),
/// as long as [restore] is called first.
abstract class AuthService {
  /// The signed-in user's id, or null when signed out.
  String? get uid;

  /// Loads a persisted sign-in, if any.
  Future<void> restore();

  /// The bearer token for API calls.
  Future<String?> idToken();

  Future<void> signOut();
}

/// Google sign-in via Firebase Authentication.
class FirebaseAuthService implements AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  String? get uid => _auth.currentUser?.uid;

  /// Suggested nickname for onboarding (first name from the Google account).
  String? get suggestedName => _auth.currentUser?.displayName?.split(' ').first;

  @override
  Future<void> restore() async {
    // Firebase restores the session itself; wait for its first auth event.
    await _auth.authStateChanges().first;
  }

  Future<void> signInWithGoogle() => _auth.signInWithProvider(GoogleAuthProvider());

  @override
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();

  @override
  Future<void> signOut() => _auth.signOut();
}

/// Demo mode: the user id typed on the sign-in screen is the bearer token.
/// Pairs with the server's demo profile — never use it with real data.
class DemoAuthService implements AuthService {
  static const _key = 'demo_user_id';

  String? _uid;

  @override
  String? get uid => _uid;

  @override
  Future<void> restore() async {
    _uid = (await SharedPreferences.getInstance()).getString(_key);
  }

  Future<void> signIn(String userId) async {
    _uid = userId.trim().toLowerCase();
    await (await SharedPreferences.getInstance()).setString(_key, _uid!);
  }

  @override
  Future<String?> idToken() async => _uid;

  @override
  Future<void> signOut() async {
    _uid = null;
    await (await SharedPreferences.getInstance()).remove(_key);
  }
}
