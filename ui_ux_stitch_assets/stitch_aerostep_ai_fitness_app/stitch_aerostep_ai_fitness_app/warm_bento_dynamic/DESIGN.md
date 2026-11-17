---
name: Warm Bento Dynamic
colors:
  surface: '#fcf8fb'
  surface-dim: '#dcd9dc'
  surface-bright: '#fcf8fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f5'
  surface-container: '#f0edef'
  surface-container-high: '#eae7ea'
  surface-container-highest: '#e5e1e4'
  on-surface: '#1b1b1d'
  on-surface-variant: '#584238'
  inverse-surface: '#303032'
  inverse-on-surface: '#f3f0f2'
  outline: '#8c7166'
  outline-variant: '#dfc0b2'
  surface-tint: '#a04100'
  primary: '#a04100'
  on-primary: '#ffffff'
  primary-container: '#ff7a2f'
  on-primary-container: '#612400'
  inverse-primary: '#ffb693'
  secondary: '#006782'
  on-secondary: '#ffffff'
  secondary-container: '#46cffe'
  on-secondary-container: '#00566d'
  tertiary: '#934b13'
  on-tertiary: '#ffffff'
  tertiary-container: '#e48b4f'
  on-tertiary-container: '#5c2900'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbcc'
  primary-fixed-dim: '#ffb693'
  on-primary-fixed: '#351000'
  on-primary-fixed-variant: '#7a3000'
  secondary-fixed: '#bbe9ff'
  secondary-fixed-dim: '#5fd4ff'
  on-secondary-fixed: '#001f29'
  on-secondary-fixed-variant: '#004d63'
  tertiary-fixed: '#ffdbc8'
  tertiary-fixed-dim: '#ffb689'
  on-tertiary-fixed: '#311300'
  on-tertiary-fixed-variant: '#743500'
  background: '#fcf8fb'
  on-background: '#1b1b1d'
  surface-variant: '#e5e1e4'
typography:
  display-hero:
    fontFamily: Space Grotesk
    fontSize: 56px
    fontWeight: '700'
    lineHeight: 60px
    letterSpacing: -0.04em
  display-hero-mobile:
    fontFamily: Space Grotesk
    fontSize: 44px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '800'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.01em
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  data-metric-lg:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.03em
  data-metric-sm:
    fontFamily: Space Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: -0.02em
  label-caps:
    fontFamily: Space Grotesk
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.06em
  caption:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 0.75rem
  gutter-md: 1rem
  margin: 1rem
  margin-md: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.875rem
  space-lg: 1.25rem
  space-xl: 1.75rem
  space-2xl: 2.5rem
---

## Brand & Style

This design system blends an energetic fitness lifestyle with high-end editorial tech. Tailored for dynamic urban movers, runners, and everyday steppers, the aesthetic replaces clinical biometric screens with an optimistic, sensory warmth. 

The visual strategy merges modern Bento card architecture, soft organic peach gradients, and high-impact kinetic data. Tactile materials, warm atmospheric backdrops, and crisp geometric data metrics transform daily step counts, pacing telemetry, and AI movement coaching into an inviting ritual.

## Colors

The palette balances radiant kinetic energy with grounding charcoal contrast:

- **Primary Canvas**: A soft Peach-Apricot wash radiating from `#FFFDFB` to `#FDE8D7`, decorated with micro-opacity geometric starbursts to inject visual motion without visual clutter.
- **Sunset Tangerine Accent**: Driven by `#FF7A2F` transitioning into `#FFA163`, reserved for primary action zones, progress streaks, and the dedicated AI kinetic button.
- **Sky-Cyan Telemetry**: `#38C6F4` acts as a high-visibility accent for real-time telemetry, cadence signals, GPS tracking, and micro badges.
- **Deep Charcoal & Text**: `#141416` delivers resolute structural contrast for critical headings, icon glyphs, and primary floating navigation hulls.
- **Frosted Translucent White**: `#FFFFFF` at 90% opacity layered over the warm apricot background, generating soft, airy bento tiles.
- **Dark Mode Extension**: Canvas flips to Warm Espresso Obsidian (`#12100E`), shifting Bento surfaces into smoked glass surfaces (`#221C18`) paired with neon-tinted Tangerine and Cyan accents.

## Typography

The typographic hierarchy implements an expressive, dual-type strategy:

1. **Plus Jakarta Sans** leads user interfaces, motivational statements, headings, and conversational AI summaries. Its rounded geometry reinforces approachable warmth.
2. **Space Grotesk** serves as the telemetry engine. Dedicated to step counters, active calorie readouts, pacing stats, and upper-case capsule chips, its technical proportions emphasize precision and digital craftsmanship.

## Layout & Spacing

A strict fluid modular grid organizes interface modules into dynamic Bento panels. 

- **Grid Alignment**: 4-column base structure on mobile devices transitioning to an 8-column layout on tablets. Bento cards span 2 or 4 mobile columns to deliver staggered, asymmetrical visual weight (e.g., a dominant 2x2 daily step circle tile paired alongside two stacked 2x1 tiles for hydration and cadence).
- **Rhythm & Padding**: Outer edge safety margin defaults to `1rem` on mobile, scaling to `1.5rem` on larger screens. Gutters maintain `0.75rem` to keep cards grouped and tactile. Internal bento container padding adheres strictly to `space-lg` (`1.25rem`).
- **Safe Clearance**: Persistent bottom layouts implement an extra `5rem` bottom clearance buffer to prevent overlap with the floating split-pill dock.

## Elevation & Depth

Visual hierarchy uses frosted planar layering and warm diffused ambient shadows rather than stark linear separators:

- **Bento Card Surface**: 90% opacity white with an underlying 16px blur radius, complemented by a soft sunset drop shadow (`rgba(255, 122, 47, 0.08)` at 20px blur with a 6px vertical offset).
- **Micro-Borders**: Subsurface panels leverage low-contrast ambient borders: 1px solid white (`rgba(255, 255, 255, 0.6)`) to accentuate edge crispness against the gradient canvas.
- **AI Glowing Orb**: Elevated to the highest z-index using a dual-ring glow: an inner radial drop shadow (`#FF7A2F` at 35% opacity, 16px blur) and an outer atmospheric halo (`#FFA163` at 20% opacity, 32px blur).
- **Dark Mode Smoked Elevation**: In Espresso mode, surfaces employ a subtle 1px border (`rgba(255, 255, 255, 0.08)`) with deeply tinted ambient shadows (`rgba(0, 0, 0, 0.5)` at 24px blur).

## Shapes

The interface is defined by extra-rounded surfaces and continuous curves:

- **Bento Tiles**: Built with an exaggerated 28px outer border radius (`rounded-xl` customization), creating a soft, pebble-like aesthetic.
- **Capsule Badges**: Full pill rounding (9999px) for telemetry indicators, live markers, and status chips.
- **Control Surfaces**: Floating dock, interactive pills, and primary buttons conform to complete capsule geometries for smooth thumb interaction.

## Components

### Bento Cards
- **Construction**: 28px rounded corners, frosted white base (`rgba(255, 255, 255, 0.90)`), 1px translucent perimeter stroke, and warm apricot-tinted drop shadows.
- **Internal Layout**: Top-left contains capsule metadata or category icon; center/bottom houses Space Grotesk headline metrics paired with a Plus Jakarta Sans sub-label.

### Floating Split-Pill Dock
- **Navigation Capsule**: Deep Charcoal (`#141416`) elongated capsule housing 3–4 minimalist frosted icon buttons with dynamic micro-dot indicators for active states.
- **Detached AI Spark Button**: A floating 56px circular button separated by an 8px air gap from the main dock. Finished with a Sunset Tangerine gradient (`#FF7A2F` to `#FFA163`), glowing warm ambient shadow, and an inset white kinetic AI star icon.

### Vertical & Horizontal Capsule Badges
- **Metrics Telemetry Badges**: Space Grotesk uppercase typography set inside full-radius capsules. Sky-Cyan tint (`#38C6F4` at 15% fill with `#0C8BB5` text) indicates live pacing, while Tangerine badges indicate active calorie burn streaks.

### Buttons & Interactive Controls
- **Primary Actions**: Full capsule geometry filled with linear Sunset Tangerine gradient, bold white Plus Jakarta Sans text, and an inner edge highlight.
- **Secondary / Ghost Controls**: Translucent frosted capsules with deep charcoal labels and a subtle 1px ambient border.

### Inputs & Selection States
- **Form Controls & Search**: Full pill search bars with inset frosted fills and warm active outlines on focus.
- **Toggle Switches & Radios**: Smooth pill tracks transitioning from warm muted gray (`#E5DFDA`) to lively Sky-Cyan or Sunset Tangerine upon state activation.