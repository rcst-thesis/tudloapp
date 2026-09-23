# UI and Responsive Rules

## Visual Foundation

- Font: bundled `ComicRelief`, weights 400 and 700.
- Shared colors: mint `#ACE6B0`, green `#4E9F3E`, dark green `#2C6121`, lime
  `#70DF43`, charcoal `#202020`.
- Home wall `#EADF99`, navigation `#BD8C57`, selected Home tile `#966E42`.
- Rounded layered controls, visible depth, friendly art, centered composition,
  and concise child-readable labels are established visual traits.

Do not normalize the screens into generic Material layouts; much geometry is
deliberately aligned with supplied artwork.

## Baseline and Runtime Strategies

Main Menu, Name, Grade, Energy, Learner Card, and Load use a 412×917 reference
canvas inside `FittedBox(BoxFit.contain)`. Back/pagination controls are separately
SafeArea-positioned and scaled on both axes.

Home and Welcome are more adaptive:

- Home uses `LayoutBuilder`, centered max width 720, responsive top controls,
  and an independent scroll scene.
- Welcome selects normal/wide SVG layers and computes bounded scene/text/action
  sizes from available constraints.

Preserve each screen's current strategy unless a requested, tested redesign
explicitly replaces it.

## Aspect Ratio

Must retain aspect ratio: Koka characters/loading art, logos, badges, icons,
headers, speech bubbles, Home lamp/window/settings/energy/navigation icons,
Welcome layers, circular controls, and illustrated cards.

May intentionally fill/stretch: flat backgrounds, flexible scroll regions,
spacers/panels, and fixed-reference hit regions.

Prefer `BoxFit.contain`, `AspectRatio`, bounded `LayoutBuilder`, and centered
constraints. Review existing `BoxFit.fill` before changing it; do not apply it to
protected artwork.

## Safe Areas and Orientation

- Dart and native configuration currently restrict portrait orientation.
- Most screens use one `SafeArea` for primary content.
- Home bottom navigation owns bottom SafeArea with `top: false`.
- Do not add duplicate SafeArea padding.
- Keep controls clear of status bars, notches, rounded corners, gesture areas,
  hinges, and keyboards.
- Portrait success does not prove landscape readiness; add explicit landscape
  tests before removing orientation locks.

## Home Contract

```text
fixed energy/settings
scrollable wall + lamp + window + future scene content
fixed bottom navigation
```

- Only scene content scrolls; lamp/window move with it.
- Energy, Settings, and bottom navigation remain stationary.
- Content is centered and capped at 720 logical pixels.
- Current scene height is temporary: at least 720 and 1.5× viewport height.
- `_HomeSceneLayout` contains the 412-wide window reference: left 194, top 160,
  size 128.

### Bottom Navigation

- Six equal-width items: Home, Translate, Lessons, Map, Dictionary, Me.
- Home remains selected until tab state exists.
- Per-icon display sizes are intentional optical corrections.
- Every label shares one computed size; `dictionary` determines the limiting
  width. Do not assign inconsistent sizes.
- Selected tile uses aspect ratio 0.92 and radius 12; do not force a perfect
  square or excessive rounding.
- Content max width is 720 with horizontal breathing room.

## Motion and Interaction

- Prefer smooth low-amplitude ambient motion.
- Home window is a ten-second loop; sun/cloud composition must survive resize.
- Lamp toggles local state and fades its beam.
- Welcome combines touch tilt with optional sensor support; current screen
  disables hardware tilt.
- Learner-card painters are repaint-bounded/quantized for performance.
- Honor `MediaQuery.disableAnimations` with a stable resting state.
- Maintain semantics and usable hit regions even when visible art is small.

## Text and Accessibility

- Do not solve peer-label overflow with inconsistent font sizes.
- Prefer bounded widths, deliberate wrapping, max lines, or scale-down while
  keeping text readable.
- Some fixed-canvas screens use `MediaQuery.withNoTextScaling` to protect exact
  geometry. This is a known limitation, not a default for new accessible UI.
- Name remains a real Flutter text field with keyboard-safe resizing.
- Image-only/custom-painted controls need semantic labels/button roles.

## Required Verification

Check 320×480, 360×640, 412×917, and 800×1200; bottom insets; long names/labels;
reduced motion; Home fixed-versus-scroll behavior; and absence of overflow,
clipping, distortion, unintended crop, overlap, or competing hit areas.

## NEEDS PROJECT CONTEXT

- Official orientation target.
- Required text-scaling/accessibility range.
- Canonical Figma frames/approved measurements.
- Which versioned assets remain production candidates.
- Tablet-specific composition beyond centered scaling.

