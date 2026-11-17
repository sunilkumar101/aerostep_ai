# AeroStep AI — ASO keyword research (Phase 8)

Source: Ahrefs Keywords Explorer, 2026-11-17. **Google web-search** volumes (US monthly, plus global),
used as a proxy for Play Store demand. Play's own search volumes aren't exposed by any public API.
KD = Ahrefs keyword difficulty (0–100, web SERP).

## Head terms (high volume, the listing must contain them)
| Keyword | US vol | Global vol | KD | Used in |
|---|---:|---:|---:|---|
| pedometer | 19,000 | 44,000 | 38 | Title, full |
| step counter | 9,500 | 34,000 | 47 | Short, full |
| step tracker | 4,600 | 14,000 | 52 | Full |
| pedometer app | 3,600 | 10,000 | 70 | (title + "app" context) |
| step counter app | 3,000 | 12,000 | 62 | (short + full) |
| walking app | 2,600 | 8,200 | 41 | Full |
| walking tracker | 700 | 1,900 | 50 | Full |

## Low-difficulty opportunities (KD ≤ 35)
| Keyword | US vol | Global vol | KD | Notes |
|---|---:|---:|---:|---|
| most accurate step counter | 700 | 1,000 | 16 | Anti-shake / vehicle filter story ("Counts more accurately") |
| free walking app | 1,400 | 2,500 | 28 | Covered by the "no account, no popup ads" message; "free" kept out of the title (Play policy) |
| best free walking app | 900 | 1,200 | 12 | Policy forbids "best" in metadata; target via ratings/reviews |
| best step counter app | 700 | 3,000 | 1 | Same: earn via reviews, not wording |
| most accurate pedometer | 400 | 500 | 2 | "Counts more accurately" section |
| easy walking app | 300 | 600 | 0 | Simple onboarding, no account |
| walking app for weight loss | 30 | 80 | 9 | Dedicated section in full description |
| walking challenge app | 300 | 500 | 36 | Step Bingo (squads backend still pending) |

## Policy guardrails applied
- No "best", "#1", "top", "free" or emoji in the title. No competitor names (e.g. Pacer) anywhere.
- Only shipped features are described. **Not** advertised yet, because they are UI demos without a backend:
  squad leaderboards / team chat, Virtual Trail progress, AI Meal Snap, Pro subscription.
- No unverifiable numeric claims (e.g. "99.4% precision", "<2% battery"); "no GPS" is used instead.

## Suggested title alternatives (A/B test in Play Console "Store listing experiments")
- `AeroStep: Pedometer & Step AI` (29): current, per the runbook
- `AeroStep Pedometer: Step Count` (30): more head-term coverage
- `AeroStep: Step Counter & Walk` (29): targets "step counter" + "walking app"
