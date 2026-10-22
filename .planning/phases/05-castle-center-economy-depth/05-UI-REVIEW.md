# Phase 05 — UI Review (Castle Center and Economy Depth)

**Audited:** 2026-10-22T09:41:43Z
**Baseline:** Abstract 6-pillar standards (no 05-UI-SPEC.md exists for this phase). Phase 5 copy, sizes and colours read from ui/world/card_row.gd, card_row_model.gd, spot_label.gd, spot_label.tscn, spot_label_model.gd, ui/hud/dawn_no_income_marker.gd, ui/overlay/economy_overlay_sections.gd, stat_overlay_sections.gd, and presentation/environment/pond_view.gd. The HUD type scale and palette from the Phase 3 review (03-UI-REVIEW.md) are used as the project's reference where it applies.
**Screenshots:** captured (existing, not re-taken). 44 real-window PNGs at 1280x720, Forward+, under `screenshots/`. Viewed in this audit: castle_cards, castle_tier_four, economy_day, field_locked, shrine_awake_night, castle_gate_locked, harbor_pond, plus the convention shots spot_label, dawn_payout, day_overview and build_in_progress. The CI Compatibility-renderer copies under `build/ci-screenshots/screenshots/` were not separately graded; the packet says they carry the same content with flatter lighting.
**Interaction captures:** off (interaction_capture: false, and this is a Godot build, so the web interaction driver does not apply). Every interaction finding below is code-derived or read from the static shots, and says so.

This review grades what ships. The owner's packet (05-PLAYTEST-GATE.md) lists four known open points. Those are marked KNOWN below and are not presented as new discoveries. Findings the packet does not list are marked NEW.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Lock and payout copy is plain ("Needs Castle II", "Needs a Mill", "Next dawn: N gold"); the Shrine label "Asleep: 30 of 100 enemy health" is unexplained, and no copy anywhere says how to pick or buy a card |
| 2. Visuals | 2/4 | The spot label's title and effect lines nearly touch on every plot; the banner sits over the raised card (KNOWN) and over the tier IV spire (NEW); the castle label is anchored inside the 15 m keep at tier IV (NEW) |
| 3. Color | 3/4 | The world UI runs a third palette beside the HUD plate and cyan accent (card slate, lavender highlight, yellow numbers); the off-palette dawn marker #DB1A1A is still in place (KNOWN) |
| 4. Typography | 2/4 | Six distinct world font sizes (48, 34, 32, 30, 24, 22) across two surfaces, outlines at 16, 12 and 8, and the flavour lines at 22 px are the smallest readable text on the card |
| 5. Spacing | 2/4 | Title-to-effect step (0.45 m) is smaller than the 48 px title it follows; the coin row lands on the king sprite; the card row hugs the top HUD band |
| 6. Experience Design | 3/4 | Every state is covered (locked, max tier, asleep, awake, boats, denied bump), but a player is never told to pick a card first, locked plots hide their price, and the cards re-appear with no dismiss (owner decision, KNOWN) |

**Overall: 15/24**

No pillar scored 1 and no BLOCKER-class defect was found. Every card can be picked by key or by pointer and bought by hold; every plot label reads its lock reason; the flow is reachable. The defects below degrade legibility and discoverability and should be fixed.

---

## Top 3 Priority Fixes

1. **Spot label stack is cramped on every plot.** Title (48 px) at y 0.55, effect (30 px) at y 0.10, status and coin row at y -0.40 (spot_label.tscn). The title and effect lines nearly touch in spot_label.png ("House I" over "+1 gold at dawn") and in build_in_progress.png ("Tower I" over "Range 9.0 · Damage 3"). User impact: the one line that tells a player what a plot costs and pays is the hardest text on the screen to read. Concrete fix: move the Effect Label3D to y 0.00 and the Coins/Status pair to y -0.55, or drop the title size to 40. This is a transform change in spot_label.tscn; no code change.

2. **No instruction that cards are picked, then bought.** The card row has no header and no copy. The only prompt is "Hold N to start Night N" (hud.gd). A first-time player sees four cards, presses nothing, and gets the denied bump on a hold because no card is highlighted (spot_label_model and the packet's assumption 6). User impact: the castle's central choice is discoverable only by trial. Concrete fix: add one line to the card row, for example "Press 1–4 to pick, then hold Space to buy", drawn above the cards at the same world size as the name line. Copy and a Label3D only. Owner decision whether to pre-highlight card 1 (packet decision 5) is separate.

3. **Banner and card collisions at the top of the frame.** "Night 1 of 8" overlaps the Commander card's top edge and the gap to Masons in castle_cards.png (KNOWN, packet open point 1). The same banner sits over the tier IV spire in castle_tier_four.png (NEW, not in the packet) and over the enemy crowd and yellow arrows in shrine_awake_night.png (the packet notes the arrows only). Concrete fix (untested): lower the card row by about 0.8 m (ROW_HEIGHT 7.6 to about 6.8 in card_row.gd) and confirm in castle_cards.png that the raised card clears the banner; or move the banner up one HUD row. Either is the presentation offset the packet names as the cheapest route.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

Strengths, verified in code and in shots:
- Lock reasons are literal and correct: "Needs Castle II" (castle gate, spot_label_model.gd `_locked_line`), "Needs a Mill" (field_locked.png), "Max tier" at the top tier (castle_tier_four.png).
- Income copy is plain: "+1 gold at dawn" (house), "Next dawn: N gold" (Mine, built), "Boats 2 of 5, next dawn 3 gold" (Harbor, from code), "Health 100 · Arrow 3 · 2 gold at dawn" (castle, castle_cards.png).
- Card flavour lines are short, in-world and have no IP content ("A steady voice carries the whole line.", "Coin follows the banner home.").
- No generic labels (Submit, OK, Click Here) in the Phase 5 surfaces.

Findings:
- WARNING, Shrine label is unexplained. "Asleep: 30 of 100 enemy health" (spot_label_model.gd `_shrine_effect`) tells the player a number but not what raises it (enemies dying within 18 m of the Shrine). "Awake" alone does not say what the Shrine now does. Fix: "Wakes after 100 enemy health falls nearby" as the locked line, "Firing" when awake.
- WARNING, no card instruction. Searching ui/hud and ui/world for copy about picking or choosing a card returns nothing (grep of the copy strings, this audit). The card row has no header. Fix: see Top Fix 2.
- NIT, the Picks line "Royal Training · Engineers · Golden Age" (castle_tier_four.png) uses the middle dot separator, the same as the castle effect line. Consistent; no change.

### Pillar 2: Visuals (2/4)

Strengths:
- The raised card with its yellow effect line gives a clear focal point in castle_cards.png; the pointed-at card is the one read first.
- Locked plots say why in the label (field_locked.png, castle_gate_locked.png). The gate reads as a requirement, not as an error (no red, no cost shown).
- The castle keep grows visibly per tier (castle_cards tier I to castle_tier_four tier IV); the picks line under the label carries the card names.

Findings:
- WARNING, spot label title and effect lines nearly touch on every plot (spot_label.png, build_in_progress.png, field_locked.png, castle_gate_locked.png). See Top Fix 1.
- WARNING, coin row lands on the king. In build_in_progress.png the grey and gold coin discs sit on the king's head and on the effect line. In spot_label.png the grey coin dots sit just above the king's head. The coin row is at y -0.40, the same as the status line, and is drawn over the king at the standard camera. NEW.
- WARNING, castle label is inside the keep at tier IV. LABEL_HEIGHT is a fixed 3.2 m above the plot (spot_label.gd line 10). The tier IV keep is about 15 m tall (packet). In castle_tier_four.png "Castle IV" is drawn over the tower face and the picks line crosses the king's sprite. The label does not rise with the building. NEW. Fix: anchor the castle label at the current keep height, plus 1.5 m, or raise the label for the castle plot only.
- WARNING, banner overlap, KNOWN (packet point 1). castle_cards.png: "Night 1" sits over the Commander card's top right corner and "of 8" over Masons. Status: unchanged from the packet.
- WARNING, banner over the keep spire, NEW. castle_tier_four.png: "Night 1 of 8" sits over the blue roof and spire of the tier IV keep. Not in the packet's open points; the packet only covers the tier IV crop.
- WARNING, Shrine reads as a small Tower. In shrine_awake_night.png the Shrine is a short tower with a blue cone roof, the same family as Tower I. Only the violet plot disc and the awake orb separate it at the standard camera. NEW. Fix: give shrine_t1.tscn a distinct silhouette or an orb-topped cap visible when asleep.
- KNOWN (packet point 3), economy_day.png: the Mine, Mill, Harbor and Shrine are small at zoom 3.4. The Mill's sails and the Mine's coins are not distinguishable at that camera. No change proposed in this review beyond the packet's own options.
- KNOWN (packet point 2), castle_tier_four.png: the roof tip and flag are cropped at the top edge at the default zoom.

### Pillar 3: Color (3/4)

Strengths:
- The card row keeps dark slate (CARD_COLOR #242938 at alpha 0.94) against the grass, and the highlight is a lighter blue-grey (CARD_HIGHLIGHT_COLOR #5C668F): the raised card reads by value, not only by hue.
- Coin colours are coded: gold for paid, grey for unpaid, red for unaffordable (spot_label.gd constants), and the unaffordable red is the same family as the HUD's denied state.
- The map palette (tan plots, red tower discs, violet Shrine discs, teal and blue roofs, blue pond) stays distinct per building type in the wide shot.

Findings:
- WARNING, the world UI runs its own palette. The card row uses slate and lavender (card_row.gd), the numbers line uses yellow #FFD666 (`NUMBERS_COLOR`), and the HUD uses plates #14141A at 0.78 with a cyan #8CEBFF accent. There is no shared token. The yellow effect line also competes with the gold coin colour and the gold counter. Fix: take the card face and highlight from the HUD plate and accent, or document the world palette as its own token set in the Phase 8 pass.
- KNOWN (Phase 3, Pillar 3 warning), dawn_no_income_marker.gd line 14: BAR_COLOR Color(0.86, 0.1, 0.1) is still #DB1A1A, not the world health fill #D9332E. Verified unchanged in this audit. Not visible in any Phase 5 shot (no rebuilt income building was captured).
- NIT, the blue pond (WATER_COLOR 0.2, 0.46, 0.74) and the blue house roofs sit close in value to the Tower plot discs. Acceptable in the shots; not a defect.

### Pillar 4: Typography (2/4)

Counted from the Phase 5 world UI (Label3D font_size values, scene and code):
- spot_label.tscn: Title 48, Status 34, Effect 30, Picks 30.
- card_row.gd: Name 32, Numbers 24, Flavour 22.
- Six distinct sizes across two surfaces (48, 34, 32, 30, 24, 22), against the Phase 3 HUD scale of four (36, 28, 22, 18). The world labels were never reconciled with that scale. The Phase 1–3 review used a four-size rule for the HUD; the Phase 5 world UI breaks it.
- Outlines differ: 16 on the Title, 12 on Effect, Status and Picks, 8 on card labels. Three outline weights for one label family.

Findings:
- WARNING, the status line is larger than the effect line. On a locked plot the Status "Needs a Mill" is 34 px and the Effect "+1 gold at dawn" is 30 px (field_locked.png shows the lock line as the bigger text). The lock reason is more important than the effect, so the size order is defensible, but the Effect size should not be the smallest line in the label.
- WARNING, flavour lines are the smallest readable text in the game. The 22 px flavour text on each card reads small in castle_cards.png (the flavour line looks about 13 px tall on the 1280x720 frame). It is the only copy a player needs to choose a card, and it is the smallest.
- WARNING, six world sizes is above the four-size HUD rule. Consolidate to 48 / 32 / 24 / 22 or align both surfaces to the HUD's 36 / 28 / 22 / 18.

### Pillar 5: Spacing (2/4)

Strengths:
- Card geometry is internally consistent: 3.4 by 3.2 m cards, 0.3 m gap, icon slot 0.9 m with its centre at 1.05 m, name at 0.5 m, flavour at 0.05 m, numbers at -0.85 m (card_row.gd constants). The raised card's 0.35 m rise leaves the other cards at rest.
- The card row clears the spot label vertically (cards bottom at about 6.0 m above the spot; label top at about 4.2 m), so the row and the label never overlap in the wide view.
- The castle's picks line sits below the effect line with its own spacing and does not crowd the coins.

Findings:
- WARNING, title-to-effect step is too small. Title at y 0.55, effect at y 0.10: a 0.45 m step against a 48 px title. The lines touch (Top Fix 1). NEW.
- WARNING, coin row and status line share one position (y -0.40). They never show together (a locked plot has no coins), so no overlap occurs today, but the shared slot is fragile. If a status line ever appears on a buyable plot, the coins and status will overlap. NEW (code-derived).
- WARNING, card row hugs the HUD top band. At 1280x720 the raised card's top edge is within about 20 px of the top of the frame (castle_cards.png), and the banner sits on it (Top Fix 3).
- Known, Phase 3 HUD: the "+4 gold" payout line in harbor_pond.png sits under the gold counter in the day view. It is the Phase 3 stale-payout line (03-UI-REVIEW Fix 1). Here it persists into the day with the next night's prompt showing. KNOWN.

### Pillar 6: Experience Design (3/4)

State coverage verified in the shots and code:
- Locked lines: "Needs Castle II" and "Needs a Mill" with no price shown and no red (castle_gate_locked.png, field_locked.png). A denied hold bumps and the label shakes (spot_label.gd `_play_denied`).
- Max tier, asleep and awake Shrine, Harbor boats and Mine next payout are all read from code and the label model; the Mine's "Next dawn: N gold" is shown on a built Mine.
- The F3 overlay's Stats and Economy sections are read-only and list every stacked bonus, the castle's picks, each Mine's payout, the Harbor's boats and each Shrine's credit (economy_overlay_sections.gd, stat_overlay_sections.gd). Good debugging support.
- Keyboard pick (keys 1 to 4) and pointer pick are both wired (card_rects hit test in card_row.gd).

Findings:
- WARNING, no pick instruction (Top Fix 2). A player who has not read the packet has no way to learn that a card must be highlighted before the hold will buy. Code-derived; confirmed by the copy search and the captures.
- WARNING, locked plots hide their price. spot_label_model.gd sets cost 0 for any locked tier, so Tower II reads "Range 10.5 · Damage 6 / Needs Castle II" with no cost (castle_gate_locked.png). The player cannot plan a saving toward the castle or the Mill from the label. The packet's question 3 asks whether the gate reads as a choice; hiding the price is part of why it reads as a wall. Fix: show the cost as grey coins on locked plots and keep the red-free treatment. NEW.
- WARNING, locked plots look like buildable plots. A Field and an unlocked Field use the same tan disc (field_locked.png, economy_day.png). The only cue is the label, which shows only for the focused plot. A player cannot see from the map which plots are gated. NEW (code and shot evidence).
- KNOWN (packet decision 5 and assumption 7), the cards re-appear on every pass with enough gold and no dismiss. Owner decision (research A10). Not re-graded here.
- KNOWN (packet decision 5 and assumption 6), no card is pre-highlighted. Owner decision (research A7).
- WARNING, the king stands on the pond. harbor_pond.png shows the king on the water. The pond is visual only (packet, assumption 14), so the player can ride across a lake that looks like a lake. NEW to this review; the packet records it as known and visual-only. Fix: add the pond as a no-walk area, or draw the king's path around it, or accept it and say so in the Phase 8 pass.
- KNOWN (packet point 4), the Shrine does nothing in bot play. Balance, not presentation; the Shrine's visual reads as a Tower (see Visuals) and the owner decides between a nearer plot, a longer reach, or a different wake rule.
- KNOWN (packet point 5), the Harbor dominates income. Balance decision for the owner.

---

## Known Open Points: Status Check

| Packet point | Status in this audit |
|---|---|
| 1. Banner overlaps a raised card | KNOWN, confirmed in castle_cards.png; also seen over the tier IV spire (NEW) |
| 2. Tier IV roof and flag cropped | KNOWN, confirmed in castle_tier_four.png; the castle label sitting inside the keep is NEW |
| 3. Small buildings in economy_day | KNOWN, confirmed |
| 4. Shrine does almost nothing | KNOWN (balance); its visual reads as a Tower (NEW) |
| 5. Harbor dominates income | KNOWN (balance) |
| 6. Castle tiers III and IV out of bot reach | KNOWN (balance); not a UI finding |
| 7. Cards re-appear on every pass | KNOWN, owner decision; not re-graded |

## Registry Safety

Not applicable: Godot project, no components.json. The key tiles are Kenney Input Prompts (CC0), logged per the project's asset conventions. The card icons are first-party SVGs logged in ASSETS.md as CC0-1.0 (packet, assumption 8).

---

## Files Audited

- .planning/phases/05-castle-center-economy-depth/05-PLAYTEST-GATE.md (owner packet: open points, assumptions, "What Claude already checked")
- .planning/phases/05-castle-center-economy-depth/05-12-SUMMARY.md (phase gate; the eleven shots and the CI copies)
- .planning/phases/03-king-combat-troops/03-UI-REVIEW.md (precedent: the HUD type scale, palette, the stale payout line, the dawn marker colour)
- ui/world/card_row.gd, ui/world/card_row_model.gd (card geometry, sizes, colours, copy)
- ui/world/spot_label.gd, ui/world/spot_label.tscn, ui/world/spot_label_model.gd (label anchor, type sizes, outlines, locked and max-tier copy)
- ui/hud/dawn_no_income_marker.gd (BAR_COLOR, line 14)
- ui/overlay/economy_overlay_sections.gd, ui/overlay/stat_overlay_sections.gd (F3 overlay copy)
- ui/hud/hud.gd (HUD copy: start-night prompt, banner, preview; grep for card-pick copy returned none)
- presentation/environment/pond_view.gd (pond colour; visual-only)
- screenshots/: castle_cards, castle_tier_four, economy_day, field_locked, shrine_awake_night, castle_gate_locked, harbor_pond, spot_label, dawn_payout, day_overview, build_in_progress (read by eye; not re-captured)
- Not read in full: 05-01 to 05-11 PLAN and SUMMARY files and 05-CONTEXT.md. Their decisions were taken from the owner packet's assumptions list, which restates them with plan references.
