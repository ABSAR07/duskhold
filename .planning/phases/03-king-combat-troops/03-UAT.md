---
status: testing
phase: 03-king-combat-troops
source: [03-VERIFICATION.md]
started: 2026-10-12T09:35:00Z
updated: 2026-10-12T09:35:00Z
---

## Current Test

number: 1
name: Guard and commit readability at night
expected: |
  Build a Barracks and an Archery Range, play a night and watch the squads: footmen hold the ground in front of the plot, pick one grunt and stay on it, then walk back to the post; archers stay back and shoot. Units read as footmen and archers, guard rather than wander, commit to one target instead of flip-flopping and return to their formation after the fight, even as static bind-pose puppets.
awaiting: user response

## Tests

### 1. Guard and commit readability at night
requirement: UNIT-04
expected: Build a Barracks and an Archery Range, play a night and watch the squads. Footmen hold the ground in front of the plot, pick one grunt and stay on it, then walk back to the post; archers stay back and shoot. Units read as footmen and archers, guard rather than wander, commit to one target instead of flip-flopping and return to their formation after the fight (03-01 D8; test_squad_guard 14/14 pins the rules).
result: [pending]

### 2. Barracks and Archery Range models and replacement pace
requirement: UNIT-07
expected: Build each military plot to tier 3 and look at the models; lose units at night and watch the 10 / 7 / 4 s trickle at the building, then the full restore at dawn. Each tier reads bigger than the last next to the House and Tower models, the trickle pace feels right for the gold spent, and dawn visibly makes every squad whole (03-02 D8).
result: [pending]

### 3. HUD in a real window at 1920x1080 and 16:10
requirement: UI-01
expected: Open the exported build at 1920x1080 and at a 16:10 resolution, play a day and a night, and compare with screenshots hud_day_squads_1080p, hud_night_squad_down_16x10 and hud_day_counter_long. The HUD scales uniformly, "Night N of 8" reads over the 3D scene, nothing overlaps and the middle of the screen stays clear (03-03 D6).
result: [pending]

### 4. Slam and regeneration feel
requirement: KING-04, KING-05
expected: Press Q (pad X) amid enemies and by day; watch the ring, the sword icon fill and the ready flash; take a hit, stop being hit and watch health return. The 4 m / 4 damage / 9 s slam feels useful, the ring and flash read, and regeneration (1 s delay, 10 percent of max per second) feels Thronefall-like and not too generous. The floating bar over the king and the bottom-left widget agree after a heal (open review finding WR-01: today the floating bar does not follow regeneration).
result: [pending]

### 5. Squad slot look at 1280x720
requirement: UI-01
expected: Compare the bottom-centre squad strip with 03-UI-SPEC.md in play: icon weight, alive / max, stance glyph at 20 px, replacement fill and the dawn border flash. Slots read at a glance and the post, hold, follow, patrol and attack-move glyphs are tellable apart at slot size (03-UI-REVIEW notes post, hold and patrol look alike at that size; 03-05 D7).
result: [pending]

### 6. Selection, follow, hold and rally feel
requirement: UNIT-05, UNIT-06, UNIT-09
expected: Click a squad, double-click a unit (every squad of that type), Tab, F2; press F, H and R; watch the rings and the slot highlight; end a night and check a held or following squad keeps its stance the next day. Selection and the three verbs respond at once and read clearly; hold-at-centroid and rally-ignores-enemies match what you meant; stances persist across dawn (03-06 D9; test_squad_stance_persistence 3/3).
result: [pending]

### 7. Right-click move, attack-move on A, and the king standing still while a squad is selected
requirement: UNIT-10, INPT-01
expected: Select a squad and hold A: the king must not move; then left-click ground to attack-move. Press Escape once to cancel an armed command and again to clear the selection. With nothing selected hold A and the king rides left. Right-click ground to move. The D-15 amendment you decided at the 03-07 checkpoint (keep A, movement goes to the selection, the king is the implicit selection, Escape clears) feels right in play, and the pings and the armed line read (03-07 D8; test_selection_steering and test_king_selection_steering pin the rule).
result: [pending]

### 8. Patrol, Shift queue, drag box and control groups
requirement: UNIT-09, UNIT-10
expected: Hold P and right-click points, release P; Shift-queue several moves then a hold; drag a box over both squads; Ctrl+1 to store and 1 to recall; build a new squad while a group exists. The patrol line, numbered queue discs (nine orders kept, six drawn), hover rings, drag box, recall flash and slot badges read well. Decide whether a newly built squad should auto-join a group (today it joins none, assumption 9) (03-08 D7).
result: [pending]

### 9. Gamepad on a physical pad
requirement: INPT-02
expected: Play one full night on a real pad: ride, sprint (RB), build (A), start night (Y), slam (X), D-pad verbs, LB layer for move / attack-move / patrol with the right-stick cursor (900 px/s), R3 select all, LB+R3 select type, Start group mode, RT to queue, B to cancel, D-pad right to cycle. Every in-run action is reachable on the pad with nothing needing a pointer; cursor speed, button feel, trigger edges and the chord layout feel right. Every pad event in every test and screenshot was synthetic; the pad layout was chosen by Claude, not by you (03-09 D6, assumption 8).
result: [pending]

### 10. Prompts follow the device; glyph legibility at 24 px
requirement: INPT-02, UI-01
expected: Switch between keyboard-and-mouse and the pad mid-run several times, in a day and in a fight, and read the start-night line, the slam badge and the hint row. Every prompt flips at once on any press or stick move of the other device (mouse counts as keyboard); 24 px tiles are readable (the D-pad tile is a cross with one arm lit, the Shift and Q tiles are small); Xbox tiles are acceptable on a non-Xbox pad until Phase 13 (03-10 D7; test_device_model and test_prompt_switch pin the switching).
result: [pending]

### 11. Balance feel with an army
requirement: UNIT-04
expected: Play three nights with an army, including nights 5 to 8 (now 25 / 31 / 39 / 39 enemies), and read 03-BALANCE-REPORT.md. Say which balance finding to accept: squads are not stronger than towers per gold under the bots; the balanced bot loses 1 of 10, not the 2 or 3 asked for in G-02-15; night 8 equals night 7. Nights should feel tense with squads (03-11 D7, D-08, Phase 2 D-18).
result: [pending]

### 12. E6: longest toast inside x 384..896
requirement: UI-01
expected: Select a squad, ride to the edge of the ground and right-click off the map to raise the "Can't go there" toast. Accept a 526 px toast (x 377..903, one line, entirely below the clear centre), or have the copy shortened, or amend the UI-SPEC bound (03-12 D4; unmet-truth entry in .planning/WINDOWS.md).
result: [pending]

### 13. Knocked-out king widget legibility
requirement: UI-01
expected: Get the king knocked out at night and read the bottom-left widget and the "Knocked out" countdown label (screenshot hud_king_down). The red "0 / 50" is readable (KNOCKED_OUT_ALPHA 0.4 gives about 1.6:1 contrast per 03-UI-REVIEW.md priority fix 1); otherwise raise the alpha or keep the label opaque.
result: [pending]

### 14. Bottom-centre hierarchy, plural copy and the lingering payout line
requirement: UI-01
expected: On a day with a squad selected look at the bottom-centre stack (hint row, slots, start-night prompt, fill bar, preview); at one enemy left read the banner; after a dawn look for the "+2 gold" line. The start-night prompt still reads as the day focal point beside a cyan selected slot; the banner should say "1 enemy", not "1 enemies left"; the payout line should expire at the next day start. Decide whether any of these block Phase 4 (03-UI-REVIEW fix 3; PLAYTEST-GATE open readability points; the plural and payout lines are Phase 1 and 2 copy).
result: [pending]

### 15. Owner Phase 3 gate: two or three full runs on both devices, then sign off or name fixes
requirement: UNIT-04, UNIT-05, UNIT-06, UNIT-07, UNIT-09, UNIT-10, KING-04, KING-05, INPT-01, INPT-02, UI-01
expected: Launch build/windows/Duskhold.exe (exported 2026-10-12 from c418b6c, launch-checked) or the editor binary, play two or three full 8-night runs with an army, once on keyboard and mouse and once on a gamepad, switching device at least once per run, following 03-PLAYTEST-GATE.md. Record a decision through /gsd-verify-work: sign off (squads guard and commit, selection and commands feel right on both devices, slam and regeneration suit the game, the HUD reads at night with the centre clear, the retuned nights are tense) or list fixes and any of assumptions 1 to 15 to change. No Phase 4 work starts before it.
result: [pending]

## Summary

total: 15
passed: 0
issues: 0
pending: 15
skipped: 0
blocked: 0

## Gaps

None recorded yet. Open code-review findings (03-REVIEW.md, all open in 03-REVIEW-DISPOSITION.md): CR-01 unbounded squad spawn loop on a unit with max_health <= 0 (data corruption only; shipped footman 10 hp, archer 6 hp), WR-01 the king's floating health bar ignores regeneration, WR-02 tools/screenshot.sh does not fail on script errors, WR-03 refused squad orders are silent, IN-01 to IN-06. A review-fix pass is the next step before or alongside this UAT.
