# AeroStep AI: Smart Pedometer & Walk Coach

Flutter app (Android + iOS) · package `com.sunilkhatri.aerostep` · current version **1.0.2 (3)**

Accurate, zero-GPS step counter with an anti-shake / vehicle filter, a Gemini-powered walking coach, widgets and a warm "Bento" design.

- Google Play (closed testing): <https://play.google.com/apps/testing/com.sunilkhatri.aerostep>
- Privacy policy: <https://sunilkumar101.github.io/aerostep_ai/privacy-policy.html>

## Features

- **Hardware step counter, zero GPS.** Uses `TYPE_STEP_COUNTER` / CoreMotion. No background service: the sensor keeps counting while the app is closed, and the backlog is added (spread over the gap) when the app opens.
- **Anti-shake & vehicle auto-pause.** Steps count only after a 60–220 SPM rhythm holds for more than 6 s; activity recognition pauses counting in cars, buses and on bikes.
- **Health Connect / HealthKit sync** with 15-minute UTC bucket de-duplication (watch + phone never double count) and a timezone-proof ledger.
- **Start today from 0.** Reset today's counter (history kept, undo, ends at midnight).
- **Share progress.** Exports a 4:5 progress image to Instagram, Facebook, WhatsApp, etc.
- **Your own profile name** (tap the header to edit).
- **Squads.** A local friends list ranked against your real weekly steps, plus Kinetic Step Bingo.
- **Stride AI coach** powered by the Gemini API, with a one-time consent prompt and an offline fallback coach.
- **Streak Shields**, hydration tracking, live walk mode, trends, Android home-screen widgets, light + espresso dark themes.
- **Ethical ads.** Only optional rewarded videos; no popup/interstitial ads.

## Project layout

```
lib/
  app/              router, shell, dock
  core/
    ai/             Gemini client (gemini_coach.dart)
    pedometer/      step engine, cadence gate, health sync, snapshot builder
    data/           drift database (UTC step ledger)
    state/          Riverpod providers (profile, activity, hydration, shields)
  design_system/    Warm Bento tokens, typography, widgets
  features/         home, analysis, trails, squads, coach, live_walk, onboarding, unlock, widgets_showcase
android/ ios/       platform projects (iOS WidgetKit sources in ios/AeroStepWidget)
docs/               GitHub Pages: privacy policy, terms, app-ads.txt
store_assets/       Play listing copy, screenshots, feature graphic, promo video project
tool/               store screenshot renderer, PNG flattener
test/               engine unit tests + 360px no-overflow smoke tests
```

## Setup

1. Flutter 3.44+ (Dart 3.12).
2. `flutter pub get`
3. **Gemini key (optional):** copy `secrets.example.json` to `secrets.json` and put your Google AI Studio key in `GEMINI_API_KEY`. `secrets.json` is git-ignored. Without a key the coach uses the built-in offline answers.
   Restrict the key in Google Cloud Console → Credentials → *Android apps* to `com.sunilkhatri.aerostep` + your signing-certificate SHA-1s (the app sends the `X-Android-Package` / `X-Android-Cert` headers).
4. **Release signing:** `android/key.properties` + the upload keystore are git-ignored (kept in a private repo).

## Run, test, build

```bash
flutter run --dart-define-from-file=secrets.json
flutter analyze
flutter test --dart-define=AERO_DEMO=true
flutter build appbundle --release --dart-define-from-file=secrets.json
```

`AERO_DEMO=true` runs the UI with demo data (used by tests and the store screenshot renderer).

Store screenshots: `flutter test --dart-define=AERO_DEMO=true tool/store_assets_render_test.dart && python tool/flatten_store_pngs.py`

## Changelog

- **1.0.2 (3)**: reset-to-zero, share progress image, editable name, local friends squads, Gemini AI coach, updated privacy policy and Data safety.
- **1.0.1 (2)**: removed the health foreground service (closed-app steps credited on next open, spread over the gap).
- **1.0.0 (1)**: first release.
