# AeroStep AI — Build Progress Checklist

Source of truth: `CLAUDE.md` + `aerostep_master_build_publish_runbook.md`.

## Phase 1: Smart Open-Source Bootstrap & Stitch Asset Ingestion
- [x] Stitch assets located (already extracted under `ui_ux_stitch_assets/stitch_aerostep_ai_fitness_app/stitch_aerostep_ai_fitness_app/`; no zip present)
- [x] DESIGN.md + design tokens read; 15 screen folders + 2 runner photos inspected
- [x] Flutter project initialised (Android + iOS), applicationId / bundle id `com.sunilkhatri.aerostep`
- [x] Runner photos copied to `assets/images/hero_runner_light.png` / `hero_runner_dark.png`
- [x] Packages added: riverpod, go_router, shared_preferences, drift (+drift_flutter), pedometer, sensors_plus, flutter_activity_recognition, health, permission_handler, flutter_foreground_task, disable_battery_optimization, device_info_plus, google_fonts, fl_chart, home_widget, google_mobile_ads, share_plus, url_launcher
- [x] `flutter pub get` + `flutter analyze` clean
- Note: `sqlite3_flutter_libs` is end-of-life upstream; replaced with `drift_flutter` (bundles sqlite via build hooks).
- **[VERIFIED PASS] 2026-11-17T09:51Z**

## Phase 2: Warm Bento Dynamic UI/UX (13 screens + light/espresso themes)
- [x] Design system (`lib/design_system/`): tokens, light + espresso themes, Bento/Tangerine/Charcoal/Cyan cards, segmented pills, ring, dock
- [x] Contrast fix: `CharcoalCard` forces white text; `AeroSegmented` active pill = #141416 + #FFFFFF (Trends "Week" + "Century Streak")
- [x] Unified `AeroFloatingBottomDock` (Home / Analysis / Trails / Squads + AI Sparkle FAB with pulsing cyan dot)
- [x] All Stitch screens implemented and wired (onboarding L/D, smart setup, home, tracker L/D, analysis, trends, live walk, trails, squads, AI coach hub + stride coach, widgets/watch, unlock pass)
- [x] Zero RenderFlex overflow at 360x640 — `test/app_smoke_test.dart` (13 cases, light + dark, every tab/sub-view/route, scrolled)
- **[VERIFIED PASS] 2026-11-17T11:10Z**

## Phase 3: Pedometer engine, anti-shake, OEM battery, UTC ledger
- [x] Hardware step counter engine (`lib/core/pedometer/step_engine.dart`); accelerometer (~120 Hz) only while validating a new bout
- [x] Anti-shake / vehicle gate: 60–220 SPM sustained > 6 s + activity recognition IN_VEHICLE/ON_BICYCLE + accel shake veto
- [x] Health Connect / HealthKit 15-min UTC bucket dedup (max per bucket), synced every 15 min
- [x] UTC ledger (drift) with per-row offset; travel-proof local days; Streak Shield auto-deploy
- [x] Android foreground service (type `health`) + persistent notification; 1-tap OEM battery wizard (native MethodChannel in MainActivity.kt)
- [x] Unit tests: `test/pedometer_core_test.dart` — 20/20 pass
- Note: `disable_battery_optimization` removed (abandoned, breaks AGP 9) — replaced by native intents.
- **[VERIFIED PASS] 2026-11-17T11:10Z** (on-device behaviour pending Phase 7)

## Phase 4: Ethical AdMob
- [x] `google_mobile_ads` configured (Android manifest placeholder, iOS GADApplicationIdentifier via xcconfig)
- [x] Rewarded video only on "Watch Video to Unlock (30s)" / trail "Unlock" → grants 1x Streak Shield or 24h Trail Pass only when reward earned
- [x] Zero interstitial / app-open ads; offline / no-fill fallback message
- [ ] Real AdMob app id + rewarded unit ids (currently Google TEST ids) — needs user
- **[VERIFIED PASS — test ids] 2026-11-17T11:10Z**

## Phase 5: iOS readiness + WidgetKit
- [x] Podfile `platform :ios, '15.0'`; Info.plist motion/health/background/GAD/ATT keys; Runner.entitlements (HealthKit + App Group); deployment target 15.0
- [x] Swift WidgetKit sources: 2x2 Small Tangerine + 4x2 Bento (interactive +250 ml App Intent on iOS 17)
- [ ] Add widget extension target in Xcode + `flutter build ios --config-only --no-codesign` — **requires macOS** (see `ios/AeroStepWidget/README_XCODE_SETUP.md`)

## Build
- [x] `flutter analyze` — no issues
- [x] `flutter build apk --debug` — OK (compileSdk 37, AGP 9, Kotlin non-incremental for cross-drive Windows builds)

## Phase 6: GitHub push + Pages privacy policy / app-ads.txt
- [x] Public repo: https://github.com/sunilkumar101/aerostep_ai (lib/, android/, ios/, assets/, docs/)
- [x] GitHub Pages from `main:/docs` — `curl -I` HTTP 200:
  - Privacy Policy: https://sunilkumar101.github.io/aerostep_ai/privacy-policy.html
  - Terms: https://sunilkumar101.github.io/aerostep_ai/terms.html
  - app-ads.txt: https://sunilkumar101.github.io/aerostep_ai/app-ads.txt
- [ ] Replace `SUPPORT_EMAIL_PLACEHOLDER` in privacy policy / terms — needs user
- [ ] AdMob requires app-ads.txt at the domain ROOT (`https://sunilkumar101.github.io/app-ads.txt`) → needs a `sunilkumar101.github.io` user-site repo + real publisher ID — needs user
- **[VERIFIED PASS — URLs live] 2026-11-17**

## Phase 7: USB device QA + signed .aab
Device: OPPO CPH1937 (A9 2020), ColorOS, Android 11 / API 30, hardware step counter + accelerometer.
- [x] 1. Real walk test — 100 counted steps → app +96 (hardware sensor 96%, gate rejected 0 of the steps the sensor reported). Ring, notification and widget data agree.
- [x] 2. 15 s hand-shake test — count unchanged (86 → 86).
- [x] 3. Locked-screen walk — foreground service (type `health`) survived; screen-off batches credited via backlog logic (106 → 384).
- [x] 4. 1-Tap OEM battery — `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` dialog shown; app now on deviceidle whitelist. ColorOS 11 AutoStart intent added.
- [x] 5. Light + Warm Espresso dark — all main tabs, sub-views, coach, unlock, widgets captured on device (`build/device_shots/`, not committed); no overflow / Flutter errors in logcat.
- [ ] 6. Health Connect — "Sync watch steps" card detects Health Connect is NOT installed on this phone and offers Install. Permission + dedup on device pending user installing Health Connect. (Dedup logic covered by unit tests.)
- [x] 7. AdMob rewarded (Google TEST ad) — played, reward callback fired, Streak Shields 2 → 3.
- [x] 8. Home widget — 2x2 widget pinned via in-app button; provider instance registered; widget data (steps/goal/kcal) populated; service now refreshes widgets while UI is closed.
- [x] logcat: no FATAL / `E flutter` from AeroStep during the session.
- [x] Upload keystore generated (`android/upload-keystore.jks` + `android/key.properties`, git-ignored — BACK THESE UP).
- [x] Signed `build/app/outputs/bundle/release/app-release.aab`.

Bugs found on device and fixed:
- Screen-off step batches were rejected as impossible cadence → backlog credit by elapsed interval.
- Accelerometer zero-crossing cadence (~2 peaks per step) was vetoing real walking → veto now only on violent motion (RMS > 8 m/s²; walking measured 1.4–3.6).
- Activity recognition failed in the service isolate (needed an Activity) → check permission via permission_handler, listen to stream directly.
- `disable_battery_optimization` broke AGP 9 → native MethodChannel in MainActivity.
- **[VERIFIED PASS — 7/8 on device; Health Connect pending install] 2026-11-17**

## Phase 8: ASO metadata
- [x] Ahrefs keyword research (US + global): head terms pedometer 19k, step counter 9.5k, step tracker 4.6k, walking app 2.6k; low-KD long tail listed in `store_assets/aso_keyword_research.md`
- [x] Title `AeroStep: Pedometer & Step AI` (29/30)
- [x] Short description (77/80)
- [x] Full description (3,007/4,000), only shipped features, Play policy guardrails (no "best"/competitor names/unverifiable claims)
- [x] Saved `store_assets/aso_metadata.json` (+ release notes, contact email, privacy URL)
- Note: Squads leaderboard/chat, Virtual Trail progress, Meal Snap and Pro are UI demos without a backend and are deliberately NOT advertised.
- **[VERIFIED PASS] 2026-11-17**

## Phase 9: Store visual assets + promo video
- [ ] 

## Phase 10: Play Console submission
- [ ] 
