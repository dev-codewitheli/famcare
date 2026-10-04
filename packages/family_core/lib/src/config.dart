/// How the app proves who the user is.
enum AuthMode {
  /// No Firebase project needed: you type a demo user id and the server (in demo
  /// mode) trusts it. For local development and the portfolio demo only.
  demo,

  /// Google sign-in through Firebase Authentication; the server verifies the ID token.
  firebase,
}

/// Build-time configuration, passed with `--dart-define`:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=https://famcare.example.com --dart-define=AUTH_MODE=firebase
/// ```
class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.authMode});

  factory AppConfig.fromEnvironment() {
    // 10.0.2.2 is the host machine as seen from the Android emulator.
    const url = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080');
    const mode = String.fromEnvironment('AUTH_MODE', defaultValue: 'demo');
    return AppConfig(
      apiBaseUrl: Uri.parse(url),
      authMode: mode == 'firebase' ? AuthMode.firebase : AuthMode.demo,
    );
  }

  final Uri apiBaseUrl;
  final AuthMode authMode;

  bool get usesFirebase => authMode == AuthMode.firebase;
}
