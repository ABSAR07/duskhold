---
status: diagnosed
trigger: "UAT Test 18 of Phase 2 (round 3, gap G-02-18): the owner replayed the fresh build (build/windows/Duskhold.exe exported 2026-10-07 from commit 2bdcbd4) and asked for a tuning change: \"Note: make the normal speed 1.5x current normal speed for the king. adjust the speedup to stay at the current magnitude\". Clarified once (AskUserQuestion, 2026-10-07): \"Sprint stays 12 m/s\" - walk 5.0 -> 7.5 m/s, sprint stays 12 m/s (multiplier 2.4 -> 1.6), night fast-forward stays 2x."
created: 2026-10-07T09:14:17Z
updated: 2026-10-07T09:28:43Z
---

## Current Focus

hypothesis: CONFIRMED. Not a defect but an owner tuning decision on shipped data. The king's walk and sprint are two values in data/king/king.tres (:7 walk_speed = 5.0, :8 sprint_multiplier = 2.4, the same at the exported commit 2bdcbd4). King.move_speed (presentation/king/king.gd:27-30) and the playtest bot (tools/replay/playtest_bot.gd:121, :125) read them live. Nothing under simulation/ reads them and nothing hard-codes them. Walk 7.5 with multiplier 1.6 keeps the sprint at exactly 12.0 m/s and needs no code change. It leaves every bot result, the full_idle digest and the smoke golden byte-identical. It turns exactly three literal-pin tests red: walk == 5.0, multiplier == 2.4, and the D-03 ride budget of 20-30 s, which becomes 14.67 s.
test: done. Code read and grep, an IEEE float check of the defending pace, and a TEMPORARY king.tres edit (walk_speed 7.5, sprint_multiplier 1.6). The edit was measured with the four targeted GUT scripts, the full GUT suite, the smoke and full_idle replays, and a 5-strategy x 10-seed playtest diffed against a baseline run at HEAD. Data restored from a cp backup; git diff --quiet -- data/king/king.tres passes; tree clean except this file.
expecting: n/a
next_action: none (diagnose-only); hand back ROOT CAUSE FOUND to the caller
bug_class: Bohrbug (deterministic shipped data value; the request is a tuning change - every run reproduces the 5.0 m/s walk the owner judged)
reasoning_checkpoint:
  hypothesis: "The walk the owner judged in round 3 is walk_speed 5.0 in data/king/king.tres:7. The sprint is 12 m/s = 5.0 x sprint_multiplier 2.4 at :8, identical at 2bdcbd4. King.move_speed reads both live, so walk_speed 7.5 with sprint_multiplier 1.6 gives the owner's 7.5 m/s walk with the sprint still exactly 12 m/s. That two-number data edit is the whole mechanical change."
  confirming_evidence:
    - "grep: walk_speed and sprint_multiplier are set only in king.tres and the frozen smoke fixture king. The readers are King.move_speed (king.gd:27-30, :67) and PlaytestBot._move_king (playtest_bot.gd:121, :125). simulation/ never reads them."
    - "Temporary 7.5 / 1.6 edit, full suite: 829 tests, 826 passing. The 3 failures are exactly the predicted literal pins: test_walk_speed_is_five_metres_per_second '[7.5] expected to equal [5.0]', test_sprint_is_at_least_one_and_a_half_times_the_original_sprint '[1.6] expected to equal [2.4]', and test_ride_across_the_map_takes_twenty_to_thirty_seconds '[14.666...] expected to be between [20.0] and [30.0]'. The full-sprint stop, the e2e ride (ratio within 15% of the data multiplier) and the bot pace tests stay green."
    - "Temporary edit: playtest report.md and report.json (5 strategies x seeds 1-10) are byte-identical to the baseline at HEAD. full_idle REPLAY_OK ticks=5140 digest bb9059c8... unchanged. Smoke digest 2599c7c2... equals the golden. test_balance_acceptance 8 of 8 passing."
  falsification_test: "If anything cached or hard-coded the 5.0 walk, or if the bots walked at night, the bot numbers or the full_idle digest would move with the edit. If 7.5 x 1.6 were not exactly 12.0 in doubles, the defending bot's per-tick step would differ and the digest would move. None of that happened."
  fix_rationale: "The owner's request is a data value, so the fix is the data value (walk_speed 7.5, sprint_multiplier 1.6). On top of that come the three literal pins, the KingDef defaults and doc comment, and the D-03 amendment that the ride-time test encodes. No mechanism change is needed."
  blind_spots: "The bots never walk at night. All building strategies sprint everywhere, and no_build never moves. So the unchanged balance table says nothing about a human who rides without holding sprint: between sprints that player's king is half again as mobile. That can only make human play a little easier, never harder, because the top speed (12 m/s) is unchanged. Walking feel is the owner's judgment: a 0.47 m walk stop, a 0.125 s ramp, and a sprint that adds only 4.5 m/s. The 15 screenshots were not re-run. The hold-point scenarios walk the bot king at walk pace and may frame slightly differently (no golden images exist)."
  candidate_causes:
    - "data: walk_speed 5.0 and sprint_multiplier 2.4 in king.tres are the values the owner wants changed to 7.5 and 1.6 (CONFIRMED)"
    - "code: a hard-coded walk or sprint speed in King, the bot, the camera or the simulation that a data edit would not move (ELIMINATED)"
    - "config/test: contract tests pinning 5.0, 2.4 and the D-03 20-30 s ride budget (CONFIRMED as consequences: exactly 3 tests go red; they encode the old decision, not a defect)"
    - "environment: the exported build carried different numbers from the tree (ELIMINATED: 2bdcbd4 has 5.0 / 2.4 / 60.0 and nothing outside .planning changed since)"
  and_gate: "No. One data change: two coupled numbers so the sprint stays 12 m/s. The D-03 amendment follows from the decision; it is not a second cause."
tdd_checkpoint: (n/a, diagnose-only)

## Symptoms

expected: A recorded decision through /gsd-verify-work (owner round-3 playtest gate, ROADMAP SC4, D-18, G-02-12): sign-off, or a list of fixes.
actual: "Note: make the normal speed 1.5x current normal speed for the king. adjust the speedup to stay at the current magnitude" (owner, round 3, 2026-10-07). Clarification: sprint stays 12 m/s; walk 5.0 -> 7.5 m/s; sprint multiplier becomes 1.6; night fast-forward stays 2x. Everything else judged in round 3 passed (castle 22 m / 27 m/s, the fast-forward toggle, the full-wall difficulty, assumptions 12 to 15).
errors: None reported
reproduction: Test 18 in .planning/phases/02-night-defense-playtest-gate/02-UAT.md (owner play on build/windows/Duskhold.exe exported 2026-10-07 from commit 2bdcbd4); gap id G-02-18
started: Discovered during round-3 UAT on 2026-10-07; the 12 m/s sprint (multiplier 2.4 at walk 5.0, acceleration 60) landed in plan 02-13 on 2026-10-06

## Eliminated

- hypothesis: The walk or sprint speed is hard-coded somewhere outside the data (King, PlaytestBot, CameraRig, the simulation), so editing king.tres would not change the game
  evidence: grep finds walk_speed and sprint_multiplier only in king.tres, the frozen fixture king, King.move_speed (king.gd:27-30) and PlaytestBot._move_king (playtest_bot.gd:121, :125). KingState stores reported positions without any speed check (king_state.gd:40-43). The temporary 7.5 edit turned test_walk_speed_is_five_metres_per_second red with "[7.5] expected to equal [5.0]" and the ride budget red at 14.67 s, so the data edit alone drives the speed.
  timestamp: 2026-10-07T09:28:43Z

- hypothesis: The faster walk moves the bots' balance shape (balanced 8 of 10, losing seeds 3 and 9 on night 3), so the owner's full-wall decision would need re-measuring
  evidence: Every bot that builds uses KING_DEFEND_NEAREST_THREAT, which moves at walk_speed x sprint_multiplier x STEP on every tick. 5.0 x 2.4 and 7.5 x 1.6 both round to exactly 12.0 in IEEE doubles (0.4 m per tick). no_build never leaves king_spawn. Playtest report.md and report.json for 5 strategies x seeds 1-10 are byte-identical to the baseline. test_balance_acceptance passes 8 of 8. full_idle digest bb9059c8... is unchanged.
  timestamp: 2026-10-07T09:28:43Z

- hypothesis: The frozen fixtures or tests/golden/smoke.json move with the walk speed
  evidence: The smoke scenario loads tests/fixtures/fixture_king_replay_smoke.tres (walk 5.0, multiplier 1.6), not the shipped king. Smoke on the temporary edit gave REPLAY_OK digest 2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f, equal to the golden.
  timestamp: 2026-10-07T09:28:43Z

- hypothesis: The exported build the owner played (2bdcbd4) carried numbers different from the tree
  evidence: git show 2bdcbd4:data/king/king.tres has walk_speed 5.0, sprint_multiplier 2.4, acceleration 60.0. git diff --stat 2bdcbd4 HEAD outside .planning is empty.
  timestamp: 2026-10-07T09:28:43Z

## Evidence

- timestamp: 2026-10-07T09:14:17Z
  checked: Knowledge base (.planning/debug/knowledge-base.md) and .planning/debug/resolved/
  found: Neither exists; no MemPalace available. Closest prior session castle-range-arrow-speed.md (an owner tuning decision on shipped data, G-02-13).
  implication: No known-pattern candidate; treat as a data-tuning diagnosis.

- timestamp: 2026-10-07T09:17:12Z
  checked: data/king/king.tres (15 lines), simulation/defs/king_def.gd (23 lines), presentation/king/king.gd (112 lines), grep for walk_speed and sprint_multiplier across every .gd/.tres/.tscn/project.godot outside .godot/.tools/addons
  found: The walk and sprint live only in king.tres:7 walk_speed = 5.0 and :8 sprint_multiplier = 2.4 (acceleration 60.0 at :9). KingDef declares the same defaults (king_def.gd:5, :8, :11). Its doc comment at :6-7 quotes "12 m/s at walk 5.0 ... half again as fast as the 8 m/s sprint", and :9-10 says "60 keeps a full-sprint stop (v^2 / 2a = 1.2 m) inside the build radius". There are only two runtime readers. King.move_speed (king.gd:27-30) returns walk_speed * sprint_multiplier when sprinting, else walk_speed; it is used at king.gd:67, with velocity.move_toward(target, acceleration * delta) at :69. PlaytestBot._move_king uses walk_speed * STEP for the idle and hold modes (playtest_bot.gd:121) and walk_speed * sprint_multiplier * STEP for the defending king (:125). Nothing under simulation/ reads walk_speed or sprint_multiplier: KingState.report_position just stores the position (king_state.gd:40-43), and KingState reads only max_health, attack_range, attack_damage and attack_interval. No code hard-codes 5.0, 2.4 or 12.
  implication: The owner's request is two data values (walk_speed 7.5, sprint_multiplier 1.6); no mechanism has to change. The sprint stays 12 m/s, the number the 02-13 tests and the braking budget were built on.

- timestamp: 2026-10-07T09:17:12Z
  checked: tools/replay/playtest_strategies.gd:91-106, tools/replay/replay_scenarios.gd:86-102, the float arithmetic of the defending pace
  found: balanced, greedy_economy, houses_first and towers_first all use KING_DEFEND_NEAREST_THREAT. Its pace is walk_speed * sprint_multiplier * STEP on every tick, including the way back to the castle front. Only no_build uses KING_IDLE_AT_CASTLE, which walks toward king_spawn; the king starts and respawns there, so he never moves. full_idle plays the balanced bot on the shipped king.tres. Smoke plays KING_HOLD_POINT on tests/fixtures/fixture_king_replay_smoke.tres (walk 5.0, multiplier 1.6, frozen). In IEEE doubles, 5.0 * 2.4 = 11.99999999999999955... and 7.5 * 1.6 = 12.00000000000000067... both round to exactly 12.0 (half an ulp at 12 is 8.9e-16). So the defending pace is bit-identical before and after.
  implication: Prediction: every bot result (all five strategies), the full_idle digest bb9059c8... and the smoke golden stay exactly the same. Only hold-point paths that use the shipped king (screenshot scenarios, some integration tests) can move.

- timestamp: 2026-10-07T09:17:12Z
  checked: tests/unit/test_king_movement_config.gd (72 lines), tests/e2e/test_king_ride.gd (163 lines), tests/unit/test_prototype_map_data.gd:12-13 and :72-86 (ride budget), tests/unit/test_playtest_strategies.gd:102-127, 01-CONTEXT.md D-03, 01-04-PLAN/SUMMARY (15% band)
  found: Literal pins in test_king_movement_config.gd:
    - :10 SOURCE_WALK_SPEED 5.0, asserted at :22-23 ("walk speed feeds the ride-time budget (D-03)").
    - :11 OWNER_SPRINT_MULTIPLIER 2.4, asserted at :27.
    - :12 ORIGINAL_SPRINT_SPEED 8.0 with a 1.5x floor (12 >= 12 still holds).
    - :13 acceleration 60.
    - The header at :2-6 quotes 2.4 and 12 m/s at walk 5.0.
  test_prototype_map_data.gd:12-13 sets MIN_RIDE_S 20 and MAX_RIDE_S 30, and :85-86 computes ride_s = farthest / walk_speed. D-03 says "Riding from edge to edge takes about 20-30 s at normal speed". The farthest pair is 110 m (STATE.md 01-05), so 110 / 7.5 = 14.67 s < 20. test_king_ride.gd reads walk_speed and sprint_multiplier from the data; its ratio test at :62-69 has a +-15% band around the data multiplier (the 01-04 band), which applies to 1.6 again. test_playtest_strategies.gd:124-127 also reads both from the data, and the sprint step of 0.4 m still beats the walk step of 0.25 m.
  implication: Predicted reds: test_walk_speed_is_five_metres_per_second, test_sprint_is_at_least_one_and_a_half_times_the_original_sprint (its multiplier pin) and test_ride_across_the_map_takes_twenty_to_thirty_seconds (the D-03 budget). The D-03 conflict is a decision fact for the plan, not a test to bend silently.

- timestamp: 2026-10-07T09:28:43Z
  checked: Baseline at HEAD (shipped data): bash tools/playtest.sh --seeds=10 --out=build/pt_kw_base (PLAYTEST_OK runs=50, 45 s)
  found: no_build 0% (median loss night 2), greedy_economy 0% (nights 2-3, median loss night 3), houses_first 80%, towers_first 100%, balanced 80% (median loss night 3). This matches the 02-19 round-3 numbers.
  implication: Apples-to-apples baseline for the walk-speed measurement.

- timestamp: 2026-10-07T09:28:43Z
  checked: TEMPORARY edit of king.tres (cp backup to the session scratchpad, sed walk_speed 5.0 -> 7.5 and sprint_multiplier 2.4 -> 1.6), then bash tools/test.sh -gselect= for test_king_movement_config.gd, test_king_ride.gd, test_prototype_map_data.gd and test_playtest_strategies.gd (junit read after each run)
  found:
    - test_king_movement_config.gd: 7 tests, 2 failing. test_walk_speed_is_five_metres_per_second fails at line 23 with "[7.5] expected to equal [5.0]: walk speed feeds the ride-time budget (D-03)". test_sprint_is_at_least_one_and_a_half_times_the_original_sprint fails at line 27 with "[1.6] expected to equal [2.4]: sprint multiplier is 2.4"; its 12 >= 1.5 x 8 floor still holds. The full-sprint stop (1.2 m < 2.5 m) passes.
    - test_king_ride.gd: 10/10 passing. Covered: ride-to-spot within distance / walk_speed + 1.5 s; the sprint/walk ratio within 15% of the data multiplier 1.6 (estimated 10.8 m / 7.03 m = 1.54); the one-step ramp; diagonal movement at walk speed.
    - test_prototype_map_data.gd: 20 tests, 1 failing. test_ride_across_the_map_takes_twenty_to_thirty_seconds fails at line 86 with "[14.666...] expected to be between [20.0] and [30.0]".
    - test_playtest_strategies.gd: 14/14 passing.
  implication: Exactly the three predicted literal pins go red; the data-driven tests absorb the change.

- timestamp: 2026-10-07T09:28:43Z
  checked: Same temporary edit: bash tools/replay.sh --scenario=smoke --twice --expect-file=tests/golden/smoke.json and --scenario=full_idle --twice (out build/replay_kw)
  found: smoke REPLAY_OK outcome=won ticks=703 digest=2599c7c250f45b3dfe6653a8fc683918cbdce768a9afcaf8e3752d3454ccf31f (the golden). full_idle REPLAY_OK outcome=won ticks=5140 digest=bb9059c884f649c3b2b869505e73b94d860dca372820d247d08eeee26fb82dac, IDENTICAL to today. The brief expected full_idle to move. It does not, because the balanced bot only ever moves at the sprint pace, which is exactly 12.0 m/s either way.
  implication: No digest, golden or phase-doc replay line changes.

- timestamp: 2026-10-07T09:28:43Z
  checked: Same temporary edit: bash tools/playtest.sh --seeds=10 --out=build/pt_kw_75 (PLAYTEST_OK runs=50), diffed against build/pt_kw_base
  found: report.md is identical (diff exit 0) and report.json is identical (0 diff lines). balanced 8 of 10, towers_first 10 of 10, houses_first 8 of 10, greedy_economy 0 of 10 (nights 3 and 4), no_build 0 of 10 (night 2), and every per-night number the same.
  implication: The walk change does not touch the balance shape the owner chose. The acceptance pins (balanced 7 or 8 wins, lost seeds exactly [3, 9], never before night 3) need no attention.

- timestamp: 2026-10-07T09:28:43Z
  checked: Full GUT suite on the same temporary edit (bash tools/test.sh, 279 s, log and junit copied to the session scratchpad)
  found: Scripts 95, Tests 829, Passing 826, Failing 3: the same three literal pins and nothing else. test_balance_acceptance.gd 8/8, test_fast_forward*.gd, test_determinism, test_king_sturdiness and test_run_outcomes all pass.
  implication: The fix plan has exactly three test edits to make, all of which encode the old decision.

- timestamp: 2026-10-07T09:28:43Z
  checked: Restore: cp of the scratchpad backup over data/king/king.tres, git diff --quiet -- data/king/king.tres (exit 0, printed RESTORED_CLEAN), git status --short
  found: Only ?? .planning/debug/king-walk-speed-1-5x.md remains.
  implication: Tree clean except this session file.

- timestamp: 2026-10-07T09:28:43Z
  checked: Consequences of walk 7.5 / sprint 12 / acceleration 60: stop distance v^2/2a, ramp time v/a, and ride times on the shipped plots (castle (0,0), king_spawn (0,7), houses (+-9,9) (+-18,-12) (0,-24), towers (+-55,20) (0,-55))
  found:
    - Stopping and ramp: the walk stop is 0.47 m (was 0.21 m) and the full-sprint stop 1.2 m (unchanged); both are inside the 2.5 m build radius. Ramp to walk speed is 0.125 s (was 0.083 s); ramp to sprint is 0.2 s (unchanged).
    - Sprint ratio: 1.6 (was 2.4). This is the source game's ratio again (FEATURES.md: 14 vs 23 wiki units, about 1.64x). The 01-04 15% band in test_king_ride.gd applies to the data multiplier and holds. Sprinting now adds 4.5 m/s instead of 7.0 and saves 37.5% of a ride instead of 58%.
    - Ride times, walk 5 -> walk 7.5 (sprint 12): king_spawn to the inner Houses, 9.2 m: 1.84 -> 1.23 s (0.77). To house_3/4, 26.2 m: 5.23 -> 3.49 s (2.18). To house_5, 31 m: 6.2 -> 4.13 s (2.58). To tower_1/2, 56.5 m: 11.3 -> 7.54 s (4.71). To tower_3, 62 m: 12.4 -> 8.27 s (5.17). tower_1 to tower_3, 93 m: 18.6 -> 12.4 s (7.75). The farthest pair, tower_1 to tower_2, 110 m: 22.0 -> 14.67 s (9.17).
    - D-03 (01-CONTEXT.md:57-60) says "Riding from edge to edge takes about 20-30 s at normal speed", and test_prototype_map_data.gd:12-13, :72-86 pins it. At 7.5 m/s the map is a 14.7 s walk.
    - Night mobility: the walk is 2.3x a grunt (3.2 m/s) and 2.7x a skirmisher (2.8 m/s); it was 1.6x and 1.8x. The top speed between roads is still 12 m/s. Under the 2x fast-forward, the walk covers 15 m/s and the sprint 24 m/s of ground in real time.
    - The day has no timer, so ride time costs only real time, never gold.
  implication: The only rule the request breaks is D-03's 20-30 s ride budget. It must be amended by the owner's decision (precedent: the dated D-05 amendments), not by growing the map, which would move every balance number. The bots cannot see the change. A human who rides without sprint gets a little more mobile, which can only make human play slightly easier.

- timestamp: 2026-10-07T09:28:43Z
  checked: Documents and comments that quote the walk, sprint or ride-time numbers (grep across .planning, simulation, presentation, tests and tools; historic PLAN/SUMMARY files left out)
  found:
    - simulation/defs/king_def.gd: :5 default walk_speed 5.0; :6-7 doc "12 m/s at walk 5.0 ... half again as fast as the 8 m/s sprint"; :8 default 2.4; :9-10 braking comment (still true for the sprint; add the 0.47 m walk stop).
    - tests/unit/test_king_movement_config.gd: :2-6 header; :10 SOURCE_WALK_SPEED 5.0; :11 OWNER_SPRINT_MULTIPLIER 2.4; :22-23; :26-27.
    - tests/unit/test_prototype_map_data.gd: :12-13 MIN_RIDE_S 20 / MAX_RIDE_S 30; :72-86.
    - .planning/phases/01-foundation-day-loop/01-CONTEXT.md:59 (D-03 ride time).
    - .planning/STATE.md: :123 ("110 m, 22 s") and :174 (02-13 "sprint 12 m/s (multiplier 2.4 ...)").
    - 02-PLAYTEST-GATE.md: :31 controls row "Sprint (12 m/s)" (there is no walk row). :84 assumption 12 (bots sprint at 12 m/s) is still true; it is worth adding that they never walk at night, so a walk change cannot move their numbers.
    - 02-BALANCE-REPORT.md:169 (02-13 row; add a round-4 note that the table is byte-identical).
    - ROADMAP.md:150 (02-13 row, still true; the new plan gets its own row).
    - tools/replay/playtest_bot.gd:66-67 doc ("idle and hold modes walk at the king's walking speed; the defending king sprints") stays true.
    - tools/screenshot/shot_scenarios.gd:257, :326, :385 walk the bot king to a hold point at walk pace. There are no image goldens; framing may shift slightly.
  implication: This is the fix plan's refresh list. No golden, fixture or replay line needs to change.

## Resolution

root_cause: "Not a code defect: an owner tuning decision on shipped data. The king's walk is data/king/king.tres:7 walk_speed = 5.0, and the 12 m/s sprint comes from :8 sprint_multiplier = 2.4 (King.move_speed = walk_speed x sprint_multiplier, presentation/king/king.gd:27-30). The exported commit 2bdcbd4 has the same values. The owner wants the walk 1.5x faster with the sprint kept at 12 m/s: walk_speed 7.5 and sprint_multiplier 1.6. Nothing in code reads a hard-coded speed. The change collides only with three tests that pin the old decision literally (walk == 5.0, multiplier == 2.4, and the ride budget). The ride-budget test encodes D-03's 'edge to edge about 20-30 s at normal speed'; at 7.5 m/s the farthest pair is 110 m / 7.5 = 14.67 s, and the owner's decision supersedes D-03."
fix: "(not applied - diagnose-only) Set walk_speed = 7.5 and sprint_multiplier = 1.6 in data/king/king.tres (acceleration 60 unchanged). Update the KingDef defaults and doc comment and the two literal pins in test_king_movement_config.gd. Amend D-03 and set the matching ride-time band in test_prototype_map_data.gd. Verified on a temporary edit: 826/829 pass with only those three red, and the bots, full_idle and smoke are byte-identical."
verification: "Diagnosis verified by code read and grep, and an IEEE double check of 5.0 x 2.4 and 7.5 x 1.6 (both exactly 12.0). A temporary 7.5 / 1.6 edit was measured with the four targeted GUT scripts, the full GUT suite, the smoke and full_idle replays, and a 5 x 10 playtest diffed against a HEAD baseline. Data restored from a cp backup; git diff --quiet -- data/king/king.tres passes; git status --short shows only this debug file."
files_changed: []
