---
status: diagnosed
phase: 02-night-defense-playtest-gate
source: [02-VERIFICATION.md]
started: 2026-10-05T15:26:33Z
updated: 2026-10-06T10:56:56Z
---

## Current Test

[testing complete]

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

## Summary

total: 11
passed: 9
issues: 2
pending: 0
skipped: 0
blocked: 0

## Gaps
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
    - "Speed-up: either sprint_multiplier 2.4 (12 m/s, acceleration about 60, update test_king_movement_config.gd) or a new deterministic fast-forward input (more fixed 1/30 s ticks per real second, king movement scaled the same) — owner to decide which was meant"
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
