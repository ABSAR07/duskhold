---
status: testing
phase: 02-night-defense-playtest-gate
source: [02-VERIFICATION.md]
started: 2026-10-05T15:26:33Z
updated: 2026-10-06T14:44:25Z
---

## Current Test

number: 12
name: Owner round-2 playtest gate (ROADMAP SC4, D-18): replay one or two runs on the fresh build/windows/Duskhold.exe (exported in 02-16) and either sign off or name further fixes, covering the four G-02-1 points and the G-02-2 spacing
expected: |
  A recorded decision through /gsd-verify-work. Sign-off means: base gold fixes the tower-first trap without making gold meaningless, the castle attack is simple and not too strong, the 12 m/s sprint and the night fast-forward are fast enough, the game is a bit easier but still tense, and the results spacing looks even. Otherwise a list of fixes and any of assumptions 12 to 15 to change. Read the Round 2 section of 02-PLAYTEST-GATE.md first (what changed for each point, the controls table with the Fast-forward row, the round-2 balance table)
awaiting: user response

## Tests

### 1. Owner playtest gate (ROADMAP SC4, D-18): play one or two full 8-night runs on the exported build and either sign off or record the fixes that must land before Phase 3
expected: A recorded decision through /gsd-verify-work: sign-off that gold trade-offs feel meaningful and nights feel tense and readable, or a list of tuning/feel fixes, plus any of the 13 assumptions to change
result: issue
reported: "(1) there needs to be some base gold gain at each wave. I made a tower the first wave and then had 0 gold for all waves after that. (2) castle should also have a simple attack, not too strong though. Maybe takes three shots to kill a grunt and two to kill the ranged units. (3) the speed up should be at least 1.5x faster too (4) i cant currently win lol make it just a bit easier"
severity: major

### 2. Results screen layout and the accidental-restart tap (WR-03, and the second review's WR-01, both now fixed in the code)
expected: Stat rows have a clear gap above the buttons; Quit is distinguishable from the panel. Tapping or mashing Space or gamepad A as Victory/Defeat appears does not restart the run or quit: for the first 0.6 s of the screen both buttons ignore every press, and Play again works after that. A press that BEGINS inside the 0.6 s window and is released after it also does nothing (the code stamps when a press began, on button_down, and counts it only if it began after the window), and so does a key that was already held when the screen appeared. A fresh press that begins after the window works. Judge the feel: that 0.6 s neither lets a mash through nor feels sluggish before Play again responds, and that a held or straddling press does nothing
result: issue
reported: "stat rows have a gap between each other and between them and the buttons but the gap between the stat rows and the buttons is smaller than the gap within the stat rows. I think it should be equal. The rest is all good and passes (accidental-restart tap and press feel pass)."
severity: cosmetic

### 3. Enemy, health-bar, projectile and slash readability at night at the default camera
expected: Red grunts and violet skirmishers are told apart and read against the dark ground; hurt-only bars on enemies, king, castle and buildings are legible; arrows (now 15 cm x 1 m) are visible; the king's slash is visible
result: pass

### 4. Ghost king and knockout countdown
expected: On a knockout the king becomes a cyan ghost that cannot be steered, 'Knocked out - back in N s' reads clearly, and the king reappears at the castle on time; respawn times (6, 10, 14, 15 s) feel like a cost but not a punishment
result: pass

### 5. Rubble and collapse
expected: A destroyed House or tower collapses over about 0.9 s into rubble that is readable against the dark ground and on the pale plot disc
result: pass

### 6. Spawn telegraph markers and the night preview line
expected: By day each spawn point that will send enemies shows a red disc with its count (44 px on 1280x720) or an edge arrow when off screen, and 'Night N: X enemies from Y directions' sits under the start-night prompt; the player can plan from them
result: pass

### 7. Crossed-out coin over rebuilt Houses at dawn
expected: Each rebuilt House shows a crossed-out gold coin (26 px, on a red roof) and the player understands it pays nothing this dawn; it fades when the day starts
result: pass

### 8. Debug overlay path lines (F3) during a night
expected: Enemy-to-target and road lines are visible enough at game camera distance (currently 1-pixel hairlines); Wave, King and Paths sections read correctly
result: pass

### 9. Loss beat and results screen in a real defeat and a real victory
expected: On defeat the castle collapses for about 1.2 s, then the Defeat screen; on victory the screen appears at once; Play again starts a fresh run from day 1 and Quit closes the game; the screen works with keyboard, gamepad and mouse (all three act only after the 0.6 s grace)
result: pass

### 10. Hand-steered king, ride cost and gamepad feel at night; night 3 fairness
expected: The king handles well when steered by hand; riding between plots costs a meaningful amount of day; night 3 (king alone against two roads) feels fair to a first-time player; gamepad play at night works
result: pass

### 11. The 13 assumptions on the owner's behalf
expected: Owner confirms or changes each; in particular full dawn repair (1), no last dawn payout after night 8 (2), 6/10/14/15 s respawn (10), the 4-gold opening (13). Also the Play again behaviour recorded in 02-07 (a new random seed, so a replayed run is not the same run) is flagged in the summary but is not one of the 13
result: pass

### 12. Owner round-2 playtest gate (ROADMAP SC4, D-18): replay one or two runs on the fresh build/windows/Duskhold.exe (exported in 02-16) and either sign off or name further fixes, covering the four G-02-1 points and the G-02-2 spacing
expected: A recorded decision through /gsd-verify-work. Sign-off means: base gold fixes the tower-first trap without making gold meaningless, the castle attack is simple and not too strong, the 12 m/s sprint and the night fast-forward are fast enough, the game is a bit easier but still tense, and the results spacing looks even. Otherwise a list of fixes and any of assumptions 12 to 15 to change. Read the Round 2 section of 02-PLAYTEST-GATE.md first (what changed for each point, the controls table with the Fast-forward row, the round-2 balance table)
result: [pending]

### 13. G-02-1 points 1 and 2 as seen on the real camera: the castle's base-income coin at dawn and the castle's arrows at night
expected: At dawn one coin starts from the top of the castle keep (4.5 m above the castle centre) and flies to the gold counter, read as the castle paying 1 gold. At night, when an enemy comes within 11 m of the castle, a gold arrow leaves the top of the keep; three hits kill a grunt and two a skirmisher. Judge whether the castle attack reads as simple and not too strong. Note: the balanced bot never lets an enemy within 11 m, so castle arrows appear mostly when the defence is thin
result: [pending]

### 14. G-02-1 point 3: how the 12 m/s sprint, the 60 m/s^2 braking and the night 2x fast-forward feel in the owner's hands
expected: The king still stops on a plot when the sprint key is released (full-sprint stop 1.2 m, inside the 2.5 m build radius) and is not uncontrollable at 12 m/s. Holding F or the gamepad left trigger at night runs the game at 2x and the 'Fast-forward 2x' label (top right) is legible. The game returns to real time at dawn, in the 1.2 s defeat beat and on the results screen. Say whether night-only is acceptable or you want it by day too or faster than 2x (assumption 14). Round-1 test 10 passed at 8 m/s; the sprint changed, so the handling judgement is partly reopened here
result: [pending]

### 15. G-02-1 point 4: difficulty for a human after the three fixes
expected: Decide whether the run is now 'a bit easier' rather than too easy, and whether night 3 and the castle still feel fair. The bots now win 10 of 10 (balanced and tower-first); the balanced bot loses no building and is never knocked out, which is easier than 'a bit easier', and none of your two levers (night-3 east grunts 5 to 4, castle health 70 to 80) was applied because the balanced bot never lost. If it feels too easy, the levers in 02-BALANCE-REPORT.md are the night counts and the castle's damage, never grunt health
result: [pending]

### 16. G-02-2: results screen spacing on a real Victory and a real Defeat
expected: The visible gap from the last stat row to the Play again and Quit buttons looks equal to the gap between stat rows (11 px added above the button row). Quit is still distinguishable. Play again, Quit and the 0.6 s accidental-restart grace behave as passed in round 1
result: [pending]

### 17. Assumptions 12 to 15 of the round-2 packet, made on the owner's behalf
expected: Confirm or change: 12 (the bot measurement rule), 13 (base income of 1 gold per dawn paid on every dawn including the first, the castle attack numbers 2 dmg / 11 m / 1.5 s / 18 m/s, no night-3 or castle-health change), 14 (fast-forward night only, 2x, F or left trigger), 15 (the base income shown as a coin from the castle, not a text line)
result: [pending]

## Summary

total: 17
passed: 9
issues: 2
pending: 6
skipped: 0
blocked: 0

## Gaps

> Round 2 (2026-10-06): plans 02-12 to 02-16 closed the code side of G-02-1 (points 1 to 3) and G-02-2, and re-measured point 4 under the owner's rule (no lever applied; balanced bot 10 of 10). The owner's re-check of each is tests 12 to 17 above; the gap rows below keep their round-1 wording until that decision is recorded.
- gap_id: G-02-1
  truth: "A recorded decision through /gsd-verify-work: sign-off that gold trade-offs feel meaningful and nights feel tense and readable, or a list of tuning/feel fixes, plus any of the 13 assumptions to change"
  status: failed
  reason: "User reported: (1) there needs to be some base gold gain at each wave. I made a tower the first wave and then had 0 gold for all waves after that. (2) castle should also have a simple attack, not too strong though. Maybe takes three shots to kill a grunt and two to kill the ranged units. (3) the speed up should be at least 1.5x faster too (4) i cant currently win lol make it just a bit easier"
  severity: major
  test: 1
  root_cause: "Gold enters a run only as MapConfig.starting_gold (4) and the dawn sum of standing Houses' dawn_income (run_manager.gd:191-198, building_system.gd:78-90); towers pay nothing (D-10) and no base, castle or per-night income exists, so a day-1 tower leaves gold at 0 for the whole run (the towers_first bot earns 0 and loses 10 of 10). The castle holds health only (castle_state.gd) and NightSim.step never steps a castle attacker: a castle attack is a missing feature; grunt 6 hp and skirmisher 4 hp make damage 2 the one value giving 3 and 2 shots, with range about 11 m to reach a skirmisher firing at the castle. There is no game speed-up control at all (no input action, no Engine.time_scale, map_root.gd:42 passes the raw delta); the only speed-up the owner had is the king's sprint, walk 5.0 x 1.6 = 8 m/s (king.tres:7-8), so 'at least 1.5x faster' means sprint_multiplier >= 2.4 if it means the sprint, or a new fast-forward if it means game speed (owner asked). Difficulty: the tower-first opening is a dead end because of the income rule, and night 3 (king alone against 6 west + 5 east grunts, prototype_map.tres:100-114) is the one tight night; a 700-run probe shows +1 gold per dawn alone turns tower-first from 0/10 into 10/10 and keeps greedy at 0/10."
  artifacts:
    - path: "simulation/run/run_manager.gd"
      issue: "_apply_dawn_payout (191-198) grants only the sum of building income; no base income path"
    - path: "simulation/buildings/building_system.gd"
      issue: "dawn_income_by_spot (78-90) lists standing non-rebuilt Houses only"
    - path: "data/maps/prototype_map.tres"
      issue: "starting_gold 4 (:345), castle_max_health 70 (:353), castle_radius 3.5 (:354), night 3 groups (:100-114); no base income or castle attack fields exist in MapConfig"
    - path: "simulation/castle/castle_state.gd"
      issue: "health only; no attacker"
    - path: "simulation/night/night_sim.gd"
      issue: "step (74-79) orders spawn, king, towers, enemies, hits; no castle attacker step"
    - path: "simulation/night/tower_system.gd"
      issue: "the attacker pattern to reuse (TargetQuery.nearest_enemy, SimClock.flight_ticks, PendingHits.enqueue with KIND_CASTLE)"
    - path: "presentation/vfx/projectile_vfx.gd"
      issue: "113 and 172-183 ignore attacker kinds other than building and enemy; castle arrows would be invisible"
    - path: "tools/replay/replay_driver.gd"
      issue: "136-139 tallies kills for king and towers only"
    - path: "ui/hud/dawn_payout_vfx.gd"
      issue: "151-191 expects total to equal the sum of per_spot; base gold must be listed per spot (castle key) or it warns and never flies"
    - path: "data/king/king.tres"
      issue: "walk 5.0, sprint_multiplier 1.6, acceleration 40 (:7-9); pinned by test_king_movement_config.gd:20-21"
    - path: "project.godot"
      issue: "no speed-up / fast-forward input action exists"
  missing:
    - "A base dawn income that does not come from a building (e.g. MapConfig.base_dawn_income, script default 0 so frozen fixtures and the golden keep their digests; 1 in prototype_map.tres), paid in _apply_dawn_payout and listed in per_spot so the payout VFX contract holds"
    - "A castle attacker: MapConfig data (damage 2, range about 11 m, interval about 1.5 s, projectile speed about 18 m/s, defaults 0 = off), a TowerSystem-style step at a fixed point in NightSim order using KIND_CASTLE, plus ProjectileVfx origin handling and the replay kill tally"
    - "Speed-up, OWNER DECISION 2026-10-06 (\"both\"): (a) the king sprint at least 1.5x its current 8 m/s, i.e. sprint_multiplier >= 2.4 (12 m/s) with acceleration raised (about 60) so stopping stays inside the 2.5 m build radius, and test_king_movement_config.gd updated; AND (b) a new fast-forward input (keyboard and gamepad bindings, mouse not required) that runs the simulation at >= 1.5x real time while held during the night: deterministic by construction (more fixed 1/30 s ticks per real second, king movement in presentation scaled the same), with the MAX_ADVANCE_SECONDS clamp and the debug overlay accounted for"
    - "Re-run tools/playtest.sh and the owner's playtest after the above before touching night 3 counts or castle health; do not lower grunt hp to 5 (king would one-shot grunts)"
  debug_session: .planning/debug/playtest-economy-castle-speed-difficulty.md
- gap_id: G-02-2
  truth: "Stat rows have a clear gap above the buttons; Quit is distinguishable from the panel. Tapping or mashing Space or gamepad A as Victory/Defeat appears does not restart the run or quit: for the first 0.6 s of the screen both buttons ignore every press, and Play again works after that. A press that BEGINS inside the 0.6 s window and is released after it also does nothing (the code stamps when a press began, on button_down, and counts it only if it began after the window), and so does a key that was already held when the screen appeared. A fresh press that begins after the window works. Judge the feel: that 0.6 s neither lets a mash through nor feels sluggish before Play again responds, and that a held or straddling press does nothing"
  status: failed
  reason: "User reported: stat rows have a gap between each other and between them and the buttons but the gap between the stat rows and the buttons is smaller than the gap within the stat rows. I think it should be equal. The rest is all good and passes (accidental-restart tap and press feel pass)."
  severity: cosmetic
  test: 2
  root_cause: "The Column VBoxContainer (results_screen.tscn:39) puts 12 px between every child rect, but each 36 px stat Label rect carries about 9 px of empty space above its capitals (font ascent minus cap height, Open Sans SemiBold 26 px) while the Buttons row has no such leading and the focused Play again's focus StyleBox expands 2 px above its rect; measured on the render the stat rows are 28 px baseline-to-cap apart but the last row is only 17 px from the Play again outline, 11 px short."
  artifacts:
    - path: "ui/results/results_screen.tscn"
      issue: "Column separation 12 (:37-39) applied rect to rect; Buttons HBoxContainer (:76-101) has no leading above it and the focus outline extends 2 px above Play again"
  missing:
    - "Add 11 px above the Buttons row only: wrap Buttons in a MarginContainer with margin_top = 11, or give Buttons custom_minimum_size (0, 59) with both buttons size_flags_vertical SHRINK_END; keep the stat rows untouched (the e2e tests reach the buttons by unique name, so wrapping is safe)"
    - "Note the value depends on the font and size; recompute as ascent minus cap height plus the 2 px focus expand if either changes"
  debug_session: .planning/debug/results-screen-button-gap.md
