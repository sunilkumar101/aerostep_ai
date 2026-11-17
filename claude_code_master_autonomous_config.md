# CLAUDE.md — AeroStep AI Autonomous Build, QA & Play Console Publishing Brain (v3.0 — Final Stitch Zip Integrated)

## 1. Zero-Prompt Autonomous Execution Rule
When launched inside the `aerostep_ai` workspace, you (**Claude Code**) must immediately read this `CLAUDE.md` file, `AeroStep_Claude_Code_Full_Build_Publish_Master_Prompt.md`, and `./ui_ux_stitch_assets/warm_bento_dynamic/DESIGN.md`, and execute **Phase 1 through Phase 10** autonomously from start to finish without waiting for manual user explanations.

* **App Name:** AeroStep AI: Smart Pedometer & Walk Coach
* **Package / Bundle ID:** `com.sunilkhatri.aerostep`
* **Platforms:** Full production Flutter codebase for **Android** and **iOS** pushed to GitHub.
* **Publishing Scope:**
  * **Android:** Test on the connected physical Android phone via `adb`, perform ASO keyword research via connected Ahrefs/Chrome, host Privacy Policy & `app-ads.txt` on GitHub Pages, configure Google AdMob, generate all Play Store visual/video assets, and publish the signed release `.aab` to **Google Play Console** via the active logged-in Chrome browser session.
  * **iOS:** Configure and verify the complete `ios/` Xcode workspace, HealthKit entitlements, `Info.plist`, and native Swift `WidgetKit` extension, and push to GitHub (**DO NOT publish iOS to the Apple App Store yet**).

---

## 2. MANDATORY SELF-VERIFICATION GATE (NON-NEGOTIABLE RULE)
After completing **EVERY** phase (Phase 1 to Phase 10), you MUST:
1. Re-read this `CLAUDE.md` file and `BUILD_PROGRESS_CHECKLIST.md`.
2. Verify line-by-line that every single requirement, UI screen, contrast fix, and technical feature in the current phase is 100% implemented.
3. Run `flutter analyze` and relevant unit/device tests.
4. Log `[VERIFIED PASS]` with a timestamp in `BUILD_PROGRESS_CHECKLIST.md` before moving to the next phase. Never skip a single instruction.

---

## 3. Exact Stitch UI/UX Folder Map (`./ui_ux_stitch_assets/`)
The user has generated and extracted the Stitch UI/UX package inside `./ui_ux_stitch_assets/` (or `./ui_ux_stitch_assets/stitch_aerostep_ai_fitness_app/` — check both paths automatically and if `stitch_aerostep_ai_fitness_app.zip` is present, unzip it first). You must inspect both `code.html` and `screen.png` inside every folder below:

1. `./ui_ux_stitch_assets/warm_bento_dynamic/DESIGN.md` — **Master Design System** (`Warm Bento Dynamic`: Peach-Apricot canvas `#FFFDFB` to `#FDE8D7`, Sunset Tangerine `#FF7A2F` to `#FFA163`, Sky-Cyan `#46CFFE`/`#38C6F4`, Deep Charcoal `#141416`, Warm Espresso Dark Mode `#12100E` & `#221C18`, `Plus Jakarta Sans` + `Space Grotesk` tabular numerals, 28px Bento card radius).
2. `./ui_ux_stitch_assets/design_tokens.json` — Structured JSON design tokens for Flutter theme generation.
3. `aerostep_ai_onboarding_welcome_light/` (`code.html` + `screen.png`) — Light Mode Onboarding Step 1 ("Step Today, Shine Tomorrow" + `#141416` 36px bottom sheet + Tangerine/White "Get Started" pill CTA).
4. `aerostep_ai_onboarding_welcome_dark_mode/` (`code.html` + `screen.png`) — Dark Edition Onboarding Step 1 (`#12100E` canvas + `#1C1714` bottom card + Biomechanical Hub badge).
5. `aerostep_ai_smart_setup_battery_protection_light/` (`code.html` + `screen.png`) — Onboarding Step 2: Interactive `10,000 Steps/Day` circular dial + slider (`6k` to `15k`) + `#141416` bottom card for **1-Tap OEM Battery Protection (Samsung, Xiaomi, Realme/Pixel)** + **Auto-Pause Vehicle Rides** toggle.
6. `aerostep_ai_home_dashboard/` (`code.html` + `screen.png`) — Main Home Dashboard ("Walk today, shine tomorrow.", Sunil Kumar header, search/voice bar, category pills, `8,420 / 10,000` Tangerine Hero Card, Active Burn & Average Pace Bento row, Stride AI Coach callout, Sunset Interval Walk quick-start bar).
7. `aerostep_ai_activity_tracker_light/` (`code.html` + `screen.png`) — Detailed Daily Activity Tracker in Light Mode (`11,482 / 12k` steps 95% ring, Distance `8.2 km`, Active Time `1h 14m`, Climb `142 m`, Energy `648 kcal`, Gait `5.8 km/h` / `118 spm`, Walking Rhythm 6 AM–8 PM hourly bar chart, "Quick Start Walk" CTA).
8. `aerostep_ai_activity_tracker_dark_mode/` (`code.html` + `screen.png`) — Companion **Warm Espresso Obsidian (`#12100E` / `#221C18`)** Dark Mode Activity Tracker (`11,482` neon tangerine-cyan ring, Heart Rate `134 bpm` Zone 2 sparkline, Elevation `142 m` curve, Adaptive Recovery Night Sync card, Weekly Kinetic Cadence waveform, Quick Log `+250ml` button).
9. `aerostep_ai_analysis_active_calories/` (`code.html` + `screen.png`) — Weekly Summary & Active Metrics Bento Grid (`64,280 steps` Trio-Bar chart comparing Step Activity, Burn Pace & Base Goal; Left tall Tangerine `8,420` card; Top-right Sky-Cyan `342 kcal` capsule card; Bottom-right Charcoal `6.2 km` capsule card; Streak Shield Active Day 14 banner).
10. `aerostep_ai_trends_analytics/` (`code.html` + `screen.png`) — Day/Week/Month/Year Trends (`78,410 steps` Weekly Stride Volume bar chart, Outdoor Dynamics banner, Cadence & Balance `168 SPM` L/R symmetry bar, Cardio Fitness `48.2 VO2`, `14 Days Century Streak` dark card, `94% Readiness` tile).
11. `aerostep_ai_live_walk_pace_coach/` (`code.html` + `screen.png`) — Live Walk & Stride Session (`Indoor Sensor 0% GPS` vs `Outdoor Route` switcher, stylized warm vector route map with `1 km` & `2 km` Sky-Cyan pins and `Pace 5:14/km` badge, `118 SPM` Fat-Burn Zone Tangerine HUD with Voice Coach quote, Duration `34:12` & Distance `2.95 km` Bento cards, `#141416` bottom control sheet with `Auto-Pause Drive Filter: Active`, Lock button, Sky-Cyan `Pause` pill, and Tangerine `Finish` pill).
12. `aerostep_ai_virtual_world_adventures/` (`code.html` + `screen.png`) — Explore World Trails (`Inca Trail to Machu Picchu • 68% Complete • 28.5 / 42.0 km Done` topographic hero card with `Zero GPS • 100% Pedometer Synced` badge, `12 Collectible Postcards` Tangerine card, `1-Tap Share` Story Ready Sky-Cyan card, Upcoming Expeditions: `Mount Fuji 5th Station` & `Amalfi Cliffside Pathway`).
13. `aerostep_ai_squads_challenges/` (`code.html` + `screen.png`) — Squads & Kinetic Step Bingo (`Office Walkers Squad • 312,400 / 400k • 78%`, `Invite: AERO-88` copy button, `Verified` anti-cheat badge, Squad Standings leaderboard with Priya Sharma #1, Marcus Chen #2, Amina Diallo #3, Sunil Kumar #4, **3x3 Kinetic Step Bingo** grid, Live Team Pulse chat).
14. `aerostep_ai_ai_coach_weight_loss_hub/` (`code.html` + `screen.png`) — AI Coach & Weight-Loss Hub (Voice/Chat mode toggle, Stride Intelligence Tangerine quote card, `1.75 / 2.5 L` animated liquid cylinder Hydration card with `+250ml` button, `1,420 / 2,100 kcal` AI Meal Snap card with macros `P: 84g C: 160g F: 42g`, `2 Rest Days Available` Streak Shield card, `-420 kcal net` Metabolic Deficit progress bar).
15. `aerostep_ai_stride_ai_coach/` (`code.html` + `screen.png`) — Biomechanical Gait & Audio Drill Coach (Accessible as the "Biomechanics & Gait" sub-tab inside the AI Coach Hub: `Dynamic Gait Matrix` 3D foot-sole pressure map `72% Forefoot / 28% Heel`, `164 SPM` Cadence Tempo, `+4.2 DEG/S` Pronation Velocity, `Interval Cadence Drill 172 BPM` audio player, Hydration Window, and live voice question bar).
16. `aerostep_ai_widget_showcase_smartwatch/` (`code.html` + `screen.png`) — Widgets & Wrist Companion Showcase (`2x2 Small Tangerine Widget`, `4x2 Medium Interactive Bento Widget` with live `+250ml` water tap, `Always-On OLED Smartwatch Dial` `10:42 AM • 8,420 / 10k • 118 SPM`, Sync Companion Face toggle).
17. `aerostep_ai_unlock_pass_pro_vip/` (`code.html` + `screen.png`) — Ethical Unlock Pass & Pro VIP Modal (`NO POPUP ADS PROMISE` badge; Option 1: Free Daily Reward Pass — Watch 1 Short 30s Video to unlock `1x Streak Shield` or `24h Trail Pass`; Option 2: `#141416` Charcoal & Sunset Tangerine Pro VIP card with `$14.99/yr` Annual Pass SAVE 37% and `$1.99/mo` Monthly Flexibility + 7-Day Free Trial).
18. **Hero Runner Photography Assets:** Copy `full_body_shot_of_an_athletic_energetic_young_woman_runner_smiling_while/screen.png` and `athletic_young_runner_in_stylish_dark_obsidian_athletic_apparel_with_glowing/screen.png` into Flutter `assets/images/` for offline-first rendering on the Light and Dark Onboarding screens.

---

## 4. Mandatory UI/UX Polish & Fixes (Apply Automatically During Phase 2)
While converting the Stitch `code.html` files into Flutter widgets, you MUST apply these 4 fixes automatically:
1. **Fix Dark-on-Dark Text Contrast Bug in `aerostep_ai_trends_analytics`:**
   * In `aerostep_ai_trends_analytics/code.html`, a typo class (`text-surface-lowest` instead of `text-surface-container-lowest`) caused the active `"Week"` pill button text and the `"Century Streak"` title inside the `#141416` dark charcoal containers to render in dark black text.
   * **Rule:** In Flutter, every `#141416` or `#1C1714` dark charcoal pill, button, or card MUST enforce `#FFFFFF` (`Colors.white`) for primary headings/selected tab labels and `#FFDBCC` / `#FF7A2F` for accent text.
2. **Standardize the Floating Split-Pill Bottom Navigation Dock (`AeroFloatingBottomDock`):**
   * Across all main screens, render one consistent floating split-pill dock at the bottom:
     * **Left `#141416` Charcoal Capsule (4 Main Tabs):**
       1. `Home` (`directions_walk` / `roofing` — toggles between `Home Dashboard` and `Daily Activity Tracker` view, with a quick header toggle for Light Mode vs Warm Espresso Dark Mode).
       2. `Analysis` (`query_stats` — switches between `Analysis & Active Calories` and `Trends & Analytics`).
       3. `Trails` (`explore` — `Virtual World Adventures`).
       4. `Squads` (`groups` — `Squads & Kinetic Step Bingo`).
       * *Active Tab Styling:* Sits inside a solid Sunset Tangerine (`#FF7A2F`) circle with soft orange glow `BoxShadow(color: Color(0x73FF7A2F), blurRadius: 14)`.
     * **Right Detached 56x56 Circular Button (8px gap):**
       * Sunset Tangerine gradient (`#FF7A2F` to `#FFA163`) with white `auto_awesome` AI Sparkle icon and a pulsing Sky-Cyan (`#46CFFE`) online dot. Tapping opens the **AI Coach Hub** (which includes both `Weight-Loss Hub` and `Stride Biomechanics Coach`).
3. **Seamless Navigation Wiring for Secondary Screens:**
   * Tapping `"Quick Start Walk"`, `"Start Evening Stride"`, or `"Sunset Interval Walk (START)"` launches `aerostep_ai_live_walk_pace_coach`.
   * Tapping the Watch/Widget icon or Profile menu opens `aerostep_ai_widget_showcase_smartwatch`.
   * Tapping `"Unlock"`, `"Claim Perks"`, or the Pro badge opens `aerostep_ai_unlock_pass_pro_vip`.
4. **Tabular Numerals & Overflow Safety:**
   * Apply `Space Grotesk` with `FontFeature.tabularFigures()` on all step, calorie, distance, cadence, and timer readouts so live sensor increments never jitter horizontally. Wrap all rows/grids in responsive constraints so small 360px screens have zero RenderFlex overflow errors.

---

## 5. Technical Architecture & Pacer Pain-Point Solutions (Phase 3 & 4)
Use open-source Flutter packages (`flutter_riverpod`, `drift` or `isar`, `health`, `pedometer`, `sensors_plus`, `flutter_activity_recognition`, `flutter_foreground_task`, `disable_battery_optimization`, `fl_chart`, `home_widget`, `google_mobile_ads`, `share_plus`, `google_fonts`) to solve all 7 Pacer user complaints:
1. **Zero-GPS Battery Saving Mode:** Use hardware `TYPE_STEP_COUNTER` (Android) and `CMStepCounter` (iOS) for `<2%` daily battery consumption. Only enable GPS when the user switches to `"Outdoor Route"` in `Live Walk & Stride`.
2. **Smart Anti-Shake & Vehicle Auto-Pause Filter:** Combine `flutter_activity_recognition` (`IN_VEHICLE`, `ON_BICYCLE`) with a 120Hz accelerometer/gyroscope cadence gate (valid walking requires `60–220 SPM` sustained for `>6 seconds`) so car/bus/rickshaw vibrations and hand shaking never add fake steps.
3. **1-Tap Android OEM Battery Protection Wizard:** Implement the exact `aerostep_ai_smart_setup_battery_protection_light` screen to auto-detect `Samsung`, `Xiaomi`, `Realme`, `Oppo`, `Vivo`, `OnePlus`, and `Pixel` and trigger native `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` + OEM auto-start intents alongside a lightweight foreground notification.
4. **Zero-Variance Health Sync Deduplication:** Merge hardware step sensor deltas with **Google Health Connect** and **Apple HealthKit** using 15-minute UTC bucket deduplication so smartwatch + phone steps never double-count.
5. **Timezone-Proof UTC Ledger:** Store all step, calorie, and hydration logs in UTC with local timezone offsets so traveling across timezones never breaks streaks.
6. **Streak Shield & Rest Day Guard:** Implement automatic Streak Shield deployment (Level 4 / 2 Rest Days available, plus free unlock via 1 voluntary rewarded video ad).
7. **Ethical AdMob Monetization:**
   * **ZERO** unsolicited full-screen interstitial popups on app open or tab switches.
   * Wire **Voluntary Rewarded Video Ads** to the `"Watch Video to Unlock (30s)"` button in `aerostep_ai_unlock_pass_pro_vip` and `"Unlock"` trail buttons, plus subtle native banners on secondary scrolls.

---

## 6. Sequential 10-Phase Execution Checklist (`BUILD_PROGRESS_CHECKLIST.md`)
Maintain `BUILD_PROGRESS_CHECKLIST.md` and verify every phase before advancing:
* [ ] **Phase 1: Smart Open-Source Bootstrap & Stitch Asset Ingestion** — Unzip `stitch_aerostep_ai_fitness_app.zip` if needed, copy local runner images into `assets/images/`, initialize Flutter (`com.sunilkhatri.aerostep`), install packages, and pass `flutter analyze`.
* [ ] **Phase 2: Warm Bento Dynamic UI/UX Implementation (All 13 Screens + Light & Espresso Dark Themes)** — Implement all 13 Stitch screens, apply the `#141416` white-text contrast fix, unify the Floating Split-Pill Dock, and verify zero layout overflows.
* [ ] **Phase 3: Core Pedometer, Anti-Shake Vehicle Filter, OEM Battery Fix & UTC Health Sync** — Build hardware sensor + Health Connect/HealthKit deduplication, vehicle filter, OEM battery intents, and pass unit tests.
* [ ] **Phase 4: Ethical Google AdMob Integration** — Wire Rewarded Video Ads (`1x Streak Shield` / `24h Trail Pass`) and non-intrusive native ads.
* [ ] **Phase 5: Complete iOS Workspace & WidgetKit Readiness (Do Not Publish to App Store)** — Configure `ios/Podfile`, `Info.plist`, HealthKit entitlements, Swift `WidgetKit` extension (`2x2` & `4x2`), and verify `flutter build ios --config-only --no-codesign`.
* [ ] **Phase 6: GitHub Repository Push & Live GitHub Pages Privacy Policy / `app-ads.txt`** — Push complete Flutter + iOS code to GitHub, publish `/docs/privacy-policy.html` & `/docs/app-ads.txt` on GitHub Pages, and verify HTTP 200 via `curl -I`.
* [ ] **Phase 7: Physical Mobile USB (`adb`) Hardware QA & Signed Release `.aab`** — Run all 8 live hardware tests on the connected Android phone, capture real screenshots, verify zero errors in `adb logcat`, and build signed `app-release.aab`.
* [ ] **Phase 8: Ahrefs + Chrome ASO Keyword Research & Store Listing Copy** — Research high-volume, low-difficulty pedometer keywords and generate Title (30 chars), Short Description (80 chars), and Full Description (4,000 chars).
* [ ] **Phase 9: Play Console Visual Assets & 60fps Motion Graphics Promo Video** — Generate 512x512 App Icon, 1024x500 Feature Graphic, 8 Framed 1080x1920 Screenshots (in Warm Peach & Tangerine Bento style), and a 30s Motion Graphics Promo Video.
* [ ] **Phase 10: Google Play Console Automated Submission via Logged-In Chrome** — Fill all App Content declarations (Privacy Policy URL, Data Safety, Health Connect, Content Rating, Ads), upload all graphics and `app-release.aab`, and submit for release.