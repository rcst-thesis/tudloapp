# G3 U1 L1.3 — Pagbakal ni Koka sa Merkado

This pack contains the lesson-specific SVG assets for the Grade 3 landscape lesson.

## Included

- `background/` — market landscape.
- `people/` — two Nanay poses, nine-year-old child, fruit vendor, fish vendor, and general vendor.
- `products/` — mango, fish, flower, spoon, chair, candle, single banana, and egg.
- `shopping_props/` — cup, basket, list, price tag, peso coin, play money, tray, and crate.
- `stalls/` — reusable empty fruit, fish, flower and inventory stalls plus a market counter.

## Intentionally excluded

- New Koka artwork. Use the project's approved existing Koka assets.
- Hands, stars, sparkles, confetti and generic UI graphics.
- Baked-in answer text, prices and quantities.

## Key implementation rule

Duplicate the single product SVGs in code to create exact quantities. Keep prices, labels, question text and answer text as application-rendered text.

## Main lesson mapping

- Intro: Koka Idle + Nanay shopping-list pose.
- Age model: `Boy_Age_9.svg`.
- Chair example: duplicate `Chair.svg` 12 times.
- Mango price example: one `Mango.svg` with `Price_Tag_Blank.svg`, displaying 10 pesos in code.
- Fish price question: `Stall_Fish_Empty.svg`, `Fish.svg`, `Vendor_Fish_Male.svg`, and a 15-peso label rendered in code.
- Mango quantity question: duplicate `Mango.svg` six times.
- Flower price question: `Flower_Pink.svg` with a 5-peso label.
- Birthday-age question: `Boy_Age_9.svg` and eight duplicated candles.
- Twenty-peso question: `Price_Tag_Blank.svg` with 20 pesos rendered in code.
- Spoon quantity question: duplicate `Spoon.svg` 11 times.
- Shopping challenge: basket, shopping list, bananas, eggs and cups.
