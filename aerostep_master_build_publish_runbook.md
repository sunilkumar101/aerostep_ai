# AEROSTEP AI — MASTER CLAUDE CODE A-TO-Z BUILD & PUBLISH RUNBOOK (v3.0 — Final Stitch Zip Integrated)

## Autonomous Zero-Intervention Directive
You are an autonomous Principal Flutter & iOS Architect, UI/UX Engineer, Hardware QA Tester, ASO Specialist, and Google Play Console Publisher. Execute this entire specification from **Phase 1 to Phase 10** without requiring manual user intervention.

### Mandatory Self-Verification Protocol (Run After Every Phase)
1. Re-read `CLAUDE.md` and this `AeroStep_Claude_Code_Full_Build_Publish_Master_Prompt.md` file at the end of every phase.
2. Check off every single sub-requirement in `BUILD_PROGRESS_CHECKLIST.md` with `[VERIFIED PASS]` and timestamp.
3. If any screen, button, sensor filter, contrast rule, or build check is incomplete, fix it immediately before advancing to the next phase.

---

## PHASE 1: Smart Open-Source Bootstrapping & Stitch Asset Ingestion
1. **Locate & Extract Stitch Assets:**
   * Check `./ui_ux_stitch_assets/`. If `stitch_aerostep_ai_fitness_app.zip` is in the project root or inside `./ui_ux_stitch_assets/` and not yet extracted, unzip it into `./ui_ux_stitch_assets/`.
   * Read `./ui_ux_stitch_assets/warm_bento_dynamic/DESIGN.md` and `./ui_ux_stitch_assets/design_tokens.json`.
   * Inspect all 13 Stitch screen folders (`code.html` + `screen.png`) and the 2 local runner photography folders (`full_body_shot_of_an_athletic_energetic_young_woman_runner_smiling_while/screen.png` and `athletic_young_runner_in_stylish_dark_obsidian_athletic_apparel_with_glowing/screen.png`).
2. **Initialize Flutter Project (Android + iOS):**
   * Initialize Flutter in the project workspace with organization `com.sunilkhatri.aerostep` and project name `aerostep_ai`.
   * Copy the 2 local runner photography PNGs and brand assets into `assets/images/` and register them in `pubspec.yaml`.
3. **Configure Open-Source Accelerator Packages in `pubspec.yaml`:**
   * State & Architecture: `flutter_riverpod`, `go_router`, `shared_preferences`, `drift` + `sqlite3_flutter_libs` (or `isar`) for timezone-proof UTC storage.
   * Sensors & Health Sync: `pedometer`, `sensors_plus`, `flutter_activity_recognition`, `health`, `permission_handler`.
   * Background & OEM Battery Bypass: `flutter_foreground_task`, `disable_battery_optimization`, `device_info_plus`.
   * UI, Charts, Widgets & Monetization: `google_fonts`, `fl_chart`, `home_widget`, `google_mobile_ads`, `share_plus`, `url_launcher`.
4. **PHASE 1 SELF-CHECK GATE:** Re-read Phase 1, run `flutter pub get` and `flutter analyze`, and log `[VERIFIED PASS]` in `BUILD_PROGRESS_CHECKLIST.md`.

---

## PHASE 2: Warm Bento Dynamic UI/UX Implementation (All 13 Stitch Screens + Mandatory UI Fixes)
Build the complete Flutter UI matching the exact Stitch `code.html` and `screen.png` references in `./ui_ux_stitch_assets/`:

### 2.1 Theme & Core Component System (`lib/design_system/`)
* **Light Mode (`Warm Peach-Apricot & Sunset Tangerine`):** Canvas gradient `#FFFDFB -> #FFF3EA -> #FDE8D7` with subtle geometric asterisk (`*`) watermark painter; 28px rounded frosted white Bento cards (`#FFFFFF` at 90% opacity, `1px` white/60% border, warm shadow `rgba(255, 122, 47, 0.08)`); Sunset Tangerine hero cards (`#FF7A2F -> #FFA163`); Sky-Cyan telemetry badges (`#46CFFE` / `#38C6F4`); Deep Charcoal contrast cards/sheets (`#141416`).
* **Dark Mode (`Warm Espresso Obsidian`):** Canvas `#12100E -> #1C1714`; Smoked Espresso Bento cards (`#221C18` at 95% opacity, `1px` white/8% border); Neon Tangerine (`#FF7A2F`) and Sky-Cyan (`#46CFFE`) accents.
* **Typography:** `Plus Jakarta Sans` for headings/body and `Space Grotesk` with `FontFeature.tabularFigures()` for all numeric counters.

### 2.2 Mandatory UI Polish & Fixes (Must Be Applied)
1. **Contrast Fix on `#141416` Charcoal Surfaces (`aerostep_ai_trends_analytics`):** Ensure the selected `"Week"` segmented tab pill and the `"Century Streak"` card title inside `#141416` containers use crisp `#FFFFFF` white text (fixing the dark-on-dark typo from Stitch's HTML).
2. **Unified `AeroFloatingBottomDock` Across All Main Tabs:**
   * Left `#141416` capsule with 4 tabs:
     * Tab 0: `Home` (switches between `aerostep_ai_home_dashboard` and `aerostep_ai_activity_tracker_light` / `dark_mode`, plus a top header theme toggle).
     * Tab 1: `Analysis` (switches between `aerostep_ai_analysis_active_calories` and `aerostep_ai_trends_analytics`).
     * Tab 2: `Trails` (`aerostep_ai_virtual_world_adventures`).
     * Tab 3: `Squads` (`aerostep_ai_squads_challenges`).
   * Right detached 56x56 circular Sunset Tangerine (`#FF7A2F -> #FFA163`) AI Sparkle button (`auto_awesome` icon + pulsing Sky-Cyan dot) opening the **AI Coach Hub** (`aerostep_ai_ai_coach_weight_loss_hub` + `aerostep_ai_stride_ai_coach`).

### 2.3 All 13 Stitch Screens to Implement (`lib/features/`)
1. **Onboarding Welcome (Light & Dark):** `aerostep_ai_onboarding_welcome_light` & `aerostep_ai_onboarding_welcome_dark_mode` using the bundled local runner PNGs, `#141416` / `#1C1714` 36px bottom sheet, `"Step Today, Shine Tomorrow"`, `"0% GPS DRAIN"` & `"AUTO-PAUSE IN TRANSIT"` chips, and `"Get Started"` pill CTA.
2. **Smart Setup & OEM Battery Protection:** `aerostep_ai_smart_setup_battery_protection_light` with interactive `10,000` Steps/Day circular SVG dial, `4,000–16,000` slider (updating calories & km live), `#141416` bottom sheet with `Samsung (OneUI Ready)`, `Xiaomi (AutoStart OK)`, `Realme/Pixel (Unrestricted)` selector cards, `Auto-Pause Vehicle Rides (AI Accel)` switch, and `"Complete Setup & Launch"` CTA.
3. **Home Dashboard:** `aerostep_ai_home_dashboard` with Sunil Kumar header, `"Walk today, shine tomorrow."` + curved orange arrow, search/mic bar, category pills (`DAILY STEPS`, `VIRTUAL TRAILS`, `SQUADS`, `FAST WALK`, `HYDRATION`), `8,420 / 10,000` Tangerine Hero Card (`84%` ring, `6.1 km`, `52 min`, `380 kcal`, `114 spm Brisk Cadence`), `Active Burn` & `Average Pace` Bento cards, `STRIDE AI COACH` card, and `Sunset Interval Walk (START)` card.
4. **Daily Activity Tracker (Light & Espresso Dark Mode):** `aerostep_ai_activity_tracker_light` & `aerostep_ai_activity_tracker_dark_mode` with `11,482 / 12k (95%)` ring, `Walking Rhythm` hourly bar chart (`6a` to `8p`), Heart Rate `134 bpm` & Elevation `142 m` sparklines, `Adaptive Recovery Night Sync`, `Weekly Kinetic Cadence` wave, and `Quick Start Walk` button.
5. **Analysis & Active Calories:** `aerostep_ai_analysis_active_calories` with `64,280 steps` Weekly Summary Trio-Bar chart (`M T W T F S S`), `Active Metrics` white sheet (Left tall Tangerine `8,420` card, Top-right Sky-Cyan `342 kcal` capsule card, Bottom-right Charcoal `6.2 km` capsule card), and `Streak Shield Active (DAY 14)` banner.
6. **Trends & Analytics:** `aerostep_ai_trends_analytics` with `Day / Week / Month / Year` pill bar (with `#FFFFFF` text on active `#141416` pill), `78,410 STEPS` Weekly Stride Volume bar chart (`14.2k` peak tooltip), `Elevated Ground Tempo` banner, `168 SPM` Cadence & L/R symmetry card, `48.2 VO2` Cardio Fitness card, `Century Streak (14 Days)` dark card (with `#FFFFFF` title), and `94% Readiness` card.
7. **Live Walk & Stride Pace Coach:** `aerostep_ai_live_walk_pace_coach` with `Indoor Sensor (0% GPS)` vs `Outdoor Route` pill switcher, warm vector route map with `1 km` & `2 km` Sky-Cyan markers and `Pace 5:14/km` tooltip, `118 SPM` Fat-Burn Zone Tangerine HUD with Voice Coach quote, `34:12` Duration & `2.95 km` Distance cards, Metabolic Burn/Stride Length/Balance strip, and `#141416` bottom control sheet (`Auto-Pause Drive Filter: Active`, Lock button, Sky-Cyan `Pause` button, Tangerine `Finish` button).
8. **Virtual World Adventures:** `aerostep_ai_virtual_world_adventures` with `Inca Trail to Machu Picchu (68% COMPLETE • 28.5 / 42.0 km Done)` topographic hero card, `12 Collectible Postcards` Tangerine card, `1-Tap Share` Story Ready Sky-Cyan card, and Upcoming Expeditions (`Mount Fuji 5th Station 14.2 km` & `Amalfi Cliffside Pathway 8.8 km`).
9. **Squads & Kinetic Step Bingo:** `aerostep_ai_squads_challenges` with `Office Walkers Squad (312,400 / 400k • 78%)` Tangerine hero card, `Invite: AERO-88` clipboard copy button with toast, `VERIFIED` anti-cheat pill, `Squad Standings` (`Steps` / `Pace` toggle, Priya Sharma #1, Marcus Chen #2, Amina Diallo #3, Sunil Kumar #4), **3x3 Kinetic Step Bingo** interactive grid, and `Live Team Pulse` chat.
10. **AI Coach & Weight-Loss Hub + Stride Biomechanics Coach:** Combine `aerostep_ai_ai_coach_weight_loss_hub` and `aerostep_ai_stride_ai_coach` via a top sub-switcher (`Weight-Loss & Hydration` vs `Gait & Audio Drills`):
    * *Weight-Loss Hub:* Voice/Chat toggle, `"You are 1,580 steps away..."` Tangerine insight card, `1.75 / 2.5 L` interactive liquid cylinder Hydration card (`+250ml` button), `1,420 / 2,100 kcal` AI Meal Snap card (`P: 84g C: 160g F: 42g`), `2 Rest Days Available` Streak Shield card, `-420 kcal net` Metabolic Deficit card, and bottom AI prompt bar.
    * *Stride Biomechanics Coach:* `AeroStep Stride Intelligence` card, `Dynamic Gait Matrix` foot-sole pressure SVG (`72% Forefoot / 28% Heel`, `164 SPM`, `+4.2 DEG/S`), `Interval Cadence Drill (172 BPM)` interactive audio metronome player, and `Hydration Window` log card.
11. **Widgets & Watch Showcase:** `aerostep_ai_widget_showcase_smartwatch` displaying the `2x2 Small Tangerine Widget`, `4x2 Interactive Bento Widget` (with live `+250ml` water tap), `Always-On OLED Smartwatch Dial` (`10:42 AM • 8,420 / 10k • 118 SPM`), and `Sync Companion Face` toggle.
12. **Unlock Pass & Pro VIP Modal:** `aerostep_ai_unlock_pass_pro_vip` with `NO POPUP ADS PROMISE` badge, Free Daily Reward Pass card (`1x Streak Shield` or `24h Trail Pass` via `"Watch Video to Unlock (30s)"`), and `#141416` + Tangerine `AeroStep Pro VIP` card (`$14.99/yr` Annual Pass SAVE 37% vs `$1.99/mo` Monthly Flexibility + `"Start 7-Day Free Trial"`).
* **PHASE 2 SELF-CHECK GATE:** Re-read Phase 2, verify all 13 screens and both UI fixes, and log `[VERIFIED PASS]`.

---

## PHASE 3: Anti-Pacer Core Pedometer Engine (Zero Battery Drain, Anti-Shake & OEM Fix)
1. **Hardware Step Sensor + Health Connect / HealthKit Deduplication:** Read continuous hardware steps (`pedometer`) for instant UI updates and merge with `Google Health Connect` / `Apple HealthKit` (`health`) in 15-minute UTC intervals so smartwatch + phone steps never double-count.
2. **Anti-Shake & Vehicle Auto-Pause Filter:** Combine `flutter_activity_recognition` (`IN_VEHICLE`, `ON_BICYCLE`) with a 120Hz accelerometer cadence gate (`60–220 SPM` sustained for `>6 seconds`) so bumpy vehicle rides and hand shaking never add fake steps.
3. **1-Tap Android OEM Battery Wizard:** Detect device manufacturer (`device_info_plus`) and wire the Samsung/Xiaomi/Realme buttons in `aerostep_ai_smart_setup_battery_protection_light` to native `disable_battery_optimization` intents + persistent foreground service (`flutter_foreground_task`).
4. **Timezone-Proof UTC Ledger & Streak Shield:** Store all step/hydration/calorie records in UTC with local offset metadata and auto-deploy Streak Shields on rest/low-activity days.
5. **PHASE 3 SELF-CHECK GATE:** Run unit tests on step deduplication, anti-shake cadence filtering, and UTC streak persistence. Log `[VERIFIED PASS]`.

---

## PHASE 4: Ethical Google AdMob Integration
1. Configure `google_mobile_ads` in `AndroidManifest.xml` and iOS `Info.plist`.
2. Wire **Voluntary Rewarded Video Ads** to the `"Watch Video to Unlock (30s)"` button on `aerostep_ai_unlock_pass_pro_vip` (granting `1x Streak Shield` or `24h Trail Pass` upon completion) and to locked World Trails.
3. Ensure **ZERO unsolicited interstitial popups** on app launch or tab switches.
4. **PHASE 4 SELF-CHECK GATE:** Verify Rewarded Ad loading, reward callback, and graceful offline fallback. Log `[VERIFIED PASS]`.

---

## PHASE 5: Complete iOS Build Readiness (Xcode, HealthKit, WidgetKit — Do Not Publish Yet)
1. Configure `ios/Podfile` (`platform :ios, '15.0'`), `Info.plist` (`NSMotionUsageDescription`, `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`, `UIBackgroundModes`, `GADApplicationIdentifier`), and `Runner.entitlements` (HealthKit + App Groups).
2. Create the native Swift `WidgetKit` extension for the `2x2 Small Tangerine Widget` and `4x2 Medium Bento Widget` synced via `home_widget`.
3. Run `flutter build ios --config-only --no-codesign` and verify zero errors.
4. **IMPORTANT:** Push all `ios/` files to GitHub, but **DO NOT publish to the Apple App Store yet**.
5. **PHASE 5 SELF-CHECK GATE:** Verify clean iOS configuration and log `[VERIFIED PASS]`.

---

## PHASE 6: GitHub Repository Push & Live GitHub Pages Privacy Policy / `app-ads.txt`
1. Initialize Git, commit the complete Flutter (`lib/`, `android/`, `ios/`, `assets/`) codebase, and push to GitHub (`gh repo create`).
2. Generate a Play Console & GDPR/Health-Connect compliant `/docs/privacy-policy.html`, `/docs/terms.html`, and `/docs/app-ads.txt`.
3. Enable GitHub Pages and verify the live public Privacy Policy URL returns HTTP 200 via `curl -I`.
4. **PHASE 6 SELF-CHECK GATE:** Log live GitHub repo URL and Privacy Policy URL in `BUILD_PROGRESS_CHECKLIST.md` with `[VERIFIED PASS]`.

---

## PHASE 7: Physical Mobile USB (`adb`) Hardware Testing & Signed Release `.aab`
1. Detect the connected physical Android phone via `adb devices` and install the app.
2. Execute all 8 live hardware checks on the connected device:
   * Real 50-step walk test (instant ring update).
   * 15-second rapid hand-shake test (rejected by Anti-Shake filter).
   * 5-minute locked-screen walk test (foreground service persistence).
   * 1-Tap OEM Battery Protection intent trigger test.
   * Light Mode & Warm Espresso Dark Mode switch + screenshot capture across all screens.
   * Health Connect permission & deduplication test.
   * AdMob Rewarded Video playback & Streak Shield unlock test.
   * Native Android Home Screen Widget placement & live update test.
3. Inspect `adb logcat` to confirm 0 crashes/exceptions, generate a production upload keystore (`key.properties`), and build `build/app/outputs/bundle/release/app-release.aab` (`flutter build appbundle --release`).
4. **PHASE 7 SELF-CHECK GATE:** Confirm signed `app-release.aab` exists and log `[VERIFIED PASS]`.

---

## PHASE 8: Ahrefs + Chrome ASO Keyword Research & Store Listing Copy
1. Use the connected Ahrefs MCP / Chrome browser to analyze high-volume, low-competition keywords in the Pedometer, Step Counter, Offline Walking Tracker, and Weight Loss niche.
2. Generate conversion-optimized Play Store metadata:
   * **App Title (max 30 chars):** `AeroStep: Pedometer & Step AI`
   * **Short Description (max 80 chars):** `Accurate offline step counter, zero GPS battery drain, AI walk coach & trails.`
   * **Full Description (up to 4,000 chars):** Highlight Zero GPS Battery Drain, Smart Anti-Shake Vehicle Filter, 1-Tap Xiaomi/Samsung Battery Fix, Virtual World Trails, Squads & Step Bingo, AI Stride Coach, and No Annoying Popup Ads.
3. **PHASE 8 SELF-CHECK GATE:** Save metadata to `store_assets/aso_metadata.json` and log `[VERIFIED PASS]`.

---

## PHASE 9: Automated Generation of Play Console Visual Assets & Motion Graphics Promo Video
1. **App Icon (`512x512` 32-bit PNG):** Sunset Tangerine (`#FF7A2F`) & Deep Charcoal (`#141416`) 3D Bento emblem with glowing stride ring.
2. **Feature Graphic (`1024x500` PNG):** Warm Peach-Cream & Sunset Tangerine promotional banner showcasing the `8,420` step ring, OLED watch dial, and headline *"Step Today, Shine Tomorrow. Zero Battery Drain."*
3. **8 Framed Phone Screenshots (`1080x1920` PNGs):** Framed device mockups in the Warm Peach & Sunset Tangerine Bento style covering Home Dashboard, Activity Tracker (Dark & Light), Analysis & Calories, Live Walk Coach, Virtual World Trails, Squads & Step Bingo, AI Coach Hub, and Widgets/Smartwatch.
4. **30-Second 60fps Motion Graphics Promo Video:** Render a smooth motion graphics showcase video (`MP4`) and upload to YouTube (Unlisted/Public) if needed for the Play Console video URL field.
5. **PHASE 9 SELF-CHECK GATE:** Verify exact pixel dimensions of all generated store assets and log `[VERIFIED PASS]`.

---

## PHASE 10: Google Play Console End-to-End Automated Filling & Publishing via Logged-in Chrome
1. Use the active logged-in Google Chrome browser session to open Google Play Console (`https://play.google.com/console`).
2. Create the app (`AeroStep: Pedometer & Step AI`, English US, App, Free) and complete all **App Content** declarations:
   * Privacy Policy URL (live GitHub Pages URL from Phase 6).
   * Ads Declaration (`Yes, my app contains ads`).
   * App Access (`All functionality is available without special access` or test instructions).
   * Content Rating (IARC Health & Fitness questionnaire -> Everyone / PEGI 3).
   * Target Audience (`13+` / `18+`, not Appeal to Children).
   * Data Safety Form (Health & Fitness step count, Device IDs for AdMob, encrypted in transit).
   * Health Apps Declaration & Health Connect Permission justification.
   * Advertising ID & Financial/Government declarations.
3. Populate **Main Store Listing** with ASO Title, Short Description, Full Description, 512x512 Icon, 1024x500 Feature Graphic, 8 Phone Screenshots, and Promo Video link.
4. Upload the signed `app-release.aab` to Production (or Testing track), add Release Notes, verify 0 blocking errors in **Publishing Overview**, and submit for review.
5. **FINAL MASTER AUDIT GATE 10:** Re-read `CLAUDE.md` and `BUILD_PROGRESS_CHECKLIST.md` from Phase 1 to Phase 10, confirm 100% completion, and print the final launch summary.