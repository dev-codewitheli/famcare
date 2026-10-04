# Deploy: Render + Neon

The server runs as a free Docker web service on **Render** (Singapore region), with
**Neon** for PostgreSQL. Both have free tiers that cover a family-sized app.

## 1. Database (Neon)
1. Sign in at <https://neon.tech> (GitHub sign-in is fine) → **New project**
   - Name: `famcare`, Postgres version: latest, Region: **AWS Asia Pacific (Singapore)**.
2. On the project dashboard, click **Connect** and copy the connection details. Neon shows a URL like
   `postgresql://USER:PASSWORD@ep-xxxx.ap-southeast-1.aws.neon.tech/neondb?sslmode=require`.
   Split it into the three values Render needs:

   | Render variable | Value |
   |---|---|
   | `DATABASE_URL` | `jdbc:postgresql://ep-xxxx.ap-southeast-1.aws.neon.tech/neondb?sslmode=require` |
   | `DATABASE_USERNAME` | `USER` |
   | `DATABASE_PASSWORD` | `PASSWORD` |

   Flyway creates the tables on the first start. There's nothing to run by hand.

## 2. Server (Render)
1. <https://dashboard.render.com> → **New → Blueprint** → connect `dev-codewitheli/famcare`.
   Render reads `render.yaml` and proposes the `famcare-server` service.
2. Fill in the three `DATABASE_*` values when asked, then **Apply**.
3. Open the service → **Environment → Secret Files → Add**:
   - Filename: `firebase-service-account.json`
   - Contents: paste the whole Firebase service-account key JSON.
   Save; Render redeploys.
4. Check `https://<your-service>.onrender.com/actuator/health` shows `{"status":"UP"}`.

## 3. Keep it awake
Render's free tier sleeps after 15 minutes without traffic. A sleeping server delays the
first ring by about 50 s and pauses re-rings. Use a free uptime monitor, such as
<https://cron-job.org> or UptimeRobot, to request `/actuator/health/liveness` every 10 minutes.
That endpoint doesn't query the database, so Neon still scales to zero between uses.
One always-on service fits within Render's free monthly hours.

## 4. Release APK
Release builds are signed with the key referenced by `apps/homebell/android/key.properties`
(gitignored). The keystore lives outside the repo; **back it up**. Without it, installed
copies can't be updated.

Add the release key's SHA-1 in Firebase (**Project settings → Your apps → HomeBell →
Add fingerprint**) so Google sign-in works in release builds.

```bash
cd apps/homebell
flutter build apk --release --split-per-abi \
  --dart-define=AUTH_MODE=firebase \
  --dart-define=API_BASE_URL=https://<your-service>.onrender.com
```

Share `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (modern phones) through
Firebase App Distribution or directly.
