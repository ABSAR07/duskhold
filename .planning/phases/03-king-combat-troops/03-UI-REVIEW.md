# Phase 03 - UI Review (King Combat and Troops)

**Audited:** 2026-10-13T19:38:03Z
**Baseline:** 03-UI-SPEC.md (approved design contract, amended by 03-15 for the StartNightPlate and by 03-19 for the knocked-out dimming rule and the singular enemy copy), 03-CONTEXT.md D-21 to D-28
**Screenshots:** not captured in this run (Godot desktop build, no dev server, nothing run). Reviewed the 33 existing real-window captures under screenshots/ (file dates 2026-10-14, re-taken on the current build after plans 03-13 to 03-19), with the most weight on hud_day_squads, hud_day_squads_1080p, hud_king_down, hud_night_squad_down, hud_night_squad_down_16x10, hud_long_toast, spawn_telegraph, night_combat, cmd_queue_ten and hud_rubble_squad. The older build/ci-screenshots copies were ignored.
**Interaction captures:** off (interaction_capture: false). Interaction findings below are code-derived and say so.

This review supersedes the 2026-10-12 review (19/24).

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Singular "1 enemy" fixed on the banner and the preview; all contract strings match; no generic labels |
| 2. Visuals | 3/4 | Start-night plate fixes the focal point in code and capture, but the centre column still stacks five layers and the cyan selected slot is still the most saturated element above it |
| 3. Color | 3/4 | Knocked-out "0 / 50" now opaque and measured 5.88:1; one off-palette world marker (#DB1A1A) remains |
| 4. Typography | 4/4 | All HUD sizes in code and scenes are 36/28/22/18; no off-scale value found |
| 5. Spacing | 3/4 | E6 "Can't go there" toast still 526 px (x about 377..903), past the contract's x 384..896 bound; owner decision, UAT test 12 |
| 6. Experience Design | 3/4 | Knocked-out legibility, the regen bar and the Shift-queue gap are fixed; the stale "+2 gold" payout line still carries into night and the 24 px glyphs stay small |

**Overall: 20/24** (previous 19/24)

No pillar scored 1 and no BLOCKER-class defect was found: select, command, slam, cursor, toast, knockout and start-night paths are all reachable and readable in the captures. Every sub-4 score cites a specific observed or code-verified finding.

---

## Status of the 2026-10-12 Findings

| Previous finding | Status now | Evidence |
|------------------|-----------|----------|
| Fix 1: knocked-out "0 / 50" near-illegible (KING widget alpha 0.4 on the whole widget) | FIXED (03-19, G-03-13) | king_widget.gd: only the bar, the plate's own self_modulate, the sword and the glyph go to 0.4; HealthLabel and the "Slam" caption stay at alpha 1.0 with the 6 px black outline. hud_king_down shows a crisp red "0 / 50". The 03-19 probe reads 5.88:1 on that capture (was 1.62:1). Not re-run here (no process runs in this audit). |
| Fix 2: longest toast wider than the contract promises (526 px, E6) | REMAINS, owner decision (UAT test 12), not a gap | hud_long_toast.png: "Can't go there. Click a point on the visible ground." spans about x 377..903 at y 504..536. It stays below the protected rectangle (y 96..500), so the verification hook passes, but the contract's "never reaches x 384 or x 896" promise is not met. Toast.CANT_GO_THERE is unchanged. |
| Fix 3: bottom-centre hierarchy inverted (selected slot outranked the start-night prompt) | FIXED IN CODE AND CAPTURE, feel judgment open (03-15, UAT test 14) | StartNightPlate (#14141A at 0.78, radius 8, 8 px inset, x 440..840, y 624..690) is visible behind "Hold N to start Night 1" and its fill bar in hud_day_squads and hud_day_squads_1080p. The plate is wider and taller than the selected slot. The 4 px cyan border is still the most saturated pixel in the column. Whether the prompt leads is the owner's call at test 14. |
| Owner-flagged "1 enemies left" | FIXED (03-19, G-03-14) | hud_king_down: "Night 7 of 8 — 1 enemy left". spawn_telegraph: "Night 1: 5 enemies from 1 direction". Hud.enemy_count_text is used by the banner and both preview patterns. |
| Warning: knocked-out contrast (Pillar 3 and 6) | FIXED (same as Fix 1) | As above. |
| Warning: off-palette world colour, dawn_no_income_marker.gd BAR_COLOR #DB1A1A | REMAINS (unchanged) | dawn_no_income_marker.gd line 14: Color(0.86, 0.1, 0.1). Contract world health fill is #D9332E. |
| Warning: "+2 gold" payout line persists under the gold counter into the next night | REMAINS, with a code cause identified | hud_night_squad_down, hud_night_squad_down_16x10 (Night 5, "+2 gold" under Gold: 26) and the Night 7 capture all show it. dawn_payout_vfx.gd `_show_total` shows PayoutTotal and hides it only from a 2.0 s wall-clock tween (TOTAL_SHOWN_SECONDS). Nothing hides it on the phase change to night. Captures that step the sim quickly reach night inside those 2 s; a player who starts night quickly does too. |
| Warning: 24 px glyph legibility ("Queue" Shift tile, pad cross tiles) | REMAINS, owner judgement at UAT | hud_day_squads and hud_night captures: the Shift tile in the hint row is a small keycap with tiny lettering. |
| Owner-flagged, referenced only: Xbox glyphs on non-Xbox pads, pad layout, thin beige patrol line | REMAINS, unchanged, deferred or owner judgement | Not changed by plans 03-13 to 03-19. |

---

## Top 3 Priority Fixes

1. **Stale "+2 gold" payout line carries into the night.** The line stays under the gold counter (hud_night_squad_down, hud_night_squad_down_16x10), reads as current income during the fight and sits in the top-left HUD for no reason. User impact: the gold figure reads as double-counted during the night. Fix: in hud.gd `_on_phase_changed`, when the phase leaves DAWN, kill the payout tween and hide `%PayoutTotal` (or expose a `clear()` on DawnPayoutVfx and call it there), so the line expires at the phase change rather than after a 2 s real-time tween.

2. **Longest toast is 526 px against a 384..896 bound (E6, UAT test 12).** "Can't go there. Click a point on the visible ground." crosses x 384 and x 896 by about 7 px each side (hud_long_toast). User impact: the one error line that a mouse player sees on a bad click runs past the centre band the contract protects. Fix (owner decision): shorten to fit about 512 px at Body 22, for example "Can't go there. Click visible ground.", and update Toast.CANT_GO_THERE and the contract copy together; or amend the contract's bound to match the 526 px line. Either is a one-line change once chosen.

3. **Centre column still stacks five layers; the selected slot still competes with the start-night prompt.** In hud_day_squads the hint row, the slot strip, the plated prompt with its fill bar and the NightPreview all sit in x 440..900 at y 504..716. The cyan 4 px border of the selected slot is still the most saturated element in that column. User impact: the day's focal action has a plate but not clear precedence. Fix: owner judgment at UAT test 14 first. If the prompt does not lead, the options all need a contract amendment, since the spec fixes the border at 4 px and the prompt at 22 px: a 2 px selected border while the day prompt shows, or the NightPreview moved to the 18 px tertiary tier above the hint row.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)
- The owner-flagged plural is fixed. Hud.NIGHT_BANNER and NIGHT_PREVIEW both take `enemy_count_text()`; `ENEMY_ONE` is "%d enemy" and `ENEMY_MANY` is "%d enemies" (hud.gd lines 19 to 23, 187 to 189). The banner in hud_king_down reads "Night 7 of 8 — 1 enemy left".
- Strings match the contract: "Night 1 of 8" (DayCounter), "Hold N to start Night 1" (start-night prompt), "Knocked out — back in 6 s", the seven verbs (Follow, Hold, Rally, Move, Attack, Patrol, Queue), "Slam", "Select a squad first", "Group %d saved", "Group %d is empty".
- No exclamation marks and no generic Submit, OK, Cancel or Save labels in ui/hud.
- The E6 toast is a copy-length problem with a layout bound. It is scored under Spacing (Pillar 5), not here, so it does not hold this pillar down.

### Pillar 2: Visuals (3/4)
- Focal point by day: the StartNightPlate (hud.tscn, plan 03-15) gives the start-night prompt its own dark panel and a wider footprint than the selected slot. The captures confirm the plate at x 440..840, y 624..690 on the 1280x720 and 1920x1080 shots.
- Focal point by night: the KingWidget bottom-left (red health bar, 36 / 50 in hud_night_squad_down, Slam plate with caption) and the banner at top-centre read clearly. The knocked-out state dims the bar and icon while the count and caption stay opaque (hud_king_down).
- The day centre column is still five layers (hint row at y 504..536, slot strip at 544..614, plated prompt at 624..690, fill bar, NightPreview at 690..716). The layers are each within contract, but together they read as a busy strip beside a cleared centre. This is the Fix 3 item.
- Stance glyphs at 20 px remain small in the slots, as in the previous review. Post, hold and patrol are distinct in code but not at slot scale in hud_day_squads.
- Icon-only check passes: the Slam plate has a text caption and a keycap glyph; the slots carry digits.
- Night readability: the night captures (night_combat, hud_night_squad_down) keep the HUD on a CanvasLayer with dark plates and outlines; no HUD text is lost against the night ground.

### Pillar 3: Color (3/4)
- 60/30/10 holds on the HUD. Dark #14141A at 0.78 plates dominate; white and #C8CCD4 carry the secondary text; accent #8CEBFF appears only on the contract's allowed list (selected slot border, ready border, respawn label, queue discs, ground rings).
- Knocked-out count: #FF4040 on its own opaque black outline. The 03-19 probe measured 5.88:1 on hud_king_down (threshold 4.5:1). The count reads clearly in the capture.
- WARNING, off-palette world colour: ui/hud/dawn_no_income_marker.gd line 14 `BAR_COLOR := Color(0.86, 0.1, 0.1)` (#DB1A1A) differs from the contract's world health fill #D9332E used by health_bar_3d.gd. A small Phase 1 marker; align it to the constant. Not on the HUD, so it does not break the HUD palette.

### Pillar 4: Typography (4/4)
- Scene sizes in ui/hud/hud.tscn are 36, 28, 22 and 18 only (GoldLabel 28, DayCounter 28, RespawnLabel 28, PhaseBanner 36, start-night and PayoutTotal 22, NightPreview 18, FastForwardLabel 22). The off-scale 30, 26 and 24 are gone.
- Code sizes: king_widget HEALTH_FONT_SIZE 22 and CAPTION_FONT_SIZE 18; squad_slot.tscn 22 and 18; prompt_glyph KEYCAP_FONT_SIZE and command_hints LABEL_FONT_SIZE are 18. Nothing outside {36, 28, 22, 18}.
- Numerals are bold (HudBoldLabel) on the health label and the slot counts; words are regular.
- Outline 6 on new labels; the FastForward label keeps 8 per contract.

### Pillar 5: Spacing (3/4)
- Tokens hold in code: slot 136x72, KingWidget separation 8, icon 56x56, bar 192x24, label min width 96, hint row 16 px separation, the StartNightPlate 8 px inset and the 624 top edge.
- OPEN, E6 (Fix 2): hud_long_toast is about 526 px wide, one line, at y 504..536. It clears the protected rectangle's y range (96..500), so the verification hook passes, but it runs about 7 px past x 384 and x 896 on each side, against the contract's "never reaches x 384 or x 896" promise. The owner decision (UAT test 12) is still pending.
- The hint row is about 647 px wide on keyboard (x 317..964) and about 776 px on pad (per 03-10). This is wider than the contract's 610 px estimate. It clears the king widget and the slots.
- Nit: hud_night_squad_down_16x10 and hud_day_squads_1080p show the layout holding at 16:10 and 1080p.

### Pillar 6: Experience Design (3/4)
- Fixed since the previous review:
  - Knocked-out state: the count and caption are readable (03-19). The RespawnLabel countdown is on the same screen.
  - The floating bar over the king now follows regeneration and hides at full (03-14, G-03-4). This is code and test verified; the bar is not in any capture.
  - Shift+F, Shift+H and Shift+R queue behind walks, as the hint row's "Queue" promises (03-13, G-03-8). Code and scene tests verified; the real-window probe is recorded in the 03-13 summary.
  - Squad queue discs: MAX_DISCS_SHOWN is 6 (order_markers.gd line 30), and cmd_queue_ten shows six numbered discs with lines.
- WARNING, stale payout line (Fix 1): "+2 gold" stays under the gold counter into the night. The line is owned by a 2.0 s real-time tween in dawn_payout_vfx.gd and is not cleared on the phase change. The owner flagged it at UAT; it is still present.
- WARNING, 24 px glyph legibility: the Shift tile in the hint row ("Queue") and the pad tiles are small keycaps. Owner judgement at UAT; no change in this round.
- State coverage in the captures: zero-alive slot (red "0 / 4", dimmed icon, replacement fill in hud_night_squad_down and hud_rubble_squad), knocked-out king with RespawnLabel, ready flash and denied shake (code verified), the armed-point and pad aim ring (hud_pad_cursor), the toast slot, and the start-night hold with a device-named glyph.
- Not verified in captures (code-derived only): squad slot hover border, group badge during group mode, dawn-restore border flash, stance shape changes at rest, the 2 s payout tween's behaviour at a real dawn, and the 9-order queue cap (code caps at 9, the disc display at 6).
- Interaction captures: off. Every interaction finding here is code-derived, not captured.

---

## Registry Safety

Not applicable: no components.json (Godot project, no shadcn). Input-prompt tiles are Kenney Input Prompts 1.5 (CC0), logged in assets/attribution.json per 03-10.

---

## Files Audited
- .planning/phases/03-king-combat-troops/03-UI-REVIEW.md (the superseded 2026-10-12 review), 03-UI-SPEC.md (amended by 03-15 and 03-19), 03-CONTEXT.md (D-21 to D-28)
- 03-13, 03-14, 03-15, 03-18, 03-19 SUMMARY.md (gap-closure evidence); 03-03, 03-05, 03-10, 03-12 SUMMARY.md read for the foundation and the screenshot runner
- ui/hud/hud.gd, hud.tscn, king_widget.gd, toast.gd, dawn_payout_vfx.gd (the payout tween and the phase handling), order_markers.gd (MAX_DISCS_SHOWN), dawn_no_income_marker.gd (BAR_COLOR)
- presentation/units/squad_plan_view.gd (disc cap wiring), presentation/king/king.gd (regen bar, read only)
- screenshots/: hud_day_squads, hud_day_squads_1080p, hud_king_down, hud_night_squad_down, hud_night_squad_down_16x10, hud_long_toast, hud_rubble_squad, spawn_telegraph, night_combat, cmd_queue_ten (read by eye; the probe and the screenshot runner were not run in this audit)
