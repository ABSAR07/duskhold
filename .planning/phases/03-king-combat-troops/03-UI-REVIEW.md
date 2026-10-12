# Phase 03 - UI Review (King Combat and Troops)

**Audited:** 2026-10-12T08:32:48Z
**Baseline:** 03-UI-SPEC.md (approved design contract for the in-run HUD, squad slots, command feedback and device prompts)
**Screenshots:** not captured in this run. Reviewed 8 existing local Forward+ PNGs in screenshots/ (hud_day_squads, hud_night_squad_down, hud_long_toast, hud_king_down, hud_pad_cursor, hud_rubble_squad, hud_drag_box, hud_ability_ready), plus scene, theme and script files. No dev server used.
**Interaction captures:** off (interaction_capture: false). Interaction findings below are code-derived.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Contract strings match; "1 enemies left" plural bug on the banner (owner-flagged) |
| 2. Visuals | 3/4 | Bottom-centre stack of five layers; selected slot outranks the start-night focal prompt |
| 3. Color | 3/4 | Palette and accent discipline match; knocked-out "0 / 50" near-illegible at alpha 0.4 |
| 4. Typography | 4/4 | Only 36/28/22/18 used in scene and widgets; off-scale labels fixed; outlines consistent |
| 5. Spacing | 3/4 | Grid tokens hold; longest toast 526 px spans x 377..903, past the x 384..896 band (E6, known) |
| 6. Experience Design | 3/4 | State coverage broad; knocked-out legibility, lingering "+2 gold" and 24 px glyphs weaken it |

**Overall: 19/24**

No pillar scored 1 and no BLOCKER-class defect was found: select, command, slam, cursor and toast paths are all reachable and readable. Each sub-4 score cites a specific observed or code-verified gap.

---

## Top 3 Priority Fixes

1. **Knocked-out king health is near-illegible.** The whole KingWidget drops to alpha 0.4 (ui/hud/king_widget.gd, KNOCKED_OUT_ALPHA = 0.4), so the red "0 / 50" blends into the ground (estimated contrast about 1.6:1, against the contract rule that HUD text reads at night). User impact: the number that says the king is down is the hardest to read. Fix: keep HealthLabel and the Slam caption at alpha 1.0 and dim only the icon and bar, or raise KNOCKED_OUT_ALPHA to at least 0.7 with the label on the opaque plate.
2. **Longest toast is wider than the contract promises.** "Can't go there. Click a point on the visible ground." is 526 px at x 377..903; the contract says it never reaches x 384 or x 896. It does clear the protected rectangle (y 504..536, below 500), so this is a spec-wording failure, not a centre intrusion. Fix (owner decision, E6): shorten the copy to fit 512 px at Body 22 (for example "Can't go there. Click visible ground.") and update Toast.CANT_GO_THERE together with the contract, or amend the contract's bound.
3. **Bottom-centre hierarchy is inverted.** In hud_day_squads and hud_night_squad_down the selected slot's cyan border and plate are the strongest element at y 544..614, directly above the start-night prompt (y 624..650), which the contract names as the day focal point. Fix: put the start-night prompt on a #14141A at 0.78 plate with an 8 px inset (Spacing sm), and keep NightPreview at 18 px as tertiary.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)
- Strings match the contract: "Night 1 of 8" (DayCounter), "4 / 4" and "50 / 50", "Slam", the seven verbs (Follow, Hold, Rally, Move, Attack, Patrol, Queue), "Select a squad first", "Aim with the right stick, release to confirm", "Knocked out — back in 6 s".
- No exclamation marks and no generic Submit, OK, Cancel or Save labels in ui/hud or presentation/units.
- Owner-flagged, not re-litigated: hud_king_down shows "Night 7 of 8 — 1 enemies left". hud.gd NIGHT_BANNER has no singular case; NIGHT_PREVIEW_ONE handles the singular direction but the banner does not. Fix: pluralise enemy/enemies for a count of one.
- Held at 3, not 4, because the shipped night banner is grammatically wrong at a count of one, on screen during the fight.

### Pillar 2: Visuals (3/4)
- The night focal point works: KingWidget bottom-left (red health fill, cyan Slam ready border) and the banner and RespawnLabel at the top.
- Day stack (hud_day_squads): hint row (504..536), slot strip (544..614), start-night prompt (624..650), fill bar (about 652..666), NightPreview (about 676..692). Five layers in one centre column reads as clutter beside the cleared centre.
- The selected slot's 4 px cyan border is the highest-contrast element in that column, above the prompt (Fix 3).
- Stance glyphs at 20 px (ui/hud/stance_glyph.gd GLYPH_SIZE 20, LINE_WIDTH 2, #C8CCD4): in the captures post, hold and patrol look nearly alike at slot scale. The shapes are distinct in code, not at the displayed size.
- Icon-only check passes: the Slam plate has a text caption and a keycap glyph; slots carry digits.

### Pillar 3: Color (3/4)
- 60/30/10 is applied: dark #14141A at 0.78 plates dominate; white and #C8CCD4 secondary text; accent #8CEBFF used only on the contract's allowed list (selected slot border, ready border, drag box, pad ring and line, respawn label). Idle and hover slot borders do not use the accent (IDLE #3A3F4B, HOVER #C8CCD4).
- Danger #FF4040 text and #D9332E fill match the contract constants in king_widget.gd and squad_slot.gd.
- WARNING, knocked-out contrast: KNOCKED_OUT_ALPHA 0.4 on the whole widget blends #FF4040 text to roughly (140,74,70) on a (63,80,73) ground, about 1.6:1. The contract's promise that night lighting cannot dim HUD text is broken in this one state.
- WARNING, off-palette world colour: ui/hud/dawn_no_income_marker.gd BAR_COLOR Color(0.86, 0.1, 0.1) (#DB1A1A) differs from the contract world health fill #D9332E. Small Phase 1 world marker; align it to the constant.

### Pillar 4: Typography (4/4)
- Scene sizes in ui/hud/hud.tscn: 28 (GoldLabel, DayCounter, RespawnLabel), 22 (start-night pre and post, FastForward, PayoutTotal), 18 (NightPreview), 36 (PhaseBanner). The off-scale values 30, 26 and 24 from the contract are gone.
- Code sizes: king_widget HEALTH 22 and CAPTION 18; prompt_glyph KEYCAP 18; command_hints LABEL 18; squad_slot 22 and 18. Nothing outside {36, 28, 22, 18}.
- Outline 6 on new labels (theme Label outline_size 6; GoldLabel and DayCounter explicit). FastForward keeps 8 per contract.
- Bold: HudBoldLabel theme variation (FontVariation, embolden 0.5) on the health label and slot counts, matching "numerals bold, words regular".

### Pillar 5: Spacing (3/4)
- Tokens hold in code: hint separation 16 (row) and 4 (item), slot 136x72, KingWidget separation 8, icon 56x56, bar 192x24, label min width 96, glyphs 24 and 32.
- The hint row sits 8 px above the slot strip (504..536 over 544..614), as specified.
- KNOWN OPEN ITEM, E6 (from 03-12 SUMMARY; not a new discovery): hud_long_toast is 526 px wide at x 377..903 on one line at y 504..536. Below the protected rectangle (y 96..500), so the runner's check passes, but 7 px past x 384 and x 896 on each side. Left for the owner (Fix 2).
- Nit: the hint row is about 647 px wide on keyboard (x 317..964) and about 776 px on the pad (x 252..1028, per 03-10), wider than the contract's 610 px estimate. It clears the king widget and slots.

### Pillar 6: Experience Design (3/4)
- State coverage is broad and visible in the captures: zero-alive slot (red "0 / 4", dimmed icon, replacement fill), rubble partial state (hud_rubble_squad), knocked-out king with the RespawnLabel countdown (hud_king_down), ready flash, pad aim ring and line (hud_pad_cursor), toast and armed-line replacement, and the start-night hold with a device-named glyph.
- Device switching: one device_changed signal re-renders the hint row, start-night glyph and slam badge (code-verified in 03-10; the pad capture shows Y and the aiming line).
- WARNING, knocked-out legibility: the state the player most needs to read is the least legible (Pillar 3, Fix 1).
- WARNING, owner-flagged (referenced only): a "+2 gold" payout line persists under the gold counter into the next night (visible in hud_night_squad_down and hud_long_toast). It is a reused Phase 1 label and should expire at the next day start.
- WARNING, owner-flagged (referenced only): 24 px glyph legibility. The "Queue" Shift tile in hud_day_squads is a small, hard-to-read keycap; pad tiles are a cross with one arm lit (03-10 D7). Owner judgement at UAT.
- Owner-flagged (referenced only): Xbox glyphs on non-Xbox pads (Y shown in hud_pad_cursor), the pad layout (LB layer, Start group mode, R3 chords; 03-09 D6), and the thin beige patrol line (03-12 open points).
- Not verified in captures (code-derived only): squad slot hover border, group badge during group mode, dawn-restore border flash, stance shape changes at rest.

---

## Registry Safety

Not applicable: no components.json (Godot project, no shadcn). Input-prompt tiles are Kenney Input Prompts 1.5 (CC0), logged in assets/attribution.json per 03-10.

---

## Files Audited
- .planning/phases/03-king-combat-troops/03-UI-SPEC.md, 03-CONTEXT.md (D-09..D-25)
- 03-09-SUMMARY.md, 03-10-SUMMARY.md, 03-12-SUMMARY.md (03-03..03-08 scanned for open items only)
- ui/hud/hud.tscn, ui/theme/hud_theme.tres, ui/hud/hud_root.gd, toast.gd, command_hints.gd, king_widget.gd, squad_strip.gd, squad_slot.gd, prompt_glyph.gd, stance_glyph.gd, dawn_no_income_marker.gd, hud.gd (copy constants)
- tools/screenshot/shot_runner.gd (PROTECTED_RECT, EXEMPT_NODES)
- project.godot (window/stretch/mode canvas_items, aspect expand: present)
- screenshots/: hud_day_squads, hud_night_squad_down, hud_long_toast, hud_king_down, hud_pad_cursor, hud_rubble_squad, hud_drag_box, hud_ability_ready
