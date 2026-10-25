# Phase 05 — UI Review (Castle Center and Economy Depth), re-audit after gap round 1

**Audited:** 2026-10-26
**Baseline:** Abstract 6-pillar standards (no 05-UI-SPEC.md exists). Starting point: the previous review of 2026-10-22 (15/24). Source read this round: ui/hud/king_widget.gd, ui/world/card_row.gd, ui/world/spot_label_model.gd, data/abilities/*.tres (card names and flavour lines), plus the 05-20 SUMMARY (the x100 HUD and its ten shot reviews).
**Screenshots:** captured earlier, not re-taken this run (Godot desktop build, no dev server). Viewed this round, 1280x720 real-window, Forward+:
- Fresh from this round (05-20 / 05-23): castle_cards.png, hud_day_squads.png, harbor_pond.png, economy_day.png
- Orchestrator probe (2026-10-25): rt_after_buy.png, rt_tier2_rt_raised_crop.png, rt_tier3_he_raised_crop.png, tw_unbuilt_tower_label.png
- Not viewed this round: hud_night_squad_down, hud_king_down, hud_king_120, overlay_on, castle_tier_four, walls_day, spot_label, crowd_stress_night, rt_tier2_rt_raised, rt_tier3_he_raised, tw_tower_label, rt_tier2_row, rt_tier3_row. Claims about them below are taken from the 05-20 SUMMARY and marked as such.
- The other 32 PNGs (2026-10-22, before the rescale) were not used.
**Interaction captures:** off (interaction_capture: false; Godot build, no browser driver). Interaction findings are code-derived and say so.

This review grades what ships. Known points the owner ruled on (UAT test 6, 2026-10-22: "pass for now, revisit in phase 8") are marked KNOWN. The round changed numbers and card copy only; no font size, colour, plate or layout changed except the king label width (96 to 128 px).

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Card copy is plain and the three recut cards read cleanly, but the x100 numbers now mix units on one label ("Range 9.0 · Damage 300") and the Shrine line is still unexplained ("Asleep: 3000 of 10000 enemy health") |
| 2. Visuals | 2/4 | Title and effect lines still nearly touch on the tower plot; the coin row still sits on the king's head; the banner still sits on the raised card (KNOWN) |
| 3. Color | 3/4 | Unchanged: the world UI runs its own slate and lavender palette beside the HUD plate; the off-palette dawn marker is still in place (KNOWN) |
| 4. Typography | 2/4 | Unchanged: six world font sizes across two surfaces; the 22 px flavour line is the smallest text on the card |
| 5. Spacing | 2/4 | Unchanged: the raised card's top edge is cut by the frame at 1280x720 and the picks line sits on the king's head at Castle III |
| 6. Experience Design | 3/4 | Unchanged: no pick instruction on the card row; locked plots still hide their price; the king's health label now reads at full scale in every state checked |

**Overall: 15/24** (unchanged from 2026-10-22)

No pillar scored 1 and no BLOCKER-class defect was found. The round fixed one real overflow risk (the king's "6250 / 6250" now fits on one line), but it did not move any pillar score, because the open findings are presentation and copy, and this round did not touch them.

---

## Top 3 Priority Fixes

1. **Spot label stack is cramped on every plot (unchanged).** Title (48 px) at y 0.55, effect (30 px) at y 0.10 in spot_label.tscn. In tw_unbuilt_tower_label.png "Tower I" sits directly on "Range 9.0 · Damage 300" with no gap. User impact: the line that says what a plot costs and pays is the hardest text to read on the map. Concrete fix: move the effect label to y 0.00 and the coin/status pair to y -0.55, or drop the title to 40 px. Transform change in spot_label.tscn; no code change.

2. **Mixed units on the scaled labels (NEW this round).** The x100 rescale was applied to health and damage, but range was not: the tower label reads "Range 9.0 · Damage 300" (tw_unbuilt_tower_label.png), and the castle reads "Health 10000 · Arrow 300 · 2 gold at dawn" beside a king bar at "5000 / 5000". A player cannot tell from the label that range is in metres and damage is in the scaled unit. User impact: the scaled numbers look like an error on the first tower a player inspects. Concrete fix: either show range in the same scale (for example "Range 9.0 m") or add the unit to the damage and health words; this is a copy decision for the owner, since the 05-20 summary records that the numbers are shown as they are. Copy only in spot_label_model.gd.

3. **No instruction that cards are picked, then bought (unchanged).** The card row has no header. The only prompt is "Hold N to start Night 1" (hud.gd). Searching ui/hud and ui/world for copy about picking returns nothing. User impact: the castle's central choice is discoverable only by trial. Concrete fix: one line above the cards, for example "Press 1–4 to pick, then hold Space to buy", at the name line's world size. Copy and a Label3D only.

---

## Previous Findings: Status This Round

| Previous finding (2026-10-22) | Status now | Evidence |
|---|---|---|
| Spot label title and effect lines nearly touch | CHANGED (still holds) | tw_unbuilt_tower_label.png; transforms unchanged |
| No pick instruction on the card row | CHANGED (still holds) | hud_day_squads.png; no copy added in 05-21 to 05-23 |
| Shrine label unexplained ("Asleep: 30 of 100") | CHANGED (still holds, scaled) | Now "Asleep: 3000 of 10000 enemy health" in spot_label_model.gd; copy still unexplained |
| Coin row lands on the king | STILL HOLDS | tw_unbuilt_tower_label.png: coin dots directly above the king's head; castle_cards.png the same |
| Castle label inside the keep at tier IV | NOT RE-VERIFIED | castle_tier_four.png not viewed this round; the label height is unchanged in code. At tier III (rt_after_buy.png) "Castle III" sits on the keep top and the picks line "Royal Training" sits on the king's head |
| Banner overlaps raised card (KNOWN, packet point 1) | STILL HOLDS, KNOWN | castle_cards.png, hud_day_squads.png, rt_tier3_he_raised_crop.png: "Night 1 of 8" over the top edge of the Engineers and War Horns cards |
| Banner over the tier IV spire (NEW last round) | NOT RE-VERIFIED | castle_tier_four.png not viewed this round |
| Shrine reads as a small Tower | NOT RE-VERIFIED | shrine_awake_night.png not viewed this round; no shrine change in the round |
| Typography: six world sizes; 22 px flavour is smallest | STILL HOLDS | No font size changed; rt_tier3_he_raised_crop.png shows the flavour line legible but the smallest text on the card |
| Card row hugs the top HUD band | STILL HOLDS | castle_cards.png: card tops cut by the frame; rt_after_buy.png shows the row at y 40 |
| Stale "+4 gold" payout line under the gold counter (Phase 3, KNOWN) | STILL HOLDS, KNOWN | harbor_pond.png: "+4 gold" under "Gold: 66" |
| King stands on the pond | CHANGED (not in this shot) | harbor_pond.png shows the king on the grass beside the pond, not on the water. Pond walkability was not re-checked in code this round |
| Locked plots hide their price | STILL HOLDS | spot_label_model.gd: cost 0 for a locked tier; no code change this round |
| Locked plots look like buildable plots | NOT RE-VERIFIED | not changed this round |
| Cards re-appear on every pass (KNOWN, owner decision) | KNOWN | Not re-graded |
| No card pre-highlighted (KNOWN, owner decision) | KNOWN | hud_day_squads.png shows card 1 highlighted only after the key press in that capture; not re-graded |
| Dawn marker #DB1A1A (Phase 3, KNOWN) | STILL HOLDS, KNOWN | Not changed this round |
| Harbor dominates income; Shrine does nothing in bot play (KNOWN, balance) | KNOWN | Not a UI finding; not re-graded |

---

## Round Changes: What Ships Now

**King widget (05-20).** The label is 128 px wide (LABEL_MIN_WIDTH in ui/hud/king_widget.gd), and the row spans x 16 to 408. Observed: "5000 / 5000" (hud_day_squads.png, castle_cards.png) and "6250 / 6250" (rt_after_buy.png, after Royal Training) sit on one line and end near x 403, clear of the start-night plate at x 440. The row does not shift. This is a real fit, and it removes the risk the round targeted. Scored under Pillar 5 and 6 as a clean result, not as an improvement to the pillar scores.

**Card recut (05-21).** Observed in the shots:
- Royal Training: "+25% king health, +100 king damage" (rt_tier2_rt_raised_crop.png) fits its card on two lines. The number is shown in full at x100.
- Headsman's Edge: "x2 king damage, x1.25 king attack interval" with the new flavour "Heavier cuts that land only a little slower." (rt_tier3_he_raised_crop.png) fits its card on two lines and reads clearly.
- Prosperity and Golden Age: their numbers lines were not observed this round. Prosperity's flavour "Coin follows the banner home." is visible in castle_cards.png. Golden Age's copy was not checked on screen.

**Harbor move (05-22) and re-aimed shots (05-23).** economy_day.png and harbor_pond.png show the pond and boats at the west side of the map, on a smaller pond. Three boats are visible in harbor_pond.png. The Harbor plot sits beside the pond. The small-buildings point in economy_day.png is still KNOWN (packet point 3).

**Numbers at x100 (05-20).** Observed: "Health 10000 · Arrow 300 · 2 gold at dawn" at tier II and "Health 14000 · Arrow 400 · 3 gold at dawn" at tier III fit on one line. "Range 9.0 · Damage 300" fits on one line. No number clips. The only new problem is the mixed-unit reading (Top Fix 2).

**Test kings (shot-only).** hud_king_120 (12000 health) and crowd_stress_night (10000000) run past x 408. These are test kings, not the shipped game, and are excluded from scoring, as the owner recorded.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

Strengths, verified in code and in shots:
- Lock reasons are literal: "Needs Castle II" (spot_label_model.gd `_locked_line`), "Needs a Mill", "Max tier".
- Income copy is plain: "+1 gold at dawn", "Next dawn: N gold", "Boats 2 of 5, next dawn 3 gold", "Health 10000 · Arrow 300 · 2 gold at dawn".
- The recut card copy is short and reads in-world. Flavour lines are from data/abilities/*.tres: "Heavier cuts that land only a little slower.", "The king drills until the blade feels light.", "Coin follows the banner home."
- No generic labels (Submit, OK, Click Here) on the Phase 5 surfaces.

Findings:
- WARNING, mixed units on one label (NEW, Top Fix 2). "Range 9.0 · Damage 300" puts an unscaled range beside a scaled damage. The castle's "Health 10000" and the king's "5000 / 5000" are scaled but carry no unit. Fix: a unit or a consistent scale for range; owner's copy call.
- WARNING, Shrine label is unexplained (unchanged in substance). "Asleep: 3000 of 10000 enemy health" tells the player a number but not what raises it. "Awake" alone does not say what the Shrine now does. Fix: a locked line such as "Wakes after 10000 enemy health falls nearby", and "Firing" when awake.
- WARNING, no card instruction (Top Fix 3). Copy search of ui/hud and ui/world finds no pick copy.
- NIT, the Picks line "Royal Training · Engineers · Golden Age" uses the same middle-dot separator as the castle effect line. Consistent.

### Pillar 2: Visuals (2/4)

Strengths:
- The raised card with its yellow numbers line is the clear focal point in castle_cards.png and rt_tier3_he_raised_crop.png.
- The castle keep grows visibly per tier (Castle II in castle_cards.png, Castle III in rt_after_buy.png).
- The king's label reads as one unit beside the bar in every fresh shot.

Findings:
- WARNING, spot label title and effect lines nearly touch on the tower plot (tw_unbuilt_tower_label.png). Top Fix 1. Unchanged.
- WARNING, coin row lands on the king. In tw_unbuilt_tower_label.png the grey coin dots sit directly above the king's head; in castle_cards.png the coin row sits over the keep's door and just above the king. Unchanged.
- WARNING, banner overlap (KNOWN, packet point 1). "Night 1 of 8" sits over the top edge of the raised card and the gap between cards (castle_cards.png, rt_tier3_he_raised_crop.png). Owner ruled "pass for now". Scored as a warning, not re-graded as new.
- WARNING, Castle III picks line on the king (NEW this round, from rt_after_buy.png). The "Royal Training" picks line at the foot of the castle label sits on the king's head. At tier III the label does not clear the king.
- KNOWN, castle_tier_four.png roof and flag cropped at the top (packet point 2). Not re-viewed this round.
- KNOWN, economy_day.png: the Mine, Mill, Harbor and Shrine are small at zoom. Owner ruled "pass for now".

### Pillar 3: Color (3/4)

Strengths:
- The card row keeps dark slate (CARD_COLOR, alpha 0.94) against the grass, and the highlight is a lighter blue-grey (CARD_HIGHLIGHT_COLOR). The raised card reads by value, not only by hue (castle_cards.png, rt_tier3_he_raised_crop.png).
- The king's health bar and its label use the red fill and white text consistently across all shots.

Findings:
- WARNING, the world UI runs its own palette. The card row uses slate and lavender (card_row.gd), the numbers line uses yellow #FFD666 (`NUMBERS_COLOR`), and the HUD uses plates #14141A at 0.78 with a cyan #8CEBFF accent. No shared token. Unchanged.
- KNOWN (Phase 3), dawn_no_income_marker.gd BAR_COLOR #DB1A1A is still off the world health fill #D9332E. Not visible in any shot this round.
- NIT, the blue pond and the blue house roofs sit close in value to the Tower plot discs. Acceptable in the shots.

### Pillar 4: Typography (2/4)

Counted from the Phase 5 world UI (Label3D font_size values, scene and code), unchanged this round:
- spot_label.tscn: Title 48, Status 34, Effect 30, Picks 30.
- card_row.gd: Name 32, Numbers 24, Flavour 22.
- Six distinct sizes across two surfaces (48, 34, 32, 30, 24, 22), against the Phase 3 HUD scale of four (36, 28, 22, 18).
- Outline sizes differ: 16 on the Title, 12 on Effect, Status and Picks, 8 on card labels.

Findings:
- WARNING, flavour lines are the smallest readable text on the card. The 22 px flavour text is legible in rt_tier3_he_raised_crop.png but is the smallest copy on the card, and it is the copy a player needs to choose.
- WARNING, the status line is larger than the effect line on a locked plot (34 px against 30 px). Defensible, since the lock reason matters more; the effect should not be the smallest line.
- WARNING, six world sizes is above the four-size HUD rule. Consolidate to 48 / 32 / 24 / 22 or align both surfaces to the HUD scale.
- PASS for the king's health label: HEALTH_FONT_SIZE 22 bold in a 128 px minimum width. The text fits at every value shown in the fresh shots.

### Pillar 5: Spacing (2/4)

Strengths:
- Card geometry is internally consistent: 3.4 by 3.2 m cards, 0.3 m gap, icon slot 0.9 m, name at 0.5 m, flavour at 0.05 m, numbers at -0.85 m (card_row.gd). Wrapped card text stays inside its card in every fresh shot.
- The king's widget row spans x 16 to 408 and clears the start-night plate at x 440 (hud_day_squads.png, rt_after_buy.png).

Findings:
- WARNING, card row hugs the top of the frame. In castle_cards.png the raised card's top edge is cut by the frame and the tops of the unraised cards are clipped. In rt_after_buy.png the row sits at y 40, clear of the frame, but the banner still overlaps it. Unchanged.
- WARNING, title-to-effect step is too small (0.45 m against a 48 px title). Unchanged (Top Fix 1).
- WARNING, coin row and status line share one slot (y -0.40). They do not show together today; if a status line appears on a buyable plot, they will overlap. Code-derived.
- WARNING, the Castle III picks line overlaps the king's head (rt_after_buy.png). NEW this round.
- KNOWN, Phase 3 HUD: the "+4 gold" payout line sits under the gold counter in the day view (harbor_pond.png).

### Pillar 6: Experience Design (3/4)

State coverage verified in the shots and code:
- Locked lines "Needs Castle II" and "Needs a Mill" carry no price and no red. A denied hold bumps and shakes the label (spot_label.gd `_play_denied`).
- Max tier, Harbor boats and the Mine's next payout are read from the label model.
- The king's health label shows its knocked-out state in code (red "0 / 5000", KNOCKED_OUT_COLOR) and the slam cooldown ring is present in the widget (king_widget.gd). The knocked-out shot (hud_king_down.png) was not viewed this round; the state is code-derived.
- Keyboard pick (1 to 4) and pointer pick are wired (card_rects hit test in card_row.gd).

Findings:
- WARNING, no pick instruction (Top Fix 3). Unchanged.
- WARNING, locked plots hide their price (spot_label_model.gd sets cost 0 for any locked tier). The player cannot plan a saving toward the castle or the Mill from the label. Unchanged.
- WARNING, locked plots look like buildable plots. A Field and an unlocked Field use the same tan disc (economy_day.png). The only cue is the label, shown only for the focused plot. Not re-verified this round.
- KNOWN (packet decision 5 and assumption 7), the cards re-appear on every pass with enough gold and no dismiss. Owner decision; not re-graded.
- KNOWN (packet decision 5 and assumption 6), no card is pre-highlighted. Owner decision; not re-graded.
- KNOWN (packet points 4 and 5), Shrine does nothing in bot play; Harbor dominates income. Balance, not presentation.

---

## Known Open Points: Status Check

| Packet point | Status in this audit |
|---|---|
| 1. Banner overlaps a raised card | KNOWN, still holds (castle_cards.png, rt_tier3_he_raised_crop.png) |
| 2. Tier IV roof and flag cropped | KNOWN, not re-viewed this round |
| 3. Small buildings in economy_day | KNOWN, still holds (economy_day.png) |
| 4. Shrine does almost nothing | KNOWN (balance) |
| 5. Harbor dominates income | KNOWN (balance) |
| 6. Castle tiers III and IV out of bot reach | KNOWN (balance); not a UI finding |
| 7. Cards re-appear on every pass | KNOWN, owner decision; not re-graded |

## Registry Safety

Not applicable: Godot project, no components.json. The key tiles are Kenney Input Prompts (CC0), logged per the project's asset conventions. The card icons are first-party SVGs logged in ASSETS.md as CC0-1.0.

---

## Files Audited

- .planning/phases/05-castle-center-economy-depth/05-UI-REVIEW.md (previous review, 2026-10-22)
- .planning/phases/05-castle-center-economy-depth/05-20-SUMMARY.md (the x100 HUD, the ten shot review lines)
- ui/hud/king_widget.gd (LABEL_MIN_WIDTH 128, row x 16 to 408, font sizes, knocked-out colours)
- ui/world/card_row.gd (card geometry, font sizes 32 / 24 / 22, colours, card_rects)
- ui/world/spot_label_model.gd (copy: locked lines, castle and tower effect lines, Shrine line, picks line)
- data/abilities/*.tres (card display names and flavour lines, grep)
- screenshots/: castle_cards.png, hud_day_squads.png, harbor_pond.png, economy_day.png (viewed)
- uat/out/ probe: rt_after_buy.png, rt_tier2_rt_raised_crop.png, rt_tier3_he_raised_crop.png, tw_unbuilt_tower_label.png (viewed)
- Not read this round: 05-21, 05-22, 05-23 SUMMARY files, 05-CONTEXT.md, 05-UAT.md, 05-PLAYTEST-GATE.md, and the other shots listed under "Not viewed this round". Card and Harbor changes are taken from the orchestrator's brief and checked only where a shot shows them.
