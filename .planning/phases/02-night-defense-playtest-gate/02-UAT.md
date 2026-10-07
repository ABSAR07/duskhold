---
status: testing
phase: 02-night-defense-playtest-gate
source: [02-VERIFICATION.md]
started: 2026-10-05T15:26:33Z
updated: 2026-10-07T00:55:13Z
---

## Current Test

number: 18
name: Owner round-3 playtest gate (ROADMAP SC4, D-18, G-02-12): replay one or two full runs on the fresh build/windows/Duskhold.exe (exported 2026-10-07 in plan 02-20) or the editor binary, then either sign off or name the fixes that must land first, covering the three round-2 fixes (castle 22 m and 27 m/s, the fast-forward toggle, the full-wall night counts)
expected: |
  A recorded decision through /gsd-verify-work. Sign-off means: the castle's reach and arrows feel right, the toggle works the way the owner wants, and the game is 'a little harder' in a way the owner accepts. Otherwise a list of fixes (for example the alternatives k7pS4m or k4pS6m named in 02-PLAYTEST-GATE.md) and any of assumptions 12 to 15 to change
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
result: issue
reported: "Fixes first (owner decision, round 2, 2026-10-07): castle range should be double and arrow speed 1.5x faster (test 13); speed up should be togglable instead of hold (test 14); difficulty a little harder, balanced bot should lose 2-3 of 10 (test 15). Everything else passes: base gold, spacing, sprint, 2x pace, label, night-only. Phase 2 does not close until these land and the owner replays (round 3)"
severity: major

### 13. G-02-1 points 1 and 2 as seen on the real camera: the castle's base-income coin at dawn and the castle's arrows at night
expected: At dawn one coin starts from the top of the castle keep (4.5 m above the castle centre) and flies to the gold counter, read as the castle paying 1 gold. At night, when an enemy comes within 11 m of the castle, a gold arrow leaves the top of the keep; three hits kill a grunt and two a skirmisher. Judge whether the castle attack reads as simple and not too strong. Note: the balanced bot never lets an enemy within 11 m, so castle arrows appear mostly when the defence is thin
result: issue
reported: "castle range should be double what it is now, and arrow speed should be 1.5x faster (owner, round 2, 2026-10-07; given on the gate test, belongs to the castle attack)"
severity: minor

### 14. G-02-1 point 3: how the 12 m/s sprint, the 60 m/s^2 braking and the night 2x fast-forward feel in the owner's hands
expected: The king still stops on a plot when the sprint key is released (full-sprint stop 1.2 m, inside the 2.5 m build radius) and is not uncontrollable at 12 m/s. Holding F or the gamepad left trigger at night runs the game at 2x and the 'Fast-forward 2x' label (top right) is legible. The game returns to real time at dawn, in the 1.2 s defeat beat and on the results screen. Say whether night-only is acceptable or you want it by day too or faster than 2x (assumption 14). Round-1 test 10 passed at 8 m/s; the sprint changed, so the handling judgement is partly reopened here
result: issue
reported: "speed up should be togglable instead of hold to speed up. everything else is pass (owner, round 2, 2026-10-07: sprint, braking, 2x, label and night-only all pass; the fast-forward input should be a toggle, not a hold)"
severity: minor

### 15. G-02-1 point 4: difficulty for a human after the three fixes
expected: Decide whether the run is now 'a bit easier' rather than too easy, and whether night 3 and the castle still feel fair. The bots now win 10 of 10 (balanced and tower-first); the balanced bot loses no building and is never knocked out, which is easier than 'a bit easier', and none of your two levers (night-3 east grunts 5 to 4, castle health 70 to 80) was applied because the balanced bot never lost. If it feels too easy, the levers in 02-BALANCE-REPORT.md are the night counts and the castle's damage, never grunt health
result: issue
reported: "difficulty should be tweaked to be little harder. I think balanced bot should lose 2-3 times out of 10 (owner, round 2, 2026-10-07: target for the balanced bot on seeds 1 to 10 is 7 or 8 wins, not 10; levers per 02-BALANCE-REPORT.md are the night counts and the castle's damage, never grunt health)"
severity: minor

### 16. G-02-2: results screen spacing on a real Victory and a real Defeat
expected: The visible gap from the last stat row to the Play again and Quit buttons looks equal to the gap between stat rows (11 px added above the button row). Quit is still distinguishable. Play again, Quit and the 0.6 s accidental-restart grace behave as passed in round 1
result: pass
evidence: "owner: otherwise the spacing etc looks ok (round 2, 2026-10-07); orchestrator screenshots results_victory/results_defeat show the button row spaced like the stat rows"

### 17. Assumptions 12 to 15 of the round-2 packet, made on the owner's behalf
expected: Confirm or change: 12 (the bot measurement rule), 13 (base income of 1 gold per dawn paid on every dawn including the first, the castle attack numbers 2 dmg / 11 m / 1.5 s / 18 m/s, no night-3 or castle-health change), 14 (fast-forward night only, 2x, F or left trigger), 15 (the base income shown as a coin from the castle, not a text line)
result: pass
evidence: "owner, round 2, 2026-10-07: 12 confirmed as the measurement rule with the target changed to the balanced bot winning 7 or 8 of 10 seeds; 15 pass; 13 and 14 superseded by the answers on tests 13 (castle range x2, arrow speed x1.5), 14 (fast-forward toggle) and 15 (a little harder)"

### 18. Owner round-3 playtest gate (ROADMAP SC4, D-18, G-02-12): replay one or two full runs on the fresh build/windows/Duskhold.exe (exported 2026-10-07 in plan 02-20) or the editor binary, then either sign off or name the fixes that must land first, covering the three round-2 fixes (castle 22 m and 27 m/s, the fast-forward toggle, the full-wall night counts)
expected: A recorded decision through /gsd-verify-work. Sign-off means: the castle's reach and arrows feel right, the toggle works the way the owner wants, and the game is 'a little harder' in a way the owner accepts. Otherwise a list of fixes (for example the alternatives k7pS4m or k4pS6m named in 02-PLAYTEST-GATE.md) and any of assumptions 12 to 15 to change
result: [pending]

### 19. G-02-13 as seen on the real camera: the castle at 22 m reach and 27 m/s arrows
expected: At night a gold arrow leaves the keep at an enemy up to 22 m away and flies visibly fast (an edge shot lands in 25 ticks, under the 45-tick interval, so one arrow is in the air at a time); three hits kill a grunt and two a skirmisher. The owner says whether this reads as simple and not too strong now that it covers the two inner House plots and the centres of houses 3 and 4
result: [pending]

### 20. G-02-14: the fast-forward toggle on a real keyboard and a real gamepad trigger
expected: At night one press of F (or one left-trigger pull) switches to 2x and it stays on after release with the 'Fast-forward 2x' label; the next press switches it off. A long hold, a quick tap and a trigger hovering near halfway each toggle once. It resets by itself at dawn, victory and defeat, so each night starts at real time, and presses by day or on the results screen do nothing
result: [pending]

### 21. G-02-15: difficulty after the full wall, in the owner's hands
expected: The owner decides whether the game is 'a little harder' rather than too hard, knowing the measured shape: the balanced bot wins 8 of 10 seeds (36 of 50 on seeds 1 to 50), every loss is a night-3 wall for a House opening that lost two Houses on night 2 (3 gold at dawn 2, below the 4-gold tower, then 21 grunts with no tower), and a tower opening is the strictly safer start
result: [pending]

### 22. Assumptions 12 to 15 of the round-3 packet, on the owner's behalf
expected: The owner confirms or changes: 12 (bot measurement rule restated with the 7-or-8 target), 13 and 14 (rewritten in round 3 for the castle numbers and the toggle), 15 (base income shown as a coin from the castle, still standing)
result: [pending]

## Summary

total: 22
passed: 11
issues: 6
pending: 5
skipped: 0
blocked: 0

## Gaps

> Round 2 (2026-10-06): plans 02-12 to 02-16 closed the code side of G-02-1 (points 1 to 3) and G-02-2, and re-measured point 4 under the owner's rule (no lever applied; balanced bot 10 of 10). The owner's re-check of each is tests 12 to 17 above; the gap rows below keep their round-1 wording until that decision is recorded.
> Round 3 (2026-10-07): plans 02-17 to 02-20 closed the code side of G-02-13 (castle 22 m / 27 m/s), G-02-14 (fast-forward toggle) and G-02-15 (the full wall, balanced 8 of 10) and reopened the gate for G-02-12 with a fresh export and the round-3 packet. The owner's re-check of each is tests 18 to 22 above; the gap rows below keep their round-2 wording until that decision is recorded through /gsd-verify-work.
- gap_id: G-02-1
  truth: "A recorded decision through /gsd-verify-work: sign-off that gold trade-offs feel meaningful and nights feel tense and readable, or a list of tuning/feel fixes, plus any of the 13 assumptions to change"
  status: resolved
  resolved_by: 02-12-PLAN.md, 02-13-PLAN.md, 02-15-PLAN.md, 02-16-PLAN.md
  resolved_at: 2026-10-06
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
  status: resolved
  resolved_by: 02-14-PLAN.md
  resolved_at: 2026-10-06
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
- gap_id: G-02-13
  truth: "At dawn one coin starts from the top of the castle keep (4.5 m above the castle centre) and flies to the gold counter, read as the castle paying 1 gold. At night, when an enemy comes within 11 m of the castle, a gold arrow leaves the top of the keep; three hits kill a grunt and two a skirmisher. Judge whether the castle attack reads as simple and not too strong. Note: the balanced bot never lets an enemy within 11 m, so castle arrows appear mostly when the defence is thin"
  status: failed
  reason: "User reported: castle range should be double what it is now, and arrow speed should be 1.5x faster (owner, round 2, 2026-10-07; given on the gate test, belongs to the castle attack)"
  severity: minor
  test: 13
  root_cause: "A tuning decision on shipped data, not a code bug: data/maps/prototype_map.tres:357 castle_attack_range = 11.0 and :359 castle_projectile_speed = 18.0 are read by CastleAttack.step every tick (range into TargetQuery.nearest_enemy at castle_attack.gd:51, speed into SimClock.flight_ticks at :54-56) and ProjectileVfx times each arrow from the event's flight_ticks, so 'double the range, 1.5x the arrow speed' is exactly 22.0 and 27.0 in those two lines with no code change. At 11 m the castle fires only during the last 6.3 m before a grunt reaches its wall and covers no House plot; at 22 m it covers house_1 to house_4 (12.7 and 21.6 m), never a tower circle (gap 22.5 m), a lone grunt takes all three hits before the wall and a lone skirmisher dies before its 10.5 m stand-off; flight at the edge is 25 ticks (0.83 s) instead of 19. validate() accepts both values; no test asserts 11.0 or 18.0 against the shipped map (817 of 817 pass on a temporary 22.0/27.0 edit); fixtures and the smoke golden keep castle fields at 0. Balance (seeds 1 to 10, temporary edit): balanced identical (10 of 10, 0 castle kills, the castle never fires for it), towers_first 10 of 10, greedy_economy 0 of 10 with its loss moved from night 5 to night 6 (the top of the acceptance band), no_build now survives exactly night 1 on every seed."
  artifacts:
    - path: "data/maps/prototype_map.tres"
      issue: "castle_attack_range 11.0 (:357) and castle_projectile_speed 18.0 (:359); the owner wants 22.0 and 27.0"
    - path: "simulation/night/castle_attack.gd"
      issue: "doc comment :7-10 states 'reach 11 m' and the stand-off formula; logic reads the map and needs no change"
    - path: "simulation/defs/map_config.gd"
      issue: "doc comment :40-43 ('a simple, slow shot'); _validate_castle_attack :167-185 accepts INF, NaN and sub-step intervals (fourth review WR-02, open)"
    - path: "tests/unit/test_map_validate_castle.gd"
      issue: ":92-116 pins only range >= 10.75, interval 1.5 and speed > 0; does not lock the owner's new numbers"
    - path: "tests/unit/test_castle_attack.gd"
      issue: ":7, :15-19, :95-97, :140-150 use their own 11.0 / 18.0 numbers and call them 'the castle's own numbers'; stay green but go stale (6 m at 27 m/s is 7 ticks)"
    - path: "tests/integration/test_balance_acceptance.gd"
      issue: "GREEDY_LAST_LOSS_NIGHT 6 is now the measured greedy loss night; the G-02-15 lever must pull it back inside the band"
  missing:
    - "Set castle_attack_range 22.0 and castle_projectile_speed 27.0 on the shipped map (data only); add a shipped-data assertion for both in test_map_validate_castle.gd written failing first; refresh the test_castle_attack.gd numbers or header and the two doc comments"
    - "Land this BEFORE the G-02-15 difficulty lever and measure that lever with the 22 m castle in place"
    - "Close the fourth review's WR-02 in the same change: reject non-finite range/interval/speed and an interval below SimClock.STEP when the castle attacks (INF or sub-step fires every tick, NaN silently disarms); optionally an upper bound on the range"
    - "Update the docs quoting 11 m / 18 m/s (02-PLAYTEST-GATE.md :19 :62, 02-BALANCE-REPORT.md :23, ROADMAP.md :154, STATE.md :172) in the round-3 packet plan"
  debug_session: .planning/debug/castle-range-arrow-speed.md
- gap_id: G-02-14
  truth: "The king still stops on a plot when the sprint key is released (full-sprint stop 1.2 m, inside the 2.5 m build radius) and is not uncontrollable at 12 m/s. Holding F or the gamepad left trigger at night runs the game at 2x and the 'Fast-forward 2x' label (top right) is legible. The game returns to real time at dawn, in the 1.2 s defeat beat and on the results screen. Say whether night-only is acceptable or you want it by day too or faster than 2x (assumption 14). Round-1 test 10 passed at 8 m/s; the sprint changed, so the handling judgement is partly reopened here"
  status: failed
  reason: "User reported: speed up should be togglable instead of hold to speed up. everything else is pass (owner, round 2, 2026-10-07: sprint, braking, 2x, label and night-only all pass; the fast-forward input should be a toggle, not a hold)"
  severity: minor
  test: 14
  root_cause: "A design change, not a defect: the hold lives in one line, input/fast_forward_controller.gd:82 inside _apply, `scale_for(phase, Input.is_action_pressed(ACTION), _ctx.tuning)`, which runs every frame from _process (:61-63) and inside the simulation step from _on_phase_changed (:77-78); the controller keeps no on/off state, so Engine.time_scale follows the key from frame to frame, exactly as plan 02-13 asked ('it is a hold, not a toggle'). A toggle needs a latched switch flipped on a press edge while the phase is NIGHT and applied through the same scale_for(phase, switch_on, tuning), which keeps the night-only clamp, the single-writer rule and the determinism argument untouched (nothing under simulation/ reads the time scale; replays never involve the controller). Probe findings on the real InputMap: Input.is_action_just_pressed fires once per left-trigger pull past the 0.5 deadzone, while per-event InputEvent.is_action_pressed is true for every motion event at or above 0.5 (so an _unhandled_input toggle would flip several times in one pull); Godot has no deadzone hysteresis, so a trigger wavering around 0.5 re-fires on each upward crossing (a new risk under a toggle); GUT tests resume on process_frame before any _process, so Input.action_press is seen as just_pressed; the build-hold edge idiom `is_action_just_pressed(ACTION) or (pressed and not _was_pressed)` catches every case exactly once. A scratch latch run through the real scale_for behaved as the orchestrator's default semantics: day presses ignored, press on / press off at night, cleared within the step that leaves NIGHT (dawn, won, lost), a key held from day into night 2 does not arm it."
  artifacts:
    - path: "input/fast_forward_controller.gd"
      issue: ":82 is the only level read of the action (called from _process :61-63 and _on_phase_changed :77-78); scale_for's `held` parameter (:35-41) keeps its body and only needs renaming; hold wording in the docs at :3-4, :15-16, :32; _exit_tree (:66-72) stays"
    - path: "tests/unit/test_fast_forward_rules.gd"
      issue: "_controller_on (:42-47) uses add_child without autofree (fourth review WR-01): under a toggle a leaked controller stays switched on after release_all_actions and flips on later tests' presses; T5 (:95-111), T6 (:114-121, inverts: a key held from day into the night must NOT switch it on), T7 (:123-130), T8 (:133-145, 'resumes across dawn' becomes 'resets at dawn'), T9 (:148-155) and the names of T1/T2 change meaning"
    - path: "tests/e2e/test_fast_forward.gd"
      issue: "header :2-4, E1 (:71-81) 'pressing by day changes nothing', E2 (:84-99) 'hides on release' becomes 'stays shown after release, hides on the second press', E3/E4 should release after the press, E5 (:128-145) 'key still held' becomes 'still switched on' and the next night starts with the label hidden"
    - path: "tests/unit/test_input_map.gd"
      issue: "doc comment :144; the deadzone pin (:58, :146-149) changes only if the deadzone is raised against trigger chatter"
    - path: "simulation/defs/loop_tuning.gd"
      issue: ":53 doc wording ('held'); tests/unit/test_loop_tuning_contract.gd:167 likewise"
  missing:
    - "Keep every change inside FastForwardController: add a `_wanted_on` switch and a `_was_pressed` updated every frame in every phase; detect a press with the build-hold edge idiom and flip the switch only while the phase is NIGHT; apply scale_for(phase, _wanted_on, tuning); in _on_phase_changed clear the switch before _apply when the new phase is not NIGHT so dawn, victory and defeat drop to real time in the same step and each night starts at real time"
    - "Keep F and the left trigger, the `changed` signal, the HUD label, _exit_tree and the single-writer rule; do not use _unhandled_input with event.is_action_pressed (one trigger pull would flip several times); consider a short real-time debounce or a higher deadzone against trigger chatter"
    - "Rewrite the fast-forward tests for toggle semantics (a long hold toggles once, one trigger pull toggles once, a sub-frame tap toggles, WON/LOST/DAWN clear the switch, a day press does not arm the next night) and fix WR-01 with add_child_autofree in the same change"
    - "Record the semantics as the rewritten assumption 14 in the round-3 packet (press on, press off, resets when the night ends, day presses ignored; the switch survives alt-tab where the hold did not); update the controls row in 02-PLAYTEST-GATE.md and the hold wording in 02-SECURITY.md T-02-29 and ROADMAP.md:150"
  debug_session: .planning/debug/fast-forward-toggle.md
- gap_id: G-02-15
  truth: "Decide whether the run is now 'a bit easier' rather than too easy, and whether night 3 and the castle still feel fair. The bots now win 10 of 10 (balanced and tower-first); the balanced bot loses no building and is never knocked out, which is easier than 'a bit easier', and none of your two levers (night-3 east grunts 5 to 4, castle health 70 to 80) was applied because the balanced bot never lost. If it feels too easy, the levers in 02-BALANCE-REPORT.md are the night counts and the castle's damage, never grunt health"
  status: failed
  reason: "User reported: difficulty should be tweaked to be little harder. I think balanced bot should lose 2-3 times out of 10 (owner, round 2, 2026-10-07: target for the balanced bot on seeds 1 to 10 is 7 or 8 wins, not 10; levers per 02-BALANCE-REPORT.md are the night counts and the castle's damage, never grunt health)"
  severity: minor
  test: 15
  root_cause: "Balance data, not a code bug, in two parts that only matter together (every number measured with the G-02-13 castle range 22.0 and arrow speed 27.0 applied). (1) Why balanced wins 10 of 10 and loses nothing: a bigger group count makes a road's stream last longer (one enemy per 1.5 s per group) but never denser; from night 3 on the balanced bot has a tower on every road before it opens (north tower from night 5, north road opens night 6); tier II towers one-shot grunts; the bot's king sprints at 12 m/s to the enemy nearest the castle and kills grunts faster than one road brings them; no enemy ever gets within 41 m of the castle, so castle damage and castle health never matter for it. Nights 6 to 8 have the most slack (+6 per road on night 8 still 10 of 10), and late pressure breaks towers_first first (no north tower, 7 gold; night 8 +1 per road already loses the acceptance-pinned seeds 2 and 3). None of the five obvious levers (nights 3-5 +1/+2, nights 6-8 +1/+3, extra skirmishers, castle damage 1, castle health 60), alone or stacked, moves balanced off 10 of 10. (2) The one place balanced can lose is nights 2 to 3 of its House opening: when night 2 costs the lone king 2 of its 3 Houses, dawn 2 pays 3 gold (a rebuilt House pays nothing that dawn, building_system.gd:82), below the 4-gold first tower, so night 3 starts with no tower and must then be too heavy for the king plus the castle. Either change alone still gives 10 of 10. Recommended data edit k4pS5m: night 2 adds an east grunt group (count 4, delay 2.0 s, interval 1.5 s); night 3 west 6 to 11, east 5 to 10; night 4 west 7 to 11, east 4 to 7 and night 5 west 7 to 9, east 7 to 8 only so the totals never fall (totals 5, 12, 21, 21, 21, 22, 27, 33); castle damage 2, castle health 70, grunt health 6, costs, incomes, base income, starting gold, nights 1 and 6 to 8 and all skirmisher groups unchanged. Measured (tool runs on temporary edits): balanced 8 of 10 (loses seeds 3 and 9 on night 3; 36 of 50 = 72% on the wider harness), greedy_economy 0 of 10 with losses on nights 3 (x6) and 4 (x4), no_build loses night 2, towers_first 10 of 10 and 50 of 50 with 7.0 gold, no balanced knockout. Alternatives: k7pS4m (night 2 east 7; night 3 west 10, east 9; night 4 west 10, east 6; night 5 west 8) gives 7 of 10 (seeds 4, 6, 8) and 76% of 50 with greedy losses spread over nights 3 to 6; k4pS6m (night 3 west 12, east 11 and more) gives 7 of 10 but 66% of 50. The response is steep (night 3 +4/+5/+6/+8 per road = 88/72/66/56% over 50 seeds), so 7 or 8 of 10 is one setting, not a range. Plainly for the owner: the extra difficulty is a NIGHT-3 WALL for House openings (a House opening that loses 2 Houses on night 2 meets 21 grunts on night 3 with no tower, heavier than round 1's night 3 that the owner could not beat); a tower opening stays safe and becomes the strictly safer start; houses_first loses on the same seeds. The bot target is met, but only the owner's replay can judge whether this is 'a little harder'."
  artifacts:
    - path: "data/maps/prototype_map.tres"
      issue: "night 2 to 5 grunt group counts (:86-160) and a new night-2 east group; nights 1 and 6 to 8 and all skirmisher groups unchanged"
    - path: "tests/integration/test_balance_acceptance.gd"
      issue: "test_balanced_wins_every_run pins 3 of 3 on seeds 1 to 3; with the edit seed 3 is lost (0.667) and the pin must become a seeds-1-to-10 win count between 7 and 8 (optionally the losing seeds 3 and 9 and 'every balanced loss on night 3 or later'); runtime about 23 to 25 s"
    - path: "tests/unit/test_night_data_contract.gd"
      issue: "NIGHT_TOTALS must become [5, 12, 21, 21, 21, 22, 27, 33]; the only other failing test"
    - path: "simulation/buildings/building_system.gd"
      issue: ":82, a rebuilt House pays nothing that dawn: the rule that makes the lever work; no change"
    - path: "tools/replay/playtest_bot.gd"
      issue: "the perfect king (sprint to the nearest threat, never misses) and the tower ordering explain why counts do not bite; out of scope to change"
    - path: ".planning/phases/02-night-defense-playtest-gate/02-BALANCE-REPORT.md"
      issue: "needs a Round 3 section; the full_idle replay changes to 5140 ticks, digest bb9059c8... (quoted only in phase docs; no test or CI step pins the old 27fa2a80...)"
  missing:
    - "OWNER DECISION 2026-10-07 (asked once, chose the full wall, bot 8 of 10): land G-02-13 (22.0 / 27.0) first, then apply exactly the measured k4pS5m edit (night 2 adds an east grunt group of 4, delay 2.0 s, interval 1.5 s; night 3 west 11, east 10; night 4 west 11, east 7; night 5 west 9, east 8; totals 5, 12, 21, 21, 21, 22, 27, 33). The owner heard that this is a night-3 wall for House openings and accepted it; the round-3 packet must say so plainly"
    - "Change test_balanced_wins_every_run to a seeds-1-to-10 count between 7 and 8 (pin the losing seeds and night 3 or later) and NIGHT_TOTALS to the new totals; test_every_night_ends, test_king_sturdiness, test_wave_schedule, test_spawn_telegraph (night 2 now shows two markers), test_prototype_nights, test_map_validate_nights, test_playtest_strategies and test_balance_report pass unchanged; the smoke golden is unchanged"
    - "Refresh 02-BALANCE-REPORT.md and the round-3 packet, re-run the 15 screenshots in a real window (night_combat, spawn_telegraph and building_destroyed depend on the night data), export a fresh build, and tell the owner plainly about the night-3 wall"
  debug_session: .planning/debug/difficulty-balanced-7-of-10.md
- gap_id: G-02-12
  truth: "A recorded decision through /gsd-verify-work. Sign-off means: base gold fixes the tower-first trap without making gold meaningless, the castle attack is simple and not too strong, the 12 m/s sprint and the night fast-forward are fast enough, the game is a bit easier but still tense, and the results spacing looks even. Otherwise a list of fixes and any of assumptions 12 to 15 to change. Read the Round 2 section of 02-PLAYTEST-GATE.md first (what changed for each point, the controls table with the Fast-forward row, the round-2 balance table)"
  status: failed
  reason: "User reported: Fixes first (owner decision, round 2, 2026-10-07): castle range should be double and arrow speed 1.5x faster (test 13); speed up should be togglable instead of hold (test 14); difficulty a little harder, balanced bot should lose 2-3 of 10 (test 15). Everything else passes: base gold, spacing, sprint, 2x pace, label, night-only. Phase 2 does not close until these land and the owner replays (round 3)"
  severity: major
  test: 12
  root_cause: "Not a code defect: this row is the owner's round-2 gate decision ('fixes first', D-18). The three fixes it names are diagnosed as their own gaps and this gap closes when they land and the owner replays: G-02-13 (castle range 22 m, arrow speed 27 m/s), G-02-14 (fast-forward as a toggle), G-02-15 (a little harder: balanced bot wins 7 or 8 of 10). Everything else the owner judged passes: base gold, results spacing, sprint and braking, 2x pace, label, night-only rule, assumptions 12 (confirmed with the 7-8 of 10 target) and 15. No debugger was spawned for this row; the orchestrator recorded it."
  artifacts:
    - path: ".planning/phases/02-night-defense-playtest-gate/02-PLAYTEST-GATE.md"
      issue: "needs a Round 3 section: what changed for the three fixes, the rewritten assumptions 13 (castle numbers, difficulty levers) and 14 (toggle), the round-3 balance table and the decision prompt"
  missing:
    - "Land G-02-13, G-02-14 and G-02-15, export a fresh build/windows/Duskhold.exe, write the round-3 packet, then the owner replays and decides through /gsd-verify-work (a new UAT round; this row is answered then)"
  debug_session: none (gate record; see the three gap sessions)
