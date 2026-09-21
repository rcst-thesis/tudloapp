# G3 U2 L2.1 — Ang Nadula nga Ido: SVG Asset Map

These are the lesson-specific assets only. Koka, shared navigation, buttons, progress bars, audio controls, checks, locks, hotspot rings, arrows, speech bubbles, activity panels, and text must use the existing app components or be rendered in code.

| Asset | Use |
|---|---|
| `animals/Bantay_Idle.svg` | Event card and non-celebration Bantay appearance |
| `animals/Bantay_Happy.svg` | Farm reveal and reward page |
| `people/Vendor_Female_Idle.svg` | Market arrival and tappable vendor hotspot |
| `people/Vendor_Female_Pointing.svg` | Vendor clue response, “Tan-awa sa uma!” |
| `props/Dog_Bed_Empty.svg` | House intro and NADULA event card |
| `props/Dog_Bowl.svg` | House intro beside the empty bed |
| `clues/Dog_Footprint.svg` | Reuse exactly three times for the Farm trail |
| `clues/Farm_Clue_Card.svg` | Story tray after the vendor clue |
| `map/*_Location_Icon.svg` | Four-location gated map cards |
| `reward/Story_Detective_Sticker.svg` | Final collectable reward |

## Existing backgrounds to reuse

- House/living room: `HospitalLandscape-1 1.svg`
- Classroom: `ClassroomLandscape 1.svg`
- Market: `MarketLandscape 1.svg`
- Farm: `FarmLandscape 1.svg`

## Code-built elements

- Classroom hotspot hit areas and labels: `Lamesa`, `Bag`, `Pultahan`
- Search counters `0/3` to `3/3`
- Footprint enabled, disabled, completed and pulsing states
- Sequence cards and drop slots
- Correct/incorrect feedback animations
- Route completion checks and all instructional text

Use `object-fit: contain` for every SVG. Never bake lesson text into character or object assets.
