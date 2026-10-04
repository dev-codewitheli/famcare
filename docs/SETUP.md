# Setup: Firebase + production

Use a **personal** Google account for the Firebase project, not a work account.

## 1. Firebase project
1. Go to <https://console.firebase.google.com> → **Add project** (e.g. `famcare`). Google
   Analytics isn't needed.
2. **Authentication → Sign-in method → Google → Enable.**
3. **Project settings → Your apps → Add app → Android**
   - Package name: `com.devcodewitheli.homebell`
   - Debug signing certificate SHA-1: get it with
     `cd apps/homebell/android && ./gradlew signingReport` (look for `Variant: debug`).
4. Download **`google-services.json`** to `apps/homebell/android/app/`.
   It's gitignored. The Android build picks it up automatically when present.
5. Cloud Messaging (FCM) is enabled by default for new projects.

## 2. Server credentials
**Project settings → Service accounts → Generate new private key.** Save the JSON
**outside the repo** (e.g. `~/secrets/famcare-firebase.json`). It's a secret: it can send
pushes and verify tokens as your project.

## 3. Run with Firebase locally
```bash
# Server: real token verification + real pushes, still on in-memory H2
cd server
SPRING_PROFILES_ACTIVE=firebase FIREBASE_CREDENTIALS_FILE=~/secrets/famcare-firebase.json ./gradlew bootRun

# App: on a real phone on the same Wi-Fi (use your PC's LAN IP)
cd apps/homebell
flutter run --dart-define=AUTH_MODE=firebase --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

## 4. Production
- Profiles: `SPRING_PROFILES_ACTIVE=postgres,firebase`
- Env: `DATABASE_URL` (`jdbc:postgresql://…`), `DATABASE_USERNAME`, `DATABASE_PASSWORD`,
  `FIREBASE_CREDENTIALS_FILE` (mount the key as a secret file)
- Local Postgres for testing: `cd server && docker compose up -d`
- The app talks to an **HTTPS** URL in release builds (plain HTTP is allowed only in debug builds).

## 5. Distribute to the family
**Firebase App Distribution**: upload the release APK, add family members' emails as testers.
They get an install link and update notifications. No Play Store needed.

```bash
flutter build apk --release --dart-define=AUTH_MODE=firebase --dart-define=API_BASE_URL=https://<your-server>
```

On each phone, open HomeBell → shield icon → fix every item on the reliability checklist.
