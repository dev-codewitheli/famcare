# Roadmap

## v0.1: HomeBell MVP (current)
- [x] Family groups with invite codes (create / join), nickname-only profiles
- [x] Firebase Authentication (Google) verified by the server; demo auth for local development
- [x] "I'm at the gate" → alarm-style, full-screen ring on every other phone
- [x] "Coming!" acknowledgement → sender sees who's coming
- [x] Server-side re-ring (every 30 s) and expiry after 4 rings → "Nobody answered"
- [x] Sender can cancel ("I got in")
- [x] Reliability checklist: notifications, full-screen intent, battery optimization, OEM tips
- [x] Create the Firebase project and connect the app (see SETUP.md)
- [x] Deployable: Dockerfile + Render blueprint, verified on PostgreSQL 17
- [ ] Deploy the server (Render) + PostgreSQL (Neon), see DEPLOY.md
- [ ] Distribute to the family via Firebase App Distribution
- [x] Release signing config (key kept outside the repo)

## v0.2: FamCare (vitamin tracker)
- [ ] Each person's vitamins: name, dose, time(s) of day
- [ ] Daily checklist that resets at midnight (Asia/Manila); tick to mark as taken
- [ ] Server-side "remind only if not taken yet" push at each scheduled time
- [ ] Family view: see who has or hasn't taken theirs; "Nudge" a specific person
- [ ] History and streaks
- [ ] Low-stock reminder ("Fish oil: about 5 days left")

## v0.3: one-tap extras
- [ ] NFC sticker at the gate: tap your phone on it to ring
- [ ] Quick Settings tile: "Gate" in the notification shade (Kotlin `TileService`)
- [ ] Home-screen widgets: gate button, today's vitamins
- [ ] Optional "almost home" heads-up (geofence ~300–500 m, opt-in)

## Portfolio polish
- [ ] Public demo with made-up data that resets nightly
- [ ] Screenshots and a short GIF (demo data only)
- [ ] GitHub Actions: server tests, Flutter analyze/test, APK build attached to releases
