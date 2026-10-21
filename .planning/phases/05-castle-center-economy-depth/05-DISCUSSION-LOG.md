# Phase 5: Castle Center & Economy Depth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-21
**Phase:** 05-castle-center-economy-depth
**Areas discussed:** Castle tiers & the four abilities, Choice cards: flow and controls, New plots on the map & the goldens, Income curves & destroyed-building rules

---

## Castle tiers & the four abilities

| Option | Description | Selected |
|--------|-------------|----------|
| Three tiers, two picks (Recommended) | Castle starts at tier I; II and III raise health (about 70 → 210 → 490) and each offers one of four abilities; costs about 7 then 20 gold, fitted by the bots | |
| Four tiers, three picks | One more rung, three picks per run, gentler health and cost step, twelve abilities to author | ✓ |

**User's choice:** Four tiers, three picks

| Option | Description | Selected |
|--------|-------------|----------|
| Claude picks eight, Thronefall-style (Recommended) | Run-wide passives touching only systems that exist by Phase 5, through the new stacking order (e.g. Royal Training, Commander, Masons, Prosperity, Assassin's Training, Engineers, Rallying Banner, Magic Armor) | ✓ |
| Same four lines at both tiers, tier III deepens the tier II pick | Four ability lines with a stronger second step each | |
| Two stat picks and two rule-changers per tier | Half plain bonuses, half rule changes | |

**User's choice:** Claude picks them (twelve with four tiers)

| Option | Description | Selected |
|--------|-------------|----------|
| Top tier of every building needs castle II (Recommended) | One gate, authored per tier in data; label "Needs Castle II", denied bump on hold | ✓ |
| Tier II needs castle II, tier III needs castle III | Two gates; the first castle upgrade near-mandatory early | |

**User's choice:** Top tier of every building needs castle II

| Option | Description | Selected |
|--------|-------------|----------|
| Health only; abilities do the rest (Recommended) | Castle arrow and base income unchanged at every tier | |
| Each tier also raises the castle's arrow and base income | Tiers II to IV add castle damage and +1 base gold each | ✓ |

**User's choice:** Each tier also raises the castle's arrow and base income

**Notes:** "More questions or next area?" → Next area. The health, arrow and base-income steps per tier are data fitted by the planner and the bots.

---

## Choice cards: flow and controls

| Option | Description | Selected |
|--------|-------------|----------|
| Approach, pick, then hold to pay (Recommended) | Cards appear on approach; highlight with keys 1–4 or the mouse; the usual hold pays; nothing spent until the last coin; release or ride away cancels free; the pick locks when the hold completes | ✓ |
| Pay first, then pick | The hold buys the tier, then the cards pop up and the day waits for a pick | |
| Click a card to buy it outright | The mouse buys instantly, no hold | |

**User's choice:** Approach, pick, then hold to pay

| Option | Description | Selected |
|--------|-------------|----------|
| A row above the castle in world space (Recommended) | Cards hover over the plot like the spot label; highlighted card raised and brighter; day only, in range only | ✓ |
| A strip at the bottom centre of the HUD | Cards in the squad-strip area | |
| A centred panel over the play area | A menu-like panel covering the centre | |

**User's choice:** A row above the castle in world space

| Option | Description | Selected |
|--------|-------------|----------|
| Numbers in the description (Recommended) | "Royal Training: +25% king health and damage" on the card itself | |
| Flavour line, numbers on hover | Short flavour line on the card; exact numbers when highlighted | ✓ |

**User's choice:** Flavour line, numbers on hover

**Notes:** "More questions or next area?" → Next area. Icon art, card size and the highlight look are Claude's.

---

## New plots on the map & the goldens

| Option | Description | Selected |
|--------|-------------|----------|
| Add the plots, regenerate the goldens once (Recommended) | New plots on the prototype map; goldens regenerated in one deliberate commit with a before/after outcome report (Phase 4 D-14 precedent) | ✓ |
| Keep the prototype map untouched; new buildings on a second sandbox map | Two maps to balance and screenshot; the bar measured without the new economy | |

**User's choice:** Add the plots, regenerate the goldens once

| Option | Description | Selected |
|--------|-------------|----------|
| 1 Mine, 1 Mill + 3 Fields, 1 Harbor, 2 Shrines (Recommended) | Eight plots (14 → 22); Fields visible from the start and locked until the Mill stands | ✓ |
| Bigger set: 2 Mines, 1 Mill + 4 Fields, 1 Harbor, 3 Shrines | Eleven plots (25) | |
| Claude sizes it from the bot runs, up to about 8 plots | Start from one of each and let the bots and screenshots decide | |

**User's choice:** 1 Mine, 1 Mill + 3 Fields, 1 Harbor, 2 Shrines

| Option | Description | Selected |
|--------|-------------|----------|
| A pond at one edge, visual only (Recommended) | Off the roads, Harbor on its shore; nothing walks on it, nothing blocked; flow field untouched | ✓ |
| A lake that blocks movement | Real water reshaping routes and the flow field | |
| No water: a riverbank prop under the Harbor | A dock prop with a strip of water texture | |

**User's choice:** A pond at one edge, visual only

**Notes:** "More questions or next area?" → Next area. Exact positions, the pond's side and the CC0 models are Claude's.

---

## Income curves & destroyed-building rules

| Option | Description | Selected |
|--------|-------------|----------|
| Thronefall shapes, fitted by Claude and the bots (Recommended) | Keep each curve's shape; fit the numbers to our scale so the balanced bot stays at 7–8 of 10; Mine floor 1 gold, never 0 | ✓ |
| Thronefall numbers as written | Wiki numbers verbatim as the first data set | |
| Scale everything down first | Roughly half Thronefall's payouts to start | |

**User's choice:** Thronefall shapes, fitted by Claude and the bots

| Option | Description | Selected |
|--------|-------------|----------|
| Mill pays for itself; Fields pay 1 flat (Recommended) | Mill tier raises only the Mill's payout; each Field pays 1 regardless | ✓ |
| Mill tier also raises each Field | Fields pay 1/2/3 with the Mill's tier | |
| Fields unlock per Mill tier | Tier I opens one Field, tier II two, tier III all three | |

**User's choice:** Mill pays for itself; Fields pay 1 flat

| Option | Description | Selected |
|--------|-------------|----------|
| Nothing accumulated; it just skips that dawn (Recommended) | Rebuilt building pays nothing that morning and makes no progress; nothing is lost | ✓ |
| Progress takes a hit | Harbor loses half its boats, Shrine goes dormant | |
| Everything accumulated is lost | Boats to zero, Shrine dormant with its count reset | |

**User's choice:** Nothing accumulated; it just skips that dawn

**Notes:** Final check ("ready for context / more on income curves / explore more gray areas") → "I'm ready for context".

---

## Claude's Discretion

- The exact twelve abilities, their numbers and tier placement; how a locked pick is shown afterwards.
- The castle's health, cost, arrow and base-income ladder across four tiers; its look per tier.
- Card size, icon art, highlight look, pre-highlight, the refusal of a hold with no highlighted card, the digit-key hand-over.
- Plot positions, the pond's edge, pond and boat visuals, CC0 models for the five building types.
- Economy numbers within the chosen curve shapes; the Shrine's radius, threshold, reach, damage, bolt look and kill tracking.
- The modifier stack's design (buckets, rounding, documentation location, overlay readout).
- Bot build orders and card picks, the golden regeneration and its report, the order of plans.

## Deferred Ideas

- Tower specializations (Phase 6) and unit/hero choices (Phase 7) reuse the card system; perks, mutators (Phase 10) and research (Phase 12) reuse the stack.
- Rule-changing abilities (offered, not chosen).
- Destruction that costs accumulated progress (rejected).
- A second sandbox map (rejected); a movement-blocking lake (rejected, possible later map gimmick).
- An optional UI design contract via `/gsd-ui-phase 5` for the card look.
