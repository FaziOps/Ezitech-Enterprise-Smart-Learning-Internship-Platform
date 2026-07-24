# UI Design System — Glass Morphism

## Where it lives

- `lib/core/theme/app_colors.dart` — every color used anywhere in the app.
- `lib/core/theme/app_tokens.dart` — spacing, radius, blur, breakpoints, motion durations.
- `lib/core/theme/app_theme.dart` — Material `ThemeData` (typography, buttons, inputs).
- `lib/core/widgets/glass_container.dart` — `GlassContainer` and `GlassCard`, the two building blocks every screen uses.
- `lib/core/widgets/ambient_background.dart` — the animated gradient + blob background that makes the glass blur actually read as glass.

If you're building a new screen, you should not need to write a single
`BackdropFilter` or `BoxDecoration` by hand — compose these five files.

## The core idea

Glass morphism only looks like glass if there's something colorful behind
the blur. A flat dark background makes `BackdropFilter` look like a grey
smudge, not glass. That's why every authenticated screen is wrapped in
`AmbientBackground`: it renders a dark gradient plus three slow-drifting
colored blobs, and `GlassContainer` panels sit on top of it.

## Tokens

**Colors** (`AppColors`): a dark navy-to-violet background gradient
(`bgTop`/`bgMid`/`bgBottom`), white-at-low-opacity glass fills
(`glassFillLight` ~12%, `glassFillStrong` ~20%), and five accent colors
each with a fixed meaning — don't reassign them per-screen:
- `primary` (indigo-blue) — main actions, active states, courses
- `secondary` (teal) — progress, success, sync-complete
- `warning` (amber) — pending/offline states
- `danger` (red/coral) — overdue, errors, destructive actions
- `aiAccent` (violet) — reserved for the AI Assistant only

**Spacing** (`AppSpacing`): `xs=4, sm=8, md=16, lg=24, xl=32, xxl=48`.
Always use these constants, never a raw number, so density stays
consistent.

**Radius** (`AppRadius`): `sm=12, md=20, lg=28, pill=999`. Glass morphism
reads as soft — nothing in this app should have a sharp corner.

**Breakpoints** (`AppBreakpoints`): `isTablet(context)` at 720px width.
Used by the Dashboard's two-column layout and by
`core/widgets/responsive_center.dart`, which every list screen added in
Week 4 now uses to cap content width on tablets instead of stretching
edge-to-edge.

## Components

### `GlassContainer`
The base panel: blur + translucent fill + border + subtle top-left sheen
+ drop shadow. Every card, every input background, every bottom-nav bar
is one of these.

### `GlassCard`
A `GlassContainer` with tap feedback (slight scale-down + fill brighten
on press). Use this instead of `GlassContainer` + `GestureDetector`
whenever the panel navigates somewhere or triggers an action.

### `AmbientBackground`
Wraps a screen's body. Owns the animation controller for the drifting
blobs — wrapped in a `RepaintBoundary` (added in the Week 4 performance
pass) so the continuous animation doesn't force repaints of the glass
panels and content stacked on top of it.

### `OfflineIndicator`
A small glass pill, only rendered when there's something to say
(offline, syncing, or stuck items needing attention) — deliberately
invisible the rest of the time so it doesn't nag.

## Typography

`Sora` via Google Fonts, applied through `AppTheme.dark`'s `textTheme`.
Text color defaults: `textPrimary` (near-white, ~100%), `textSecondary`
(~80%), `textMuted` (~60%), `textDisabled` (~30%) — pick based on
hierarchy, not per-screen judgment calls.

## Motion

`AppMotion.fast` (150ms), `.medium` (280ms), `.slow` (420ms), all
`Curves.easeOut`. Used for tap feedback, tab transitions, and container
color changes. Don't hand-roll a different duration/curve combination
elsewhere — consistency is the point.

## Accessibility notes from the Week 4 pass

- Icon-only buttons (back arrows, password visibility toggle, send
  buttons) now have `tooltip` set — screen readers announce these instead
  of silence.
- Text contrast: `textPrimary`/`textSecondary` against the dark gradient
  background comfortably clears WCAG AA at normal sizes; `textMuted` and
  `textDisabled` are intentionally lower-contrast for de-emphasis and
  should not be used for primary content.
- **Not verified**: behavior under large system text-scale settings, and
  screen-reader navigation order across the glass panels. Both need a
  pass on a real device with TalkBack/VoiceOver enabled — that's a manual
  QA step, not something I can validate without a device or a Flutter
  toolchain in this environment. Don't take "accessibility pass" in the
  Week 4 goals as fully complete; the tooltip fixes are real, the
  device-level verification isn't done.
