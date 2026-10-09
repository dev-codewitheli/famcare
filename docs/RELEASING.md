# Releasing HomeBell

Pushing a version tag builds the signed APKs on GitHub Actions and publishes them as a
GitHub Release (`.github/workflows/release.yml`).

```bash
# 1. Bump `version:` in apps/homebell/pubspec.yaml (e.g. 0.4.0+5) and commit it.
# 2. Tag and push:
git tag v0.4.0
git push origin v0.4.0
```

The release appears under **Releases** with `HomeBell-<version>-arm64.apk` (most phones) and
`-arm32.apk` (older phones). The portfolio card's download link always points at the latest one.

## One-time setup: repository secrets

The workflow needs the same two files you keep locally (outside git), stored as secrets in
**GitHub → famcare → Settings → Secrets and variables → Actions → New repository secret**.

| Secret | Value |
|---|---|
| `GOOGLE_SERVICES_JSON` | `apps/homebell/android/app/google-services.json`, base64-encoded |
| `KEYSTORE_BASE64` | the release keystore (`C:\Users\Eli\secrets\homebell-release.jks`), base64-encoded |
| `KEYSTORE_PASSWORD` | the `storePassword` value from `apps/homebell/android/key.properties` |

Copy each value to the clipboard without printing it, then paste it into GitHub. Run these in
PowerShell from the repository root. (`[IO.File]` resolves relative paths against the process
folder, not PowerShell's location, hence `$PWD`.)

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$PWD\apps\homebell\android\app\google-services.json")) | Set-Clipboard
```

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\Users\Eli\secrets\homebell-release.jks")) | Set-Clipboard
```

```powershell
(Select-String -Path "apps\homebell\android\key.properties" -Pattern "^storePassword=").Line.Split("=", 2)[1] | Set-Clipboard
```

Optional repository **variable** (not secret) `HOMEBELL_API_BASE_URL` overrides the server URL
(default `https://famcare-server.onrender.com`).

**Google sign-in needs the release key's fingerprints in Firebase** (Project settings → Your
apps → HomeBell → Add fingerprint), besides the debug ones from SETUP.md:

- SHA-1 `A7:6A:45:C0:A4:E3:D1:9D:09:3A:D8:AF:21:0D:7B:4F:E8:71:97:96`
- SHA-256 `20:75:39:1A:EB:00:18:CB:9C:EF:83:29:B0:36:7D:89:A6:40:6B:5D:71:19:91:7E:0B:03:4D:3E:D3:CC:A9:64`

**The keystore must never change.** Android only installs an update over an existing app if
it's signed with the same key, so keep `homebell-release.jks` backed up.
