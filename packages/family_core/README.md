# family_core

Shared by the HomeBell and FamCare apps:

- `AppConfig`: build-time config (`API_BASE_URL`, `AUTH_MODE`) via `--dart-define`
- `AuthService`: Firebase Google sign-in, or demo ids for local development
- `Session`: sign-in and family state that the apps route on
- `ApiClient` / `FamilyApi`: FamCare server client (RFC 9457 errors → `ApiException`)
- `PushRegistration`: keeps the server's copy of this phone's FCM token current
- Screens: `SignInScreen`, `OnboardingScreen` (create/join a family), `FamilyScreen`
