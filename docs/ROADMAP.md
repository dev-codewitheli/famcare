# Roadmap

## v0.1: HomeBell MVP (done)
- [x] Family groups with invite codes (create / join), nickname-only profiles
- [x] Firebase Authentication (Google) verified by the server; demo auth for local development
- [x] "I'm at the gate" → alarm-style, full-screen ring on every other phone
- [x] "Coming!" acknowledgement → sender sees who's coming
- [x] Server-side re-ring (every 30 s) and expiry after 4 rings → "Nobody answered"
- [x] Sender can cancel ("I got in")
- [x] Reliability checklist: notifications, full-screen intent, battery optimization, OEM tips
- [x] Create the Firebase project and connect the app (see SETUP.md)
- [x] Deployable: Dockerfile + Render blueprint, verified on PostgreSQL 17
- [x] Deploy the server (Render) + PostgreSQL (Neon), see DEPLOY.md
- [ ] Distribute to the family via Firebase App Distribution
- [x] Release signing config (key kept outside the repo)

## v0.2: HomeBell polish (done)
- [x] Native Google account picker (fixes being stranded in Chrome after sign-in)
- [x] Per-phone "Ring even on Silent / Do Not Disturb" (DND-bypass channel, off by default)
- [x] "On my way (~5/10/15/30 min)" heads-up and recent gate activity
- [x] Redesigned sign-in, onboarding, home, settings
- [x] Brand-specific phone setup: Xiaomi, OPPO/OnePlus, realme, vivo, Samsung, Infinix/Tecno

## v0.3: HomeBell family features (done)
- [x] "Time's up" reminder to the sender with "I'm at the gate" / "+5 min"
- [x] "Heads-up sent" confirmation, "Got it" acknowledgements and "Seen by"
- [x] Edit nickname; family creator renames the family and removes members
- [x] Recent activity capped at 5; phone setup without duplicate steps, Xiaomi checks automatic

## v0.4: HomeBell polish for release (done)
- [x] Clearer time's-up card: no duplicate ring button, "Not coming", auto-hide time
- [x] Leave family, delete account (Play requirement), new invite code
- [x] Signed-out phones stop ringing; nightly retention (90 days of gate activity)
- [x] Adaptive/themed icon, status-bar icon, branded splash, tablet-friendly layout
- [x] Privacy policy page, Crashlytics, release workflow (tag → signed APKs on GitHub Releases)
- [x] README screenshots and portfolio card

## v0.5: Choose who rings; lock-screen privacy (done)
- [x] Pick who "I'm at the gate" rings (e.g. not whoever is at school or work), remembered per phone
- [x] The app no longer shows over the lock screen; a ring wakes the screen with a lock-screen
      notification, and "Coming!" works from it without unlocking
- [x] When the last member leaves or deletes their account, the family and all its data are
      deleted (server; the old invite code stops working)

## v0.6: FamCare (vitamin tracker)
- [ ] Each person's vitamins: name, dose, time(s) of day
- [ ] Daily checklist that resets at midnight (Asia/Manila); tick to mark as taken
- [ ] Server-side "remind only if not taken yet" push at each scheduled time
- [ ] Family view: see who has or hasn't taken theirs; "Nudge" a specific person
- [ ] History and streaks
- [ ] Low-stock reminder ("Fish oil: about 5 days left")

## v0.6: one-tap extras
- [ ] NFC sticker at the gate: tap your phone on it to ring
- [ ] Quick Settings tile: "Gate" in the notification shade (Kotlin `TileService`)
- [ ] Home-screen widgets: gate button, today's vitamins
- [ ] Optional "almost home" heads-up (geofence ~300–500 m, opt-in)

## Portfolio polish
- [ ] Public demo with made-up data that resets nightly (optional web build)
- [x] Screenshots (demo data only)
- [x] GitHub Actions: tests on every push, signed APKs attached to releases
