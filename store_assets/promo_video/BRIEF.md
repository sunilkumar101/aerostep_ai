---
workflow: general-video
flow: automation
storyboard: no
message: "Accurate steps, zero GPS battery drain, no popup ads"
destination: youtube
aspect: "16:9"
language: en
audience: Android users looking for a battery-friendly, accurate pedometer
length: 30s
angle: product promo built from the app's real screens
fps: 60
---

## Intent
30-second motion-graphics promo for the Google Play "promo video" (YouTube URL) field.
Autonomous run per the project runbook (CLAUDE.md "zero-prompt" rule): no interview, no storyboard pass.
Landscape 16:9 because Play's promo-video guidance prefers landscape.

## Assets
- Phone renders cropped from `store_assets/play/screenshots/*.png` (real app UI, demo data).
- App icon `store_assets/play/icon_512.png`.
- Fonts: Plus Jakarta Sans + Space Grotesk (bundled OFL files from `assets/google_fonts`).

## Customizations
- Warm Bento Dynamic palette: peach canvas #FFFDFB→#FDE8D7, tangerine #FF7A2F→#FFA163, charcoal #141416, sky-cyan #46CFFE.
- Only shipped features are shown (no squads leaderboard, trail progress or meal snap).
- No Google Play badge/trademark; closing card names the app only.

## Notes
- No music bed or voice-over (no licensed audio supplied); silent video is valid for Play.
